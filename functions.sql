 create or replace NONEDITIONABLE FUNCTION blob_to_png (
     p_blob IN BLOB,
     p_file_name IN VARCHAR2
 ) RETURN VARCHAR2
 AS
     l_output_file
     UTL_FILE.FILE_TYPE;
     l_chunk_size
     BINARY_INTEGER := 32767;
     l_buffer RAW(32767);
     l_blob_len INTEGER;
 BEGIN
     -- Открытие файла для записи
     l_output_file
     := UTL_FILE.FOPEN('IMAGE_DIR', p_file_name, 'wb');
  
     -- Получение длины BLOB
     l_blob_len :=
     DBMS_LOB.getlength(p_blob);
  
     -- Чтение BLOB и запись в файл порциями
     FOR i IN 1..CEIL(l_blob_len / l_chunk_size)
     LOOP
         DBMS_LOB.read(p_blob,
     l_chunk_size, (i - 1) * l_chunk_size + 1, l_buffer);
         UTL_FILE.PUT_RAW(l_output_file,
     l_buffer, TRUE);
     END LOOP;
  
     -- Закрытие файла
     UTL_FILE.FCLOSE(l_output_file);
  
     -- Проверка успешности операции
     IF
     UTL_FILE.IS_OPEN(l_output_file) THEN
         RETURN 'File overwritten successfully!';
     ELSE
         RETURN 'File created successfully!';
     END IF;
 EXCEPTION
     WHEN OTHERS THEN
         IF
     UTL_FILE.IS_OPEN(l_output_file) THEN
             UTL_FILE.FCLOSE(l_output_file);
         END IF;
         RETURN 'Error creating file: ' || SQLERRM;
 END;


create or replace NONEDITIONABLE FUNCTION create_user_with_privileges (
     p_username IN VARCHAR2,
     p_password IN VARCHAR2,
     p_email IN VARCHAR2,
     p_tel IN VARCHAR2
 ) RETURN VARCHAR2
 AS
     l_user_id NUMBER;
 BEGIN
     -- 1. Create User
     EXECUTE IMMEDIATE 'CREATE USER ' || p_username || '
     IDENTIFIED BY ' ||
     p_password;
  
     -- 2. Get User ID
     SELECT user_id
     INTO l_user_id
     FROM all_users
     WHERE username = p_username;
  
     --
     3. Insert User Data into Users Table
     INSERT INTO Users
     (UserID, UserName, Email, Password, tel)
     VALUES (l_user_id, p_username, p_email,
     p_password, p_tel);
  
     -- 4. Grant Basic Privileges 
     EXECUTE IMMEDIATE 'GRANT CONNECT,
     RESOURCE TO ' ||
     p_username;
  
     --
     5. Grant Object Privileges (Customize as needed)
     EXECUTE IMMEDIATE 'GRANT SELECT,
     INSERT, UPDATE, DELETE ON NFT TO ' ||
     p_username;
     --
     Add more grants for other tables or procedures as required
  
     RETURN 'User created successfully!';
 EXCEPTION
     WHEN OTHERS THEN
         RETURN 'Error creating user: ' || SQLERRM;
 END;
