const ticketRepository = require("../repositories/ticket.repository");

class TicketService {
  /**
   * Cria um novo chamado.
   */
  async create(data, userId) {
    return ticketRepository.create({
      ...data,
      userId,
    });
  }

  /**
   * Busca um chamado por ID.
   */
  async getById(id) {
    const ticket = await ticketRepository.findById(id);
    if (!ticket) {
      const error = new Error("Chamado não encontrado.");
      error.statusCode = 404;
      throw error;
    }
    return ticket;
  }

  /**
   * Lista chamados com filtros e paginação.
   * Usuários comuns veem apenas seus próprios chamados.
   */
  async getAll(filters, userId, userRole) {
    // Se for usuário comum, filtra apenas seus chamados
    if (userRole === "USUARIO") {
      filters.userId = userId;
    }
    return ticketRepository.findAll(filters);
  }

  /**
   * Atualiza um chamado.
   */
  async update(id, data, userId, userRole) {
    const ticket = await this.getById(id);

    // Verifica permissão: apenas dono, técnico ou admin podem atualizar
    if (userRole === "USUARIO" && ticket.userId !== userId) {
      const error = new Error("Sem permissão para atualizar este chamado.");
      error.statusCode = 403;
      throw error;
    }

    return ticketRepository.update(id, data);
  }

  /**
   * Remove um chamado.
   */
  async delete(id, userId, userRole) {
    const ticket = await this.getById(id);

    // Apenas admin ou dono podem deletar
    if (userRole !== "ADMIN" && ticket.userId !== userId) {
      const error = new Error("Sem permissão para remover este chamado.");
      error.statusCode = 403;
      throw error;
    }

    return ticketRepository.delete(id);
  }

  /**
   * Obtém estatísticas dos chamados.
   */
  async getStats() {
    const [byStatus, byPriority] = await Promise.all([
      ticketRepository.countByStatus(),
      ticketRepository.countByPriority(),
    ]);

    return {
      byStatus,
      byPriority,
      total:
        Object.values(byStatus).reduce((sum, count) => sum + count, 0),
    };
  }
}

module.exports = new TicketService();
