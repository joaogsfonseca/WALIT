const express = require("express");
const { authenticate } = require("../middleware/authMiddleware");
const {
    createWallet,
    getMyWallets,
    getWallet,
    updateWallet,
    deleteWallet,
    inviteUser,
    acceptInvitation,
    leaveWallet
} = require("../controllers/walletController");

const router = express.Router();

router.post("/", authenticate, createWallet);
router.get("/", authenticate, getMyWallets);
router.get("/:id", authenticate, getWallet);
router.put("/:id", authenticate, updateWallet);
router.delete("/:id", authenticate, deleteWallet);
router.post("/:id/invite", authenticate, inviteUser);
router.post("/invite/accept", authenticate, acceptInvitation);
router.post("/:id/leave", authenticate, leaveWallet);

module.exports = router;
