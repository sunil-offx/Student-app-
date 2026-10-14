# syntax=docker/dockerfile:1
# Stage 1: Build Flutter Web app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Download dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and compile web release
COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=/api

# Stage 2: Production Nginx Server
FROM nginx:alpine

# Copy built web artifacts
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy Nginx reverse proxy configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
