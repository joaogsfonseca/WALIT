const prisma = require("../lib/prisma");

const getProfile = async (req, res) => {
    try {
        const userId = req.user.userId;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                name: true,
                email: true,
                profile_image_url: true,
                premium_active: true,
                premium_until: true,
                settings: {
                    select: {
                        theme: true,
                        language: true
                    }
                }
            },
        });

        if (!user) {
            return res.status(404).json({ error: "Utilizador não encontrado" });
        }

        res.json(user);
    } catch (error) {
        console.error("Erro ao obter perfil:", error);
        res.status(500).json({ error: "Erro interno do servidor" });
    }
};

const updateSettings = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { theme, language } = req.body;

        const updatedSettings = await prisma.userSettings.update({
            where: { user_id: userId },
            data: {
                ...(theme && { theme }),
                ...(language && { language }),
            },
        });

        res.json(updatedSettings);
    } catch (error) {
        console.error("Erro ao atualizar definições:", error);
        res.status(500).json({ error: "Erro interno do servidor" });
    }
};

module.exports = { getProfile, updateSettings };
