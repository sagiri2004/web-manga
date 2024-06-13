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

-- 1
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
CREATE INDEX idx_username ON dbo.users (username);
GO

-- 1
CREATE PROCEDURE get_password_by_username
    @username NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT password FROM dbo.users WHERE username = @username;
END;
GO

-- 1
CREATE PROCEDURE get_user_by_username
    @username NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM dbo.users WHERE username = @username;
END;
GO

-- 1
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
CREATE INDEX idx_user_id ON users(id);
GO

------------------------------------------------------------
-- Manga logic ---------------------------------------------

-- 1
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

-- 1
CREATE PROCEDURE get_manga_by_author_id
    @author_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM mangas WHERE author_id = @author_id;
END;
GO

-- 1
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
CREATE PROCEDURE get_manga_by_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_mangas WHERE manga_id = @manga_id;
END;
GO


-- 1
CREATE PROCEDURE get_author_id_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT author_id FROM mangas WHERE id = @manga_id;
END;
GO

-- 1
CREATE PROCEDURE update_manga
    @manga_id INT,
    @name NVARCHAR(255),
    @summary NVARCHAR(MAX),
    @manga_cover_image_data VARBINARY(MAX),
    @genres NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE mangas
    SET name = @name, summary = @summary, manga_cover_image_data = @manga_cover_image_data, updated_at = GETDATE()
    WHERE id = @manga_id;

    -- Xóa tất cả các genre của manga đó
    DELETE FROM manga_genre WHERE manga_id = @manga_id;

    -- Thêm lại các genre mới
    DECLARE @genre NVARCHAR(255);
    DECLARE @start INT = 1;
    DECLARE @pos INT = CHARINDEX(',', @genres);

    WHILE @pos > 0
    BEGIN
        SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, @pos - @start)));
        INSERT INTO manga_genre (manga_id, genre_id)
        SELECT @manga_id, id FROM genres WHERE name = @genre;

        SET @start = @pos + 1;
        SET @pos = CHARINDEX(',', @genres, @start);
    END

    -- Insert the last genre
    SET @genre = LTRIM(RTRIM(SUBSTRING(@genres, @start, LEN(@genres) - @start + 1)));
    INSERT INTO manga_genre (manga_id, genre_id)
    SELECT @manga_id, id FROM genres WHERE name = @genre;
END;
GO

CREATE INDEX idx_manga_name ON mangas(name);
GO

------------------------------------------------------
------------------------------------------------------
-- Chapter logic -------------------------------------

-- 1
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

    UPDATE mangas
    SET updated_at = GETDATE()
    WHERE id = @manga_id;
END;
GO


-- 1
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
CREATE PROCEDURE get_chapters_by_manga_id
    @manga_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_chapters WHERE manga_id = @manga_id ORDER BY number ASC;
END;
GO

-- 1
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
CREATE VIEW view_chapter_image_data AS
SELECT id, chapter_image_data FROM chapters;
GO

-- 1
CREATE PROCEDURE get_chapter_image_data_by_id
    @chapter_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_chapter_image_data WHERE id = @chapter_id;
END;
GO

-- 1
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
CREATE VIEW view_all_genres AS
SELECT name FROM genres;
GO

-- 1
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
CREATE PROCEDURE get_user_by_id
    @id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_all_users WHERE id = @id;
END;
GO

-- 1
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
CREATE PROCEDURE get_notifications_by_user_id
    @user_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT * FROM view_notifications WHERE user_id = @user_id;
END;
GO

-- 1
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

-- get_manga_by_genre su dung view_all_mangas va view_all_genres
-- 1
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
