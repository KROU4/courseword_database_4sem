import tkinter as tk
from tkinter import filedialog
import cx_Oracle
from PIL import Image, ImageTk
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import io

# Детали подключения к базе данных
db_user = 'system'
db_password = '*******'
db_dsn = 'localhost'

# Функция для подключения к базе данных с обработкой ошибок
def connect_to_db():
    try:
        connection = cx_Oracle.connect(db_user, db_password, db_dsn)
        print("Успешное подключение к базе данных!")
        return connection
    except cx_Oracle.Error as error:
        print("Ошибка подключения к базе данных:", error)
        return None

# Функция для выполнения SQL-запроса и получения данных BLOB
def fetch_blob_data(nft_id):
    conn = connect_to_db()
    if conn:
        cursor = conn.cursor()
        # Получение данных BLOB на основе nft_id
        cursor.execute("SELECT photo FROM NFT WHERE NFTID = :id", id=nft_id)
        result = cursor.fetchone()
        if result:
            blob_data = result[0].read()  # Чтение данных BLOB
            return blob_data
        else:
            print("Ошибка: NFT не найден с ID:", nft_id)
        conn.close()
    else:
        print("Ошибка: Не удалось подключиться к базе данных.")
    return None

# Функция для преобразования BLOB в PNG и отображения
def process_and_display_image(nft_id, root, nft_label):
    blob_data = fetch_blob_data(nft_id)
    if blob_data:
        # Преобразование данных BLOB в изображение
        image = Image.open(io.BytesIO(blob_data))
        # Изменение размера изображения до 256x256 пикселей
        image.thumbnail((256, 256))
        photo = ImageTk.PhotoImage(image)
        # Отображение изображения и текста в метке
        label = tk.Label(root, image=photo, text=nft_label, compound=tk.TOP)
        label.image = photo  # Сохранение ссылки для предотвращения сборки мусора
        label.pack(side=tk.LEFT, padx=10, pady=10)
    else:
        nft_label.config(text=f"Ошибка при получении NFT с ID: {nft_id}")

# Функция для получения данных NFT из базы данных
def fetch_nfts():
    conn = connect_to_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT NFTID, Title, Price FROM NFT")  # Получение nft_id, title и price
        nfts = cursor.fetchall()
        conn.close()
        return nfts
    else:
        return None

# Функция для вставки данных коллекции в базу данных
def insert_collection_data(user_id, collection_name, collection_description, photo_path):
    conn = connect_to_db()
    if conn:
        cursor = conn.cursor()
        try:
            # Чтение файла изображения и преобразование его в бинарные данные
            with open(photo_path, 'rb') as f:
                photo_data = f.read()
            # Вставка данных коллекции в базу данных
            cursor.execute(
                "INSERT INTO Collections (CollectionID, UserID, col_photo, description, name) "
                "VALUES (COLLECTION_ID_SEQ.NEXTVAL, :user_id, :photo, :description, :name)",
                user_id=user_id, photo=photo_data, description=collection_description, name=collection_name
            )
            conn.commit()
            print("Данные коллекции успешно вставлены!")
            return True
        except cx_Oracle.Error as error:
            print("Ошибка вставки данных коллекции:", error)
            conn.rollback()
        finally:
            conn.close()
    return False

# Функция для обработки события нажатия кнопки для выбора фото
def select_photo():
    # Запрос пользователю выбрать файл фото
    photo_path = filedialog.askopenfilename()
    photo_path_entry.delete(0, tk.END)
    photo_path_entry.insert(0, photo_path)

# Функция для обработки события нажатия кнопки для добавления коллекции
def add_collection():
    # Получение данных из полей ввода
    user_id = user_id_entry.get()
    collection_name = collection_name_entry.get()
    collection_description = collection_description_entry.get()
    photo_path = photo_path_entry.get()
    # Получение email пользователя
    user_email = fetch_user_email(user_id)
    if user_email:
        # Вставка данных коллекции в базу данных
        if insert_collection_data(user_id, collection_name, collection_description, photo_path):
            # Отправка email-уведомления
            send_email_notification(user_email, collection_name, collection_description, photo_path)
            # Очистка полей ввода
            user_id_entry.delete(0, tk.END)
            collection_name_entry.delete(0, tk.END)
            collection_description_entry.delete(0, tk.END)
            photo_path_entry.delete(0, tk.END)
            status_label.config(text="Коллекция успешно добавлена и уведомление по электронной почте отправлено.")
            return
    status_label.config(text="Ошибка добавления коллекции: Пользователь не найден или неверный UserID.")

# Функция для получения email пользователя из базы данных
def fetch_user_email(user_id):
    conn = connect_to_db()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT email FROM Users WHERE UserID = :id", id=user_id)
        result = cursor.fetchone()
        if result:
            user_email = result[0]
            conn.close()
            return user_email
        else:
            print("Ошибка: Пользователь не найден с ID:", user_id)
        conn.close()
    else:
        print("Ошибка: Не удалось подключиться к базе данных.")
    return None

# Функция для отправки email-уведомления
def send_email_notification(user_email, collection_name, collection_description, photo_path):
    # Данные сервера электронной почты
    smtp_server = 'smtp.gmail.com'
    smtp_port = 587
    smtp_username = '*******@gmail.com'
    smtp_password = '*********************'
    # Содержимое email
    sender_email = '*******@gmail.com'
    receiver_email = user_email
    subject = 'Добавлена новая коллекция'
    body = f'Здравствуйте,\n\nВаша коллекция «{collection_name}» успешно добавлена.\n'
    body += f'Описание коллекции: {collection_description}\n'
    body += f'Путь к фото: {photo_path}'
    # Создание многочастного сообщения и установка заголовков
    message = MIMEMultipart()
    message['From'] = sender_email
    message['To'] = receiver_email
    message['Subject'] = subject
    # Добавление текста сообщения
    message.attach(MIMEText(body, 'plain'))
    # Подключение к SMTP-серверу и отправка email
    try:
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls()
        server.login(smtp_username, smtp_password)
        text = message.as_string()
        server.sendmail(sender_email, receiver_email, text)
        print("Email-уведомление успешно отправлено!")
        server.quit()
        return True
    except Exception as e:
        print("Ошибка отправки email-уведомления:", e)
        return False

# Создание главного окна приложения
root = tk.Tk()
root.title("NFT Marketplace и Менеджер Коллекций")

# Фрейм для всех NFT
nft_frame = tk.Frame(root)
nft_frame.pack()

# Функция для получения и отображения NFT
def display_nfts():
    nfts = fetch_nfts()
    if nfts:
        for nft_id, title, price in nfts:
            nft_data = f"{nft_id}) {title} - {price}$"
            process_and_display_image(nft_id, nft_frame, nft_data)
    else:
        nft_label = tk.Label(nft_frame, text="Ошибка при получении NFT из базы данных")
        nft_label.pack()

# Кнопка для получения и отображения NFT
fetch_button = tk.Button(root, text="Получить NFT", command=display_nfts)
fetch_button.pack()

# Метка и поле ввода для UserID
user_id_label = tk.Label(root, text="UserID:")
user_id_label.pack()
user_id_entry = tk.Entry(root)
user_id_entry.pack()

# Метка и поле ввода для имени коллекции
collection_name_label = tk.Label(root, text="Имя коллекции:")
collection_name_label.pack()
collection_name_entry = tk.Entry(root)
collection_name_entry.pack()

# Метка и поле ввода для описания коллекции
collection_description_label = tk.Label(root, text="Описание коллекции:")
collection_description_label.pack()
collection_description_entry = tk.Entry(root)
collection_description_entry.pack()

# Метка и поле ввода для пути к фото
photo_path_label = tk.Label(root, text="Путь к фото:")
photo_path_label.pack()
photo_path_entry = tk.Entry(root)
photo_path_entry.pack()

# Кнопка для выбора файла фото
browse_button = tk.Button(root, text="Выбрать", command=select_photo)
browse_button.pack()

# Кнопка для добавления коллекции
add_button = tk.Button(root, text="Добавить коллекцию", command=add_collection)
add_button.pack()

# Метка для статуса сообщения
status_label = tk.Label(root, text="")
status_label.pack()

# Метка для отображения данных NFT
nft_label = tk.Label(root, text="")
nft_label.pack()

# Запуск цикла обработки событий Tkinter
root.mainloop()
