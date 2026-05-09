const userRepository = require("../repositories/user.repository");
const bcrypt = require("bcryptjs");
const config = require("../config/env");

class UserService {
  /**
   * Lista todos os usuários com paginação.
   */
  async getAll({ page, limit }) {
    return userRepository.findAll({ page, limit });
  }

  /**
   * Busca um usuário por ID.
   */
  async getById(id) {
    const user = await userRepository.findById(id);
    if (!user) {
      const error = new Error("Usuário não encontrado.");
      error.statusCode = 404;
      throw error;
    }
    return user;
  }

  /**
   * Atualiza um usuário.
   */
  async update(id, data) {
    // Verificar se o usuário existe
    await this.getById(id);

    // Se estiver atualizando email, verificar duplicidade
    if (data.email) {
      const existing = await userRepository.findByEmail(data.email);
      if (existing && existing.id !== id) {
        const error = new Error("Email já está em uso por outro usuário.");
        error.statusCode = 409;
        throw error;
      }
    }

    // Se estiver atualizando senha, fazer hash
    if (data.password) {
      data.password = await bcrypt.hash(data.password, config.bcrypt.saltRounds);
    }

    return userRepository.update(id, data);
  }

  /**
   * Remove um usuário.
   */
  async delete(id) {
    await this.getById(id);
    return userRepository.delete(id);
  }
}

module.exports = new UserService();
