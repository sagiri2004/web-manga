const { conn } = require("../../config/database");
const { decodeToken } = require("../../util/tokenUtil");

class SiteController {
  // [GET] /home
  home(req, res) {
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      const query = `SELECT * FROM view_all_mangas ORDER BY updated_at DESC`;
      conn.query(query, (err, mangas) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        // chuyển manga_cover_image_data từ buffer sang base64 và + thêm string 'data:image/png;base64,'
        mangas.forEach((manga) => {
          manga.manga_cover_image_data = `data:image/png;base64,${manga.manga_cover_image_data.toString(
            "base64"
          )}`;
        });

        // nếu người dùng đã đăng nhập thì sẽ truyền notifications
        const token = req.cookies.token;
        //console.log(token);
        if (token) {
          const userId = decodeToken(token).user_id;
          const query = `EXEC get_notifications_by_user_id ${userId}`;

          conn.query(query, (err, notifications) => {
            if (err) {
              console.error("Error occurred while executing the query:", err);
              return;
            }

            // chỉ lấy ra notifications có trạng thái là chưa đọc hay read_at = null
            notifications = notifications.filter(
              (notification) => notification.read_at === null
            );

            res.render("home", { mangas, notifications });
          });

          return;
        }
        res.render("home", { mangas });
      });
    });
  }

  // [GET] /search
  async search(req, res) {
    const searchQuery = req.query.query;
    const query = `SELECT * FROM mangas WHERE name LIKE '%${searchQuery}%'`;
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      conn.query(query, (err, mangas) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }

        // chuyển manga_cover_image_data từ buffer sang base64 và + thêm string 'data:image/png;base64,'
        mangas.forEach((manga) => {
          manga.manga_cover_image_data = `data:image/png;base64,${manga.manga_cover_image_data.toString(
            "base64"
          )}`;
        });

        //console.log(mangas);

        res.render("search", { mangas, searchQuery });
      });
    });
  }

  // [GET] tim kiem nang cao
  getAdvancedSearch(req, res) {
    // get all genres
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      const query = `SELECT * FROM view_all_genres_2`;
      conn.query(query, (err, genres) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        //console.log(genres);

        res.render("advanceSearch", { genres });
      });
    });
  }

  // [POST] tim kiem nang cao
  advancedSearch(req, res) {
    const { genres } = req.body;
    // chuyển genres từ array sang string
    let genresString = "";
    genresString += `'`;
    genres.forEach((genre, index) => {
      genresString += `${genre}`;
      if (index !== genres.length - 1) {
        genresString += ",";
      }
    });
    genresString += `'`;
    // res.send(genresString);

    const query = `SELECT * FROM GetMangasByGenreIds(${genresString})`;
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }
      conn.query(query, (err, mangas) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }

        // chuyển manga_cover_image_data từ buffer sang base64 và + thêm string 'data:image/png;base64,'
        mangas.forEach((manga) => {
          manga.manga_cover_image_data = `data:image/png;base64,${manga.manga_cover_image_data.toString(
            "base64"
          )}`;

          manga.id = manga.manga_id;
          manga.name = manga.manga_name;
        });

        //console.log(mangas);

        res.render("search", { mangas });
      });

    });
  }

}

module.exports = new SiteController();
