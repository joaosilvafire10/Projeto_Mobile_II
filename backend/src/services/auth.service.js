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

    // Gerar tokens
    const tokens = this._generateTokens(user);

    // Salvar refresh token no banco
    await userRepository.update(user.id, {
      refreshToken: tokens.refreshToken,
    });

    return { user, tokens };
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

    // Gerar tokens
    const tokens = this._generateTokens(user);

    // Salvar refresh token no banco
    await userRepository.update(user.id, {
      refreshToken: tokens.refreshToken,
    });

    // Remover senha do retorno
    const { password: _, refreshToken: __, ...userWithoutPassword } = user;

    return { user: userWithoutPassword, tokens };
  }

  /**
   * Atualiza o token de acesso usando um refresh token.
   */
  async refresh(refreshToken) {
    try {
      // Verificar se o token é válido
      const payload = jwt.verify(refreshToken, config.jwt.refreshSecret);

      // Buscar usuário no banco
      const user = await userRepository.findByEmail(payload.email);
      if (!user || user.refreshToken !== refreshToken) {
        const error = new Error("Refresh token inválido ou expirado.");
        error.statusCode = 401;
        throw error;
      }

      // Gerar novos tokens
      const tokens = this._generateTokens(user);

      // Atualizar refresh token no banco
      await userRepository.update(user.id, {
        refreshToken: tokens.refreshToken,
      });

      return tokens;
    } catch (error) {
      if (!error.statusCode) {
        error.statusCode = 401;
        error.message = "Refresh token inválido ou expirado.";
      }
      throw error;
    }
  }

  /**
   * Invalida o refresh token de um usuário.
   */
  async logout(userId) {
    await userRepository.update(userId, {
      refreshToken: null,
    });
  }

  /**
   * Gera tokens de acesso e refresh.
   */
  _generateTokens(user) {
    const accessToken = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role,
        department: user.department,
      },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );

    const refreshToken = jwt.sign(
      { email: user.email },
      config.jwt.refreshSecret,
      { expiresIn: config.jwt.refreshExpiresIn }
    );

    return { accessToken, refreshToken };
  }
}

module.exports = new AuthService();
