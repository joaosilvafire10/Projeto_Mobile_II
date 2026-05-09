const messageService = require("../services/message.service");

class MessageController {
  /**
   * POST /api/tickets/:ticketId/messages
   */
  async create(req, res, next) {
    try {
      const message = await messageService.create({
        ...req.body,
        ticketId: req.params.ticketId,
        userId: req.userId,
      });
      return res.status(201).json({
        success: true,
        message: "Mensagem enviada com sucesso.",
        data: message,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/tickets/:ticketId/messages
   */
  async getByTicketId(req, res, next) {
    try {
      const { page = 1, limit = 50 } = req.query;
      const result = await messageService.getByTicketId(req.params.ticketId, {
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
   * DELETE /api/messages/:id
   */
  async delete(req, res, next) {
    try {
      await messageService.delete(req.params.id);
      return res.status(200).json({
        success: true,
        message: "Mensagem removida com sucesso.",
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new MessageController();
