# Stage 1: Build frontend assets
FROM node:18-alpine AS frontend-build
WORKDIR /app/web-app

COPY web-app/package.json web-app/yarn.lock web-app/.yarnrc.yml ./
RUN corepack enable && corepack prepare yarn@4.4.0 --activate
RUN apk add --no-cache git && YARN_ENABLE_IMMUTABLE_INSTALLS=false yarn install --check-cache

COPY web-app/ .
ENV NODE_ENV=production
RUN yarn build

# Stage 2: Build backend binary
FROM golang:1.23-alpine AS backend-build
RUN apk add --no-cache make bash git ca-certificates
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
COPY --from=frontend-build /app/web-app/build ./web-app/build
RUN make console

# Stage 3: Final runtime image
FROM alpine:3.20
WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata && adduser -D -g '' console

COPY --from=backend-build /app/console /usr/local/bin/console
COPY --from=frontend-build /app/web-app/build /app/web-app/build

EXPOSE 8080

ENV CONSOLE_MINIO_SERVER=http://minio:9000 \
	CONSOLE_PBKDF_PASSPHRASE=change-me \
	CONSOLE_PBKDF_SALT=change-me

USER console

ENTRYPOINT ["console", "server", "--port", "8080"]
