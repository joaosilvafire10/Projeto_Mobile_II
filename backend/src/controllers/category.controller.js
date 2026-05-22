const categoryService = require("../services/category.service");

class CategoryController {
  /**
   * POST /api/categories
   */
  async create(req, res, next) {
    try {
      const category = await categoryService.create(req.body);
      return res.status(201).json({
        success: true,
        message: "Categoria criada com sucesso.",
        data: category,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/categories
   */
  async getAll(req, res, next) {
    try {
      const activeOnly = req.query.activeOnly === "true";
      const categories = await categoryService.getAll({ activeOnly });
      return res.status(200).json({
        success: true,
        data: categories,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/categories/:id
   */
  async getById(req, res, next) {
    try {
      const category = await categoryService.getById(req.params.id);
      return res.status(200).json({
        success: true,
        data: category,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/categories/:id
   */
  async update(req, res, next) {
    try {
      const category = await categoryService.update(req.params.id, req.body);
      return res.status(200).json({
        success: true,
        message: "Categoria atualizada com sucesso.",
        data: category,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/categories/:id
   */
  async delete(req, res, next) {
    try {
      await categoryService.delete(req.params.id);
      return res.status(200).json({
        success: true,
        message: "Categoria removida com sucesso.",
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CategoryController();
