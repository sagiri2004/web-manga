const express = require("express");
const router = express.Router();
const mangaController = require("../app/controllers/MangaController");

router.get("/create/:id", mangaController.getCreateChapter);
router.post("/create/:id", mangaController.createChapter);
router.get("/create", mangaController.getCreateManga);
router.post("/create", mangaController.createManga);
router.get("/:id", mangaController.getManga);

module.exports = router;
