const express = require("express");
const { getProfile, updateSettings } = require("../controllers/userController");
const { authenticate } = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/profile", authenticate, getProfile);
router.put("/settings", authenticate, updateSettings);

module.exports = router;
