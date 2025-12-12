const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { PrismaClient } = require("@prisma/client");
const { sendResetEmail, sendVerificationEmail } = require("../services/emailService");

const prisma = new PrismaClient();

// Helper: Generate and Save Refresh Token
const generateRefreshToken = async (userId, ipAddress) => {
    // Generate random token
    const token = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    // Hash the token before storing (optional if you want extra security, but plain is OK for now if DB is secure)
    // For simplicity, we store the token as is or a simple hash. Let's store as is for now to match the "token" field.
    // If you want to hash it: const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    // Using simple storage for logic clarity

    // In schema we named it "token_hash", implying we should hash it or at least treat it as the stored secret.
    // Let's store the token directly in "token_hash" for simplicity or actually hash it.
    // Recommended: Return User the "token", store "hash(token)" in DB.

    // Implementation:
    // 1. Token = random string
    // 2. Hash = SHA256(token)
    // 3. Store Hash
    // 4. Return Token to user

    // Currently Schema has `token_hash`. So let's hash.
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

    await prisma.refreshToken.create({
        data: {
            user_id: userId,
            token_hash: tokenHash,
            expires_at: expiresAt,
        }
    });

    return token;
};

const register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: "Email e password são obrigatórios" });
        }

        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ error: "Email já está em uso" });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        // Generate Verification Code
        const verificationCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6 digits starting with non-zero
        const codeExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 mins

        await prisma.$transaction(async (tx) => {
            const user = await tx.user.create({
                data: {
                    name,
                    email,
                    password_hash: passwordHash,
                    verification_code: verificationCode,
                    verification_code_expires: codeExpires,
                    email_verified: false,
                },
            });

            await tx.userSettings.create({
                data: {
                    user_id: user.id,
                },
            });

            // Send Email
            await sendVerificationEmail(email, verificationCode);
        });

        res.status(201).json({ message: "Conta criada. Verifique o seu email." });
    } catch (error) {
        console.error("Erro no registo:", error);
        res.status(500).json({ error: "Erro interno do servidor" });
    }
};

const verifyEmail = async (req, res) => {
    try {
        const { email, code } = req.body;

        if (!email || !code) return res.status(400).json({ error: "Dados em falta" });

        const user = await prisma.user.findUnique({ where: { email } });

        if (!user) return res.status(404).json({ error: "User not found" });

        if (user.email_verified) return res.status(400).json({ error: "Email já verificado" });

        if (user.verification_code !== code) {
            return res.status(400).json({ error: "Código inválido" });
        }

        if (new Date() > user.verification_code_expires) {
            return res.status(400).json({ error: "Código expirado" });
        }

        // Verify Success
        await prisma.user.update({
            where: { id: user.id },
            data: {
                email_verified: true,
                verification_code: null,
                verification_code_expires: null,
            }
        });

        // Issue Tokens
        const jwtToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
            expiresIn: "15m",
        });
        const refreshToken = await generateRefreshToken(user.id);

        res.json({
            message: "Email verificado com sucesso",
            token: jwtToken,
            refreshToken,
            user: { id: user.id, name: user.name, email: user.email }
        });

    } catch (error) {
        console.error("Verify error:", error);
        res.status(500).json({ error: "Erro na verificação" });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) {
            return res.status(401).json({ error: "Credenciais inválidas" });
        }

        const isValid = await bcrypt.compare(password, user.password_hash);
        if (!isValid) {
            return res.status(401).json({ error: "Credenciais inválidas" });
        }

        if (!user.email_verified) {
            return res.status(403).json({ error: "Email não verificado. Por favor verifique o seu email." });
        }

        // Generate Access Token (15 min)
        const jwtToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
            expiresIn: "15m",
        });

        // Generate Refresh Token
        const refreshToken = await generateRefreshToken(user.id);

        res.json({
            token: jwtToken,
            refreshToken,
            user: { id: user.id, name: user.name, email: user.email }
        });
    } catch (error) {
        console.error("Erro no login:", error);
        res.status(500).json({ error: "Erro interno do servidor" });
    }
};

const refreshToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return res.status(400).json({ error: "Refresh Token is required" });
        }

        const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

        // Find token in DB
        const savedToken = await prisma.refreshToken.findUnique({
            where: { token_hash: tokenHash },
            include: { user: true }
        });

        if (!savedToken) {
            // Token not found (maybe reused/revoked? Could be security threat)
            // If we implemented reuse detection, we would invalidate all user tokens here.
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        if (savedToken.revoked) {
            // Reuse detected!
            // Consider revoking all tokens for this user family
            return res.status(401).json({ error: "Token revoked" });
        }

        if (new Date() > savedToken.expires_at) {
            return res.status(401).json({ error: "Token expired" });
        }

        // Token is valid. Rotate it.
        // 1. Revoke old token
        await prisma.refreshToken.update({
            where: { id: savedToken.id },
            data: { revoked: true }
        });

        // 2. Generate new Access Token
        const newJwtToken = jwt.sign({ userId: savedToken.user_id }, process.env.JWT_SECRET, {
            expiresIn: "15m",
        });

        // 3. Generate new Refresh Token
        const newRefreshToken = await generateRefreshToken(savedToken.user_id);

        res.json({
            token: newJwtToken,
            refreshToken: newRefreshToken,
            user: { id: savedToken.user.id, name: savedToken.user.name, email: savedToken.user.email }
        });

    } catch (error) {
        console.error("Error refreshing token:", error);
        res.status(500).json({ error: "Internal error" });
    }
};

const logout = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        // Even if no refreshToken provided, we just say OK.
        // But if provided, we revoke it.
        if (refreshToken) {
            const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
            await prisma.refreshToken.updateMany({
                where: { token_hash: tokenHash },
                data: { revoked: true }
            });
        }
        res.json({ message: "Logout success" });
    } catch (error) {
        console.error("Logout error", error);
        res.status(500).json({ error: "Logout failed" });
    }
};

const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await prisma.user.findUnique({ where: { email } });

        if (!user) {
            // Por segurança, não dizer se o email existe ou não, mas aqui simplifico por agora.
            return res.status(404).json({ error: "Utilizador não encontrado" });
        }

        // Criar token aleatório
        const token = crypto.randomBytes(20).toString("hex");
        const expires = new Date(Date.now() + 3600000); // 1 hora

        await prisma.user.update({
            where: { id: user.id },
            data: {
                reset_token: token,
                reset_token_expires: expires,
            },
        });

        await sendResetEmail(email, token);

        res.json({ message: "Email de recuperação enviado" });
    } catch (error) {
        console.error("Erro no forgotPassword:", error);
        res.status(500).json({ error: "Erro interno" });
    }
};

const resetPassword = async (req, res) => {
    try {
        const { token, newPassword } = req.body;

        const user = await prisma.user.findFirst({
            where: {
                reset_token: token,
                reset_token_expires: { gt: new Date() }, // Expiração > Agora
            },
        });

        if (!user) {
            return res.status(400).json({ error: "Token inválido ou expirado" });
        }

        const passwordHash = await bcrypt.hash(newPassword, 10);

        await prisma.user.update({
            where: { id: user.id },
            data: {
                password_hash: passwordHash,
                reset_token: null,
                reset_token_expires: null,
            },
        });

        res.json({ message: "Password alterada com sucesso" });
    } catch (error) {
        console.error("Erro no resetPassword:", error);
        res.status(500).json({ error: "Erro interno" });
    }
};

module.exports = { register, login, refreshToken, logout, forgotPassword, resetPassword, verifyEmail };
