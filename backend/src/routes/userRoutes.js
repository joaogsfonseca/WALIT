const express = require("express");
const { getProfile, updateSettings } = require("../controllers/userController");
const { authenticate } = require("../middleware/authMiddleware");
const { generalLimiter } = require("../middleware/rateLimiter");

const router = express.Router();

router.use(generalLimiter);

router.get("/profile", authenticate, getProfile);
router.put("/settings", authenticate, updateSettings);

module.exports = router;
