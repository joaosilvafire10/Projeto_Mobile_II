const swaggerJsdoc = require("swagger-jsdoc");

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "API - Sistema Inteligente de Chamados",
      version: "1.0.0",
      description:
        "API REST para gerenciamento inteligente de chamados com integração de IA (Google Gemini). " +
        "Inclui autenticação JWT, CRUD de usuários, chamados e mensagens, além de triagem automática por IA.",
      contact: {
        name: "Suporte",
      },
    },
    servers: [
      {
        url: "/",
        description: "Servidor Atual (Relativo - Recomendado para Deploy)",
      },
      {
        url: `http://localhost:${process.env.PORT || 3000}`,
        description: "Servidor de Desenvolvimento Local",
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
          description: "Insira o token JWT obtido no login",
        },
      },
      schemas: {
        User: {
          type: "object",
          properties: {
            id: { type: "string", format: "uuid" },
            name: { type: "string" },
            email: { type: "string", format: "email" },
            role: { type: "string", enum: ["ADMIN", "TECNICO", "USUARIO"] },
            department: {
              type: "string",
              enum: [
                "TI", "SUPORTE", "INFRAESTRUTURA", "DESENVOLVIMENTO",
                "SEGURANCA", "REDES", "BANCO_DE_DADOS", "GERAL",
              ],
            },
            avatarUrl: { type: "string", nullable: true },
            active: { type: "boolean" },
            createdAt: { type: "string", format: "date-time" },
            updatedAt: { type: "string", format: "date-time" },
          },
        },
        Ticket: {
          type: "object",
          properties: {
            id: { type: "string", format: "uuid" },
            title: { type: "string" },
            description: { type: "string" },
            status: {
              type: "string",
              enum: ["ABERTO", "EM_ANDAMENTO", "AGUARDANDO_USUARIO", "RESOLVIDO", "FINALIZADO"],
            },
            priority: {
              type: "string",
              enum: ["BAIXA", "MEDIA", "ALTA", "CRITICA"],
            },
            department: {
              type: "string",
              enum: [
                "TI", "SUPORTE", "INFRAESTRUTURA", "DESENVOLVIMENTO",
                "SEGURANCA", "REDES", "BANCO_DE_DADOS", "GERAL",
              ],
            },
            aiSummary: { type: "string", nullable: true },
            userId: { type: "string", format: "uuid" },
            createdAt: { type: "string", format: "date-time" },
            updatedAt: { type: "string", format: "date-time" },
          },
        },
        Message: {
          type: "object",
          properties: {
            id: { type: "string", format: "uuid" },
            content: { type: "string" },
            sender: { type: "string", enum: ["user", "ai", "system"] },
            ticketId: { type: "string", format: "uuid" },
            userId: { type: "string", format: "uuid", nullable: true },
            createdAt: { type: "string", format: "date-time" },
          },
        },
        Error: {
          type: "object",
          properties: {
            success: { type: "boolean", example: false },
            message: { type: "string" },
            errors: {
              type: "array",
              items: { type: "object" },
              nullable: true,
            },
          },
        },
        Pagination: {
          type: "object",
          properties: {
            total: { type: "integer" },
            page: { type: "integer" },
            limit: { type: "integer" },
            totalPages: { type: "integer" },
          },
        },
      },
    },
    security: [{ bearerAuth: [] }],
  },
  apis: ["./src/routes/*.js"],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
