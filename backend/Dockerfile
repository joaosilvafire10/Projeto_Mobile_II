FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY prisma ./prisma
RUN npx prisma generate

COPY . .

EXPOSE 3000

# Script para rodar migrations e iniciar o app
CMD npx prisma migrate deploy && npm run dev
