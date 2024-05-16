create or replace NONEDITIONABLE TRIGGER trg_after_collection_insert
 AFTER INSERT ON Collections
 FOR EACH ROW
 BEGIN
     enqueue_collection_notification(:NEW.CollectionID,
     :NEW.UserID, :NEW.name);
 END;


CREATE OR REPLACE TRIGGER check_transaction_time_and_comments
BEFORE INSERT ON Transactions
FOR EACH ROW
DECLARE
    nft_status NFT.Status%TYPE;
    comment_count INTEGER;
BEGIN
    -- Проверка статуса NFT
    SELECT Status INTO nft_status
    FROM NFT
    WHERE NFTID = :NEW.NFTID;

    IF nft_status <> 'Available' THEN
        RAISE_APPLICATION_ERROR(-20001, 'NFT is not available for purchase.');
    END IF;

    -- Проверка количества комментариев
    SELECT COUNT(*) INTO comment_count
    FROM Comments
    WHERE NFTID = :NEW.NFTID;

    IF comment_count < 5 THEN
        RAISE_APPLICATION_ERROR(-20002, 'NFT must have at least 5 comments before it can be purchased.');
    END IF;
END;
