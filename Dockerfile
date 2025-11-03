# Stage 1: Build Go backend and frontend
FROM golang:1.21-alpine AS build

# Install dependencies
RUN apk add --no-cache git nodejs npm make bash
RUN npm install -g yarn

WORKDIR /app

# Copy source code (Coolify already clones your fork)
COPY . .

# Build frontend
WORKDIR /app/web-app
RUN yarn install
RUN yarn build

# Build backend
WORKDIR /app
RUN make console

# Stage 2: Minimal final image
FROM alpine:latest
WORKDIR /app
RUN apk add --no-cache ca-certificates

COPY --from=build /app/console /app/console
COPY --from=build /app/web-app/dist /app/web-app/dist

EXPOSE 8080

ENV CONSOLE_MINIO_SERVER=http://minio:9000
ENV CONSOLE_PBKDF_PASSPHRASE=change-me
ENV CONSOLE_PBKDF_SALT=change-me

ENTRYPOINT ["/app/console", "server", "--port", "8080"]
