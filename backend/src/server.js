const app = require("./app");
const config = require("./config/env");
const prisma = require("./config/database");

const startServer = async () => {
  try {
    // Testar conexão com o banco de dados
    await prisma.$connect();
    console.log("✅ Conectado ao banco de dados SQLite");

    // Iniciar servidor
    app.listen(config.port, () => {
      console.log(`
╔═══════════════════════════════════════════════════╗
║                                                   ║
║   🚀 Servidor rodando na porta ${config.port}              ║
║                                                   ║
║   📋 API:      http://localhost:${config.port}/api          ║
║   📖 Swagger:  http://localhost:${config.port}/api/docs     ║
║   💚 Health:   http://localhost:${config.port}/api/health    ║
║                                                   ║
║   🌍 Ambiente: ${config.nodeEnv.padEnd(19)}             ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error("❌ Erro ao iniciar servidor:", error);
    process.exit(1);
  }
};

// Tratamento de encerramento gracioso
process.on("SIGINT", async () => {
  console.log("\n🔄 Encerrando servidor...");
  await prisma.$disconnect();
  console.log("✅ Conexão com banco encerrada.");
  process.exit(0);
});

process.on("SIGTERM", async () => {
  await prisma.$disconnect();
  process.exit(0);
});

startServer();
