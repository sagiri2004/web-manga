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
}

module.exports = new UserController();
