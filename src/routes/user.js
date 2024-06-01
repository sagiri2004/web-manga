const express = require("express");
const router = express.Router();
const userController = require("../app/controllers/UserController");

router.get("/my-created-manga", userController.myCreatedManga);
router.get("/:id", userController.getUserProfile);

module.exports = router;
