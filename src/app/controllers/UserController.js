// const multer = require("multer");
// const path = require("path");
const { conn } = require("../../config/database");
// const fs = require("fs");
const { decodeToken } = require("../../util/tokenUtil");

// const storage = multer.diskStorage({
//   destination: function (req, file, cb) {
//     cb(null, "E:\\demo");
//   },
//   filename: function (req, file, cb) {
//     cb(null, Date.now() + path.extname(file.originalname));
//   },
// });

// const upload = multer({ storage: storage });

class UserController {
  async myCreatedManga(req, res) {
    const token = req.cookies.token;
    const { user_id } = decodeToken(token);
    const query = `EXEC get_manga_by_author_id ${user_id}`;
    conn((err, conn) => {
      conn.query(query, (err, result) => {
        if (err) {
          res.status(500).json({ message: "Internal server error" });
          return;
        }

        // console.log(result);

        const mangas = result.map((manga) => ({
          id: manga.id,
          name: manga.name,
          authorId: manga.author_id,
          mangaCoverImageData:
            "data:image/png;base64," +
            Buffer.from(manga.manga_cover_image_data, "hex").toString("base64"),
          summary: manga.summary,
          createdAt: manga.created_at,
          updatedAt: manga.updated_at,
        }));

        res.render("user/myCreatedManga", { mangas });
      });
    });
  }

  async getUserProfile(req, res) {
    const userId = req.params.id;
    const query = `EXEC get_user_by_id ${userId}`;
    conn((err, conn) => {
      conn.query(query, (err, user) => {
        if (err) {
          res.status(500).json({ message: "Internal server error siu 1" });
          return;
        }

        const userData = user[0];

        const query2 = `EXEC get_manga_by_author_id ${userId}`;
        conn.query(query2, (err, result) => {
          if (err) {
            res.status(500).json({ message: "Internal server error siu 2" });
            return;
          }

          const mangaList = result.map((manga) => ({
            id: manga.id,
            name: manga.name,
            authorId: manga.author_id,
            mangaCoverImageData:
              "data:image/png;base64," +
              Buffer.from(manga.manga_cover_image_data, "hex").toString(
                "base64"
              ),
            summary: manga.summary,
            createdAt: manga.created_at,
            updatedAt: manga.updated_at,
          }));

          res.render("user/userProfile", { user: userData, mangaList });
        });
      });
    });
  }

  async addFavoriteManga(req, res) {
    const token = req.cookies.token;
    const mangaId = req.params.id;

    if (!token) {
      res.cookie("message", "Please log in to add manga to favorites", {
        maxAge: 5000,
      });
      res.redirect(`/manga/${mangaId}`);
      return;
    }

    const { user_id } = decodeToken(token);

    const query = `EXEC add_favorite_manga ${user_id}, ${mangaId}`;
    conn((err, conn) => {
      conn.query(query, (err, result) => {
        if (err) {
          res.cookie("message", "Failed to add manga to favorites", {
            maxAge: 5000,
          });
          return res.redirect(`/manga/${mangaId}`);
        }
        res.cookie("message", "Added manga to favorites successfully", {
          maxAge: 5000,
        });
        return res.redirect(`/manga/${mangaId}`);
      });
    });
  }

  // [PUT] để đánh dấu đã đọc thông báo
  async markAsReadNotice(req, res) {
    const notificationId = req.params.id;
    const query = `EXEC mark_notification_as_read ${notificationId}`;
    conn((err, conn) => {
      conn.query(query, (err, result) => {
        if (err) {
          res.status(500).json({ message: "Internal server error" });
          return;
        }
        
        res.redirect("/");
      });
    });
  }

}

module.exports = new UserController();
