/**
 * Middleware global de tratamento de erros.
 * Captura erros não tratados e retorna respostas padronizadas.
 */
const errorHandler = (err, req, res, next) => {
  console.error("❌ Erro:", err);

  // Erro de validação do Zod
  if (err.name === "ZodError") {
    return res.status(400).json({
      success: false,
      message: "Erro de validação.",
      errors: err.errors.map((e) => ({
        campo: e.path.join("."),
        mensagem: e.message,
      })),
    });
  }

  // Erros do Prisma
  if (err.code === "P2002") {
    const campo = err.meta?.target?.join(", ") || "campo";
    return res.status(409).json({
      success: false,
      message: `Valor duplicado no campo: ${campo}`,
    });
  }

  if (err.code === "P2025") {
    return res.status(404).json({
      success: false,
      message: "Registro não encontrado.",
    });
  }

  // Erro genérico
  const statusCode = err.statusCode || 500;
  const message = err.statusCode
    ? err.message
    : "Erro interno do servidor.";

  return res.status(statusCode).json({
    success: false,
    message,
    ...(process.env.NODE_ENV === "development" && {
      stack: err.stack,
    }),
  });
};

module.exports = errorHandler;
