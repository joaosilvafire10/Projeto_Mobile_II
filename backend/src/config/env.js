require("dotenv").config();

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || "development",
  jwt: {
    secret: process.env.JWT_SECRET || "access_secret_123",
    expiresIn: process.env.JWT_EXPIRES_IN || "15m",
    refreshSecret: process.env.JWT_REFRESH_SECRET || "refresh_secret_123",
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || "7d",
  },
  bcrypt: {
    saltRounds: parseInt(process.env.BCRYPT_SALT_ROUNDS) || 10,
  },
  cors: {
    origin: process.env.CORS_ORIGIN || "*",
  },
  gemini: {
    apiKey: process.env.GEMINI_API_KEY || "",
  },
};
