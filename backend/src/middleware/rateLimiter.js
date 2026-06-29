const rateLimit = require("express-rate-limit");

// Limiter agressivo para endpoints sensíveis (login, verificação, recuperação).
// Protege contra brute force de passwords e de códigos de verificação.
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 10, // 10 tentativas por IP por janela
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: "Demasiadas tentativas. Tente novamente mais tarde." },
});

// Limiter mais permissivo para o resto da API autenticada.
const generalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: "Demasiados pedidos. Tente novamente mais tarde." },
});

module.exports = { authLimiter, generalLimiter };
