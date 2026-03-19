# make.sh Usage Guide

## Overview

`scripts/make.sh` is a shell alternative to `Makefile` commands.
It is useful when you prefer shell scripts over `make`.

## Prerequisites

- Go `1.24.x`
- `gofmt`
- `goimports`
- Docker (for Docker commands)

Make executable:

```bash
chmod +x scripts/make.sh
```

## Available Commands

| Command | Description |
|---|---|
| `./scripts/make.sh all` | Run `fmt`, `test`, `build` |
| `./scripts/make.sh fmt` | Run `gofmt -w .` and `goimports -w .` |
| `./scripts/make.sh test` | Run `go test -v ./...` |
| `./scripts/make.sh build` | Build binary `./bin/${APP_NAME}` |
| `./scripts/make.sh run` | Run binary with `RUN_ENV` |
| `./scripts/make.sh docker-build` | Build Docker image |
| `./scripts/make.sh docker-run` | Run Docker container |
| `./scripts/make.sh docker-clean` | Stop/remove container |
| `./scripts/make.sh clean` | Remove built binary |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `dudu-admin-api` | Binary and container name |
| `IMAGE_NAME` | `${APP_NAME}:latest` | Docker image name |
| `CONFIG_DIR` | `${PWD}/bin/configs` | Config mount directory |
| `TZ` | `Asia/Shanghai` | Docker build timezone |
| `RUN_ENV` | `local` | Runtime environment |

## Examples

```bash
./scripts/make.sh all
./scripts/make.sh run
```

```bash
RUN_ENV=prod ./scripts/make.sh docker-build
RUN_ENV=prod ./scripts/make.sh docker-run
./scripts/make.sh docker-clean
```

```bash
APP_NAME=dudu-admin-api-dev ./scripts/make.sh build
IMAGE_NAME=my-registry/dudu-admin-api:v1.0.0 ./scripts/make.sh docker-build
```

## Troubleshooting

Permission denied:

```bash
chmod +x scripts/make.sh
```

`goimports: command not found`:

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

Docker daemon not available:

```bash
docker info
```

## Related Docs

- [Makefile Usage Guide](Makefile-Usage.md)
- [Development Guide](Development-Guide.md)
- [Deployment Guide](Deployment-Guide.md)
