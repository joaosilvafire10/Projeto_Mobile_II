const jwt = require("jsonwebtoken");
const config = require("../config/env");

/**
 * Middleware de autenticação JWT.
 * Verifica se o token é válido e anexa os dados do usuário ao request.
 */
const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        message: "Token de autenticação não fornecido.",
      });
    }

    const parts = authHeader.split(" ");

    if (parts.length !== 2 || parts[0] !== "Bearer") {
      return res.status(401).json({
        success: false,
        message: "Formato de token inválido. Use: Bearer <token>",
      });
    }

    const token = parts[1];

    const decoded = jwt.verify(token, config.jwt.secret);
    req.userId = decoded.id;
    req.userRole = decoded.role;

    return next();
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res.status(401).json({
        success: false,
        message: "Token expirado. Faça login novamente.",
      });
    }
    if (error.name === "JsonWebTokenError") {
      return res.status(401).json({
        success: false,
        message: "Token inválido.",
      });
    }
    return res.status(500).json({
      success: false,
      message: "Erro interno na autenticação.",
    });
  }
};

/**
 * Middleware de autorização por papel (role).
 * @param  {...string} roles - Papéis autorizados
 */
const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.userRole)) {
      return res.status(403).json({
        success: false,
        message: "Acesso negado. Permissão insuficiente.",
      });
    }
    return next();
  };
};

module.exports = { authMiddleware, authorizeRoles };
