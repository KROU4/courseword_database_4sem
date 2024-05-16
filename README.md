Функция: blob_to_png

Описание: Конвертирует BLOB изображение в файл PNG.
```sql
DECLARE
    l_result VARCHAR2(255);
BEGIN
    l_result := blob_to_png(
        p_blob => (SELECT user_photo FROM Users WHERE UserID = 1), 
        p_file_name => 'user_photo.png'
    );
    DBMS_OUTPUT.PUT_LINE(l_result);
END;
```

Функция: create_user_with_privileges

Описание: Создает нового пользователя с заданными правами.
```sql
DECLARE
    l_result VARCHAR2(255);
BEGIN
    l_result := create_user_with_privileges(
        p_username => 'new_user',
        p_password => 'password123',
        p_email => 'new_user@example.com',
        p_tel => '+1234567890'
    );
    DBMS_OUTPUT.PUT_LINE(l_result);
END;
```

Процедура: add_nft

Описание: Добавляет новый NFT в базу данных.
```sql
BEGIN
    add_nft(
        p_title => 'NFT Title',
        p_price => 100.00,
        p_collection_id => 1,
        p_owner_id => 1,
        p_photo => (SELECT user_photo FROM Users WHERE UserID = 1) 
    );
END;
```

Процедура: create_collection

Описание: Создает новую коллекцию NFT.
```sql
BEGIN
    create_collection(
        p_user_id => 1,
        p_name => 'Collection Name',
        p_description => 'Collection description',
        p_col_photo => (SELECT user_photo FROM Users WHERE UserID = 1) 
    );
END;
```

Процедура: define_roles

Описание: Определяет роль пользователя (администратор или обычный пользователь).
```sql
BEGIN
    define_roles(user_id => 1);
END;
```

Процедура: delete_nft

Описание: Удаляет NFT из базы данных.
```sql
BEGIN
    delete_nft(p_nft_id => 1, p_owner_id => 1);
END;
```

Процедура: dequeue_and_send_emails

Описание: Извлекает сообщения из очереди "COLLECTION_QUEUE" и отправляет email уведомления.
```sql
BEGIN
    dequeue_and_send_emails;
END;
```

Процедура: enqueue_collection_notification

Описание: Добавляет сообщение о создании новой коллекции в очередь "COLLECTION_QUEUE".
```sql
BEGIN
    enqueue_collection_notification(
        p_collection_id => 1,
        p_user_id => 1,
        p_collection_name => 'Collection Name'
    );
END;
```

Процедура: export_NFT_to_XML

Описание: Экспортирует данные NFT в XML файл.
```sql
BEGIN
    export_NFT_to_XML(filename => 'nfts.xml');
END;
```

Процедура: IMPORT_NFT_FROM_XML

Описание: Импортирует данные NFT из XML файла.
```sql
BEGIN
    IMPORT_NFT_FROM_XML(filename => 'nfts.xml');
END;
```

Процедура: Insert_NFT_Photo

Описание: Добавляет фотографию NFT в базу данных.
```sql
BEGIN
    Insert_NFT_Photo(
        p_nft_id => 1,
        p_photo_path => 'nft_photo.png' 
    );
END;
```

Процедура: rate_nft

Описание: Добавляет или обновляет рейтинг NFT.
```sql
BEGIN
    rate_nft(
        p_user_id => 1,
        p_nft_id => 1,
        p_rating => 5 
    );
END;
```

Процедура: search_nfts

Описание: Ищет NFT по заданным параметрам.
```sql
BEGIN
    search_nfts(
        p_search_term => 'NFT',
        p_collection_id => 1,
        p_status => 'Available',
        p_min_price => 50.00,
        p_max_price => 200.00
    );
END;
```

Процедура: view_user_info

Описание: Показывает информацию о пользователях (только для администраторов).
```sql
BEGIN
    view_user_info(p_admin_id => 1);
END;
```

Процедура: add_comment

Описание: Добавляет комментарий к NFT.
```sql
BEGIN
    add_comment(
        p_UserID => 1, 
        p_NFTID => 1, 
        p_CommentText => 'This is a great NFT!' 
    );
END;
```

Процедура: like_comment

Описание: Увеличивает количество лайков к комментарию.
```sql
BEGIN
    like_comment(p_CommentID => 1);
END;
```
