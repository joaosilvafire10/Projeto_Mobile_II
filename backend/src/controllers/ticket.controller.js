const ticketService = require("../services/ticket.service");

class TicketController {
  /**
   * POST /api/tickets
   */
  async create(req, res, next) {
    try {
      const ticket = await ticketService.create(req.body, req.userId);
      return res.status(201).json({
        success: true,
        message: "Chamado criado com sucesso.",
        data: ticket,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/tickets
   */
  async getAll(req, res, next) {
    try {
      const result = await ticketService.getAll(req.query, req.userId, req.userRole, req.userDepartment);
      return res.status(200).json({
        success: true,
        ...result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/tickets/stats
   */
  async getStats(req, res, next) {
    try {
      const stats = await ticketService.getStats();
      return res.status(200).json({
        success: true,
        data: stats,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/tickets/:id
   */
  async getById(req, res, next) {
    try {
      const ticket = await ticketService.getById(req.params.id, req.userId, req.userRole, req.userDepartment);
      return res.status(200).json({
        success: true,
        data: ticket,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/tickets/:id
   */
  async update(req, res, next) {
    try {
      const ticket = await ticketService.update(
        req.params.id,
        req.body,
        req.userId,
        req.userRole,
        req.userDepartment
      );
      return res.status(200).json({
        success: true,
        message: "Chamado atualizado com sucesso.",
        data: ticket,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/tickets/:id/assign
   */
  async assignToMe(req, res, next) {
    try {
      const ticket = await ticketService.assignToMe(
        req.params.id,
        req.userId,
        req.userRole,
        req.userDepartment
      );
      return res.status(200).json({
        success: true,
        message: "Chamado atribuído com sucesso.",
        data: ticket,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/tickets/:id
   */
  async delete(req, res, next) {
    try {
      await ticketService.delete(req.params.id, req.userId, req.userRole, req.userDepartment);
      return res.status(200).json({
        success: true,
        message: "Chamado removido com sucesso.",
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new TicketController();
