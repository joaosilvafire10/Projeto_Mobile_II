const messageRepository = require("../repositories/message.repository");
const ticketRepository = require("../repositories/ticket.repository");

class MessageService {
  /**
   * Cria uma nova mensagem em um chamado.
   */
  async create({ content, sender, ticketId, userId }) {
    // Verificar se o chamado existe
    const ticket = await ticketRepository.findById(ticketId);
    if (!ticket) {
      const error = new Error("Chamado não encontrado.");
      error.statusCode = 404;
      throw error;
    }

    return messageRepository.create({
      content,
      sender,
      ticketId,
      userId: sender === "user" ? userId : null,
    });
  }

  /**
   * Lista mensagens de um chamado.
   */
  async getByTicketId(ticketId, { page, limit }) {
    // Verificar se o chamado existe
    const ticket = await ticketRepository.findById(ticketId);
    if (!ticket) {
      const error = new Error("Chamado não encontrado.");
      error.statusCode = 404;
      throw error;
    }

    return messageRepository.findByTicketId(ticketId, { page, limit });
  }

  /**
   * Remove uma mensagem.
   */
  async delete(id) {
    const message = await messageRepository.findById(id);
    if (!message) {
      const error = new Error("Mensagem não encontrada.");
      error.statusCode = 404;
      throw error;
    }
    return messageRepository.delete(id);
  }
}

module.exports = new MessageService();
