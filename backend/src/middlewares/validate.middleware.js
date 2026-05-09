const { z } = require("zod");

/**
 * Middleware de validação genérico usando Zod.
 * @param {z.ZodSchema} schema - Schema Zod para validação
 * @param {"body"|"query"|"params"} source - Fonte dos dados (default: "body")
 */
const validate = (schema, source = "body") => {
  return (req, res, next) => {
    try {
      const result = schema.parse(req[source]);
      req[source] = result; // Substituir com dados validados/transformados
      return next();
    } catch (error) {
      if (error instanceof z.ZodError) {
        return res.status(400).json({
          success: false,
          message: "Erro de validação.",
          errors: error.errors.map((e) => ({
            campo: e.path.join("."),
            mensagem: e.message,
          })),
        });
      }
      return next(error);
    }
  };
};

module.exports = validate;
