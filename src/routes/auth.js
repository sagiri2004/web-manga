const express = require("express");
const router = express.Router();
const authController = require("../app/controllers/AuthController");

router.get("/register", authController.getRegister);
router.post("/register", authController.register);
router.get("/login", authController.getLogin);
router.post("/login", authController.login);
router.post("/logout", authController.logout);

module.exports = router;
