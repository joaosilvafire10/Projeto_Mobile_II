const { z } = require("zod");

// =============================================
// SCHEMAS DE AUTENTICAÇÃO
// =============================================

const registerSchema = z.object({
  name: z
    .string({ required_error: "Nome é obrigatório." })
    .min(3, "Nome deve ter pelo menos 3 caracteres.")
    .max(100, "Nome deve ter no máximo 100 caracteres."),
  email: z
    .string({ required_error: "Email é obrigatório." })
    .email("Email inválido."),
  password: z
    .string({ required_error: "Senha é obrigatória." })
    .min(6, "Senha deve ter pelo menos 6 caracteres.")
    .max(100, "Senha deve ter no máximo 100 caracteres."),
  role: z
    .enum(["ADMIN", "ANALISTA", "USUARIO"], {
      errorMap: () => ({ message: "Role deve ser ADMIN, ANALISTA ou USUARIO." }),
    })
    .optional()
    .default("USUARIO"),
  department: z
    .enum(
      ["TI", "FINANCEIRO", "CONTABILIDADE"],
      { errorMap: () => ({ message: "Departamento inválido. Escolha entre TI, FINANCEIRO ou CONTABILIDADE." }) }
    )
    .optional()
    .default("TI"),
});

const loginSchema = z.object({
  email: z
    .string({ required_error: "Email é obrigatório." })
    .email("Email inválido."),
  password: z
    .string({ required_error: "Senha é obrigatória." })
    .min(1, "Senha é obrigatória."),
});

// =============================================
// SCHEMAS DE USUÁRIO
// =============================================

const updateUserSchema = z.object({
  name: z.string().min(3).max(100).optional(),
  email: z.string().email("Email inválido.").optional(),
  role: z
    .enum(["ADMIN", "ANALISTA", "USUARIO"])
    .optional(),
  department: z
    .enum(["TI", "FINANCEIRO", "CONTABILIDADE"])
    .optional(),
  avatarUrl: z.string().url("URL inválida.").nullable().optional(),
  active: z.boolean().optional(),
});

// =============================================
// SCHEMAS DE CHAMADO (TICKET)
// =============================================

const createTicketSchema = z.object({
  title: z
    .string({ required_error: "Título é obrigatório." })
    .min(5, "Título deve ter pelo menos 5 caracteres.")
    .max(200, "Título deve ter no máximo 200 caracteres."),
  description: z
    .string({ required_error: "Descrição é obrigatória." })
    .min(10, "Descrição deve ter pelo menos 10 caracteres.")
    .max(5000, "Descrição deve ter no máximo 5000 caracteres."),
  priority: z
    .enum(["BAIXA", "MEDIA", "ALTA", "CRITICA"], {
      errorMap: () => ({ message: "Prioridade deve ser BAIXA, MEDIA, ALTA ou CRITICA." }),
    })
    .optional()
    .default("MEDIA"),
  department: z
    .enum(
      ["TI", "FINANCEIRO", "CONTABILIDADE"],
      { errorMap: () => ({ message: "Departamento inválido. Escolha entre TI, FINANCEIRO ou CONTABILIDADE." }) }
    )
    .optional()
    .default("TI"),
});

const updateTicketSchema = z.object({
  title: z.string().min(5).max(200).optional(),
  description: z.string().min(10).max(5000).optional(),
  status: z
    .enum(["ABERTO", "EM_ANDAMENTO", "AGUARDANDO_USUARIO", "RESOLVIDO", "FINALIZADO"])
    .optional(),
  priority: z
    .enum(["BAIXA", "MEDIA", "ALTA", "CRITICA"])
    .optional(),
  department: z
    .enum(["TI", "FINANCEIRO", "CONTABILIDADE"])
    .optional(),
  aiSummary: z.string().max(5000).nullable().optional(),
  assignedToId: z.string().uuid("ID do analista deve ser um UUID válido.").nullable().optional(),
});

const assignTicketSchema = z.object({
  assignedToId: z.string({ required_error: "ID do analista é obrigatório." }).uuid("ID do analista inválido."),
});

const ticketQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(10),
  status: z
    .enum(["ABERTO", "EM_ANDAMENTO", "AGUARDANDO_USUARIO", "RESOLVIDO", "FINALIZADO"])
    .optional(),
  priority: z
    .enum(["BAIXA", "MEDIA", "ALTA", "CRITICA"])
    .optional(),
  department: z
    .enum(["TI", "FINANCEIRO", "CONTABILIDADE"])
    .optional(),
  search: z.string().optional(),
});

// =============================================
// SCHEMAS DE MENSAGEM
// =============================================

const createMessageSchema = z.object({
  content: z
    .string({ required_error: "Conteúdo é obrigatório." })
    .min(1, "Conteúdo não pode ser vazio.")
    .max(5000, "Conteúdo deve ter no máximo 5000 caracteres."),
  sender: z
    .enum(["user", "ai", "system"], {
      errorMap: () => ({ message: "Sender deve ser user, ai ou system." }),
    })
    .optional()
    .default("user"),
});

// =============================================
// SCHEMAS DA IA
// =============================================

const aiTriageSchema = z.object({
  message: z
    .string({ required_error: "Mensagem é obrigatória." })
    .min(1, "Mensagem não pode ser vazia.")
    .max(5000, "Mensagem deve ter no máximo 5000 caracteres."),
  conversationHistory: z
    .array(
      z.object({
        role: z.enum(["user", "ai"]),
        content: z.string(),
      })
    )
    .optional()
    .default([]),
  ticketId: z.string().uuid().optional(),
  categoryName: z.string().optional(),
  activityName: z.string().optional(),
});

// =============================================
// SCHEMAS DE CATEGORIA
// =============================================

const createCategorySchema = z.object({
  name: z
    .string({ required_error: "Nome é obrigatório." })
    .min(2, "Nome deve ter pelo menos 2 caracteres.")
    .max(100, "Nome deve ter no máximo 100 caracteres."),
  description: z
    .string()
    .max(500, "Descrição deve ter no máximo 500 caracteres.")
    .optional(),
});

const updateCategorySchema = z.object({
  name: z.string().min(2).max(100).optional(),
  description: z.string().max(500).nullable().optional(),
  active: z.boolean().optional(),
});

// =============================================
// SCHEMAS DE ATIVIDADE
// =============================================

const createActivitySchema = z.object({
  name: z
    .string({ required_error: "Nome é obrigatório." })
    .min(2, "Nome deve ter pelo menos 2 caracteres.")
    .max(200, "Nome deve ter no máximo 200 caracteres."),
  description: z
    .string()
    .max(500, "Descrição deve ter no máximo 500 caracteres.")
    .optional(),
  categoryId: z
    .string({ required_error: "ID da categoria é obrigatório." })
    .uuid("ID da categoria inválido."),
});

const updateActivitySchema = z.object({
  name: z.string().min(2).max(200).optional(),
  description: z.string().max(500).nullable().optional(),
  active: z.boolean().optional(),
  categoryId: z.string().uuid("ID da categoria inválido.").optional(),
});

module.exports = {
  registerSchema,
  loginSchema,
  updateUserSchema,
  createTicketSchema,
  updateTicketSchema,
  assignTicketSchema,
  ticketQuerySchema,
  createMessageSchema,
  aiTriageSchema,
  createCategorySchema,
  updateCategorySchema,
  createActivitySchema,
  updateActivitySchema,
};
