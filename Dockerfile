# Stage 1: Build frontend
FROM node:20-alpine AS frontend-build
WORKDIR /app/web-app

COPY web-app/package.json web-app/yarn.lock ./
COPY web-app/. .

RUN corepack enable && corepack prepare yarn@4.4.0 --activate
RUN yarn install
RUN yarn build

# Stage 2: Build backend
FROM golang:1.21-alpine AS backend-build
RUN apk add --no-cache make bash
WORKDIR /app

COPY . .
RUN make console

# Stage 3: Final image
FROM alpine:latest
WORKDIR /app
RUN apk add --no-cache ca-certificates

# Copy backend binary
COPY --from=backend-build /app/console /app/console

# Copy frontend dist
COPY --from=frontend-build /app/web-app/dist /app/web-app/dist

EXPOSE 8080

ENV CONSOLE_MINIO_SERVER=http://minio:9000
ENV CONSOLE_PBKDF_PASSPHRASE=change-me
ENV CONSOLE_PBKDF_SALT=change-me

ENTRYPOINT ["/app/console", "server", "--port", "8080"]
