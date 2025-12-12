const express = require("express");
const { register, login, refreshToken, logout, forgotPassword, resetPassword, verifyEmail } = require("../controllers/authController");

const router = express.Router();

router.post("/signup", register);
router.post("/verify-email", verifyEmail);
router.post("/login", login);
router.post("/refresh-token", refreshToken);
router.post("/logout", logout);
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);

module.exports = router;
