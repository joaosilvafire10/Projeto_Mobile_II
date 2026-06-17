const aiService = require("../services/ai.service");

class AIController {
  /**
   * POST /api/ai/triage
   */
  async triage(req, res, next) {
    try {
      const { message, conversationHistory, ticketId, categoryName, activityName, categoryId, activityId } = req.body;

      const result = await aiService.processMessage({
        message,
        conversationHistory,
        userId: req.userId,
        ticketId,
        categoryName,
        activityName,
        categoryId,
        activityId,
      });

      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AIController();
