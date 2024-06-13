CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY,
    name NVARCHAR(255) NOT NULL,
    username NVARCHAR(255) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE,
    role NVARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    avatar_image_data VARBINARY(MAX),
    is_banned BIT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
);
GO

CREATE TABLE mangas (
    id INT PRIMARY KEY IDENTITY,
    name NVARCHAR(255) NOT NULL,
    author_id INT NOT NULL,
    manga_cover_image_data VARBINARY(MAX),
    summary NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (author_id) REFERENCES users(id)
);
GO

CREATE TABLE genres (
    id INT PRIMARY KEY IDENTITY,
    description NVARCHAR(255),
    name NVARCHAR(255) NOT NULL UNIQUE
);
GO

CREATE TABLE manga_genre (
    manga_id INT,
    genre_id INT,
    PRIMARY KEY (manga_id, genre_id),
    FOREIGN KEY (manga_id) REFERENCES mangas(id),
    FOREIGN KEY (genre_id) REFERENCES genres(id)
);
GO

CREATE TABLE users_mangas (
    user_id INT,
    manga_id INT,
    is_favorite BIT DEFAULT 0,
    rating INT DEFAULT NULL,
    PRIMARY KEY (user_id, manga_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (manga_id) REFERENCES mangas(id)
);
GO


CREATE TABLE chapters (
    id INT PRIMARY KEY IDENTITY,
    manga_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    number INT NOT NULL,
    chapter_image_data VARBINARY(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (manga_id) REFERENCES mangas(id),
);
GO


CREATE TABLE comments (
    id INT PRIMARY KEY IDENTITY,
    user_id INT NOT NULL,
    manga_id INT NOT NULL,
    comment NVARCHAR(MAX) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (manga_id) REFERENCES mangas(id)
);
GO

CREATE TABLE notifications (
    id INT PRIMARY KEY IDENTITY,
    user_id INT NOT NULL,
    manga_id INT NOT NULL,
    chapter_id INT NULL,
    message NVARCHAR(MAX) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    read_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (manga_id) REFERENCES mangas(id),
    FOREIGN KEY (chapter_id) REFERENCES chapters(id)
);
GO

-- 1
-- tao du lieu cho bang genres
INSERT INTO genres (name) VALUES ('Action');
INSERT INTO genres (name) VALUES ('Adventure');
INSERT INTO genres (name) VALUES ('Comedy');
INSERT INTO genres (name) VALUES ('Drama');
INSERT INTO genres (name) VALUES ('Fantasy');
INSERT INTO genres (name) VALUES ('Horror');
INSERT INTO genres (name) VALUES ('Mystery');
INSERT INTO genres (name) VALUES ('Psychological');
INSERT INTO genres (name) VALUES ('Romance');
INSERT INTO genres (name) VALUES ('Sci-fi');
INSERT INTO genres (name) VALUES ('Slice of Life');
INSERT INTO genres (name) VALUES ('Supernatural');
GO

------------------------------------------------------
-- User logic ----------------------------------------

-- 1 
-- huy
-- insert_user stored procedure dung de insert user vao bang users
CREATE PROCEDURE insert_user
    @name NVARCHAR(255),
    @username NVARCHAR(255),
    @password NVARCHAR(255),
    @email NVARCHAR(255),
    @role NVARCHAR(50) = 'user',
    @avatar_image_data VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id INT;

    INSERT INTO users (name, username, password, email, role, avatar_image_data)
    VALUES (@name, @username, @password, @email, @role, @avatar_image_data);

    -- Lay id cua user vua insert
    SET @id = SCOPE_IDENTITY();

    RETURN @id;
END;
GO

-- 1
-- huy
-- check_user_exists stored procedure dung de kiem tra xem user da ton tai hay chua
CREATE PROCEDURE check_user_exists
    @username NVARCHAR(255),
    @email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM dbo.users WHERE username = @username OR email = @email;
END;
GO

-- 1
-- IF EXISTS (SELECT name FROM sys.indexes WHERE name = 'idx_username' AND object_id = OBJECT_ID('dbo.users'))
-- BEGIN
--     DROP INDEX idx_username ON dbo.users;
-- END

-- 1
-- Huy
-- Tao index cho cot username trong bang users
CREATE INDEX idx_username ON dbo.users (username);
GO

-- 1
-- Huy
-- get_password_by_username stored procedure dung de lay password cua user dua vao username
CREATE PROCEDURE get_password_by_username
    @username NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT password FROM dbo.users WHERE username = @username;
END;
GO

-- 1
-- huy
-- get_user_by_username stored procedure dung de lay thong tin cua user dua vao username
CREATE PROCEDURE get_user_by_username
    @username NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM dbo.users WHERE username = @username;
END;
GO

-- 1
-- huy
-- ban_user stored procedure dung de ban user
CREATE PROCEDURE ban_user
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE users
    SET is_banned = 1
    WHERE id = @user_id;
END;
GO

-- 1
-- huy
-- unban_user stored procedure dung de unban user
CREATE PROCEDURE unban_user
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE users
    SET is_banned = 0
    WHERE id = @user_id;
END;
GO

-- 1
-- huy
-- update_user stored procedure dung de update thong tin cua user
CREATE INDEX idx_user_id ON users(id);
GO

------------------------------------------------------------
-- Manga logic ---------------------------------------------

-- 1
-- thang + vinh
-- insert_manga_genres stored procedure dung de insert manga vao bang mangas va insert genre cua manga do vao bang manga_genre
CREATE PROCEDURE insert_manga_genres
    @name NVARCHAR(255),
    @author_id INT,
    @manga_cover_image_data VARBINARY(MAX),
    @summary NVARCHAR(MAX),
    @genres NVARCHAR(MAX) -- Cac genre cua manga duoc ngan cach boi dau phay
AS
BEGIN
    SET NOCOUNT ON; -- Cau lenh SET NOCOUNT ON se ngan chan SQL Server tra ve so dong bi anh huong boi cau lenh INSERT

    DECLARE @id INT;

    -- Hai cau lenh INSERT duoi day se insert manga vao bang mangas va lay id cua manga vua insert
    INSERT INTO mangas (name, author_id, manga_cover_image_data, summary)
    VALUES (@name, @author_id, @manga_cover_image_data, @summary);

    -- Lay id cua manga vua insert
    SET @id = SCOPE_IDENTITY();

    -- Ba cau lenh duoi day se insert cac genre cua manga do vao bang manga_genre
    DECLARE @genre NVARCHAR(255); -- Bien nay se chua ten cua genre duoc lay ra tu chuoi genres
    DECLARE @start INT = 1; -- Vi tri bat dau cua genre hien tai trong chuoi genres
    DECLARE @pos INT = CHARINDEX(',', @genres); -- Vi tri cua dau phay dau tien trong chuoi genres
                                                -- CHARINDEX se tra ve 0 neu khong tim thay dau phay
                                                -- Neu tim thay dau phay, thi tra ve vi tri cua dau phay do trong chuoi
                                                -- Se tra ve vi tri cua dau phay dau tien trong chuoi genres

    WHILE @pos > 0
    BEGIN
        SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, @pos - @start))); -- Lay ten genre hien tai
                                                    -- LTRIM va RTRIM dung de loai bo khoang trang o dau va cuoi chuoi
        INSERT INTO manga_genre (manga_id, genre_id) -- Insert genre hien tai vao bang manga_genre
        SELECT @id, id FROM genres WHERE name = @genre; -- Lay id cua genre hien tai

        SET @start = @pos + 1;  -- Cap nhat vi tri bat dau cho genre tiep theo
        SET @pos = CHARINDEX(',', @genres, @start); -- Tim vi tri cua dau phay tiep theo
                                -- CHARINDEX gom 3 tham so: chuoi can tim, chuoi tim kiem, vi tri bat dau tim kiem
    END

    -- Insert genre cuoi cung
    SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, LEN(@genres) - @start + 1)));
    INSERT INTO manga_genre (manga_id, genre_id)
    SELECT @id, id FROM genres WHERE name = @genre;

    RETURN @id;
END;
GO

-- 1
-- thang + vinh
-- get_manga_by_author_id stored procedure dung de lay tat ca manga cua mot tac gia
CREATE PROCEDURE get_manga_by_author_id
    @author_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM mangas WHERE author_id = @author_id;
END;
GO

-- 1
-- thang + vinh
-- view_all_mangas la view chua tat ca thong tin cua mot manga
-- bao gom ten manga, ten tac gia, summary, cover image, created_at, updated_at
CREATE VIEW view_all_mangas AS
SELECT 
    m.id AS manga_id,
    m.author_id,
    m.name AS manga_name,
    u.name AS author_name,
    m.summary,
    m.manga_cover_image_data,
    m.created_at,
    m.updated_at
FROM 
    mangas m
JOIN 
    users u ON m.author_id = u.id;
GO

-- 1
-- thang + vinh
-- get_manga_by_id stored procedure dung de lay thong tin cua mot manga dua vao id
CREATE PROCEDURE get_manga_by_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_mangas WHERE manga_id = @manga_id;
END;
GO


-- 1
-- thang + vinh
-- get_author_id_by_manga_id stored procedure dung de lay id cua tac gia dua vao id cua manga
CREATE PROCEDURE get_author_id_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT author_id FROM mangas WHERE id = @manga_id;
END;
GO

-- 1
-- thang + vinh
CREATE PROCEDURE update_manga
    @manga_id INT,  -- Định nghĩa tham số đầu vào: ID của manga cần cập nhật
    @name NVARCHAR(255),  -- Định nghĩa tham số đầu vào: Tên mới của manga
    @summary NVARCHAR(MAX),  -- Định nghĩa tham số đầu vào: Tóm tắt mới của manga
    @manga_cover_image_data VARBINARY(MAX),  -- Định nghĩa tham số đầu vào: Dữ liệu hình ảnh bìa mới của manga
    @genres NVARCHAR(MAX)  -- Định nghĩa tham số đầu vào: Chuỗi các thể loại mới của manga, phân tách bằng dấu phẩy
AS
BEGIN
    SET NOCOUNT ON;  -- Tắt việc trả về số lượng dòng bị ảnh hưởng bởi các câu lệnh SQL

    UPDATE mangas  -- Cập nhật bảng mangas
    SET name = @name, summary = @summary, manga_cover_image_data = @manga_cover_image_data, updated_at = GETDATE()  -- Đặt các trường mới
    WHERE id = @manga_id;  -- Chỉ cập nhật manga có ID tương ứng

    -- Xóa tất cả các genre của manga đó
    DELETE FROM manga_genre WHERE manga_id = @manga_id;  -- Xóa tất cả các bản ghi trong bảng manga_genre có manga_id tương ứng

    -- Thêm lại các genre mới
    DECLARE @genre NVARCHAR(255);  -- Khai báo biến tạm thời để lưu trữ từng genre
    DECLARE @start INT = 1;  -- Khai báo biến để lưu trữ vị trí bắt đầu của từng genre trong chuỗi @genres
    DECLARE @pos INT = CHARINDEX(',', @genres);  -- Tìm vị trí của dấu phẩy đầu tiên trong chuỗi @genres

    WHILE @pos > 0  -- Trong khi vẫn còn dấu phẩy trong chuỗi @genres
    BEGIN
        SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, @pos - @start)));  -- Lấy ra genre từ vị trí @start đến dấu phẩy gần nhất
        INSERT INTO manga_genre (manga_id, genre_id)  -- Thêm genre này vào bảng manga_genre
        SELECT @manga_id, id FROM genres WHERE name = @genre;  -- Chọn manga_id và id của genre từ bảng genres

        SET @start = @pos + 1;  -- Cập nhật vị trí bắt đầu cho genre tiếp theo
        SET @pos = CHARINDEX(',', @genres, @start);  -- Tìm vị trí của dấu phẩy tiếp theo trong chuỗi @genres
    END

    -- Insert the last genre
    SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, LEN(@genres) - @start + 1)));  -- Lấy ra genre cuối cùng trong chuỗi @genres
    INSERT INTO manga_genre (manga_id, genre_id)  -- Thêm genre này vào bảng manga_genre
    SELECT @manga_id, id FROM genres WHERE name = @genre;  -- Chọn manga_id và id của genre từ bảng genres
END;
GO

-- 1
-- thang + vinh
-- index cho cot name trong bang mangas
CREATE INDEX idx_manga_name ON mangas(name);
GO

------------------------------------------------------
------------------------------------------------------
-- Chapter logic -------------------------------------

-- 1
-- all
-- insert_chapter stored procedure dung de insert chapter vao bang chapters
CREATE PROCEDURE insert_chapter
    @manga_id INT,
    @name NVARCHAR(255),
    @number INT,
    @chapter_image_data VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON; -- Tắt việc trả về số lượng dòng bị ảnh hưởng bởi các câu lệnh SQL

    INSERT INTO chapters (manga_id, name, number, chapter_image_data)
    VALUES (@manga_id, @name, @number, @chapter_image_data);

    UPDATE mangas
    SET updated_at = GETDATE()
    WHERE id = @manga_id;
END;
GO


-- 1
-- all
-- trigger check_chapter_number_insert dung de kiem tra va chinh sua so chapter khi insert
CREATE TRIGGER check_chapter_number_insert
ON chapters
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @manga_id INT;
    DECLARE @number INT;

    SELECT @manga_id = manga_id, @number = number FROM inserted;

    -- Nếu number < 1 thì set number = 1
    IF @number < 1
    BEGIN
        SET @number = 1;
        UPDATE chapters
        SET number = @number
        WHERE manga_id = @manga_id AND number = @number;
    END

    -- Nếu number > số lượng chapter trong manga thì set number = số lượng chapter
    DECLARE @max_number INT;
    SELECT @max_number = MAX(number) FROM chapters WHERE manga_id = @manga_id;
    IF @number > @max_number
    BEGIN
        SET @number = @max_number + 1;
        UPDATE chapters
        SET number = @number
        WHERE manga_id = @manga_id AND number = @number;
    END

    -- Update các chapter phía sau chapter mới
    UPDATE chapters
    SET number = number + 1
    WHERE manga_id = @manga_id AND number >= @number AND id <> (SELECT id FROM inserted);
END;
GO

-- 1
-- all
-- trigger check_chapter_number_delete dung de chinh sua so chapter khi delete
CREATE TRIGGER check_chapter_number_delete
ON chapters
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @manga_id INT;
    DECLARE @number INT;

    SELECT @manga_id = manga_id, @number = number FROM deleted;

    -- Update các chapter phía sau chapter bị xóa
    UPDATE chapters
    SET number = number - 1
    WHERE manga_id = @manga_id AND number > @number;
END;
GO


-- 1
-- all
-- view_all_chapters la view chua tat ca thong tin cua mot chapter
-- bao gom id, manga_id, chapter_name, number, chapter_image_data, created_at, updated_at, manga_name
CREATE VIEW view_all_chapters AS
SELECT 
    c.id AS chapter_id,
    c.manga_id,
    c.name AS chapter_name,
    c.number,
    c.chapter_image_data,
    c.created_at,
    c.updated_at,
    m.name AS manga_name
FROM
    chapters c
JOIN
    mangas m ON c.manga_id = m.id;
GO

-- 1
-- all
-- get_chapters_by_manga_id stored procedure dung de lay tat ca chapter cua mot manga
CREATE PROCEDURE get_chapters_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_chapters WHERE manga_id = @manga_id ORDER BY number ASC;
END;
GO

-- 1
-- all
-- get_previous_and_next_chapter_id stored procedure dung de lay id cua chapter truoc va sau mot chapter
CREATE PROCEDURE get_previous_and_next_chapter_id
    @chapter_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @manga_id INT, @current_chapter_number INT;

    -- Get the manga_id and number of the current chapter
    SELECT @manga_id = manga_id, @current_chapter_number = number FROM chapters WHERE id = @chapter_id;

    SELECT 
        (SELECT TOP 1 id FROM chapters WHERE manga_id = @manga_id AND number < @current_chapter_number ORDER BY number DESC) AS previous_chapter_id,
        (SELECT TOP 1 id FROM chapters WHERE manga_id = @manga_id AND number > @current_chapter_number ORDER BY number ASC) AS next_chapter_id;
END;
GO


-- 1
-- all
-- view_chapter_image_data la view chua id va chapter_image_data cua tat ca chapter
CREATE VIEW view_chapter_image_data AS
SELECT id, chapter_image_data FROM chapters;
GO

-- 1
-- all
-- get_chapter_image_data_by_id stored procedure dung de lay chapter_image_data dua vao id cua chapter
CREATE PROCEDURE get_chapter_image_data_by_id
    @chapter_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_chapter_image_data WHERE id = @chapter_id;
END;
GO

-- 1
-- all
-- delete_chapter stored procedure dung de xoa chapter
CREATE PROCEDURE delete_chapter
    @manga_id INT,
    @chapter_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM chapters WHERE id = @chapter_id AND manga_id = @manga_id;

    UPDATE mangas
    SET updated_at = GETDATE()
    WHERE id = @manga_id;
END;
GO


-- 1
-- all
-- delete_manga stored procedure dung de xoa manga
CREATE PROCEDURE delete_manga
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Delete related records in the 'notifications' table
    DELETE FROM notifications WHERE chapter_id IN (SELECT id FROM chapters WHERE manga_id = @manga_id);

    -- Delete related records in the 'users_mangas' table
    DELETE FROM users_mangas WHERE manga_id = @manga_id;

    -- Delete related records in the 'comments' table
    DELETE FROM comments WHERE manga_id = @manga_id;

    DELETE FROM chapters WHERE manga_id = @manga_id;
    DELETE FROM manga_genre WHERE manga_id = @manga_id;
    DELETE FROM mangas WHERE id = @manga_id;
END;
GO

------------------------------------------------------
-- User - Manga logic -------------------------------

-- 1
-- huy
-- add_favorite_manga stored procedure dung de them manga vao danh sach yeu thich cua user
CREATE PROCEDURE add_favorite_manga
    @user_id INT,
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO users_mangas (user_id, manga_id, is_favorite)
    VALUES (@user_id, @manga_id, 1);
END;
GO

-- 1
-- huy
-- trigger add_notification_on_insert_chapter dung de them notification khi co chapter moi ma user yeu thich
CREATE TRIGGER add_notification_on_insert_chapter
ON chapters
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @manga_id INT;
    DECLARE @chapter_id INT;
    DECLARE @message NVARCHAR(MAX);

    SELECT @manga_id = manga_id, @chapter_id = id FROM inserted;

    SET @message = 'Chapter ' + (SELECT name FROM chapters WHERE id = @chapter_id) + ' of manga ' + (SELECT name FROM mangas WHERE id = @manga_id) + ' has been added.';

    INSERT INTO notifications (user_id, manga_id, chapter_id, message)
    SELECT user_id, @manga_id, @chapter_id, @message
    FROM users_mangas
    WHERE manga_id = @manga_id AND is_favorite = 1;
END;
GO

------------------------------------------------------
-- Genre logic ---------------------------------------

-- 1
-- vinh
-- view_all_genres la view chua tat ca genre
CREATE VIEW view_all_genres AS
SELECT name FROM genres;
GO

-- 1
-- vinh
-- get_genres_by_manga_id stored procedure dung de lay tat ca genre cua mot manga
CREATE PROCEDURE get_genres_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT name FROM view_all_genres
    WHERE name IN (SELECT name FROM genres WHERE id IN (SELECT genre_id FROM manga_genre WHERE manga_id = @manga_id));
END;
GO

------------------------------------------------------
-- User logic ----------------------------------------

-- 1
-- huy 
-- view_all_users la view chua tat ca thong tin cua mot user
-- bao gom id, name, username, email, role, avatar_image_data, created_at, is_banned
CREATE VIEW view_all_users AS
SELECT 
    id,
    name,
    username,
    email,
    role,
    avatar_image_data,
    created_at,
    is_banned
FROM
    users;
GO

-- 1
-- huy
CREATE PROCEDURE get_user_by_id
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_users WHERE id = @id;
END;
GO

-- 1
-- huy

CREATE VIEW view_notifications AS
SELECT 
    n.id AS notification_id,
    n.user_id,
    u.name AS user_name,
    n.manga_id,
    m.name AS manga_name,
    n.chapter_id,
    c.name AS chapter_name,
    n.message,
    n.created_at,
    n.read_at
FROM
    notifications n
JOIN
    users u ON n.user_id = u.id
JOIN
    mangas m ON n.manga_id = m.id
LEFT JOIN
    chapters c ON n.chapter_id = c.id;
GO

-- 1
-- huy
CREATE PROCEDURE get_notifications_by_user_id
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_notifications WHERE user_id = @user_id;
END;
GO

-- 1
-- huy
-- mark_notification_as_read stored procedure dung de danh dau notification da doc
CREATE PROCEDURE mark_notification_as_read
    @notification_id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE notifications
    SET read_at = GETDATE()
    WHERE id = @notification_id;
END;
GO

-- 1
-- huy
CREATE PROCEDURE insert_comment
    @user_id INT,
    @manga_id INT,
    @comment NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO comments (user_id, manga_id, comment)
    VALUES (@user_id, @manga_id, @comment);
END;
GO

-- 1
-- huy
CREATE VIEW view_comments AS
SELECT 
    c.id AS comment_id,
    c.user_id,
    u.name AS user_name,
    u.avatar_image_data AS user_avatar_image_data,
    c.manga_id,
    m.name AS manga_name,
    c.comment,
    c.created_at,
    c.updated_at
FROM
    comments c
JOIN
    users u ON c.user_id = u.id
JOIN
    mangas m ON c.manga_id = m.id;
GO


-- 0
CREATE PROCEDURE delete_user
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Delete related records in the 'notifications' table
    DELETE FROM notifications WHERE user_id = @user_id;

    -- Delete related records in the 'users_mangas' table
    DELETE FROM users_mangas WHERE user_id = @user_id;

    -- Delete related records in the 'comments' table
    DELETE FROM comments WHERE user_id = @user_id;

    DELETE FROM users WHERE id = @user_id;
END;
GO

-- 1
-- huy
-- get_managa_by_genre stored procedure dung de lay tat ca manga cua mot genre
-- dung de lay ra manga theo 1 genre
CREATE PROCEDURE get_manga_by_genre
    @genre NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_mangas
    WHERE author_id IN (SELECT id FROM users WHERE is_banned = 0)
    AND manga_id IN (SELECT manga_id FROM manga_genre WHERE genre_id IN (SELECT id FROM genres WHERE name = @genre));
END;


-- 1
-- set quyen admin cho user
CREATE PROCEDURE set_admin_role
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE users
    SET role = 'admin'
    WHERE id = @user_id;
END;

-- 1
-- all
-- get_mangas_by_genre_ids stored procedure dung de lay tat ca manga cua mot hoac nhieu genre
-- dung de lay ra manga theo nhieu genre
-- nhan vao mot chuoi cac genre_id duoc ngan cach boi dau phay
-- vi du: '1,2,3'
CREATE FUNCTION GetMangasByGenreIds (@genre_ids NVARCHAR(MAX))
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        m.id AS manga_id,   
        m.name AS manga_name,
        m.author_id,
        m.manga_cover_image_data,
        m.summary,
        m.created_at,
        m.updated_at
    FROM 
        mangas m
    INNER JOIN 
        manga_genre mg ON m.id = mg.manga_id
    INNER JOIN 
        genres g ON mg.genre_id = g.id
    WHERE 
        g.id IN (SELECT value FROM STRING_SPLIT(@genre_ids, ','))
);

-- 1
-- view_all_genres_2 lay ra ca id
CREATE VIEW view_all_genres_2 AS
SELECT * FROM genres;
GO
