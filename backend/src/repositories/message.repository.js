const prisma = require("../config/database");

class MessageRepository {
  /**
   * Cria uma nova mensagem.
   */
  async create(data) {
    return prisma.message.create({
      data,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  /**
   * Busca mensagem por ID.
   */
  async findById(id) {
    return prisma.message.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  /**
   * Lista mensagens de um chamado com paginação.
   */
  async findByTicketId(ticketId, { page = 1, limit = 50 }) {
    const skip = (page - 1) * limit;

    const [messages, total] = await Promise.all([
      prisma.message.findMany({
        where: { ticketId },
        skip,
        take: limit,
        orderBy: { createdAt: "asc" },
        include: {
          user: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      prisma.message.count({ where: { ticketId } }),
    ]);

    return {
      data: messages,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Remove uma mensagem.
   */
  async delete(id) {
    return prisma.message.delete({
      where: { id },
    });
  }
}

module.exports = new MessageRepository();
