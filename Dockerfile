# Stage 1: Build Go backend and frontend
FROM golang:1.21-alpine AS build

# Install dependencies
RUN apk add --no-cache git nodejs npm make bash
RUN npm install -g yarn

WORKDIR /app

# Copy source code (Coolify already clones your fork)
COPY . .

# Build frontend
# Use Node 20 Alpine to get Corepack support
FROM node:20-alpine AS frontend-build

WORKDIR /app/web-app

# Copy web-app
COPY web-app/package.json web-app/yarn.lock ./
COPY web-app/. .

# Enable Corepack and use Yarn 4
RUN corepack enable \
    && corepack prepare yarn@4.4.0 --activate

# Install dependencies and build
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
