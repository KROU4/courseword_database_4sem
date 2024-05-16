 create or replace NONEDITIONABLE PROCEDURE add_nft (
     p_title IN NFT.Title%TYPE,
     p_price IN NFT.Price%TYPE,
     p_collection_id
     IN NFT.CollectionID%TYPE,
     p_owner_id IN NFT.Owner%TYPE,
     p_photo IN NFT.Photo%TYPE
 )
 AS
 BEGIN
     INSERT INTO NFT
     (Title, Price, Status, CollectionID, TimeAdded, Owner, Photo)
     VALUES (p_title, p_price, 'Available', p_collection_id,
     SYSDATE, p_owner_id, p_photo);
  
     DBMS_OUTPUT.PUT_LINE('NFT
     added successfully!');
 EXCEPTION
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error
     adding NFT: ' ||
     SQLERRM);
 END;


create or replace NONEDITIONABLE PROCEDURE create_collection (
     p_user_id IN Collections.UserID%TYPE,
     p_name IN Collections.name%TYPE,
     p_description
     IN Collections.description%TYPE,
     p_col_photo IN Collections.col_photo%TYPE DEFAULT NULL 
 )
 AS
 BEGIN
     INSERT INTO Collections
     (UserID, name, description,
     col_photo)
     VALUES (p_user_id, p_name, p_description,
     p_col_photo);
  
     DBMS_OUTPUT.PUT_LINE('Collection
     created successfully!');
 EXCEPTION
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error
     creating collection: ' ||
     SQLERRM);
 END;

 create or replace NONEDITIONABLE PROCEDURE define_roles (
     user_id IN INT
 )
 AS
     user_role VARCHAR2(20);
 BEGIN
     SELECT admin_status
     INTO user_role
     FROM Admins
     WHERE UserID = user_id;
  
     IF user_role IS NOT NULL THEN
         DBMS_OUTPUT.PUT_LINE('Role:
     Administrator');
     ELSE
         DBMS_OUTPUT.PUT_LINE('Role:
     User');
     END IF;
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('Role:
     User');
     --
     Assuming users without an admin record are regular users
 END;

 create or replace NONEDITIONABLE PROCEDURE delete_nft (
     p_nft_id IN NFT.NFTID%TYPE,
     p_owner_id IN NFT.Owner%TYPE
 )
 AS
     nft_owner_id
     NFT.Owner%TYPE;
 BEGIN
     --
     Check if the NFT exists and is owned by the user
     SELECT Owner
     INTO nft_owner_id
     FROM NFT
     WHERE NFTID = p_nft_id;
  
     IF
     nft_owner_id = p_owner_id THEN
         DELETE FROM NFT
     WHERE NFTID = p_nft_id;
         DBMS_OUTPUT.PUT_LINE('NFT
     deleted successfully!');
     ELSE
         DBMS_OUTPUT.PUT_LINE('You
     are not authorized to delete this NFT.');
     END IF;
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('NFT
     not found.');
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error
     deleting NFT: ' ||
     SQLERRM);
 END;


create or replace NONEDITIONABLE PROCEDURE dequeue_and_send_emails AS
     l_dequeue_options    
     DBMS_AQ.dequeue_options_t;
     l_message_properties 
     DBMS_AQ.message_properties_t;
     l_message_id         RAW(16);
     l_payload           
     SYS.AQ$_JMS_TEXT_MESSAGE;
     l_message           
     VARCHAR2(4000);
     l_user_id           
     NUMBER;
     l_user_email        
     VARCHAR2(100);
     l_mail_conn         
     UTL_SMTP.connection;
 BEGIN
     DBMS_AQ.dequeue (
         queue_name         
     => 'COLLECTION_QUEUE',
         dequeue_options    
     => l_dequeue_options,
         message_properties 
     => l_message_properties,
         payload            
     => l_payload,
         msgid              
     => l_message_id
     );
  
     l_message :=
     l_payload.text_vc;
  
     --
     Extract User ID from the message 
     l_user_id :=
     REGEXP_SUBSTR(l_message, 'User ID: (\d+)',
     1, 1, NULL,
     1);
  
     --
     Get user email based on User ID
     SELECT Email INTO l_user_email FROM Users WHERE UserID = l_user_id;
  
     -- Configure SMTP settings 
     l_mail_conn
     := UTL_SMTP.open_connection('smtp.gmail.com', 587);
     --
     
     UTL_SMTP.helo(l_mail_conn,
     'dimon22938@gmail.com'); 
     
     UTL_SMTP.mail(l_mail_conn,
     'dimon22938@gmail.com');
     UTL_SMTP.rcpt(l_mail_conn,
     l_user_email);
  
     -- Send the email
     UTL_SMTP.data(l_mail_conn,
     
         'From:
     NFT Marketplace < dimon22938@gmail.com >' ||
     UTL_TCP.crlf ||
         'To:
     ' || l_user_email || UTL_TCP.crlf ||
         'Subject:
     New Collection Created!' ||
     UTL_TCP.crlf ||
         l_message || UTL_TCP.crlf
     );
  
     UTL_SMTP.quit(l_mail_conn);
  
     COMMIT;
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('User
     ID not found in message: ' ||
     l_message);
     WHEN OTHERS THEN
         ROLLBACK;
         -- Handle other exceptions and logging
         DBMS_OUTPUT.PUT_LINE('Error
     sending email: ' ||
     SQLERRM);
 END;

create or replace NONEDITIONABLE PROCEDURE enqueue_collection_notification (
     p_collection_id
     IN NUMBER,
     p_user_id IN NUMBER,
     p_collection_name IN VARCHAR2
 ) AS
     l_enqueue_options    
     DBMS_AQ.enqueue_options_t;
     l_message_properties 
     DBMS_AQ.message_properties_t;
     l_message_id         RAW(16);
     l_payload           
     SYS.AQ$_JMS_TEXT_MESSAGE;
 BEGIN
     l_payload :=
     SYS.AQ$_JMS_TEXT_MESSAGE.construct();
     l_payload.set_text('New
     collection created: ' ||
     p_collection_name || ' (ID: ' ||
     p_collection_id || ') by User ID: ' || p_user_id);
  
     DBMS_AQ.enqueue (
         queue_name         
     => 'COLLECTION_QUEUE',
         enqueue_options    
     => l_enqueue_options,
         message_properties 
     => l_message_properties,
         payload            
     => l_payload,
         msgid              
     => l_message_id
     );
     COMMIT;
 END;

create or replace NONEDITIONABLE PROCEDURE export_NFT_to_XML(filename IN VARCHAR2) AS
     v_file
     UTL_FILE.FILE_TYPE;
     v_xml XMLTYPE;
 BEGIN
     -- Создание XMLTYPE объекта с данными из таблицы NFT
     SELECT XMLELEMENT("NFTs",
                XMLAGG(XMLELEMENT("NFT",
                        XMLFOREST(NFTID
     AS "NFTID",
                                  Title
     AS "Title",
                                  Price
     AS "Price",
                                  Status
     AS "Status",
                                  CollectionID
     AS "CollectionID",
                                  TimeAdded
     AS "TimeAdded",
                                  Owner
     AS "Owner"))))
     INTO v_xml
     FROM NFT;
  
     -- Создание файла и запись в него XML данных
     v_file :=
     UTL_FILE.FOPEN('XML_DIR', filename, 'W');
     UTL_FILE.PUT_LINE(v_file,
     v_xml.getClobVal());
     UTL_FILE.FCLOSE(v_file);
 EXCEPTION
     WHEN OTHERS THEN
         IF
     UTL_FILE.IS_OPEN(v_file) THEN
             UTL_FILE.FCLOSE(v_file);
         END IF;
         RAISE;
 END;

create or replace NONEDITIONABLE PROCEDURE IMPORT_NFT_FROM_XML(filename IN VARCHAR2) AS
     v_file
     UTL_FILE.FILE_TYPE;
     v_line VARCHAR2(32767); -- Line buffer
     v_xml XMLTYPE;
 BEGIN
     --
     Open the XML file for reading
     v_file
     := UTL_FILE.FOPEN('XML_DIR', filename, 'R');
  
     --
     Read the XML data from the file
     UTL_FILE.GET_LINE(v_file,
     v_line);
     v_xml
     := XMLTYPE(v_line);
  
     --
     Insert the data into the NFT table
     INSERT INTO NFT
     (NFTID, Title, Price, Status, CollectionID, TimeAdded, Owner)
     SELECT x.NFTID,
            x.Title,
            x.Price,
            x.Status,
            x.CollectionID,
            TO_TIMESTAMP(x.TimeAdded,
     'YYYY-MM-DD
     HH24:MI:SS'),
            x.Owner
     FROM XMLTABLE('/NFTs/NFT'
         PASSING
     v_xml
         COLUMNS
             NFTID
     INT PATH 'NFTID',
             Title
     VARCHAR2(100) PATH 'Title',
             Price
     DECIMAL(18,2) PATH 'Price',
             Status
     VARCHAR2(20) PATH 'Status',
             CollectionID
     INT PATH 'CollectionID',
             TimeAdded
     VARCHAR2(20) PATH 'TimeAdded',
             Owner
     INT PATH 'Owner') AS x;
  
     -- Close the file
     UTL_FILE.FCLOSE(v_file);
 EXCEPTION
     WHEN OTHERS THEN
         IF
     UTL_FILE.IS_OPEN(v_file) THEN
             UTL_FILE.FCLOSE(v_file);
         END IF;
         RAISE;
 END;

create or replace NONEDITIONABLE PROCEDURE Insert_NFT_Photo(
     p_nft_id INT,
     p_photo_path VARCHAR2
 ) AS
     v_blob BLOB;
     v_blob_length INTEGER;
     v_file
     UTL_FILE.FILE_TYPE;
 BEGIN
     -- Чтение файла PNG в BLOB переменную
     DBMS_LOB.CREATETEMPORARY(v_blob,
     TRUE);
     v_file :=
     UTL_FILE.FOPEN('PHOTO_DIR', p_photo_path, 'r');
     UTL_FILE.GET_RAW(v_file,
     v_blob);
     v_blob_length
     := DBMS_LOB.GETLENGTH(v_blob);
     UTL_FILE.FCLOSE(v_file);
  
     -- Обновление фотографии в таблице NFT
     UPDATE NFT
     SET PHOTO = v_blob
     WHERE NFTID = p_nft_id;
  
     COMMIT;
  
     DBMS_OUTPUT.PUT_LINE('Photo
     added successfully for NFTID: ' ||
     p_nft_id);
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('NFT
     not found with ID: ' ||
     p_nft_id);
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error:
     ' || SQLERRM);
 END Insert_NFT_Photo;

create or replace NONEDITIONABLE PROCEDURE rate_nft (
     p_user_id
     IN Comments.UserID%TYPE,
     p_nft_id
     IN Comments.NFTID%TYPE,
     p_rating
     IN Comments.like_col%TYPE
 )
 AS
     existing_rating
     Comments.like_col%TYPE;
 BEGIN
     --
     Check if the user has already rated the NFT
     SELECT like_col
     INTO existing_rating
     FROM Comments
     WHERE UserID = p_user_id AND NFTID = p_nft_id;
  
     IF
     existing_rating IS NULL THEN
         -- Insert new rating
         INSERT INTO Comments
     (UserID, NFTID, like_col, time_posted)
         VALUES (p_user_id, p_nft_id, p_rating,
     SYSDATE);
         DBMS_OUTPUT.PUT_LINE('NFT
     rated successfully!');
     ELSE
         -- Update existing rating
         UPDATE Comments
         SET like_col = p_rating, time_posted =
     SYSDATE
         WHERE UserID = p_user_id AND NFTID = p_nft_id;
         DBMS_OUTPUT.PUT_LINE('NFT
     rating updated successfully!');
     END IF;
 EXCEPTION
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error
     rating NFT: ' ||
     SQLERRM);
 END;

 create or replace NONEDITIONABLE PROCEDURE search_nfts (
     p_search_term
     IN VARCHAR2 DEFAULT NULL,
     p_collection_id
     IN NFT.CollectionID%TYPE DEFAULT NULL,
     p_status IN NFT.Status%TYPE DEFAULT NULL,
     p_min_price IN NFT.Price%TYPE DEFAULT NULL,
     p_max_price IN NFT.Price%TYPE DEFAULT NULL
 )
 AS
 BEGIN
     --
     Build dynamic WHERE clause based on provided parameters
     FOR nft_rec IN (
         SELECT NFTID, Title, Price, Status,
     CollectionID
         FROM NFT
         WHERE (p_search_term IS NULL OR Title LIKE '%' ||
     p_search_term || '%')
           AND (p_collection_id IS NULL OR CollectionID = p_collection_id)
           AND (p_status IS NULL OR Status = p_status)
           AND (p_min_price IS NULL OR Price >= p_min_price)
           AND (p_max_price IS NULL OR Price <= p_max_price)
     ) LOOP
         DBMS_OUTPUT.PUT_LINE('NFTID:
     ' || nft_rec.NFTID);
         DBMS_OUTPUT.PUT_LINE('Title:
     ' || nft_rec.Title);
         DBMS_OUTPUT.PUT_LINE('Price:
     ' || nft_rec.Price);
         DBMS_OUTPUT.PUT_LINE('Status:
     ' || nft_rec.Status);
         DBMS_OUTPUT.PUT_LINE('CollectionID:
     ' || nft_rec.CollectionID);
         DBMS_OUTPUT.PUT_LINE('------------------------------');
     END LOOP;
 EXCEPTION
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error
     searching NFTs: ' ||
     SQLERRM);
 END;

 create or replace NONEDITIONABLE PROCEDURE view_user_info (
     p_admin_id IN Admins.AdminID%TYPE
 )
 AS
     user_role VARCHAR2(20);
 BEGIN
     --
     Verify if the user is an admin
     SELECT admin_status
     INTO user_role
     FROM Admins
     WHERE AdminID = p_admin_id;
  
     IF user_role IS NOT NULL THEN
         -- Display user information
         FOR user_rec IN (SELECT UserID, UserName, Email, tel FROM Users) LOOP
             DBMS_OUTPUT.PUT_LINE('UserID:
     ' || user_rec.UserID);
             DBMS_OUTPUT.PUT_LINE('Username:
     ' || user_rec.UserName);
             DBMS_OUTPUT.PUT_LINE('Email:
     ' || user_rec.Email);
             DBMS_OUTPUT.PUT_LINE('Phone:
     ' || user_rec.tel);
             DBMS_OUTPUT.PUT_LINE('------------------------------');
         END LOOP;
     ELSE
         DBMS_OUTPUT.PUT_LINE('Access
     denied. You must be an administrator to view user information.');
     END IF;
 EXCEPTION
     WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('No
     users found.');
     WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE('Error:
     ' || SQLERRM);
 END;

CREATE OR REPLACE PROCEDURE add_comment (
    p_UserID IN Comments.UserID%TYPE,
    p_NFTID IN Comments.NFTID%TYPE,
    p_CommentText IN Comments.CommentText%TYPE
)
AS
BEGIN
    INSERT INTO Comments (UserID, NFTID, CommentText, time_posted)
    VALUES (p_UserID, p_NFTID, p_CommentText, SYSDATE);
    
    COMMIT;
END;

CREATE OR REPLACE PROCEDURE like_comment (
    p_CommentID IN Comments.CommentID%TYPE
)
AS
BEGIN
    UPDATE Comments
    SET like_col = like_col + 1
    WHERE CommentID = p_CommentID;

    COMMIT;
END;

