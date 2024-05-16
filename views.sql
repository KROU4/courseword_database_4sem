CREATE OR REPLACE VIEW ActiveNFTs AS
SELECT NFTID, Title, Price, CollectionID, Owner
FROM NFT
WHERE Status = 'Available';


CREATE OR REPLACE VIEW CollectionsWithNFTCount AS
SELECT c.CollectionID, c.name, c.description, c.UserID, COUNT(n.NFTID) AS NFTCount
FROM Collections c
LEFT JOIN NFT n ON c.CollectionID = n.CollectionID
GROUP BY c.CollectionID, c.name, c.description, c.UserID;


CREATE OR REPLACE VIEW TransactionDetails AS
SELECT 
    t.TransactionID, 
    t.NFTID, 
    n.Title AS NFTTitle, 
    t.BuyerID, 
    b.UserName AS BuyerName,
    t.seller_id,
    s.UserName AS SellerName,
    t.TransactionStatus,
    t.transaction_time
FROM Transactions t
JOIN NFT n ON t.NFTID = n.NFTID
JOIN Users b ON t.BuyerID = b.UserID
JOIN Users s ON t.seller_id = s.UserID;
