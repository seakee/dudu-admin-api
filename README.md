# Dudu Admin API

**Languages**: [English](README.md) | [中文](README-zh.md)

## Overview

`dudu-admin-api` is the admin backend extracted from the original `admin` branch of `seakee/dudu-admin-api`.
It focuses on admin auth, users, roles, permissions, menus, and operation records.

- Repository: `https://github.com/seakee/dudu-admin-api`
- Source branch: `seakee/dudu-admin-api:admin`
- Import baseline: `6df6cfe8aeeb27eaaaee74c7fb7e520af5f8feb2`

## Quick Start

### Requirements

- Go `1.24.x`
- MySQL and Redis (local or remote)

### Run Locally

```bash
git clone https://github.com/seakee/dudu-admin-api.git
cd dudu-admin-api

go mod download
cp bin/configs/local.json.default bin/configs/local.json
# edit bin/configs/local.json

make build
make run
```

## Runtime Configuration

### Environment Variables

| Variable | Description | Default |
|---|---|---|
| `RUN_ENV` | Config profile (`bin/configs/{RUN_ENV}.json`) | `local` |
| `APP_NAME` | Override `system.name` at runtime | from config |

### Config Files

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

### API Prefix

`system.api_prefix` controls the route prefix.  
Default: `dudu-admin-api`.

## Architecture

### Startup Chain

`main.go` -> `bootstrap.NewApp` -> `App.Start` -> `bootstrap/http.go` -> `app/http/router`

### Route Roots

- `/{apiPrefix}/external/...`
- `/{apiPrefix}/internal/...`
- `/{apiPrefix}/internal/admin/...`
- `/{apiPrefix}/internal/service/...`

### Layering Rule

Model -> Repository -> Service -> Controller.

- Controller should not call repository directly.
- Service should use `context.Context` and not depend on Gin request handling.

## Development Commands

```bash
make fmt
make test
make build
make run

make docker-build
make docker-run
make docker-clean
```

Shell alternative:

```bash
./scripts/make.sh all
./scripts/make.sh run
```

## Documentation

### Entry

- [Docs Home (EN)](docs/Home.md)
- [Docs Home (ZH)](docs/Home-zh.md)

### Core Guides

- [Architecture Design (EN)](docs/Architecture-Design.md)
- [Architecture Design (ZH)](docs/Architecture-Design-zh.md)
- [Development Guide (EN)](docs/Development-Guide.md)
- [Development Guide (ZH)](docs/Development-Guide-zh.md)
- [Deployment Guide (EN)](docs/Deployment-Guide.md)
- [Deployment Guide (ZH)](docs/Deployment-Guide-zh.md)

### API and Domain Docs

- [API Documentation](docs/API-Documentation.md)
- [API Documentation (ZH)](docs/API-Documentation-zh.md)
- [Admin Auth](docs/Admin-Auth.md)
- [Admin Auth (ZH)](docs/Admin-Auth-zh.md)
- [Admin System Management](docs/Admin-System-Management.md)
- [Admin System Management (ZH)](docs/Admin-System-Management-zh.md)

### Tooling Docs

- [Code Generator Guide](docs/Code-Generator-Guide.md)
- [Code Generator Guide (ZH)](docs/Code-Generator-Guide-zh.md)
- [Makefile Usage](docs/Makefile-Usage.md)
- [make.sh Usage](docs/make.sh-Usage.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License. See [LICENSE](LICENSE).
