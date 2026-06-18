# Arquitetura do Sistema - Chamados Inteligentes

## Visão Geral

O sistema Chamados Inteligentes foi desenvolvido utilizando uma arquitetura em camadas baseada nos princípios de Clean Architecture e Separation of Concerns.

O objetivo é garantir:

* Baixo acoplamento;
* Alta coesão;
* Facilidade de manutenção;
* Escalabilidade;
* Testabilidade.

---

# Arquitetura Geral
<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/57efd3c5-7c3c-4a08-861c-377d4bc64cea" />

UI
↓
Provider (Estado)
↓
Services
↓
Repository
↓
API REST
↓
Backend Express
↓
Prisma ORM
↓
PostgreSQL

---

# Frontend

## Camada UI

Responsável pela apresentação ao usuário.

Exemplos:

* LoginScreen
* HomeScreen
* TicketFormScreen
* TicketDetailsScreen
* ChatAIScreen

Responsabilidades:

* Exibir informações
* Capturar entradas
* Apresentar feedback visual

---

## Camada Provider

Responsável pelo gerenciamento de estado.

Exemplos:

* AuthProvider
* TicketProvider
* CategoryProvider

Responsabilidades:

* Gerenciar estado da aplicação
* Atualizar interface
* Controlar carregamentos e erros

---

## Camada Services

Responsável pela comunicação com a API.

Exemplos:

* ApiService
* AuthService
* TicketService
* AIService

Responsabilidades:

* Requisições HTTP
* Serialização
* Tratamento de erros
* Renovação automática de token

---

# Fluxo de Autenticação

Usuário realiza Login
↓
Backend gera Access Token
↓
Backend gera Refresh Token
↓
Tokens armazenados no Flutter Secure Storage
↓
Interceptor adiciona Authorization Bearer
↓
Access Token expira
↓
Refresh Token gera novo Access Token
↓
Sessão continua ativa

---

# Segurança

## Implementações

* JWT Authentication
* Refresh Token
* Flutter Secure Storage
* Interceptors Dio
* Logout Seguro
* HTTPS

---

# Backend

## Controller Layer

Responsável por receber requisições HTTP.

Exemplos:

* AuthController
* TicketController
* CategoryController
* AIController

---

## Service Layer

Responsável pelas regras de negócio.

Exemplos:

* AuthService
* TicketService
* AIService

---

## Repository Layer

Responsável pelo acesso aos dados.

Exemplos:

* TicketRepository
* UserRepository
* CategoryRepository

---

## Database Layer

Banco de dados PostgreSQL utilizando Prisma ORM.

---

# Entidade Principal

## Ticket

Atributos:

* id
* title
* description
* status
* priority
* department
* aiSummary
* createdAt
* updatedAt
* userId
* categoryId
* activityId
* assignedToId

Atende ao requisito de possuir mais de 7 atributos.

---

# Relacionamentos

## Categoria → Atividades

1 Categoria
↓
N Atividades

## Categoria → Chamados

1 Categoria
↓
N Chamados

## Usuário → Chamados

1 Usuário
↓
N Chamados

## Chamado → Mensagens

1 Chamado
↓
N Mensagens

---

# Regras de Negócio

## Regra 1

Categoria obrigatória para abertura do chamado.

## Regra 2

Atividade obrigatoriamente vinculada à categoria selecionada.

## Regra 3

Título e descrição obrigatórios para criação do chamado.

---

# Integração com Inteligência Artificial

A aplicação utiliza Google Gemini para:

* Classificação automática de chamados;
* Sugestão de categoria;
* Sugestão de prioridade;
* Geração de resumo técnico;
* Apoio à abertura de chamados.

---

# Tratamento de Erros

## API

* HTTP 400
* HTTP 401
* HTTP 403
* HTTP 404
* HTTP 500

## Rede

* Timeout
* Falha de conexão
* Serviço indisponível

## IA

* Fallback automático quando Gemini estiver indisponível
* Mensagens amigáveis ao usuário

---

# Funcionalidades Individuais

## João Victor

Chat Inteligente com IA para triagem automática de chamados.

## Eduardo Sousa

Gestão dinâmica de Categorias e Atividades integradas aos chamados.

---

# Conclusão

A arquitetura implementada atende aos requisitos da VA2, contemplando autenticação JWT, persistência de sessão, CRUD completo, relacionamento 1:N, integração com API REST, funcionalidades individuais e Inteligência Artificial integrada ao fluxo principal da aplicação.
