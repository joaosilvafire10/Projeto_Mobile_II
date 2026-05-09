const userService = require("../services/user.service");

class UserController {
  /**
   * GET /api/users
   */
  async getAll(req, res, next) {
    try {
      const { page = 1, limit = 10 } = req.query;
      const result = await userService.getAll({
        page: parseInt(page),
        limit: parseInt(limit),
      });
      return res.status(200).json({
        success: true,
        ...result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/users/:id
   */
  async getById(req, res, next) {
    try {
      const user = await userService.getById(req.params.id);
      return res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/users/:id
   */
  async update(req, res, next) {
    try {
      const user = await userService.update(req.params.id, req.body);
      return res.status(200).json({
        success: true,
        message: "Usuário atualizado com sucesso.",
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/users/:id
   */
  async delete(req, res, next) {
    try {
      await userService.delete(req.params.id);
      return res.status(200).json({
        success: true,
        message: "Usuário removido com sucesso.",
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UserController();
