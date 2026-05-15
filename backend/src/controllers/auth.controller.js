const authService = require("../services/auth.service");

class AuthController {
  /**
   * POST /api/auth/register
   */
  async register(req, res, next) {
    try {
      const result = await authService.register(req.body);
      return res.status(201).json({
        success: true,
        message: "Usuário registrado com sucesso.",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/login
   */
  async login(req, res, next) {
    try {
      const result = await authService.login(req.body);
      return res.status(200).json({
        success: true,
        message: "Login realizado com sucesso.",
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/auth/me
   */
  async me(req, res, next) {
    try {
      const userService = require("../services/user.service");
      const user = await userService.getById(req.userId);
      return res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/auth/refresh
   */
  async refresh(req, res, next) {
    try {
      const { refreshToken } = req.body;
      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: "Refresh token é obrigatório.",
        });
      }

      const tokens = await authService.refresh(refreshToken);
      return res.status(200).json({
        success: true,
        message: "Token atualizado com sucesso.",
        data: tokens,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
