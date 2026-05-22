const { Router } = require("express");
const activityController = require("../controllers/activity.controller");
const { authMiddleware, authorizeRoles } = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const { createActivitySchema, updateActivitySchema } = require("../validations/schemas");

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Atividades
 *   description: Gerenciamento de atividades dentro de categorias
 */

/**
 * @swagger
 * /api/activities:
 *   get:
 *     summary: Listar todas as atividades
 *     tags: [Atividades]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: activeOnly
 *         schema:
 *           type: boolean
 *           default: false
 *     responses:
 *       200:
 *         description: Lista de atividades
 */
router.get("/", authMiddleware, activityController.getAll);

/**
 * @swagger
 * /api/activities/category/{categoryId}:
 *   get:
 *     summary: Listar atividades por categoria
 *     tags: [Atividades]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: categoryId
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *       - in: query
 *         name: activeOnly
 *         schema:
 *           type: boolean
 *           default: false
 *     responses:
 *       200:
 *         description: Lista de atividades da categoria
 */
router.get("/category/:categoryId", authMiddleware, activityController.getByCategoryId);

/**
 * @swagger
 * /api/activities/{id}:
 *   get:
 *     summary: Buscar atividade por ID
 *     tags: [Atividades]
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
 *         description: Dados da atividade
 *       404:
 *         description: Atividade não encontrada
 */
router.get("/:id", authMiddleware, activityController.getById);

/**
 * @swagger
 * /api/activities:
 *   post:
 *     summary: Criar nova atividade (somente ADMIN)
 *     tags: [Atividades]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - categoryId
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Atualização de Windows"
 *               description:
 *                 type: string
 *                 example: "Problemas com atualizações do Windows"
 *               categoryId:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       201:
 *         description: Atividade criada com sucesso
 *       403:
 *         description: Acesso negado
 *       404:
 *         description: Categoria não encontrada
 */
router.post("/", authMiddleware, authorizeRoles("ADMIN"), validate(createActivitySchema), activityController.create);

/**
 * @swagger
 * /api/activities/{id}:
 *   put:
 *     summary: Atualizar atividade (somente ADMIN)
 *     tags: [Atividades]
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
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               active:
 *                 type: boolean
 *               categoryId:
 *                 type: string
 *                 format: uuid
 *     responses:
 *       200:
 *         description: Atividade atualizada
 *       403:
 *         description: Acesso negado
 *       404:
 *         description: Atividade não encontrada
 */
router.put("/:id", authMiddleware, authorizeRoles("ADMIN"), validate(updateActivitySchema), activityController.update);

/**
 * @swagger
 * /api/activities/{id}:
 *   delete:
 *     summary: Remover atividade (somente ADMIN)
 *     tags: [Atividades]
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
 *         description: Atividade removida
 *       403:
 *         description: Acesso negado
 *       404:
 *         description: Atividade não encontrada
 */
router.delete("/:id", authMiddleware, authorizeRoles("ADMIN"), activityController.delete);

module.exports = router;
