const prisma = require("../config/database");

class TicketRepository {
  /**
   * Cria um novo chamado.
   */
  async create(data) {
    return prisma.ticket.create({
      data,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            department: true,
          },
        },
        messages: true,
      },
    });
  }

  /**
   * Busca chamado por ID com relacionamentos.
   */
  async findById(id) {
    return prisma.ticket.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            department: true,
          },
        },
        messages: {
          orderBy: { createdAt: "asc" },
          include: {
            user: {
              select: {
                id: true,
                name: true,
              },
            },
          },
        },
      },
    });
  }

  /**
   * Lista chamados com filtros e paginação.
   */
  async findAll({ page = 1, limit = 10, status, priority, department, search, userId }) {
    const skip = (page - 1) * limit;

    const where = {};

    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (department) where.department = department;
    if (userId) where.userId = userId;
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
      ];
    }

    const [tickets, total] = await Promise.all([
      prisma.ticket.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: "desc" },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
              department: true,
            },
          },
          _count: {
            select: { messages: true },
          },
        },
      }),
      prisma.ticket.count({ where }),
    ]);

    return {
      data: tickets,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Atualiza um chamado.
   */
  async update(id, data) {
    return prisma.ticket.update({
      where: { id },
      data,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            department: true,
          },
        },
        messages: {
          orderBy: { createdAt: "asc" },
        },
      },
    });
  }

  /**
   * Remove um chamado.
   */
  async delete(id) {
    return prisma.ticket.delete({
      where: { id },
    });
  }

  /**
   * Conta chamados por status (para estatísticas).
   */
  async countByStatus() {
    const counts = await prisma.ticket.groupBy({
      by: ["status"],
      _count: { status: true },
    });

    return counts.reduce((acc, item) => {
      acc[item.status] = item._count.status;
      return acc;
    }, {});
  }

  /**
   * Conta chamados por prioridade.
   */
  async countByPriority() {
    const counts = await prisma.ticket.groupBy({
      by: ["priority"],
      _count: { priority: true },
    });

    return counts.reduce((acc, item) => {
      acc[item.priority] = item._count.priority;
      return acc;
    }, {});
  }
}

module.exports = new TicketRepository();
