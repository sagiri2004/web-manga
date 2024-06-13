const express = require("express");
const router = express.Router();
const siteController = require("../app/controllers/SiteController");

router.post("/advanced_search", siteController.advancedSearch);
router.get("/advanced_search", siteController.getAdvancedSearch);
router.get("/search", siteController.search)
router.get("/", siteController.home)

module.exports = router
