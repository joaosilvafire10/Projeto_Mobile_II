const categoryRepository = require("../repositories/category.repository");

class CategoryService {
  /**
   * Cria uma nova categoria.
   */
  async create(data) {
    // Verificar se já existe categoria com o mesmo nome
    const existing = await categoryRepository.findByName(data.name);
    if (existing) {
      const error = new Error("Já existe uma categoria com esse nome.");
      error.statusCode = 409;
      throw error;
    }
    return categoryRepository.create(data);
  }

  /**
   * Busca uma categoria por ID.
   */
  async getById(id) {
    const category = await categoryRepository.findById(id);
    if (!category) {
      const error = new Error("Categoria não encontrada.");
      error.statusCode = 404;
      throw error;
    }
    return category;
  }

  /**
   * Lista todas as categorias.
   */
  async getAll({ activeOnly = false } = {}) {
    return categoryRepository.findAll({ activeOnly });
  }

  /**
   * Atualiza uma categoria.
   */
  async update(id, data) {
    await this.getById(id);

    // Verificar nome duplicado se estiver sendo alterado
    if (data.name) {
      const existing = await categoryRepository.findByName(data.name);
      if (existing && existing.id !== id) {
        const error = new Error("Já existe uma categoria com esse nome.");
        error.statusCode = 409;
        throw error;
      }
    }

    return categoryRepository.update(id, data);
  }

  /**
   * Remove uma categoria.
   */
  async delete(id) {
    await this.getById(id);
    return categoryRepository.delete(id);
  }
}

module.exports = new CategoryService();
