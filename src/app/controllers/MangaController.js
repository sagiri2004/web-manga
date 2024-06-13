const multer = require("multer");
const path = require("path");
const { conn } = require("../../config/database");
const fs = require("fs");
const { decodeToken } = require("../../util/tokenUtil");
const { formatDate } = require("../../util/dateUtil");

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
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      const query = `EXEC get_chapters_by_manga_id ${mangaId}`;
      conn.query(query, (err, chapters) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }

        // sửa lại created at và updated at để hiện thị đep hơn
        for (let i = 0; i < chapters.length; i++) {
          chapters[i].created_at = formatDate(chapters[i].created_at);
          chapters[i].updated_at = formatDate(chapters[i].updated_at);
        }

        // console.log({ mangaId, chapters });

        res.render("manga/createChapter", { mangaId, chapters });
      });
    });
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

      res.redirect(`/manga/create/${manga_id}`);
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
          manga[0].manga_cover_image_data = `data:image/png;base64,${manga[0].manga_cover_image_data.toString(
            "base64"
          )}`;
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
            const message = req.cookies.message;
            res.clearCookie("message");
            const query4 = `SELECT * FROM view_comments WHERE manga_id = ${mangaId} ORDER BY created_at DESC`;
            conn.query(query4, (err, comments) => {
              if (err) {
                console.error(
                  "Error occurred while executing the fourth query:",
                  err
                );
                return;
              }
              // thêm string data:image/png;base64, vào trước user_avatar_image_data
              comments.forEach((comment) => {
                comment.user_avatar_image_data = `data:image/png;base64,${comment.user_avatar_image_data.toString(
                  "base64"
                )}`;
              });

              // sửa lại created at để hiện thị đep hơn
              for (let i = 0; i < comments.length; i++) {
                comments[i].created_at = formatDate(comments[i].created_at);
              }

              res.render("manga/manga", {
                manga,
                chapters,
                genres,
                comments,
                message,
              });
            });
          });
        });
      });
    });
  }

  async deleteChapter(req, res) {
    const chapterId = req.params.chapterid;
    const mangaId = req.params.mangaid;
    const userId = decodeToken(req.cookies.token).user_id;

    const query = `EXEC get_author_id_by_manga_id ${mangaId}`;
    conn((err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      conn.query(query, (err, authorId) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }

        if (authorId[0].author_id !== userId) {
          res.render("404");
          return;
        }

        const query2 = `EXEC delete_chapter ${mangaId}, ${chapterId}`;
        conn.query(query2, (err, results) => {
          if (err) {
            console.error("Error occurred while executing the query:", err);
            return;
          }

          res.redirect(`/manga/create/${mangaId}`);
        });
      });
    });
  }

  async deleteManga(req, res) {
    const mangaId = req.params.id;
    const userId = decodeToken(req.cookies.token).user_id;

    const query = `EXEC get_author_id_by_manga_id ${mangaId}`;
    conn((err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }

      conn.query(query, (err, authorId) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }

        if (authorId[0].author_id !== userId) {
          res.render("404");
          return;
        }

        const query2 = `EXEC delete_manga ${mangaId}`;
        conn.query(query2, (err, results) => {
          if (err) {
            console.error("Error occurred while executing the query:", err);
            return;
          }

          res.redirect("/user/my-created-manga");
        });
      });
    });
  }

  async getEditManga(req, res) {
    const mangaId = req.params.id;
    const userId = decodeToken(req.cookies.token).user_id;
    const query = `EXEC get_author_id_by_manga_id ${mangaId}`;
    conn((err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }
      conn.query(query, (err, authorId) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        if (authorId[0].author_id !== userId) {
          res.render("404");
          return;
        }
        const query2 = `EXEC get_manga_by_id ${mangaId}`;
        conn.query(query2, (err, manga) => {
          if (err) {
            console.error("Error occurred while executing the query:", err);
            return;
          }
          const query3 = `SELECT * FROM view_all_genres`;
          conn.query(query3, (err, genres) => {
            if (err) {
              console.error("Error occurred while executing the query:", err);
              return;
            }

            const query4 = `EXEC get_genres_by_manga_id ${mangaId}`;
            conn.query(query4, (err, mangaGenres) => {
              if (err) {
                console.error("Error occurred while executing the query:", err);
                return;
              }

              // console.log(mangaGenres);

              // Gắn cờ is_selected cho các genre đã chọn
              genres.forEach((genre) => {
                genre.is_selected = mangaGenres.some(
                  (mg) => mg.name === genre.name
                );
              });

              // console.log(genres);
              // chuyển đổi dữ liệu image data sang base64
              manga[0].manga_cover_image_data = `data:image/png;base64,${manga[0].manga_cover_image_data.toString(
                "base64"
              )}`;

              res.render("manga/edit", { manga: manga[0], genres });
            });
          });
        });
      });
    });
  }

  async editManga(req, res) {
    upload.single("manga_cover")(req, res, async (err) => {
      if (err) {
        console.error("Error uploading file:", err);
        return;
      }

      const mangaId = req.params.id;
      const userId = decodeToken(req.cookies.token).user_id;
      const { name, summary, genres } = req.body;
      const coverImagePath = path.join("E:\\demo", req.file.filename);
      const coverImageData = fs.readFileSync(coverImagePath);
      const coverImage = `0x${coverImageData.toString("hex")}`;
      const genresString = genres.join(",");
      const query = `EXEC get_author_id_by_manga_id ${mangaId}`;
      const query2 = `EXEC update_manga @manga_id=${mangaId}, @name=N'${name}', @summary=N'${summary}', @manga_cover_image_data=${coverImage}, @genres=N'${genresString}'`;
      conn((err, conn) => {
        if (err) {
          console.error(
            "Error occurred while connecting to the database:",
            err
          );
          return;
        }
        conn.query(query, (err, authorId) => {
          if (err) {
            console.error("Error occurred while executing the query:", err);
            return;
          }
          if (authorId[0].author_id !== userId) {
            res.render("404");
            return;
          }
          conn.query(query2, (err, results) => {
            if (err) {
              console.error("Error occurred while executing the query:", err);
              return;
            }
            res.redirect(`/manga/${mangaId}`);
          });
        });
      });
    });
  }

  async submitComment(req, res) {
    const userId = decodeToken(req.cookies.token).user_id;
    const { manga_id, comment } = req.body;
    const query = `EXEC insert_comment @manga_id=${manga_id}, @user_id=${userId}, @comment=N'${comment}'`;
    conn((err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }
      conn.query(query, (err, results) => {
        if (err) {
          res.status(500).send("Error saving comment");
        } else {
          const queryUser = `SELECT * FROM view_all_users WHERE id = ${userId}`;
          conn.query(queryUser, (err, user) => {
            if (err) {
              console.error("Error occurred while executing the query:", err);
              return;
            }

            // thêm string data:image/png;base64, vào trước avatar_image_data
            user[0].avatar_image_data = `data:image/png;base64,${user[0].avatar_image_data.toString(
              "base64"
            )}`;

            // chuyển đổi created_at sang dạng đẹp hơn
            user[0].created_at = formatDate(user[0].created_at);
            res.json(user[0]);
          });
        }
      });
    });
  }

  // get manga by genre
  async getMangaByGenre(req, res) {
    const genre = req.params.id;
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }
      const query = `EXEC get_manga_by_genre ${genre}`;
      conn.query(query, (err, mangas) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        // them string data:image/png;base64, vào trước manga_cover_image_data
        mangas.forEach((manga) => {
          manga.manga_cover_image_data = `data:image/png;base64,${manga.manga_cover_image_data.toString(
            "base64"
          )}`;
        });

        res.render("manga/mangaGenre", { mangas, genre });
      });
    });
  }
}
module.exports = new MangaController();
