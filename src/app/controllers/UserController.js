// const multer = require("multer");
// const path = require("path");
const { conn } = require("../../config/database");
// const fs = require("fs");
const { decodeToken } = require("../../util/tokenUtil");
const { formatDate } = require("../../util/dateUtil");

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
          // su dung ham formatDate tu dateUtil.js
          createdAt: formatDate(manga.created_at),
          updatedAt: formatDate(manga.updated_at),
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
            // su dung ham formatDate tu dateUtil.js
            createdAt: formatDate(manga.created_at),
            updatedAt: formatDate(manga.updated_at),
          }));

          // su dung ham formatDate tu dateUtil.js
          userData.created_at = formatDate(userData.created_at);

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

  // [GET] lay tat ca cac user
  async getAllUser(req, res) {
    // check is admin
    const token = req.cookies.token;
    //console.log(token);
    // token = null => chua login
    if (!token) {
      // chuyen ve trang login
      return res.redirect("/auth/login");
    } else {
      const { user_id, role } = decodeToken(token);
      if (role !== "admin") {
        res.status(403).json({ message: "Forbidden" });
        return;
      } else {
        const query = `SELECT * FROM view_all_users`;
        conn((err, conn) => {
          conn.query(query, (err, result) => {
            if (err) {
              res.status(500).json({ message: "Internal server error" });
              return;
            }

            const users = result.map((user) => ({
              id: user.id,
              username: user.username,
              email: user.email,
              role: user.role,
              is_banned: user.is_banned,
              avatarImageData:
                "data:image/png;base64," +
                Buffer.from(user.avatar_image_data, "hex").toString("base64"),
              //su dung ham formatDate tu dateUtil.js
              createdAt: formatDate(user.created_at),
            }));

            res.render("user/allUser", { users });
          });
        });
      }
    }
  }

  // [POST] ban user
  async ban(req, res) {
    // check is admin
    const token = req.cookies.token;
    if (!token) {
      res.status(403).json({ message: "Forbidden" });
      return;
    }

    const { role } = decodeToken(token);
    if (role !== "admin") {
      res.status(403).json({ message: "Forbidden" });
      return;
    }

    const userId = req.params.id;
    const query = `EXEC ban_user ${userId}`;
    conn((err, conn) =>
      conn.query(query, (err, result) => {
        if (err) {
          res.status(500).json({ message: "Internal server error" });
          return;
        }

        res.redirect("/user/admin");
      })
    );
  }

  // [POST] unban user
  async unban(req, res) {
    // check is admin
    const token = req.cookies.token;
    if (!token) {
      res.status(403).json({ message: "Forbidden" });
      return;
    }

    const { role } = decodeToken(token);
    if (role !== "admin") {
      res.status(403).json({ message: "Forbidden" });
      return;
    }

    const userId = req.params.id;
    const query = `EXEC unban_user ${userId}`;
    conn((err, conn) =>
      conn.query(query, (err, result) => {
        if (err) {
          res.status(500).json({ message: "Internal server error" });
          return;
        }

        res.redirect("/user/admin");
      })
    );
  }
}

module.exports = new UserController();
