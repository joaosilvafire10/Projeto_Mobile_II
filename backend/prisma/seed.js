const { PrismaClient } = require("../generated/prisma");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Iniciando seed do banco de dados...\n");

  // Limpar dados existentes
  await prisma.message.deleteMany();
  await prisma.ticket.deleteMany();
  await prisma.activity.deleteMany();
  await prisma.category.deleteMany();
  await prisma.user.deleteMany();
  console.log("🗑️  Dados anteriores removidos.");

  // Criar usuários
  const hashedPassword = await bcrypt.hash("123456", 10);

  const admin = await prisma.user.create({
    data: {
      name: "Administrador",
      email: "admin@empresa.com",
      password: hashedPassword,
      role: "ADMIN",
      department: "TI",
    },
  });
  console.log(`✅ Admin criado: ${admin.email}`);

  const analistaTI = await prisma.user.create({
    data: {
      name: "João da TI",
      email: "analista.ti@empresa.com",
      password: hashedPassword,
      role: "ANALISTA",
      department: "TI",
    },
  });
  console.log(`✅ Analista TI criado: ${analistaTI.email}`);

  const analistaFin = await prisma.user.create({
    data: {
      name: "Beatriz Financeiro",
      email: "analista.fin@empresa.com",
      password: hashedPassword,
      role: "ANALISTA",
      department: "FINANCEIRO",
    },
  });
  console.log(`✅ Analista Financeiro criado: ${analistaFin.email}`);

  const analistaCont = await prisma.user.create({
    data: {
      name: "Lucas Contabilidade",
      email: "analista.cont@empresa.com",
      password: hashedPassword,
      role: "ANALISTA",
      department: "CONTABILIDADE",
    },
  });
  console.log(`✅ Analista Contabilidade criado: ${analistaCont.email}`);

  const usuario = await prisma.user.create({
    data: {
      name: "Maria Usuária",
      email: "usuario@empresa.com",
      password: hashedPassword,
      role: "USUARIO",
      department: "TI",
    },
  });
  console.log(`✅ Usuário criado: ${usuario.email}`);

  // =============================================
  // CATEGORIAS E ATIVIDADES
  // =============================================

  console.log("\n📂 Criando categorias e atividades...");

  // Categoria TI
  const catTI = await prisma.category.create({
    data: {
      name: "TI",
      description: "Tecnologia da Informação - Suporte técnico, hardware, software e infraestrutura",
      activities: {
        create: [
          { name: "Atualização de Windows", description: "Problemas com atualizações do sistema operacional Windows" },
          { name: "Problema de Rede", description: "Problemas de conectividade, Wi-Fi, VPN e acesso à internet" },
          { name: "Instalação de Software", description: "Instalação, configuração e licenciamento de softwares" },
          { name: "Problema com Hardware", description: "Problemas com computador, monitor, teclado, mouse e periféricos" },
          { name: "Reset de Senha", description: "Recuperação e redefinição de senhas de acesso" },
          { name: "Problema com E-mail", description: "Problemas com envio, recebimento e configuração de e-mail" },
          { name: "Backup e Recuperação", description: "Solicitação de backup de dados ou recuperação de arquivos" },
        ],
      },
    },
    include: { activities: true },
  });
  console.log(`✅ Categoria "${catTI.name}" criada com ${catTI.activities.length} atividades`);

  // Categoria Contabilidade
  const catContabilidade = await prisma.category.create({
    data: {
      name: "Contabilidade",
      description: "Assuntos contábeis, fiscais e de demonstrações financeiras",
      activities: {
        create: [
          { name: "Nota Fiscal", description: "Emissão, cancelamento e consulta de notas fiscais" },
          { name: "Relatório Contábil", description: "Geração e correção de relatórios e balanços contábeis" },
          { name: "Declaração de Impostos", description: "Declarações fiscais, IRPJ, CSLL e obrigações acessórias" },
          { name: "Conciliação Bancária", description: "Conciliação de extratos bancários com registros contábeis" },
          { name: "Lançamentos Contábeis", description: "Registro e correção de lançamentos no sistema contábil" },
        ],
      },
    },
    include: { activities: true },
  });
  console.log(`✅ Categoria "${catContabilidade.name}" criada com ${catContabilidade.activities.length} atividades`);

  // Categoria Financeiro
  const catFinanceiro = await prisma.category.create({
    data: {
      name: "Financeiro",
      description: "Assuntos financeiros, pagamentos, recebimentos e controle orçamentário",
      activities: {
        create: [
          { name: "Pagamento de Fornecedor", description: "Processamento e acompanhamento de pagamentos a fornecedores" },
          { name: "Reembolso", description: "Solicitação e processamento de reembolsos de despesas" },
          { name: "Fluxo de Caixa", description: "Análise e projeção de fluxo de caixa" },
          { name: "Orçamento", description: "Elaboração, revisão e acompanhamento de orçamentos" },
          { name: "Contas a Receber", description: "Gestão de cobranças e recebimentos de clientes" },
        ],
      },
    },
    include: { activities: true },
  });
  console.log(`✅ Categoria "${catFinanceiro.name}" criada com ${catFinanceiro.activities.length} atividades`);

  // Criar chamados de exemplo (com categoria e atividade)
  const atividadeWindows = catTI.activities.find(a => a.name === "Atualização de Windows");
  const atividadeRede = catTI.activities.find(a => a.name === "Problema de Rede");
  const atividadeRelatorio = catContabilidade.activities.find(a => a.name === "Relatório Contábil");
  const atividadeReembolso = catFinanceiro.activities.find(a => a.name === "Reembolso");

  const ticket1 = await prisma.ticket.create({
    data: {
      title: "Computador não liga após atualização",
      description:
        "Após a atualização do Windows ontem à noite, meu computador não liga mais. Fica preso na tela azul com código de erro 0x0000007E.",
      status: "ABERTO",
      priority: "ALTA",
      department: "TI",
      categoryId: catTI.id,
      activityId: atividadeWindows.id,
      aiSummary:
        "Problema de boot após Windows Update. Código BSoD 0x0000007E indica possível driver incompatível. Recomendado boot em modo seguro para desinstalar atualização recente.",
      userId: usuario.id,
    },
  });

  const ticket2 = await prisma.ticket.create({
    data: {
      title: "Problema com rede Wi-Fi do escritório",
      description:
        "O Wi-Fi da sala de reunião principal está instável e caindo constantemente a cada 5 minutos.",
      status: "EM_ANDAMENTO",
      priority: "MEDIA",
      department: "TI",
      categoryId: catTI.id,
      activityId: atividadeRede.id,
      aiSummary:
        "Conexão instável de Wi-Fi. Provável sobrecarga do AP ou interferência de canais. Recomenda-se verificação física e reboot do roteador.",
      userId: usuario.id,
      assignedToId: analistaTI.id,
    },
  });

  const ticket3 = await prisma.ticket.create({
    data: {
      title: "Reembolso de despesa de viagem de negócios",
      description:
        "Solicito o processamento do reembolso referente aos custos de transporte e hospedagem da viagem de visita a cliente.",
      status: "EM_ANDAMENTO",
      priority: "MEDIA",
      department: "FINANCEIRO",
      categoryId: catFinanceiro.id,
      activityId: atividadeReembolso.id,
      aiSummary:
        "Solicitação de reembolso de viagem. Documentos pendentes anexados. Necessário conferência do setor financeiro.",
      userId: usuario.id,
      assignedToId: analistaFin.id,
    },
  });

  const ticket4 = await prisma.ticket.create({
    data: {
      title: "Erro na geração do relatório de balanço",
      description:
        "Ao tentar emitir o relatório contábil do primeiro trimestre, o sistema exibe erro de timeout do banco de dados.",
      status: "ABERTO",
      priority: "CRITICA",
      department: "CONTABILIDADE",
      categoryId: catContabilidade.id,
      activityId: atividadeRelatorio.id,
      aiSummary:
        "Erro de timeout em relatório contábil. Possível volume excessivo de dados ou falta de índice na consulta. Requer análise de infra ou DBA.",
      userId: usuario.id,
    },
  });

  console.log(`\n✅ ${4} chamados de exemplo criados.`);

  // Criar mensagens de exemplo
  await prisma.message.createMany({
    data: [
      {
        content: "Meu computador não liga depois da atualização de ontem.",
        sender: "user",
        ticketId: ticket1.id,
        userId: usuario.id,
      },
      {
        content:
          "Entendi o problema. Você consegue ver alguma mensagem de erro na tela? O computador faz algum som ao ligar?",
        sender: "ai",
        ticketId: ticket1.id,
      },
      {
        content:
          "Sim, aparece uma tela azul com o código 0x0000007E e depois reinicia sozinho.",
        sender: "user",
        ticketId: ticket1.id,
        userId: usuario.id,
      },
      {
        content:
          "O código 0x0000007E geralmente indica um driver incompatível. Vou criar um chamado para a equipe de TI analisar. Enquanto isso, tente iniciar o computador em modo seguro (pressione F8 durante o boot).",
        sender: "ai",
        ticketId: ticket1.id,
      },
      {
        content:
          "Chamado criado e encaminhado para o departamento de TI com prioridade alta.",
        sender: "system",
        ticketId: ticket1.id,
      },
    ],
  });

  console.log("✅ Mensagens de exemplo criadas.");

  console.log("\n========================================");
  console.log("🎉 Seed concluído com sucesso!");
  console.log("========================================");
  console.log("\nCredenciais de teste (senha: 123456):");
  console.log("  📧 admin@empresa.com    (ADMIN)");
  console.log("  📧 analista.ti@empresa.com (ANALISTA - TI)");
  console.log("  📧 analista.fin@empresa.com (ANALISTA - FINANCEIRO)");
  console.log("  📧 analista.cont@empresa.com (ANALISTA - CONTABILIDADE)");
  console.log("  📧 usuario@empresa.com  (USUARIO)");
  console.log("\n📂 Categorias criadas:");
  console.log("  🔧 TI (7 atividades)");
  console.log("  📊 Contabilidade (5 atividades)");
  console.log("  💰 Financeiro (5 atividades)");
  console.log("========================================\n");
}

main()
  .catch((e) => {
    console.error("❌ Erro no seed:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
