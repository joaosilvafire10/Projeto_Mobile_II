const { Router } = require("express");
const categoryController = require("../controllers/category.controller");
const { authMiddleware, authorizeRoles } = require("../middlewares/auth.middleware");
const validate = require("../middlewares/validate.middleware");
const { createCategorySchema, updateCategorySchema } = require("../validations/schemas");

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Categorias
 *   description: Gerenciamento de categorias de chamados
 */

/**
 * @swagger
 * /api/categories:
 *   get:
 *     summary: Listar todas as categorias com suas atividades
 *     tags: [Categorias]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: activeOnly
 *         schema:
 *           type: boolean
 *           default: false
 *         description: Se true, retorna apenas categorias e atividades ativas
 *     responses:
 *       200:
 *         description: Lista de categorias
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
 *                     $ref: '#/components/schemas/Category'
 */
router.get("/", authMiddleware, categoryController.getAll);

/**
 * @swagger
 * /api/categories/{id}:
 *   get:
 *     summary: Buscar categoria por ID
 *     tags: [Categorias]
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
 *         description: Dados da categoria com atividades
 *       404:
 *         description: Categoria não encontrada
 */
router.get("/:id", authMiddleware, categoryController.getById);

/**
 * @swagger
 * /api/categories:
 *   post:
 *     summary: Criar nova categoria (somente ADMIN)
 *     tags: [Categorias]
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
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Recursos Humanos"
 *               description:
 *                 type: string
 *                 example: "Assuntos relacionados a RH"
 *     responses:
 *       201:
 *         description: Categoria criada com sucesso
 *       403:
 *         description: Acesso negado
 *       409:
 *         description: Categoria já existe
 */
router.post("/", authMiddleware, authorizeRoles("ADMIN"), validate(createCategorySchema), categoryController.create);

/**
 * @swagger
 * /api/categories/{id}:
 *   put:
 *     summary: Atualizar categoria (somente ADMIN)
 *     tags: [Categorias]
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
 *     responses:
 *       200:
 *         description: Categoria atualizada
 *       403:
 *         description: Acesso negado
 *       404:
 *         description: Categoria não encontrada
 */
router.put("/:id", authMiddleware, authorizeRoles("ADMIN"), validate(updateCategorySchema), categoryController.update);

/**
 * @swagger
 * /api/categories/{id}:
 *   delete:
 *     summary: Remover categoria (somente ADMIN)
 *     tags: [Categorias]
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
 *         description: Categoria removida
 *       403:
 *         description: Acesso negado
 *       404:
 *         description: Categoria não encontrada
 */
router.delete("/:id", authMiddleware, authorizeRoles("ADMIN"), categoryController.delete);

module.exports = router;
