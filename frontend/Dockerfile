# Estágio 1: Build do Flutter Web
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa wget

# Define a versão do Flutter
ARG FLUTTER_VERSION=3.22.2
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
    && tar xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C /opt \
    && rm flutter_linux_${FLUTTER_VERSION}-stable.tar.xz

ENV PATH="$PATH:/opt/flutter/bin"

WORKDIR /app

COPY pubspec.yaml .
RUN flutter pub get

COPY . .

# Argumento para a URL da API que será injetado no build
ARG API_URL
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# Estágio 2: Servidor Web Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
