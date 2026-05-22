const prisma = require("../config/database");

class CategoryRepository {
  /**
   * Cria uma nova categoria.
   */
  async create(data) {
    return prisma.category.create({
      data,
      include: {
        activities: true,
      },
    });
  }

  /**
   * Busca categoria por ID com atividades.
   */
  async findById(id) {
    return prisma.category.findUnique({
      where: { id },
      include: {
        activities: {
          where: { active: true },
          orderBy: { name: "asc" },
        },
      },
    });
  }

  /**
   * Busca categoria pelo nome.
   */
  async findByName(name) {
    return prisma.category.findUnique({
      where: { name },
    });
  }

  /**
   * Lista todas as categorias com suas atividades.
   */
  async findAll({ activeOnly = false } = {}) {
    const where = activeOnly ? { active: true } : {};

    return prisma.category.findMany({
      where,
      include: {
        activities: {
          where: activeOnly ? { active: true } : {},
          orderBy: { name: "asc" },
        },
        _count: {
          select: { tickets: true },
        },
      },
      orderBy: { name: "asc" },
    });
  }

  /**
   * Atualiza uma categoria.
   */
  async update(id, data) {
    return prisma.category.update({
      where: { id },
      data,
      include: {
        activities: {
          orderBy: { name: "asc" },
        },
      },
    });
  }

  /**
   * Remove uma categoria.
   */
  async delete(id) {
    return prisma.category.delete({
      where: { id },
    });
  }
}

module.exports = new CategoryRepository();
