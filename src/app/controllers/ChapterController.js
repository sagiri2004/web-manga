const { conn } = require("../../config/database");

class ChapterController {
  getChapter(req, res) {
    const chapterId = req.params.id;
    const queryData = `EXEC get_chapter_image_data_by_id ${chapterId}`;
    conn(async (err, conn) => {
      if (err) {
        console.error("Error occurred while connecting to the database:", err);
        return;
      }
      conn.query(queryData, (err, chapter) => {
        if (err) {
          console.error("Error occurred while executing the query:", err);
          return;
        }
        // thêm string data:image/png;base64, vào trước chapter_image_data
        chapter[0].chapter_image_data = `data:image/png;base64,${chapter[0].chapter_image_data.toString("base64")}`;
        

        const queryAroundChapter = `EXEC get_previous_and_next_chapter_id ${chapterId}`;
        conn.query(queryAroundChapter, (err, aroundChapter) => {
          if (err) {
            console.error("Error occurred while executing the query:", err);
            return;
          }
          res.render("chapter/chapter", {
            chapter: chapter[0],
            aroundChapter: aroundChapter[0],
          });
        });
      });
    });
  }
}
module.exports = new ChapterController();
