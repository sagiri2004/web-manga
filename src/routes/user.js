const express = require("express");
const router = express.Router();
const userController = require("../app/controllers/UserController");

router.post("/ban/:id", userController.ban);
router.post("/unban/:id", userController.unban);
router.get("/admin", userController.getAllUser);
router.get("/my-created-manga", userController.myCreatedManga);
router.post("/add-favorite-manga/:id", userController.addFavoriteManga);
router.post("/remove-favorite-manga/:id", userController.removeFavoriteManga);
router.post("/submit-rating", userController.updateRating);
router.get("/:id", userController.getUserProfile);
router.put("/:id", userController.markAsReadNotice);

module.exports = router;
