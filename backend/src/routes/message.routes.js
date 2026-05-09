const { Router } = require("express");
const messageController = require("../controllers/message.controller");
const { authMiddleware, authorizeRoles } = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const { createMessageSchema } = require("../validations/schemas");

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Mensagens
 *   description: Gerenciamento de mensagens dos chamados
 */

/**
 * @swagger
 * /api/tickets/{ticketId}/messages:
 *   post:
 *     summary: Enviar mensagem em um chamado
 *     tags: [Mensagens]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ticketId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - content
 *             properties:
 *               content:
 *                 type: string
 *                 example: "O problema persiste mesmo após reiniciar."
 *               sender:
 *                 type: string
 *                 enum: [user, ai, system]
 *                 default: user
 *     responses:
 *       201:
 *         description: Mensagem enviada com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Message'
 *       404:
 *         description: Chamado não encontrado
 */
router.post("/:ticketId/messages", authMiddleware, validate(createMessageSchema), messageController.create);

/**
 * @swagger
 * /api/tickets/{ticketId}/messages:
 *   get:
 *     summary: Listar mensagens de um chamado
 *     tags: [Mensagens]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: ticketId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *     responses:
 *       200:
 *         description: Lista de mensagens do chamado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Message'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 */
router.get("/:ticketId/messages", authMiddleware, messageController.getByTicketId);

/**
 * @swagger
 * /api/messages/{id}:
 *   delete:
 *     summary: Remover mensagem
 *     tags: [Mensagens]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *     responses:
 *       200:
 *         description: Mensagem removida
 *       404:
 *         description: Mensagem não encontrada
 */
router.delete("/messages/:id", authMiddleware, authorizeRoles("ADMIN"), messageController.delete);

module.exports = router;
