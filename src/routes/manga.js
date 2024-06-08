const express = require("express");
const router = express.Router();
const mangaController = require("../app/controllers/MangaController");

router.delete("/deleteManga/:id", mangaController.deleteManga)
router.delete("/deleteChapter/:mangaid/:chapterid", mangaController.deleteChapter);
router.get("/create/:id", mangaController.getCreateChapter);
router.post("/create/:id", mangaController.createChapter);
router.get("/edit/:id", mangaController.getEditManga);
router.put("/edit/:id", mangaController.editManga);
router.get("/create", mangaController.getCreateManga);
router.post("/create", mangaController.createManga);
router.get("/:id", mangaController.getManga);

module.exports = router;
