const activityRepository = require("../repositories/activity.repository");
const categoryRepository = require("../repositories/category.repository");

class ActivityService {
  /**
   * Cria uma nova atividade.
   */
  async create(data) {
    // Verificar se a categoria existe
    const category = await categoryRepository.findById(data.categoryId);
    if (!category) {
      const error = new Error("Categoria não encontrada.");
      error.statusCode = 404;
      throw error;
    }

    return activityRepository.create(data);
  }

  /**
   * Busca uma atividade por ID.
   */
  async getById(id) {
    const activity = await activityRepository.findById(id);
    if (!activity) {
      const error = new Error("Atividade não encontrada.");
      error.statusCode = 404;
      throw error;
    }
    return activity;
  }

  /**
   * Lista atividades por categoria.
   */
  async getByCategoryId(categoryId, { activeOnly = false } = {}) {
    return activityRepository.findByCategoryId(categoryId, { activeOnly });
  }

  /**
   * Lista todas as atividades.
   */
  async getAll({ activeOnly = false } = {}) {
    return activityRepository.findAll({ activeOnly });
  }

  /**
   * Atualiza uma atividade.
   */
  async update(id, data) {
    await this.getById(id);

    // Verificar se a nova categoria existe, se estiver sendo alterada
    if (data.categoryId) {
      const category = await categoryRepository.findById(data.categoryId);
      if (!category) {
        const error = new Error("Categoria não encontrada.");
        error.statusCode = 404;
        throw error;
      }
    }

    return activityRepository.update(id, data);
  }

  /**
   * Remove uma atividade.
   */
  async delete(id) {
    await this.getById(id);
    return activityRepository.delete(id);
  }
}

module.exports = new ActivityService();
