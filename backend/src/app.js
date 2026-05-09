const express = require("express");
const cors = require("cors");
const swaggerUi = require("swagger-ui-express");
const config = require("./config/env");
const swaggerSpec = require("./config/swagger");
const errorHandler = require("./middlewares/error.middleware");

// Importar rotas
const authRoutes = require("./routes/auth.routes");
const userRoutes = require("./routes/user.routes");
const ticketRoutes = require("./routes/ticket.routes");
const messageRoutes = require("./routes/message.routes");
const aiRoutes = require("./routes/ai.routes");

const app = express();

// =============================================
// MIDDLEWARES GLOBAIS
// =============================================

// CORS
app.use(
  cors({
    origin: config.cors.origin,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Parse JSON
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// =============================================
// DOCUMENTAÇÃO SWAGGER
// =============================================
app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: `
    .swagger-ui .topbar { background-color: #1a1f36; }
    .swagger-ui .info .title { color: #6c63ff; }
  `,
  customSiteTitle: "API Chamados Inteligentes - Docs",
}));

// =============================================
// ROTA DE SAÚDE
// =============================================
app.get("/api/health", (req, res) => {
  res.status(200).json({
    success: true,
    message: "API funcionando corretamente! 🚀",
    timestamp: new Date().toISOString(),
    environment: config.nodeEnv,
  });
});

// =============================================
// ROTAS DA API
// =============================================
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/tickets", ticketRoutes);
app.use("/api/tickets", messageRoutes);
app.use("/api/ai", aiRoutes);

// =============================================
// ROTA 404
// =============================================
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: `Rota não encontrada: ${req.method} ${req.originalUrl}`,
  });
});

// =============================================
// TRATAMENTO GLOBAL DE ERROS
// =============================================
app.use(errorHandler);

module.exports = app;
