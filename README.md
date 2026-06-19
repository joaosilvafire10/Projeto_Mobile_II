# Chamados Inteligentes

## 📖 Descrição

Chamados Inteligentes é uma aplicação mobile desenvolvida em Flutter para gerenciamento de chamados de suporte técnico.

A solução utiliza autenticação JWT, comunicação com API REST, gerenciamento de categorias e atividades, além de integração com Inteligência Artificial utilizando Google Gemini para triagem automática e auxílio na abertura de chamados.

O objetivo do sistema é otimizar o processo de atendimento, classificação e acompanhamento de solicitações de suporte.

---

## 🌐 Ambiente de Produção

A aplicação encontra-se publicada em ambiente de produção utilizando VPS Oracle Cloud, Docker e Dokploy.

### Frontend

http://app.193.122.213.155.nip.io

### Infraestrutura

* Oracle Cloud VPS
* Docker
* Dokploy
* Node.js
* Flutter Web
* SQLite
* HTTPS via proxy reverso

---

## 👥 Integrantes

* João Victor da Silva Jesus
* Eduardo Sousa Coelho

---

## 🚀 Tecnologias Utilizadas

### Frontend

* Flutter 3.x
* Dart 3.x
* Provider
* Dio
* Flutter Secure Storage
* Material Design

### Backend

* Node.js
* Express
* Prisma ORM
* SQLite
* JWT Authentication

### Inteligência Artificial

* Google Gemini
* Google Generative AI SDK

---

## ✨ Principais Funcionalidades

### Autenticação

* Login com JWT
* Access Token
* Refresh Token
* Persistência automática de sessão
* Logout seguro

### Gestão de Chamados

* Criar chamados
* Listar chamados
* Editar chamados
* Excluir chamados
* Visualizar detalhes

### Gestão de Categorias e Atividades

* Cadastro de categorias
* Cadastro de atividades
* Relacionamento Categoria → Atividades

### Inteligência Artificial

* Triagem inteligente de solicitações
* Sugestão automática de categoria
* Sugestão automática de prioridade
* Resumo inteligente do problema
* Fallback em caso de indisponibilidade da IA

---

## 📋 Regras de Negócio

### Regra 1

Categoria é obrigatória para criação de chamados.

### Regra 2

Atividade deve pertencer à categoria selecionada.

### Regra 3

Título e descrição do chamado não podem estar vazios.

---

## 🔗 Relacionamentos

* Categoria → Atividades
* Categoria → Chamados
* Usuário → Chamados
* Chamado → Mensagens

---

## 🔐 Credenciais de Teste

**Usuário**

[admin@empresa.com](mailto:admin@empresa.com)

**Senha**

123456

---

## ⚙️ Instalação do Backend

```bash
cd backend
npm install
```

### Executar Migrations

```bash
npx prisma migrate deploy
```

### Gerar Prisma Client

```bash
npm run prisma:generate
```

### Executar Migrações

```bash
npm run prisma:migrate
```

### Popular Banco

```bash
npm run prisma:seed
```

Contas criadas automaticamente:

* [admin@empresa.com](mailto:admin@empresa.com) (Admin)
* [tecnico@empresa.com](mailto:tecnico@empresa.com) (Técnico)
* [usuario@empresa.com](mailto:usuario@empresa.com) (Usuário)

Senha padrão:

```txt
123456
```

---

## 📚 Documentação da API

Com o backend em execução:

```txt
http://localhost:3000/api/docs
```

O Swagger permite:

* Autenticação
* Teste de endpoints
* Geração de tokens
* Testes da IA
* Gestão de chamados

---

## 🖥️ Instalação do Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 🧠 Integração com IA

A funcionalidade de IA utiliza o Google Gemini para:

* Interpretar a descrição do usuário
* Gerar resumo do problema
* Classificar prioridade
* Sugerir categoria
* Auxiliar na criação automática de chamados

Quando o serviço estiver indisponível, o sistema utiliza um mecanismo de fallback para manter a experiência do usuário.

---

## 📂 Estrutura do Projeto

```text
frontend/
├── lib/
├── providers/
├── services/
├── models/
└── screens/

backend/
├── src/
├── controllers/
├── services/
├── repositories/
├── routes/
└── prisma/
```

---

## 🏗️ Arquitetura

```text
Flutter UI
     ↓
Providers
     ↓
Services
     ↓
API REST
     ↓
Node.js + Express
     ↓
Prisma ORM
     ↓
SQLite
```

A arquitetura segue o padrão de separação de responsabilidades, facilitando manutenção, testes e evolução do sistema.
