const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const config = require("../config/env");
const userRepository = require("../repositories/user.repository");

class AuthService {
  /**
   * Registra um novo usuário.
   */
  async register({ name, email, password, role, department }) {
    // Verificar se email já existe
    const existingUser = await userRepository.findByEmail(email);
    if (existingUser) {
      const error = new Error("Email já cadastrado.");
      error.statusCode = 409;
      throw error;
    }

    // Hash da senha
    const hashedPassword = await bcrypt.hash(password, config.bcrypt.saltRounds);

    // Criar usuário
    const user = await userRepository.create({
      name,
      email,
      password: hashedPassword,
      role,
      department,
    });

    // Gerar token
    const token = this._generateToken(user);

    return { user, token };
  }

  /**
   * Autentica um usuário.
   */
  async login({ email, password }) {
    // Buscar usuário com senha
    const user = await userRepository.findByEmail(email);
    if (!user) {
      const error = new Error("Credenciais inválidas.");
      error.statusCode = 401;
      throw error;
    }

    if (!user.active) {
      const error = new Error("Usuário desativado. Contate o administrador.");
      error.statusCode = 403;
      throw error;
    }

    // Verificar senha
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      const error = new Error("Credenciais inválidas.");
      error.statusCode = 401;
      throw error;
    }

    // Gerar token
    const token = this._generateToken(user);

    // Remover senha do retorno
    const { password: _, ...userWithoutPassword } = user;

    return { user: userWithoutPassword, token };
  }

  /**
   * Gera um token JWT.
   */
  _generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
      },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );
  }
}

module.exports = new AuthService();
