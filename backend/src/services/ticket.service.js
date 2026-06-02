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
  async getById(id, userId, userRole, userDepartment) {
    const ticket = await ticketRepository.findById(id);
    if (!ticket) {
      const error = new Error("Chamado não encontrado.");
      error.statusCode = 404;
      throw error;
    }

    // Se as informações de papel forem fornecidas, aplica regras de visibilidade
    if (userRole) {
      if (userRole === "USUARIO" && ticket.userId !== userId) {
        const error = new Error("Sem permissão para visualizar este chamado.");
        error.statusCode = 403;
        throw error;
      }
      if (userRole === "ANALISTA" && ticket.department !== userDepartment) {
        const error = new Error("Sem permissão para visualizar chamados de outro departamento.");
        error.statusCode = 403;
        throw error;
      }
    }

    return ticket;
  }

  /**
   * Lista chamados com filtros e paginação.
   * ADMIN vê todos, ANALISTA vê do seu departamento, USUARIO vê apenas os seus.
   */
  async getAll(filters, userId, userRole, userDepartment) {
    if (userRole === "USUARIO") {
      filters.userId = userId;
    } else if (userRole === "ANALISTA") {
      filters.department = userDepartment;
    }
    return ticketRepository.findAll(filters);
  }

  /**
   * Atualiza um chamado.
   */
  async update(id, data, userId, userRole, userDepartment) {
    const ticket = await this.getById(id, userId, userRole, userDepartment);

    // Verifica permissão para atualizar:
    // USUARIO só atualiza os próprios chamados
    // ANALISTA só atualiza chamados do próprio departamento
    if (userRole === "USUARIO" && ticket.userId !== userId) {
      const error = new Error("Sem permissão para atualizar este chamado.");
      error.statusCode = 403;
      throw error;
    }

    if (userRole === "ANALISTA" && ticket.department !== userDepartment) {
      const error = new Error("Sem permissão para atualizar chamados de outro departamento.");
      error.statusCode = 403;
      throw error;
    }

    return ticketRepository.update(id, data);
  }

  /**
   * Atribui o chamado ao analista logado.
   */
  async assignToMe(id, userId, userRole, userDepartment) {
    const ticket = await this.getById(id, userId, userRole, userDepartment);

    // Apenas ADMIN ou ANALISTA podem se auto-atribuir chamados
    if (userRole !== "ADMIN" && userRole !== "ANALISTA") {
      const error = new Error("Apenas analistas e administradores podem atender chamados.");
      error.statusCode = 403;
      throw error;
    }

    // Se for analista, o chamado deve ser do seu departamento
    if (userRole === "ANALISTA" && ticket.department !== userDepartment) {
      const error = new Error("Você só pode atender chamados do seu próprio departamento.");
      error.statusCode = 403;
      throw error;
    }

    return ticketRepository.assignTo(id, userId);
  }

  /**
   * Remove um chamado.
   */
  async delete(id, userId, userRole, userDepartment) {
    const ticket = await this.getById(id, userId, userRole, userDepartment);

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
