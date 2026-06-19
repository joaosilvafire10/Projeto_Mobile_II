Chamados Inteligentes - Sistema Inteligente de Gestão de Chamados
Descrição

Chamados Inteligentes é uma aplicação mobile desenvolvida em Flutter para gerenciamento de chamados de suporte técnico. A solução utiliza autenticação JWT, comunicação com API REST, gerenciamento de categorias e atividades, além de integração com Inteligência Artificial utilizando Google Gemini para triagem automática e auxílio na abertura de chamados.

O objetivo do sistema é otimizar o processo de atendimento, classificação e acompanhamento de solicitações de suporte.

Integrantes
João Victor da Silva Jesus
Eduardo Sousa Coelho 

Tecnologias Utilizadas
Frontend
Flutter 3.x
Dart 3.x
Provider
Dio
Flutter Secure Storage
Material Design
Backend
Node.js
Express
Prisma ORM
SQLLite
JWT Authentication

Inteligência Artificial
Google Gemini
Google Generative AI SDK
Principais Funcionalidades

Autenticação
Login com JWT
Access Token
Refresh Token
Persistência automática de sessão
Logout seguro

Gestão de Chamados
Criar chamados
Listar chamados
Editar chamados
Excluir chamados
Visualizar detalhes

Gestão de Categorias e Atividades
Cadastro de categorias
Cadastro de atividades
Relacionamento Categoria → Atividades

Inteligência Artificial
Triagem inteligente de solicitações
Sugestão automática de categoria
Sugestão automática de prioridade
Resumo inteligente do problema
Fallback em caso de indisponibilidade da IA

Regras de Negócio
Regra 1
Categoria é obrigatória para criação de chamados.

Regra 2
Atividade deve pertencer à categoria selecionada.

Regra 3
Título e descrição do chamado não podem estar vazios.

Relacionamentos
Categoria → Atividades
Uma categoria pode possuir várias atividades.

Categoria → Chamados
Uma categoria pode possuir vários chamados.

Usuário → Chamados
Um usuário pode criar vários chamados.

Chamado → Mensagens
Um chamado pode possuir várias mensagens.

Credenciais de Teste
Usuário:
admin@empresa.com
Senha:
123456

Instalação Backend
cd backend
npm install

Executar migrations:

npx prisma migrate deploy

Iniciar servidor:

npm install
npm run prisma:generate 
npm run prisma:migrate
npm run prisma:seed
O comando seed vai criar alguns chamados de exemplo e contas de teste (senha padrão: 123456):

admin@empresa.com (Admin)
tecnico@empresa.com (Técnico)
usuario@empresa.com (Usuário comum)

Teste a API via Swagger
Com o servidor rodando, abra o seu navegador e acesse: http://localhost:3000/api/docs

Pelo Swagger você tem acesso completo a todos os endpoints, já documentados. Você pode fazer o login (/api/auth/login), copiar o token, clicar no botão "Authorize" no topo da página e testar a criação de chamados, envio de mensagens e a própria rota da Inteligência Artificial (/api/ai/triage).

Instalação Frontend
cd frontend
flutter run -d chrome (executar no Chrome)

O projeto segue o padrão:

UI → Provider → Services → API → Backend

Separando responsabilidades para facilitar manutenção, testes e evolução do sistema.

Integração com IA

A funcionalidade de IA utiliza o Google Gemini para:

Interpretar a descrição do usuário;
Gerar resumo do problema;
Classificar prioridade;
Sugerir categoria;
Auxiliar na criação automática de chamados.

Quando o serviço estiver indisponível, o sistema utiliza um mecanismo de fallback para manter a experiência do usuário.

Estrutura do Projeto

frontend/
├── lib/
├── providers/
├── services/
├── models/
└── screens/

backend/
├── src/
├── controllers/

## Ambiente de Produção

A aplicação encontra-se publicada em ambiente de produção através de uma VPS Oracle Cloud utilizando Docker e Dokploy para orquestração dos serviços.

### Acesso ao Sistema

Frontend:
http://app.193.122.213.155.nip.io

### Infraestrutura

* Hospedagem em VPS Oracle Cloud;
* Deploy automatizado via Dokploy;
* Containers Docker para frontend e backend;
* Banco de dados SQLite persistido em volume dedicado;
* Integração contínua com repositório GitHub;
* Proxy reverso e gerenciamento de domínios realizados pelo Dokploy.

### Observação

O endereço de produção poderá ser alterado futuramente para um domínio próprio, mantendo a mesma infraestrutura de hospedagem e deploy.

├── services/
├── repositories/
├── routes/
└── prisma/
