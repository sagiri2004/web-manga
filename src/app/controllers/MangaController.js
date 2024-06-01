const multer = require("multer");
const path = require("path");
const { conn } = require("../../config/database");
const fs = require("fs");
const { decodeToken } = require("../../util/tokenUtil");

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "E:\\demo");
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

class MangaController {
  async getCreateManga(req, res) {
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      const query = `SELECT * FROM view_all_genres`;
      conn.query(query, (err, genres) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        res.render("manga/create", { genres });
      });
    });
  }

  async createManga(req, res) {
    upload.single("manga_cover")(req, res, async (err) => {
      if (err) {
        console.error("Error uploading file:", err);
        return;
      }
      const token = req.cookies.token;
      const { user_id } = decodeToken(token);
      const { name, summary, genres } = req.body;
      //console.log(req.body);
      const coverImagePath = path.join("E:\\demo", req.file.filename);
      const coverImageData = fs.readFileSync(coverImagePath);
      const coverImage = `0x${coverImageData.toString("hex")}`;
      const genresString = genres.join(",");
      const query = `EXEC insert_manga_genres @name=N'${name}', @summary=N'${summary}', @author_id=${user_id}, @manga_cover_image_data=${coverImage}, @genres=N'${genresString}'`;
      //console.log(genres);
      conn((err, conn) => {
        if (err) {
          console.error(
            "Error occurred while connecting to the database:",
            err
          );
          return;
        }

        conn.query(query, (err, results) => {
          if (err) {
            console.error("Error occurred while executing the query:", err);
            return;
          }

          res.redirect("/");
        });
      });
    });
  }

  async getCreateChapter(req, res) {
    const mangaId = req.params.id;
    //console.log(mangaId);
    res.render("manga/createChapter", { mangaId });
  }

  async createChapter(req, res) {
    upload.array("chapter_image_data")(req, res, async (err) => {
      if (err) {
        console.error("Error uploading files:", err);
        return;
      }

      const chapters = req.body.chapter;
      const manga_id = req.params.id;

      const createChapter = (chapter, file) => {
        return new Promise((resolve, reject) => {
          const { name, number } = chapter;
          const chapterImageDataPath = path.join("E:\\demo", file.filename);
          const chapterImageData = fs.readFileSync(chapterImageDataPath);
          const chapterImage = `0x${chapterImageData.toString("hex")}`;
          const query = `EXEC insert_chapter @manga_id=${manga_id}, @number=${number}, @name=N'${name}', @chapter_image_data=${chapterImage}`;

          conn((err, conn) => {
            if (err) {
              console.error(
                "Error occurred while connecting to the database:",
                err
              );
              reject(err);
            }

            conn.query(query, (err, results) => {
              if (err) {
                console.error("Error occurred while executing the query:", err);
                reject(err);
              }
              resolve();
            });
          });
        });
      };

      for (let i = 0; i < chapters.length; i++) {
        try {
          await createChapter(chapters[i], req.files[i]);
        } catch (err) {
          console.error("Error occurred while creating chapter:", err);
          return;
        }
      }

      res.redirect("/");
    });
  }

  async getManga(req, res) {
    const mangaId = req.params.id;
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }
      const query = `EXEC get_manga_by_id ${mangaId}`;
      conn.query(query, (err, manga) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }

        const query2 = `EXEC get_chapters_by_manga_id ${mangaId}`;
        conn.query(query2, (err, chapters) => {
          if (err) {
            console.error(
              "Error occurred while executing the second query:",
              err
            );
            return;
          }

          //console.log(chapters);

          // thêm string data:image/png;base64, vào trước chapter_image_data và manga_cover_image_data
          manga[0].manga_cover_image_data = `data:image/png;base64,${manga[0].manga_cover_image_data.toString("base64")}`;
          manga = manga[0];
          const query3 = `EXEC get_genres_by_manga_id ${mangaId}`;
          conn.query(query3, (err, genres) => {
            if (err) {
              console.error(
                "Error occurred while executing the third query:",
                err
              );
              return;
            }
            res.render("manga/manga", { manga, chapters, genres });
          });
        });
      });
    });
  }
}
module.exports = new MangaController();
