const { Router } = require("express");
const aiController = require("../controllers/ai.controller");
const { authMiddleware } = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const { aiTriageSchema } = require("../validations/schemas");

const router = Router();

/**
 * @swagger
 * tags:
 *   name: IA (Inteligência Artificial)
 *   description: Endpoints do assistente inteligente de triagem
 */

/**
 * @swagger
 * /api/ai/triage:
 *   post:
 *     summary: Enviar mensagem para triagem com IA
 *     description: >
 *       Envia uma mensagem do usuário para o assistente de IA.
 *       A IA pode:
 *       - Responder com dicas de resolução
 *       - Fazer perguntas complementares
 *       - Criar automaticamente um chamado quando necessário
 *     tags: [IA (Inteligência Artificial)]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - message
 *             properties:
 *               message:
 *                 type: string
 *                 example: "Meu computador está muito lento e reiniciando sozinho."
 *               conversationHistory:
 *                 type: array
 *                 description: Histórico da conversa atual com a IA
 *                 items:
 *                   type: object
 *                   properties:
 *                     role:
 *                       type: string
 *                       enum: [user, ai]
 *                     content:
 *                       type: string
 *                 default: []
 *               ticketId:
 *                 type: string
 *                 format: uuid
 *                 description: ID do chamado existente (se houver)
 *     responses:
 *       200:
 *         description: Resposta da IA
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     type:
 *                       type: string
 *                       enum: [response, ticket_created]
 *                       description: "'response' para respostas normais, 'ticket_created' quando um chamado foi gerado"
 *                     message:
 *                       type: string
 *                       description: Resposta da IA ou mensagem de confirmação do chamado
 *                     ticket:
 *                       $ref: '#/components/schemas/Ticket'
 *                       description: Dados do chamado (quando type é ticket_created)
 *       401:
 *         description: Não autenticado
 */
router.post("/triage", authMiddleware, validate(aiTriageSchema), aiController.triage);

module.exports = router;
