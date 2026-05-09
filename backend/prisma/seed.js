const { PrismaClient } = require("../generated/prisma");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  console.log("🌱 Iniciando seed do banco de dados...\n");

  // Limpar dados existentes
  await prisma.message.deleteMany();
  await prisma.ticket.deleteMany();
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

  const tecnico = await prisma.user.create({
    data: {
      name: "Carlos Técnico",
      email: "tecnico@empresa.com",
      password: hashedPassword,
      role: "TECNICO",
      department: "SUPORTE",
    },
  });
  console.log(`✅ Técnico criado: ${tecnico.email}`);

  const usuario = await prisma.user.create({
    data: {
      name: "Maria Usuária",
      email: "usuario@empresa.com",
      password: hashedPassword,
      role: "USUARIO",
      department: "GERAL",
    },
  });
  console.log(`✅ Usuário criado: ${usuario.email}`);

  const dev = await prisma.user.create({
    data: {
      name: "Ana Desenvolvedora",
      email: "dev@empresa.com",
      password: hashedPassword,
      role: "TECNICO",
      department: "DESENVOLVIMENTO",
    },
  });
  console.log(`✅ Desenvolvedora criada: ${dev.email}`);

  // Criar chamados de exemplo
  const ticket1 = await prisma.ticket.create({
    data: {
      title: "Computador não liga após atualização",
      description:
        "Após a atualização do Windows ontem à noite, meu computador não liga mais. Fica preso na tela azul com código de erro 0x0000007E.",
      status: "ABERTO",
      priority: "ALTA",
      department: "TI",
      aiSummary:
        "Problema de boot após Windows Update. Código BSoD 0x0000007E indica possível driver incompatível. Recomendado boot em modo seguro para desinstalar atualização recente.",
      userId: usuario.id,
    },
  });

  const ticket2 = await prisma.ticket.create({
    data: {
      title: "VPN não conecta na rede da empresa",
      description:
        "Desde segunda-feira não consigo conectar na VPN corporativa. O cliente VPN mostra erro de timeout.",
      status: "EM_ANDAMENTO",
      priority: "MEDIA",
      department: "REDES",
      aiSummary:
        "Falha de conexão VPN com timeout. Possíveis causas: certificado expirado, firewall bloqueando, ou mudança de configuração no servidor VPN.",
      userId: usuario.id,
    },
  });

  const ticket3 = await prisma.ticket.create({
    data: {
      title: "Sistema de RH exibindo dados errados",
      description:
        "O relatório de folha de pagamento está mostrando valores incorretos para o departamento financeiro.",
      status: "AGUARDANDO_USUARIO",
      priority: "CRITICA",
      department: "DESENVOLVIMENTO",
      aiSummary:
        "Bug no módulo de folha de pagamento afetando cálculos do departamento financeiro. Necessária investigação urgente na query de cálculo.",
      userId: usuario.id,
    },
  });

  console.log(`\n✅ ${3} chamados de exemplo criados.`);

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
  console.log("  📧 tecnico@empresa.com  (TECNICO)");
  console.log("  📧 usuario@empresa.com  (USUARIO)");
  console.log("  📧 dev@empresa.com      (TECNICO)");
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
