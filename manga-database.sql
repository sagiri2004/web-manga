CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY,
    name NVARCHAR(255) NOT NULL,
    username NVARCHAR(255) NOT NULL UNIQUE,
    password NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) UNIQUE,
    role NVARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    avatar_image_data VARBINARY(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
);

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

CREATE TABLE genres (
    id INT PRIMARY KEY IDENTITY,
    description NVARCHAR(255),
    name NVARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE manga_genre (
    manga_id INT,
    genre_id INT,
    PRIMARY KEY (manga_id, genre_id),
    FOREIGN KEY (manga_id) REFERENCES mangas(id),
    FOREIGN KEY (genre_id) REFERENCES genres(id)
);

CREATE TABLE users_mangas (
    user_id INT,
    manga_id INT,
    is_favorite BIT DEFAULT 0,
    rating INT DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (manga_id) REFERENCES mangas(id)
);

-- CREATE TABLE chapters (
--     id INT PRIMARY KEY IDENTITY,
--     manga_id INT NOT NULL,
--     name NVARCHAR(255) NOT NULL,
--     number INT NOT NULL,
--     created_at DATETIME DEFAULT GETDATE(),
--     updated_at DATETIME DEFAULT GETDATE(),
--     FOREIGN KEY (manga_id) REFERENCES mangas(id),
-- );

-- CREATE TABLE pages (
--     id INT PRIMARY KEY IDENTITY,
--     chapter_id INT NOT NULL,
--     page_image_data VARBINARY(MAX),
--     number INT NOT NULL,
--     created_at DATETIME DEFAULT GETDATE(),
--     updated_at DATETIME DEFAULT GETDATE(),
--     FOREIGN KEY (chapter_id) REFERENCES chapters(id),
-- );

-- xóa chapters cũ và pages cũ
DROP TABLE pages;
DROP TABLE chapters;

-- sửa lại để mỗi chapter lưu một ảnh là thuộc tính của chapter_image_data
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

ALTER TABLE chapters
ADD chapter_image_data VARBINARY(MAX);



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

------------------------------------------------------
-- User logic ----------------------------------------

-- Create stored procedure to insert user
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

    SET @id = SCOPE_IDENTITY();

    RETURN @id;
END;
GO

-- test insert user 
EXEC insert_user 'John Doe', 'johndoe', 'password', 'a@b.c', 'admin', 0x;

-- Lấy ra thông tin user với @id
CREATE PROCEDURE get_user_by_id
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM users WHERE id = @id;
END;
GO

-- test get user by id
EXEC get_user_by_id 1;

CREATE PROCEDURE check_user_login
    @username NVARCHAR(255),
    @password NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM dbo.users WHERE username = @username AND password = @password;
END;
GO

CREATE PROCEDURE check_user_exists
    @username NVARCHAR(255),
    @email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM dbo.users WHERE username = @username OR email = @email;
END;
GO

------------------------------------------------------------


-- Create stored procedure to insert manga genres
CREATE PROCEDURE insert_manga_genres
    @name NVARCHAR(255),
    @author_id INT,
    @manga_cover_image_data VARBINARY(MAX),
    @summary NVARCHAR(MAX),
    @genres NVARCHAR(MAX) -- This is a comma-separated string of genre names
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id INT;

    -- Insert the manga information
    INSERT INTO mangas (name, author_id, manga_cover_image_data, summary)
    VALUES (@name, @author_id, @manga_cover_image_data, @summary);

    SET @id = SCOPE_IDENTITY();

    -- Split the @genres string into individual genre names
    DECLARE @genre NVARCHAR(255);
    DECLARE @start INT = 1;
    DECLARE @pos INT = CHARINDEX(',', @genres);

    WHILE @pos > 0
    BEGIN
        SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, @pos - @start)));
        INSERT INTO manga_genre (manga_id, genre_id)
        SELECT @id, id FROM genres WHERE name = @genre;

        SET @start = @pos + 1;
        SET @pos = CHARINDEX(',', @genres, @start);
    END

    -- Insert the last genre
    SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, LEN(@genres) - @start + 1)));
    INSERT INTO manga_genre (manga_id, genre_id)
    SELECT @id, id FROM genres WHERE name = @genre;

    RETURN @id;
END;
GO

-- Execute the procedure with sample data
EXEC insert_manga_genres 'One Piece', 3, 0x, 'A pirate adventure manga', 'Adventure, Comedy';


-- test insert manga
EXEC insert_manga_genres 'One Piece', 1, 0x, 'A pirate adventure manga', 'Action, Adventure, Comedy';

-- lay ra manga ma user co @id da tao
CREATE PROCEDURE get_manga_by_author_id
    @author_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM mangas WHERE author_id = @author_id;
END;
GO

-- test get manga by author id
EXEC get_manga_by_author_id 1;

-- tao view de lay ra tat ca cac manga da tao
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

-- test view all mangas
SELECT * FROM view_all_mangas;

-- Tạo logic để lấy ra thông tin của một manga với @manga_id
CREATE PROCEDURE get_manga_by_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_mangas WHERE manga_id = @manga_id;
END;

-- test get manga by id
EXEC get_manga_by_id 1;

------------------------------------------------------
-- Chapter logic -------------------------------------

-- create stored chapter
CREATE PROCEDURE insert_chapter
    @manga_id INT,
    @name NVARCHAR(255),
    @number INT,
    @chapter_image_data VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO chapters (manga_id, name, number, chapter_image_data)
    VALUES (@manga_id, @name, @number, @chapter_image_data);
END;

-- test insert chapter
EXEC insert_chapter 1, 'Chapter 1', 1, 0x;

-- trigger khi insert chapter khi insert chapter thì sẽ kiểm tra xem number của chapter đó đã tồn tại chưa
-- nếu tồn tại thì sẽ set các chapter có number lớn hơn bằng number của chapter mới thêm vào tăng lên 1
CREATE TRIGGER check_chapter_number
ON chapters
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @manga_id INT;
    DECLARE @number INT;

    SELECT @manga_id = manga_id, @number = number FROM inserted;

    -- Adjust the number since it's automatically incremented by 1
    SET @number = @number - 1;

    -- Update all chapters with the same manga_id and number greater than or equal to the new chapter's number
    UPDATE chapters
    SET number = number + 1
    WHERE manga_id = @manga_id AND number >= @number;
END;


-- -- create stored procedure to get chapter by manga id
-- CREATE PROCEDURE get_chapters_by_manga_id
--     @manga_id INT
-- AS
-- BEGIN
--     SET NOCOUNT ON;

--     SELECT * FROM chapters WHERE manga_id = @manga_id ORDER BY number ASC;
-- END;
-- GO

-- -- test get chapters by manga id
-- EXEC get_chapters_by_manga_id 1;

-- tạo view để lấy ra tất cả các chapter của một manga
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

-- test view all chapters
SELECT * FROM view_all_chapters;

-- tạo get_chapters_by_manga_id sử dụng view_all_chapters
CREATE PROCEDURE get_chapters_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_chapters WHERE manga_id = @manga_id ORDER BY number ASC;
END;
GO

-- test get chapters by manga id
EXEC get_chapters_by_manga_id 1;

-- drop get_chapters_by_manga_id
DROP PROCEDURE get_chapters_by_manga_id;

-- tạo một logic nhận vào @manga_id và @chapter_id và trả về id của chapter có number trước đó và sau đó
-- sử dụng get_chapters_by_manga_id (đã sắp sếp theo mumber tăng dần) để lấy ra tất cả các chapter của manga đó
-- Add missing import statement for the 'chapters' table
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
-- test get previous and next chapter id
EXEC get_previous_and_next_chapter_id 1;

-- tạo view để lấy ra id và chapter_image_data của một chapter
CREATE VIEW view_chapter_image_data AS
SELECT id, chapter_image_data FROM chapters;
GO

-- get chapter image data by chapter id
CREATE PROCEDURE get_chapter_image_data_by_id
    @chapter_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_chapter_image_data WHERE id = @chapter_id;
END;

------------------------------------------------------
-- User - Manga logic -------------------------------

-- thêm is_favorite = 1 với @user_id và @manga_id
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

-- test add favorite manga
EXEC add_favorite_manga 1, 1;

-- khi thêm chapter mới thì thêm notification cho tất cả user is_favorite manga đó sử dụng trigger
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

-- test trigger
EXEC insert_chapter 1, 'Chapter 2', 2;

------------------------------------------------------
-- Genre logic ---------------------------------------

-- tao view de lay ra tat ca cac ten genre
CREATE VIEW view_all_genres AS
SELECT name FROM genres;
GO

-- logic lay ra tat ca cac view_all_genres
SELECT * FROM view_all_genres;

-- logic de tao manga_genre tu manga_id va genre.name
CREATE PROCEDURE insert_manga_genre
    @manga_id INT,
    @genre_name NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @genre_id INT;

    SELECT @genre_id = id FROM genres WHERE name = @genre_name;

    INSERT INTO manga_genre (manga_id, genre_id)
    VALUES (@manga_id, @genre_id);
END;

-- lấy ra tất cả các genre của một manga sư dụng view_all_genres
CREATE PROCEDURE get_genres_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT name FROM view_all_genres
    WHERE name IN (SELECT name FROM genres WHERE id IN (SELECT genre_id FROM manga_genre WHERE manga_id = @manga_id));
END;

-- test get genres by manga id
EXEC get_genres_by_manga_id 1;

------------------------------------------------------
-- User logic ----------------------------------------

-- Tạo view để lấy ra thông tin của các user gồm name, email, role, avatar_image_data, created_at và id
CREATE VIEW view_all_users AS
SELECT 
    id,
    name,
    email,
    role,
    avatar_image_data,
    created_at
FROM
    users;

-- test view all users
SELECT * FROM view_all_users;

-- Tạo stored procedure để lấy ra thông tin của một user với @id

CREATE PROCEDURE get_user_by_id
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_users WHERE id = @id;
END;
GO

-- test get user by id
EXEC get_user_by_id 1;

