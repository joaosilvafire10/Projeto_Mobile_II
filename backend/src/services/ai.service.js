const { GoogleGenerativeAI } = require("@google/generative-ai");
const config = require("../config/env");
const ticketRepository = require("../repositories/ticket.repository");
const messageRepository = require("../repositories/message.repository");

class AIService {
  constructor() {
    this.model = null;
    this._initializeModel();
  }

  /**
   * Inicializa o modelo Gemini.
   */
  _initializeModel() {
    if (!config.gemini.apiKey) {
      console.warn("⚠️  GEMINI_API_KEY não configurada. IA funcionará em modo simulado.");
      return;
    }

    try {
      const genAI = new GoogleGenerativeAI(config.gemini.apiKey);
      this.model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
    } catch (error) {
      console.error("❌ Erro ao inicializar Gemini:", error.message);
    }
  }

  /**
   * Prompt do sistema para o assistente de triagem.
   */
  _getSystemPrompt() {
    return `Você é um assistente inteligente de triagem de chamados de suporte técnico de TI.

Seu papel é:
1. CONVERSAR com o usuário de forma educada e profissional em português brasileiro.
2. TENTAR RESOLVER problemas simples diretamente (reset de senha, problemas de conexão, configurações básicas).
3. FAZER PERGUNTAS complementares para entender melhor o problema.
4. COLETAR INFORMAÇÕES técnicas relevantes (sistema operacional, navegador, mensagens de erro, quando começou, etc.).
5. IDENTIFICAR o departamento responsável com base no problema descrito.
6. Quando o problema não puder ser resolvido por você, GERAR um chamado estruturado.

Departamentos disponíveis:
- TI: Problemas gerais de tecnologia, hardware, software
- SUPORTE: Atendimento ao usuário, dúvidas operacionais
- INFRAESTRUTURA: Servidores, data centers, equipamentos de rede física
- DESENVOLVIMENTO: Bugs em sistemas, novas funcionalidades, integrações
- SEGURANCA: Incidentes de segurança, acessos, permissões, vírus
- REDES: Problemas de conectividade, VPN, firewall, DNS
- BANCO_DE_DADOS: Performance de banco, backups, consultas lentas

Prioridades:
- BAIXA: Questões cosméticas, melhorias, sem impacto operacional
- MEDIA: Problema que afeta trabalho mas tem contorno
- ALTA: Problema crítico afetando produtividade sem contorno
- CRITICA: Sistema fora do ar, segurança comprometida, perda de dados

REGRAS IMPORTANTES:
- Sempre responda em português brasileiro.
- Seja conciso mas completo.
- Se conseguir resolver, informe a solução passo a passo.
- Se NÃO conseguir resolver após coletar informações suficientes, responda EXATAMENTE neste formato JSON (e NADA mais):

{"criar_chamado": true, "titulo": "Título descritivo do problema", "descricao": "Descrição técnica detalhada", "prioridade": "MEDIA", "departamento": "TI", "resumo_ia": "Resumo técnico da triagem realizada pela IA, incluindo informações coletadas e tentativas de resolução."}

IMPORTANTE: Só responda no formato JSON quando tiver informações suficientes para criar um chamado bem estruturado. Antes disso, faça perguntas e tente resolver.`;
  }

  /**
   * Processa mensagem do usuário via Gemini ou modo simulado.
   */
  async processMessage({ message, conversationHistory, userId, ticketId }) {
    try {
      let aiResponse;

      if (this.model) {
        aiResponse = await this._processWithGemini(message, conversationHistory);
      } else {
        aiResponse = this._processSimulated(message, conversationHistory);
      }

      // Verificar se a IA quer criar um chamado
      const ticketData = this._parseTicketCreation(aiResponse);

      if (ticketData) {
        // Criar o chamado automaticamente
        const ticket = await ticketRepository.create({
          title: ticketData.titulo,
          description: ticketData.descricao,
          priority: ticketData.prioridade,
          department: ticketData.departamento,
          aiSummary: ticketData.resumo_ia,
          userId,
        });

        // Salvar histórico de mensagens no chamado
        for (const msg of conversationHistory) {
          await messageRepository.create({
            content: msg.content,
            sender: msg.role === "user" ? "user" : "ai",
            ticketId: ticket.id,
            userId: msg.role === "user" ? userId : null,
          });
        }

        // Salvar a mensagem atual do usuário
        await messageRepository.create({
          content: message,
          sender: "user",
          ticketId: ticket.id,
          userId,
        });

        // Salvar mensagem do sistema sobre criação do chamado
        const systemMessage = `✅ Chamado #${ticket.id.slice(0, 8)} criado automaticamente.\n\n` +
          `📋 **${ticket.title}**\n` +
          `🏷️ Prioridade: ${ticket.priority}\n` +
          `🏢 Departamento: ${ticket.department}\n\n` +
          `📝 ${ticketData.resumo_ia}`;

        await messageRepository.create({
          content: systemMessage,
          sender: "system",
          ticketId: ticket.id,
        });

        return {
          type: "ticket_created",
          message: systemMessage,
          ticket,
        };
      }

      // Se existir um ticketId, salvar as mensagens no chamado
      if (ticketId) {
        await messageRepository.create({
          content: message,
          sender: "user",
          ticketId,
          userId,
        });
        await messageRepository.create({
          content: aiResponse,
          sender: "ai",
          ticketId,
        });
      }

      return {
        type: "response",
        message: aiResponse,
      };
    } catch (error) {
      console.error("❌ Erro no serviço de IA:", error);
      throw error;
    }
  }

  /**
   * Processa mensagem usando Google Gemini.
   */
  async _processWithGemini(message, conversationHistory) {
    const systemPrompt = this._getSystemPrompt();

    // Montar histórico para o Gemini
    const contents = [];

    // Adicionar contexto do sistema como primeira mensagem do usuário
    contents.push({
      role: "user",
      parts: [{ text: systemPrompt }],
    });
    contents.push({
      role: "model",
      parts: [{ text: "Entendido. Estou pronto para ajudar com suporte técnico. Como posso ajudá-lo?" }],
    });

    // Adicionar histórico da conversa
    for (const msg of conversationHistory) {
      contents.push({
        role: msg.role === "user" ? "user" : "model",
        parts: [{ text: msg.content }],
      });
    }

    // Adicionar mensagem atual
    contents.push({
      role: "user",
      parts: [{ text: message }],
    });

    const result = await this.model.generateContent({ contents });
    const response = result.response;
    return response.text();
  }

  /**
   * Modo simulado (quando a API Gemini não está configurada).
   */
  _processSimulated(message, conversationHistory) {
    const msgLower = message.toLowerCase();
    const msgCount = conversationHistory.length;

    // Primeira mensagem - saudação e início da triagem
    if (msgCount === 0) {
      return (
        "Olá! 👋 Sou o assistente virtual de suporte técnico.\n\n" +
        "Estou aqui para ajudá-lo a resolver seu problema ou encaminhá-lo para a equipe correta.\n\n" +
        "Por favor, descreva o problema que você está enfrentando com o máximo de detalhes possível."
      );
    }

    // Problemas de senha
    if (msgLower.includes("senha") || msgLower.includes("password") || msgLower.includes("login")) {
      if (msgCount <= 2) {
        return (
          "Entendi que você está com um problema relacionado a senha/login. 🔑\n\n" +
          "Posso tentar ajudá-lo diretamente. Poderia me informar:\n" +
          "1. Qual sistema você está tentando acessar?\n" +
          "2. Há quanto tempo está com esse problema?\n" +
          "3. Você recebe alguma mensagem de erro específica?"
        );
      }
      return (
        "Aqui estão algumas soluções que podem resolver seu problema:\n\n" +
        "1. **Limpe o cache do navegador** (Ctrl+Shift+Delete)\n" +
        "2. **Tente o link de recuperação de senha** na tela de login\n" +
        "3. **Verifique o Caps Lock** - senhas são case-sensitive\n" +
        "4. **Tente em uma janela anônima** para descartar problemas de extensão\n\n" +
        "Alguma dessas soluções funcionou?"
      );
    }

    // Problemas de rede/internet
    if (msgLower.includes("internet") || msgLower.includes("rede") || msgLower.includes("conexão") || msgLower.includes("vpn")) {
      if (msgCount <= 2) {
        return (
          "Entendi que você está com problemas de conectividade. 🌐\n\n" +
          "Algumas perguntas para entender melhor:\n" +
          "1. O problema é com Wi-Fi ou cabo?\n" +
          "2. Outros dispositivos na rede funcionam normalmente?\n" +
          "3. Quando o problema começou?\n" +
          "4. Você está usando VPN?"
        );
      }
    }

    // Problemas de software/sistema
    if (msgLower.includes("erro") || msgLower.includes("bug") || msgLower.includes("sistema") || msgLower.includes("aplicação")) {
      if (msgCount <= 2) {
        return (
          "Entendi que há um problema com um sistema ou aplicação. 💻\n\n" +
          "Para investigar melhor, preciso saber:\n" +
          "1. Qual sistema/aplicação está apresentando o erro?\n" +
          "2. Qual a mensagem de erro exata?\n" +
          "3. Em qual navegador/sistema operacional você está?\n" +
          "4. O problema é intermitente ou constante?"
        );
      }
    }

    // Após algumas trocas, criar chamado (simulado)
    if (msgCount >= 4) {
      const departamento = this._detectDepartment(message, conversationHistory);
      const prioridade = this._detectPriority(message, conversationHistory);

      return JSON.stringify({
        criar_chamado: true,
        titulo: `Problema reportado: ${message.substring(0, 80)}`,
        descricao: `Usuário reportou um problema que não pôde ser resolvido pelo atendimento automatizado. Histórico de ${msgCount + 1} mensagens trocadas durante a triagem.`,
        prioridade,
        departamento,
        resumo_ia: `Triagem automática realizada com ${msgCount + 1} interações. O problema não pôde ser resolvido de forma remota pelo assistente virtual. Recomendado atendimento humano pelo departamento de ${departamento}.`,
      });
    }

    // Resposta genérica para coletar mais informações
    return (
      "Obrigado pelas informações! 📝\n\n" +
      "Para que eu possa ajudá-lo da melhor forma, poderia fornecer mais detalhes?\n" +
      "- Qual é o impacto desse problema no seu trabalho?\n" +
      "- Há algum prazo ou urgência?\n" +
      "- Mais algum detalhe técnico que possa ajudar na resolução?"
    );
  }

  /**
   * Detecta o departamento com base nas palavras-chave.
   */
  _detectDepartment(message, history) {
    const allText = [message, ...history.map((m) => m.content)].join(" ").toLowerCase();

    if (allText.includes("segurança") || allText.includes("vírus") || allText.includes("permissão") || allText.includes("acesso negado")) {
      return "SEGURANCA";
    }
    if (allText.includes("rede") || allText.includes("vpn") || allText.includes("firewall") || allText.includes("dns")) {
      return "REDES";
    }
    if (allText.includes("banco") || allText.includes("sql") || allText.includes("backup") || allText.includes("dados")) {
      return "BANCO_DE_DADOS";
    }
    if (allText.includes("servidor") || allText.includes("data center") || allText.includes("hardware")) {
      return "INFRAESTRUTURA";
    }
    if (allText.includes("bug") || allText.includes("código") || allText.includes("deploy") || allText.includes("api")) {
      return "DESENVOLVIMENTO";
    }
    if (allText.includes("senha") || allText.includes("dúvida") || allText.includes("ajuda") || allText.includes("como fazer")) {
      return "SUPORTE";
    }
    return "TI";
  }

  /**
   * Detecta a prioridade com base nas palavras-chave.
   */
  _detectPriority(message, history) {
    const allText = [message, ...history.map((m) => m.content)].join(" ").toLowerCase();

    if (allText.includes("urgente") || allText.includes("fora do ar") || allText.includes("parado") || allText.includes("crítico")) {
      return "CRITICA";
    }
    if (allText.includes("importante") || allText.includes("bloqueado") || allText.includes("não consigo trabalhar")) {
      return "ALTA";
    }
    if (allText.includes("lento") || allText.includes("intermitente") || allText.includes("às vezes")) {
      return "BAIXA";
    }
    return "MEDIA";
  }

  /**
   * Tenta extrair dados de criação de chamado da resposta da IA.
   */
  _parseTicketCreation(response) {
    try {
      // Tentar encontrar JSON na resposta
      const jsonMatch = response.match(/\{[\s\S]*"criar_chamado"\s*:\s*true[\s\S]*\}/);
      if (!jsonMatch) return null;

      const data = JSON.parse(jsonMatch[0]);
      if (!data.criar_chamado) return null;

      // Validar campos obrigatórios
      const validDepartments = ["TI", "SUPORTE", "INFRAESTRUTURA", "DESENVOLVIMENTO", "SEGURANCA", "REDES", "BANCO_DE_DADOS", "GERAL"];
      const validPriorities = ["BAIXA", "MEDIA", "ALTA", "CRITICA"];

      return {
        titulo: data.titulo || "Chamado criado pela IA",
        descricao: data.descricao || "Chamado gerado automaticamente pelo assistente de IA.",
        prioridade: validPriorities.includes(data.prioridade) ? data.prioridade : "MEDIA",
        departamento: validDepartments.includes(data.departamento) ? data.departamento : "GERAL",
        resumo_ia: data.resumo_ia || "Triagem realizada pelo assistente virtual.",
      };
    } catch {
      return null;
    }
  }
}

module.exports = new AIService();
