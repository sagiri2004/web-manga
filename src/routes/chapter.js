const express = require("express");
const router = express.Router();
const chapterController = require("../app/controllers/ChapterController");

router.get("/:id", chapterController.getChapter);

module.exports = router;
