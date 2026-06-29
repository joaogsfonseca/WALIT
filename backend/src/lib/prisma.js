const { PrismaClient } = require("@prisma/client");

// Singleton PrismaClient — evita múltiplos pools de ligações quando
// vários controllers importam o cliente.
const prisma = global.prisma || new PrismaClient();

if (process.env.NODE_ENV !== "production") {
    global.prisma = prisma;
}

module.exports = prisma;
