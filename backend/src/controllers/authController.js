const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const prisma = require("../lib/prisma");
const { sendResetEmail, sendVerificationEmail } = require("../services/emailService");

// Validação mínima de password.
const isPasswordValid = (password) => typeof password === "string" && password.length >= 8;

// Gera um código de verificação de 6 dígitos com gerador criptográfico.
const generateVerificationCode = () => crypto.randomInt(100000, 1000000).toString();

// Hash de tokens guardados na BD (refresh / reset).
const hashToken = (token) => crypto.createHash("sha256").update(token).digest("hex");

// Helper: gerar e guardar refresh token (guardamos apenas o hash).
const generateRefreshToken = async (userId) => {
    const token = crypto.randomBytes(40).toString("hex");
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 dias

    await prisma.refreshToken.create({
        data: {
            user_id: userId,
            token_hash: hashToken(token),
            expires_at: expiresAt,
        },
    });

    return token;
};

const register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: "Email e password são obrigatórios" });
        }

        if (!isPasswordValid(password)) {
            return res.status(400).json({ error: "A password deve ter pelo menos 8 caracteres" });
        }

        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ error: "Email já está em uso" });
        }

        const passwordHash = await bcrypt.hash(password, 10);

        const verificationCode = generateVerificationCode();
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
        });

        // Enviar email fora da transação para não a manter aberta durante I/O de rede.
        await sendVerificationEmail(email, verificationCode);

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

        if (!user.verification_code || user.verification_code !== code) {
            return res.status(400).json({ error: "Código inválido" });
        }

        if (!user.verification_code_expires || new Date() > user.verification_code_expires) {
            return res.status(400).json({ error: "Código expirado" });
        }

        // Verify Success
        await prisma.user.update({
            where: { id: user.id },
            data: {
                email_verified: true,
                verification_code: null,
                verification_code_expires: null,
            },
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
            user: { id: user.id, name: user.name, email: user.email },
        });
    } catch (error) {
        console.error("Verify error:", error);
        res.status(500).json({ error: "Erro na verificação" });
    }
};

const resendVerification = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: "Email é obrigatório" });

        const user = await prisma.user.findUnique({ where: { email } });

        // Resposta genérica para não permitir enumeração de utilizadores.
        if (!user || user.email_verified) {
            return res.json({ message: "Se a conta existir e não estiver verificada, foi enviado um novo código." });
        }

        const verificationCode = generateVerificationCode();
        const codeExpires = new Date(Date.now() + 15 * 60 * 1000);

        await prisma.user.update({
            where: { id: user.id },
            data: {
                verification_code: verificationCode,
                verification_code_expires: codeExpires,
            },
        });

        await sendVerificationEmail(email, verificationCode);

        res.json({ message: "Se a conta existir e não estiver verificada, foi enviado um novo código." });
    } catch (error) {
        console.error("Resend verification error:", error);
        res.status(500).json({ error: "Erro interno do servidor" });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: "Email e password são obrigatórios" });
        }

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
            user: { id: user.id, name: user.name, email: user.email },
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

        const tokenHash = hashToken(refreshToken);

        // Find token in DB
        const savedToken = await prisma.refreshToken.findUnique({
            where: { token_hash: tokenHash },
            include: { user: true },
        });

        if (!savedToken) {
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        if (savedToken.revoked) {
            // Reuse detectado: um token já revogado foi reutilizado.
            // Por segurança, revogamos toda a família de tokens deste utilizador.
            await prisma.refreshToken.updateMany({
                where: { user_id: savedToken.user_id, revoked: false },
                data: { revoked: true },
            });
            return res.status(401).json({ error: "Token revoked" });
        }

        if (new Date() > savedToken.expires_at) {
            return res.status(401).json({ error: "Token expired" });
        }

        // Token válido. Rodar: revogar o antigo e emitir novos.
        const newRefreshTokenValue = crypto.randomBytes(40).toString("hex");
        const newRefreshHash = hashToken(newRefreshTokenValue);

        await prisma.$transaction([
            prisma.refreshToken.update({
                where: { id: savedToken.id },
                data: { revoked: true, replaced_by_token: newRefreshHash },
            }),
            prisma.refreshToken.create({
                data: {
                    user_id: savedToken.user_id,
                    token_hash: newRefreshHash,
                    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
                },
            }),
        ]);

        const newJwtToken = jwt.sign({ userId: savedToken.user_id }, process.env.JWT_SECRET, {
            expiresIn: "15m",
        });

        res.json({
            token: newJwtToken,
            refreshToken: newRefreshTokenValue,
            user: { id: savedToken.user.id, name: savedToken.user.name, email: savedToken.user.email },
        });
    } catch (error) {
        console.error("Error refreshing token:", error);
        res.status(500).json({ error: "Internal error" });
    }
};

const logout = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        if (refreshToken) {
            const tokenHash = hashToken(refreshToken);
            await prisma.refreshToken.updateMany({
                where: { token_hash: tokenHash },
                data: { revoked: true },
            });
        }
        res.json({ message: "Logout success" });
    } catch (error) {
        console.error("Logout error", error);
        res.status(500).json({ error: "Logout failed" });
    }
};

const forgotPassword = async (req, res) => {
    // Resposta genérica em todos os casos para evitar enumeração de utilizadores.
    const genericResponse = { message: "Se existir uma conta com esse email, foi enviado um link de recuperação." };
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: "Email é obrigatório" });

        const user = await prisma.user.findUnique({ where: { email } });

        if (user) {
            // Geramos o token, enviamos o original por email e guardamos apenas o hash.
            const rawToken = crypto.randomBytes(32).toString("hex");
            const expires = new Date(Date.now() + 3600000); // 1 hora

            await prisma.user.update({
                where: { id: user.id },
                data: {
                    reset_token: hashToken(rawToken),
                    reset_token_expires: expires,
                },
            });

            await sendResetEmail(email, rawToken);
        }

        res.json(genericResponse);
    } catch (error) {
        console.error("Erro no forgotPassword:", error);
        res.status(500).json({ error: "Erro interno" });
    }
};

const resetPassword = async (req, res) => {
    try {
        const { token, newPassword } = req.body;

        if (!token || !newPassword) {
            return res.status(400).json({ error: "Token e nova password são obrigatórios" });
        }

        if (!isPasswordValid(newPassword)) {
            return res.status(400).json({ error: "A password deve ter pelo menos 8 caracteres" });
        }

        const user = await prisma.user.findFirst({
            where: {
                reset_token: hashToken(token),
                reset_token_expires: { gt: new Date() }, // Expiração > Agora
            },
        });

        if (!user) {
            return res.status(400).json({ error: "Token inválido ou expirado" });
        }

        const passwordHash = await bcrypt.hash(newPassword, 10);

        await prisma.$transaction([
            prisma.user.update({
                where: { id: user.id },
                data: {
                    password_hash: passwordHash,
                    reset_token: null,
                    reset_token_expires: null,
                },
            }),
            // Revogar todas as sessões ativas após mudança de password.
            prisma.refreshToken.updateMany({
                where: { user_id: user.id, revoked: false },
                data: { revoked: true },
            }),
        ]);

        res.json({ message: "Password alterada com sucesso" });
    } catch (error) {
        console.error("Erro no resetPassword:", error);
        res.status(500).json({ error: "Erro interno" });
    }
};

module.exports = { register, login, refreshToken, logout, forgotPassword, resetPassword, verifyEmail, resendVerification };
