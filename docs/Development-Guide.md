# Development Guide

**Languages**: [English](Development-Guide.md) | [中文](Development-Guide-zh.md)

## Prerequisites

- Go `1.24.x` (project uses `go 1.24.13`)
- MySQL and Redis
- `make` and standard Go toolchain (`gofmt`, `go test`)

## Project Setup

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

### Config Files

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

### Environment Variables

- `RUN_ENV`: selects `bin/configs/{RUN_ENV}.json`, default `local`
- `APP_NAME`: overrides `system.name` at runtime

## Architecture and Layering

### Startup Chain

`main.go` -> `bootstrap.NewApp` -> `App.Start` -> `bootstrap/http.go` -> `app/http/router`

### Required Layer Order

Model -> Repository -> Service -> Controller

- Controller must not call repository directly.
- Service should accept `context.Context` and should not handle Gin request/response details.
- Repository should focus on persistence, not business orchestration.

### Repository DB Access Rule

Prefer model-layer helpers first (such as `Where`, `First`, `List`, `Create`, `Updates`, `Count`, `FindWithPagination`, `BatchInsert`).

Direct `db.WithContext(ctx)...` in repository is only for:
- transactions (`Transaction(...)`)
- queries not covered by model helpers (for example `Select`, `Pluck`, `Joins`)

## Route Structure

The default API prefix is `dudu-admin-api` (`system.api_prefix`).

- `/{apiPrefix}/external/...`
- `/{apiPrefix}/internal/...`
- `/{apiPrefix}/internal/admin/...`
- `/{apiPrefix}/internal/service/...`

When adding endpoints, define:
- auth middleware (`CheckAppAuth` and/or `CheckAdminAuth`)
- operation logging (`SaveOperationRecord`) requirement
- sensitive payload redaction requirement

## Typical Feature Workflow

1. Define or update model
2. Implement repository with model helpers
3. Implement service business logic
4. Add controller handlers
5. Register routes under the correct module path
6. Add tests
7. Update bilingual docs and error-code/i18n mapping when user-facing behavior changes

## Code Generation

Generator entry: `command/codegen/handler.go`

```bash
# Generate from one SQL file name
go run ./command/codegen/handler.go -name auth_app

# Generate one PostgreSQL SQL file
go run ./command/codegen/handler.go -dialect=postgres -sql bin/data/sql/postgres -name oauth_app

# Generate from all SQL files
go run ./command/codegen/handler.go
```

Default SQL directory:
- `bin/data/sql`

After generation, complete manual integration:
- service layer wiring
- controller/router wiring
- tests
- docs and error-code updates when needed

## Testing and Formatting

Minimum verification before finalizing changes:

```bash
gofmt -w .
go test ./...
```

Recommended for medium/large changes:

```bash
go test -race ./...
```

## Build and Run Commands

```bash
make fmt
make test
make build
make run
```

Shell script alternative:

```bash
./scripts/make.sh all
./scripts/make.sh run
```

## Related Docs

- [Architecture Design](Architecture-Design.md)
- [API Documentation](API-Documentation.md)
- [Admin Auth](Admin-Auth.md)
- [Admin System Management](Admin-System-Management.md)
- [Code Generator Guide](Code-Generator-Guide.md)
- [Makefile Usage](Makefile-Usage.md)
- [make.sh Usage](make.sh-Usage.md)
- [Deployment Guide](Deployment-Guide.md)
