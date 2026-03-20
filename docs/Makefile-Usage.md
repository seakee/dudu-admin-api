# Makefile Usage Guide

## Overview

This project provides a `Makefile` for common development and runtime tasks.
Current commands reflect the repository `Makefile`.

## Prerequisites

- Go `1.24.x`
- `gofmt`
- `goimports` (used by `make fmt`)
- Docker (for Docker targets)

Install `goimports`:

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

## Available Targets

### Development

| Target | Description |
|---|---|
| `make all` | Run `fmt`, `test`, `build` |
| `make fmt` | Run `gofmt -w .` and `goimports -w .` |
| `make test` | Run `go test -v ./...` |
| `make build` | Build binary to `./bin/${APP_NAME}` |
| `make run` | Run `./bin/${APP_NAME}` |
| `make clean` | Remove built binary |

### Docker

| Target | Description |
|---|---|
| `make docker-build` | Build image `${IMAGE_NAME}` |
| `make docker-run` | Run container `${APP_NAME}` |
| `make docker-clean` | Stop and remove container `${APP_NAME}` |

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `dudu-admin-api` | Binary and container name |
| `TZ` | `Asia/Shanghai` | Docker build timezone argument |
| `IMAGE_NAME` | `${APP_NAME}:latest` | Docker image name |
| `CONFIG_DIR` | `${PWD}/bin/configs` | Config mount path for container |
| `RUN_ENV` | `local` | Runtime environment passed to container |

## Examples

Basic flow:

```bash
make all
make run
```

Docker flow:

```bash
make docker-build
RUN_ENV=prod make docker-run
make docker-clean
```

Custom app/image names:

```bash
APP_NAME=dudu-admin-api-dev make build
IMAGE_NAME=my-registry/dudu-admin-api:v1.0.0 make docker-build
```

## Troubleshooting

`goimports: command not found`:

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

Binary not found when running `make run`:

```bash
make build
make run
```

Docker permission issues:

```bash
sudo make docker-build
sudo make docker-run
```

## Related Docs

- [make.sh Usage Guide](make.sh-Usage.md)
- [Development Guide](Development-Guide.md)
- [Deployment Guide](Deployment-Guide.md)
