const prisma = require("../config/database");

class ActivityRepository {
  /**
   * Cria uma nova atividade.
   */
  async create(data) {
    return prisma.activity.create({
      data,
      include: {
        category: true,
      },
    });
  }

  /**
   * Busca atividade por ID.
   */
  async findById(id) {
    return prisma.activity.findUnique({
      where: { id },
      include: {
        category: true,
      },
    });
  }

  /**
   * Busca atividades por categoria.
   */
  async findByCategoryId(categoryId, { activeOnly = false } = {}) {
    const where = { categoryId };
    if (activeOnly) where.active = true;

    return prisma.activity.findMany({
      where,
      include: {
        category: true,
      },
      orderBy: { name: "asc" },
    });
  }

  /**
   * Lista todas as atividades.
   */
  async findAll({ activeOnly = false } = {}) {
    const where = activeOnly ? { active: true } : {};

    return prisma.activity.findMany({
      where,
      include: {
        category: true,
        _count: {
          select: { tickets: true },
        },
      },
      orderBy: { name: "asc" },
    });
  }

  /**
   * Atualiza uma atividade.
   */
  async update(id, data) {
    return prisma.activity.update({
      where: { id },
      data,
      include: {
        category: true,
      },
    });
  }

  /**
   * Remove uma atividade.
   */
  async delete(id) {
    return prisma.activity.delete({
      where: { id },
    });
  }
}

module.exports = new ActivityRepository();
