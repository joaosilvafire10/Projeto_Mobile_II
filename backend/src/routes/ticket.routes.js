const { Router } = require("express");
const ticketController = require("../controllers/ticket.controller");
const { authMiddleware } = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const { createTicketSchema, updateTicketSchema, ticketQuerySchema } = require("../validations/schemas");

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Chamados
 *   description: Gerenciamento de chamados de suporte
 */

/**
 * @swagger
 * /api/tickets:
 *   post:
 *     summary: Criar novo chamado
 *     tags: [Chamados]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - description
 *             properties:
 *               title:
 *                 type: string
 *                 example: "Problema com acesso ao sistema"
 *                 minLength: 5
 *               description:
 *                 type: string
 *                 example: "Não consigo fazer login no sistema de RH desde ontem."
 *                 minLength: 10
 *               priority:
 *                 type: string
 *                 enum: [BAIXA, MEDIA, ALTA, CRITICA]
 *                 default: MEDIA
 *               department:
 *                 type: string
 *                 enum: [TI, SUPORTE, INFRAESTRUTURA, DESENVOLVIMENTO, SEGURANCA, REDES, BANCO_DE_DADOS, GERAL]
 *                 default: GERAL
 *     responses:
 *       201:
 *         description: Chamado criado com sucesso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/Ticket'
 */
router.post("/", authMiddleware, validate(createTicketSchema), ticketController.create);

/**
 * @swagger
 * /api/tickets:
 *   get:
 *     summary: Listar chamados com filtros e paginação
 *     tags: [Chamados]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [ABERTO, EM_ANDAMENTO, AGUARDANDO_USUARIO, RESOLVIDO, FINALIZADO]
 *       - in: query
 *         name: priority
 *         schema:
 *           type: string
 *           enum: [BAIXA, MEDIA, ALTA, CRITICA]
 *       - in: query
 *         name: department
 *         schema:
 *           type: string
 *           enum: [TI, SUPORTE, INFRAESTRUTURA, DESENVOLVIMENTO, SEGURANCA, REDES, BANCO_DE_DADOS, GERAL]
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Buscar por título ou descrição
 *     responses:
 *       200:
 *         description: Lista de chamados
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
 *                     $ref: '#/components/schemas/Ticket'
 *                 pagination:
 *                   $ref: '#/components/schemas/Pagination'
 */
router.get("/", authMiddleware, validate(ticketQuerySchema, "query"), ticketController.getAll);

/**
 * @swagger
 * /api/tickets/stats:
 *   get:
 *     summary: Obter estatísticas dos chamados
 *     tags: [Chamados]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Estatísticas de chamados por status e prioridade
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     byStatus:
 *                       type: object
 *                     byPriority:
 *                       type: object
 *                     total:
 *                       type: integer
 */
router.get("/stats", authMiddleware, ticketController.getStats);

/**
 * @swagger
 * /api/tickets/{id}:
 *   get:
 *     summary: Buscar chamado por ID
 *     tags: [Chamados]
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
 *         description: Dados do chamado com mensagens
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Ticket'
 *       404:
 *         description: Chamado não encontrado
 */
router.get("/:id", authMiddleware, ticketController.getById);

/**
 * @swagger
 * /api/tickets/{id}:
 *   put:
 *     summary: Atualizar chamado
 *     tags: [Chamados]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
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
 *             properties:
 *               title:
 *                 type: string
 *               description:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [ABERTO, EM_ANDAMENTO, AGUARDANDO_USUARIO, RESOLVIDO, FINALIZADO]
 *               priority:
 *                 type: string
 *                 enum: [BAIXA, MEDIA, ALTA, CRITICA]
 *               department:
 *                 type: string
 *                 enum: [TI, SUPORTE, INFRAESTRUTURA, DESENVOLVIMENTO, SEGURANCA, REDES, BANCO_DE_DADOS, GERAL]
 *               aiSummary:
 *                 type: string
 *     responses:
 *       200:
 *         description: Chamado atualizado
 *       403:
 *         description: Sem permissão
 *       404:
 *         description: Chamado não encontrado
 */
router.put("/:id", authMiddleware, validate(updateTicketSchema), ticketController.update);

/**
 * @swagger
 * /api/tickets/{id}:
 *   delete:
 *     summary: Remover chamado
 *     tags: [Chamados]
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
 *         description: Chamado removido
 *       403:
 *         description: Sem permissão
 *       404:
 *         description: Chamado não encontrado
 */
router.delete("/:id", authMiddleware, ticketController.delete);

module.exports = router;
