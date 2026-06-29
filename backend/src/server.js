require("dotenv").config();
const express = require("express");
const cors = require("cors");

const app = express();

// CORS: se CORS_ORIGIN estiver definido, restringe às origens listadas.
// Caso contrário permite todas (apenas adequado em desenvolvimento).
const corsOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(",").map((o) => o.trim())
    : "*";
app.use(cors({ origin: corsOrigins }));

app.use(express.json());

app.get("/", (req, res) => {
  res.json({ message: "API Running" });
});

// Importar rotas depois
const authRoutes = require("./routes/authRoutes");
const walletRoutes = require("./routes/walletRoutes");
const userRoutes = require("./routes/userRoutes");
app.use("/auth", authRoutes);
app.use("/wallets", walletRoutes);
app.use("/users", userRoutes);

// Handler de erros centralizado — apanha exceções não tratadas nas rotas.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({ error: "Erro interno do servidor" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("Server running on port", PORT));
