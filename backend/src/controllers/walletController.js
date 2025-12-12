const { PrismaClient } = require("@prisma/client");
const crypto = require("crypto");
const { sendInvitationEmail } = require("../services/emailService");
const prisma = new PrismaClient();

const createWallet = async (req, res) => {
    try {
        const { name, type, currency } = req.body;
        const userId = req.user.userId;

        if (!name || !type || !currency) {
            return res.status(400).json({ error: "Missing required fields" });
        }

        const user = await prisma.user.findUnique({ where: { id: userId } });
        const walletCount = await prisma.walletMember.count({
            where: { user_id: userId }
        });

        const limit = user.premium_active ? 10 : 2;
        if (walletCount >= limit) {
            return res.status(403).json({ error: `User limit reached. You can only have/join ${limit} wallets.` });
        }

        const wallet = await prisma.wallet.create({
            data: {
                name,
                type,
                currency,
                owner_id: userId,
                members: {
                    create: {
                        user_id: userId,
                        role: "OWNER",
                    },
                },
            },
            include: {
                members: true,
            },
        });

        res.status(201).json(wallet);
    } catch (error) {
        console.error("Error creating wallet:", error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const getMyWallets = async (req, res) => {
    try {
        const userId = req.user.userId;

        const wallets = await prisma.wallet.findMany({
            where: {
                members: {
                    some: {
                        user_id: userId,
                    },
                },
            },
            include: {
                members: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                name: true,
                                email: true,
                                profile_image_url: true
                            }
                        }
                    }
                },
                _count: {
                    select: { members: true }
                }
            },
            orderBy: {
                created_at: 'desc'
            }
        });

        res.json(wallets);
    } catch (error) {
        console.error("Error fetching wallets:", error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const getWallet = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;

        const wallet = await prisma.wallet.findUnique({
            where: { id },
            include: {
                members: {
                    include: {
                        user: {
                            select: {
                                id: true,
                                name: true,
                                email: true,
                                profile_image_url: true
                            }
                        }
                    }
                },
                invitations: true,
                _count: {
                    select: { members: true }
                }
            },
        });

        if (!wallet) {
            return res.status(404).json({ error: "Wallet not found" });
        }

        // Check if user is a member
        const isMember = wallet.members.some(member => member.user_id === userId);
        if (!isMember) {
            return res.status(403).json({ error: "Access denied" });
        }

        res.json(wallet);
    } catch (error) {
        console.error("Error fetching wallet:", error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const updateWallet = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, type, currency } = req.body;
        const userId = req.user.userId;

        const walletMember = await prisma.walletMember.findUnique({
            where: {
                user_id_wallet_id: {
                    user_id: userId,
                    wallet_id: id,
                },
            },
        });

        if (!walletMember || (walletMember.role !== "OWNER" && walletMember.role !== "ADMIN")) {
            return res.status(403).json({ error: "Insufficient permissions" });
        }

        const updatedWallet = await prisma.wallet.update({
            where: { id },
            data: { name, type, currency },
        });

        res.json(updatedWallet);
    } catch (error) {
        console.error("Error updating wallet:", error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const deleteWallet = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;

        const wallet = await prisma.wallet.findUnique({
            where: { id },
        });

        if (!wallet) {
            return res.status(404).json({ error: "Wallet not found" });
        }

        if (wallet.owner_id !== userId) {
            return res.status(403).json({ error: "Only the owner can delete the wallet" });
        }

        await prisma.wallet.delete({
            where: { id },
        });

        res.status(204).send();
    } catch (error) {
        console.error("Error deleting wallet:", error);
        res.status(500).json({ error: "Internal server error" });
    }
}

const inviteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { email } = req.body;
        const inviterId = req.user.userId;

        if (!email) {
            return res.status(400).json({ error: "Email is required" });
        }

        const wallet = await prisma.wallet.findUnique({
            where: { id },
            include: { members: true }
        });

        if (!wallet) {
            return res.status(404).json({ error: "Wallet not found" });
        }

        const isMember = wallet.members.some(m => m.user_id === inviterId);
        if (!isMember) {
            return res.status(403).json({ error: "Access denied" });
        }

        if (wallet.members.length >= 5) {
            return res.status(400).json({ error: "Wallet has reached the maximum limit of 5 members" });
        }

        const userToInvite = await prisma.user.findUnique({ where: { email } });
        if (userToInvite) {
            const alreadyMember = wallet.members.some(m => m.user_id === userToInvite.id);
            if (alreadyMember) {
                return res.status(400).json({ error: "User is already a member" });
            }
        }

        const existingInvite = await prisma.invitation.findFirst({
            where: {
                wallet_id: id,
                email_invited: email,
                status: "PENDING"
            }
        });

        if (existingInvite) {
            return res.status(400).json({ error: "Invitation already sent to this email" });
        }

        const token = crypto.randomBytes(32).toString("hex");

        await prisma.invitation.create({
            data: {
                wallet_id: id,
                email_invited: email,
                invited_by: inviterId,
                token,
                status: "PENDING"
            }
        });

        const inviter = await prisma.user.findUnique({ where: { id: inviterId } });
        await sendInvitationEmail(email, token, inviter.name || inviter.email, wallet.name);

        if (!process.env.SMTP_HOST) {
            return res.json({ message: "Invitation sent", token });
        }

        res.json({ message: "Invitation sent" });

    } catch (error) {
        console.error("Error inviting user:", error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const acceptInvitation = async (req, res) => {
    try {
        const { token } = req.body;
        const userId = req.user.userId;

        if (!token) {
            return res.status(400).json({ error: "Token is required" });
        }

        const invitation = await prisma.invitation.findUnique({
            where: { token },
            include: { wallet: { include: { members: true } } }
        });

        if (!invitation || invitation.status !== "PENDING") {
            return res.status(400).json({ error: "Invalid or expired invitation" });
        }

        if (invitation.wallet.members.length >= 5) {
            return res.status(400).json({ error: "Wallet is full" });
        }

        const alreadyMember = invitation.wallet.members.some(m => m.user_id === userId);
        if (alreadyMember) {
            await prisma.invitation.delete({ where: { id: invitation.id } });
            return res.json({ message: "You are already a member" });
        }

        const user = await prisma.user.findUnique({ where: { id: userId } });
        const walletCount = await prisma.walletMember.count({
            where: { user_id: userId }
        });

        const limit = user.premium_active ? 10 : 2;
        if (walletCount >= limit) {
            return res.status(403).json({ error: `User limit reached. You can only have/join ${limit} wallets.` });
        }

        await prisma.walletMember.create({
            data: {
                user_id: userId,
                wallet_id: invitation.wallet_id,
                role: "MEMBER"
            }
        });

        await prisma.invitation.delete({ where: { id: invitation.id } });

        res.json({ message: "Joined wallet successfully" });

    } catch (error) {
        console.error("Error accepting invitation:", error);
        res.status(500).json({ error: "Internal server error" });
    }
};

const leaveWallet = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;

        const walletMember = await prisma.walletMember.findUnique({
            where: {
                user_id_wallet_id: {
                    user_id: userId,
                    wallet_id: id,
                },
            },
            include: { wallet: true }
        });

        if (!walletMember) {
            return res.status(404).json({ error: "Not a member of this wallet" });
        }

        if (walletMember.role === "OWNER") {
            // Optional: Check if there are other members and force transfer or just allow generic error
            return res.status(403).json({ error: "Owner cannot leave wallet. Delete it or transfer ownership." });
        }

        await prisma.walletMember.delete({
            where: {
                user_id_wallet_id: {
                    user_id: userId,
                    wallet_id: id,
                }
            }
        });

        res.json({ message: "Left wallet successfully" });
    } catch (error) {
        console.error("Error leaving wallet:", error);
        res.status(500).json({ error: "Internal server error" });
    }
}

module.exports = {
    createWallet,
    getMyWallets,
    getWallet,
    updateWallet,
    deleteWallet,
    inviteUser,
    acceptInvitation,
    leaveWallet
};
