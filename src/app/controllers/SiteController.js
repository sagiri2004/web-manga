const { conn } = require("../../config/database");

class SiteController {
  // [GET] /home
  home(req, res) {
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      const query = `SELECT * FROM view_all_mangas`;
      conn.query(query, (err, mangas) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        // chuyển manga_cover_image_data từ buffer sang base64 và + thêm string 'data:image/png;base64,'
        mangas.forEach((manga) => {
          manga.manga_cover_image_data = `data:image/png;base64,${manga.manga_cover_image_data.toString("base64")}`;
        });
        res.render("home", { mangas });
      });
    });
  }
}

module.exports = new SiteController();
