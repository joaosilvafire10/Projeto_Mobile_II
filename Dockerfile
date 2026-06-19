FROM ghcr.io/cirruslabs/flutter:stable

# Define a pasta raiz do contêiner
WORKDIR /app

# Copia todo o conteúdo do repositório (incluindo as pastas frontend e backend)
COPY . .

# Entra especificamente na pasta do Flutter onde está o pubspec.yaml
WORKDIR /app/frontend

# Evita possíveis erros de permissão do git internamente
RUN git config --global --add safe.directory '*'

# Agora os comandos rodam no lugar certo
RUN flutter pub get
RUN flutter build web --release

# --- Etapa do Nginx para servir a aplicação ---
FROM nginx:alpine

# Copia o resultado do build da pasta correta para o Nginx
COPY --from=0 /app/frontend/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
