# To build you own OpenMaxIO UI:

```bash
git clone https://github.com/OpenMaxIO/openmaxio-object-browser
cd openmaxio-object-browser/web-app
git checkout v1.7.6
yarn install
yarn build
cd ../
make console
./console server
```

# To connect OpenMaxIO UI to an existing Minio server run this command (replace 1.2.3.4:9000 to your address)

```bash
CONSOLE_MINIO_SERVER=http://1.2.3.4:9000 ./console server
```

# OpenMaxIO Console

This is a fork of MinIO Console.
This is a communitty driven project and is not affiliated with MinIO, Inc.

OpenMaxIO is a community-maintained fork of MinIO, created in response to the removal of key features from the MinIO open-source distribution. Our goal is simple:
to preserve a fully open, fully functional, and production-grade object storage server that stays true to the original spirit of minimalism, performance, and freedom.

MinIO once stood for minimal, high-performance, open-source object storage. But recent changes have shifted core capabilities behind a commercial license. We believe the open-source ecosystem deserves better.

OpenMaxIO brings back what was removed and keeps it open for good.

## Contributing

We welcome contributions to OpenMaxIO Console. These are still early days, so please be patient as we work to restore and enhance the features you love.

![build](https://github.com/minio/console/workflows/Go/badge.svg) ![license](https://img.shields.io/badge/license-AGPL%20V3-blue)

A graphical user interface for [MinIO](https://github.com/minio/minio)

| Object Browser                     | Dashboard                     | Creating a bucket             |
| ---------------------------------- | ----------------------------- | ----------------------------- |
| ![Object Browser](images/pic3.png) | ![Dashboard](images/pic1.png) | ![Dashboard](images/pic2.png) |

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->

**Table of Contents**

- [MinIO Console](#minio-console)
  - [Install](#install)
    - [Build from source](#build-from-source)
  - [Setup](#setup)
    - [1. Create a user `console` using `mc`](#1-create-a-user-console-using-mc)
    - [2. Create a policy for `console` with admin access to all resources (for testing)](#2-create-a-policy-for-console-with-admin-access-to-all-resources-for-testing)
    - [3. Set the policy for the new `console` user](#3-set-the-policy-for-the-new-console-user)
  - [Start Console service:](#start-console-service)
  - [Start Console service with TLS:](#start-console-service-with-tls)
  - [Connect Console to a Minio using TLS and a self-signed certificate](#connect-console-to-a-minio-using-tls-and-a-self-signed-certificate)
- [Contribute to console Project](#contribute-to-console-project)

<!-- markdown-toc end -->

MinIO Console is a library that provides a management and browser UI overlay for the MinIO Server.

## Deploy to Coolify (UI + MinIO together)

This repository includes a `docker-compose.yml` that lets Coolify deploy the OpenMaxIO Console (UI) and a MinIO server in one stack and auto-connect them.

### What it does

- Brings up two services on the same Docker network:
  - `minio` (S3 API on 9000, admin UI on 9001)
  - `app` (OpenMaxIO Console UI on 8080)
- Wires the UI to MinIO internally via `CONSOLE_MINIO_SERVER=http://minio:9000`.
- Persists MinIO data with a named Docker volume.

### One-time setup in Coolify

1. In Coolify, create a new Application.
2. Choose “Git” and point it to this repo/branch.
3. Deployment type: “Docker Compose”.
4. Compose file path: `docker-compose.yml`.
5. Environment variables / secrets (set in the Application in Coolify):
   - `CONSOLE_PBKDF_PASSPHRASE` – a strong random string
   - `CONSOLE_PBKDF_SALT` – a strong random string
   - `MINIO_ROOT_USER` – initial MinIO admin user (e.g., `console`)
   - `MINIO_ROOT_PASSWORD` – initial MinIO admin password (min 12 chars)
6. Deploy. Coolify will build the UI image and start both services.

After deploy, open the Application’s URL (port is handled by Coolify). The UI is served on port `8080` inside the container.

Optional: If you also want to access MinIO directly, expose it publicly in Coolify or map a domain to ports `9000` (S3 API) and `9001` (MinIO admin UI). The Compose file already maps these ports; Coolify may override them with its networking/ingress rules.

Login tip: On first run, sign in to the UI with the MinIO credentials you set (`MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`). For production, create a dedicated `console` user with an appropriate admin policy as shown below and use that for day-to-day access.

### Alternative: Use Coolify’s MinIO Service

Instead of Compose, you can add a managed MinIO “Service” in Coolify and then deploy only the UI container. Set the UI environment:

```
CONSOLE_PBKDF_PASSPHRASE=<random>
CONSOLE_PBKDF_SALT=<random>
CONSOLE_MINIO_SERVER=http://<coolify-minio-service-hostname>:9000
```

Check the service’s internal hostname in Coolify and use that in `CONSOLE_MINIO_SERVER`.

## Setup

All `console` needs is a MinIO user with admin privileges and URL pointing to your MinIO deployment.

> Note: We don't recommend using MinIO's Operator Credentials

### 1. Create a user `console` using `mc`

```bash
mc admin user add myminio/
Enter Access Key: console
Enter Secret Key: xxxxxxxx
```

### 2. Create a policy for `console` with admin access to all resources (for testing)

```sh
cat > admin.json << EOF
{
	"Version": "2012-10-17",
	"Statement": [{
			"Action": [
				"admin:*"
			],
			"Effect": "Allow",
			"Sid": ""
		},
		{
			"Action": [
                "s3:*"
			],
			"Effect": "Allow",
			"Resource": [
				"arn:aws:s3:::*"
			],
			"Sid": ""
		}
	]
}
EOF
```

```sh
mc admin policy create myminio/ consoleAdmin admin.json
```

### 3. Set the policy for the new `console` user

```sh
mc admin policy attach myminio consoleAdmin --user=console
```

> NOTE: Additionally, you can create policies to limit the privileges for other `console` users, for example, if you
> want the user to only have access to dashboard, buckets, notifications and watch page, the policy should look like
> this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["admin:ServerInfo"],
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": [
        "s3:ListenBucketNotification",
        "s3:PutBucketNotification",
        "s3:GetBucketNotification",
        "s3:ListMultipartUploadParts",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucket",
        "s3:HeadBucket",
        "s3:GetObject",
        "s3:GetBucketLocation",
        "s3:AbortMultipartUpload",
        "s3:CreateBucket",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:DeleteBucket",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:GetBucketPolicy"
      ],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::*"],
      "Sid": ""
    }
  ]
}
```

## Start Console service:

Before running console service, following environment settings must be supplied

```sh
# Salt to encrypt JWT payload
export CONSOLE_PBKDF_PASSPHRASE=SECRET

# Required to encrypt JWT payload
export CONSOLE_PBKDF_SALT=SECRET

# MinIO Endpoint
export CONSOLE_MINIO_SERVER=http://localhost:9000
```

Now start the console service.

```
./console server
2021-01-19 02:36:08.893735 I | 2021/01/19 02:36:08 server.go:129: Serving console at http://localhost:9090
```

By default `console` runs on port `9090` this can be changed with `--port` of your choice.

## Start Console service with TLS:

Copy your `public.crt` and `private.key` to `~/.console/certs`, then:

```sh
./console server
2021-01-19 02:36:08.893735 I | 2021/01/19 02:36:08 server.go:129: Serving console at http://[::]:9090
2021-01-19 02:36:08.893735 I | 2021/01/19 02:36:08 server.go:129: Serving console at https://[::]:9443
```

For advanced users, `console` has support for multiple certificates to service clients through multiple domains.

Following tree structure is expected for supporting multiple domains:

```sh
 certs/
  │
  ├─ public.crt
  ├─ private.key
  │
  ├─ example.com/
  │   │
  │   ├─ public.crt
  │   └─ private.key
  └─ foobar.org/
     │
     ├─ public.crt
     └─ private.key
  ...

```

## Connect Console to a Minio using TLS and a self-signed certificate

Copy the MinIO `ca.crt` under `~/.console/certs/CAs`, then:

```sh
export CONSOLE_MINIO_SERVER=https://localhost:9000
./console server
```

You can verify that the apis work by doing the request on `localhost:9090/api/v1/...`

## Debug logging

In some cases it may be convenient to log all HTTP requests. This can be enabled by setting
the `CONSOLE_DEBUG_LOGLEVEL` environment variable to one of the following values:

- `0` (default) uses no logging.
- `1` log single line per request for server-side errors (status-code 5xx).
- `2` log single line per request for client-side and server-side errors (status-code 4xx/5xx).
- `3` log single line per request for all requests (status-code 4xx/5xx).
- `4` log details per request for server-side errors (status-code 5xx).
- `5` log details per request for client-side and server-side errors (status-code 4xx/5xx).
- `6` log details per request for all requests (status-code 4xx/5xx).

A single line logging has the following information:

- Remote endpoint (IP + port) of the request. Note that reverse proxies may hide the actual remote endpoint of the client's browser.
- HTTP method and URL
- Status code of the response (websocket connections are hijacked, so no response is shown)
- Duration of the request

The detailed logging also includes all request and response headers (if any).

# Contribute to console Project

Please follow console [Contributor's Guide](https://github.com/minio/console/blob/master/CONTRIBUTING.md)
