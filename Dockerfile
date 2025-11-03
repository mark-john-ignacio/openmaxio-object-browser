# Stage 1: Build Go backend and React frontend
FROM golang:1.21-alpine AS build

# Install dependencies
RUN apk add --no-cache git nodejs npm make bash

# Install Yarn
RUN npm install -g yarn

# Set working directory
WORKDIR /app

# Copy repo into container (if building from local folder)
COPY . .

# Checkout stable version of web-app
WORKDIR /app/web-app
RUN git checkout v1.7.6

# Install frontend dependencies and build
RUN yarn install
RUN yarn build

# Build backend
WORKDIR /app
RUN make console

# Stage 2: Final minimal image
FROM alpine:latest
WORKDIR /app

# Install CA certificates for HTTPS
RUN apk add --no-cache ca-certificates

# Copy compiled console binary
COPY --from=build /app/console /app/console

# Copy built frontend
COPY --from=build /app/web-app/dist /app/web-app/dist

# Expose port (can override with --port)
EXPOSE 8080

# Default environment variables (can override in Coolify)
ENV CONSOLE_MINIO_SERVER=http://minio:9000
ENV CONSOLE_PBKDF_PASSPHRASE=change-me
ENV CONSOLE_PBKDF_SALT=change-me
ENV CONSOLE_DEBUG_LOGLEVEL=0

# Start the console server
ENTRYPOINT ["/app/console", "server", "--port", "8080"]
