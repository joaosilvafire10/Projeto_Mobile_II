const activityService = require("../services/activity.service");

class ActivityController {
  /**
   * POST /api/activities
   */
  async create(req, res, next) {
    try {
      const activity = await activityService.create(req.body);
      return res.status(201).json({
        success: true,
        message: "Atividade criada com sucesso.",
        data: activity,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/activities
   */
  async getAll(req, res, next) {
    try {
      const activeOnly = req.query.activeOnly === "true";
      const activities = await activityService.getAll({ activeOnly });
      return res.status(200).json({
        success: true,
        data: activities,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/activities/category/:categoryId
   */
  async getByCategoryId(req, res, next) {
    try {
      const activeOnly = req.query.activeOnly === "true";
      const activities = await activityService.getByCategoryId(
        req.params.categoryId,
        { activeOnly }
      );
      return res.status(200).json({
        success: true,
        data: activities,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/activities/:id
   */
  async getById(req, res, next) {
    try {
      const activity = await activityService.getById(req.params.id);
      return res.status(200).json({
        success: true,
        data: activity,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/activities/:id
   */
  async update(req, res, next) {
    try {
      const activity = await activityService.update(req.params.id, req.body);
      return res.status(200).json({
        success: true,
        message: "Atividade atualizada com sucesso.",
        data: activity,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/activities/:id
   */
  async delete(req, res, next) {
    try {
      await activityService.delete(req.params.id);
      return res.status(200).json({
        success: true,
        message: "Atividade removida com sucesso.",
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ActivityController();
