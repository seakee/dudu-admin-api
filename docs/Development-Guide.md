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

### Single-entry bootstrap / project generation (database + super admin seed data)

`bin/data/sql/{dialect}/init.sql` already contains full schema and admin seed data. Use `scripts/init-project.sh` as the single recommended entry:

```bash
# Run inside repository: initialize the current repository interactively
./scripts/init-project.sh

# Remote download and run: generate the default ./dudu-admin-api directory
curl -fsSL https://raw.githubusercontent.com/seakee/dudu-admin-api/main/scripts/init-project.sh -o init-project.sh
bash init-project.sh

# Remote download and generate a custom project
bash init-project.sh --project-name my-api --module-name github.com/acme/my-api

# Non-interactive mode: generate and initialize a new project
bash init-project.sh --non-interactive --yes \
  --project-name my-api \
  --module-name github.com/acme/my-api \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name my-api --db-user my-api --db-password 'your-password'

# Non-interactive mode: initialize an existing repository
bash init-project.sh --non-interactive --yes \
  --project-dir ./dudu-admin-api --skip-clone \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name dudu-admin-api --db-user dudu-admin-api --db-password 'your-password'
```

If `--module-name` is not a remote repository path and you are not running inside the template repository, pass `--repo-url` explicitly.

The script generates a minimal runnable config file (`bin/configs/{RUN_ENV}.json`) including:
- `system.name`
- `system.route_prefix`
- `system.run_mode`
- `system.http_port`
- `system.default_lang`
- `system.jwt_secret`
- `system.admin.jwt_secret`

Notes:
- The effective route prefix is configured by `system.route_prefix`.
- If the frontend project uses `dudu-admin`, keep `VITE_API_ROUTE_PREFIX` aligned with the effective route prefix to avoid drift between API docs, dev proxy settings, and server routes.
- When `--admin-password` is provided, the script stores `bcrypt(md5(plain_password))` and clears the preset TOTP state for `user_id=1`.
- Before executing `init.sql`, the script rewrites seeded RBAC permission paths to the effective prefix.
- If `--config` writes to a custom path, start the service with `APP_CONFIG_PATH=/path/to/config.json`.

### CI/Automation (Non-interactive)

PostgreSQL example:

```bash
bash init-project.sh \
  --non-interactive --yes \
  --project-dir ./dudu-admin-api \
  --repo-url https://github.com/seakee/dudu-admin-api.git \
  --repo-ref main \
  --env local \
  --dialect postgres \
  --name dudu-admin-api \
  --route-prefix dudu-admin-api \
  --run-mode release \
  --http-port :8080 \
  --default-lang zh-CN \
  --db-host 127.0.0.1 \
  --db-port 5432 \
  --db-name dudu-admin-api \
  --db-user dudu-admin-api \
  --db-password 'CHANGE_ME_DB_PASSWORD' \
  --db-ssl-mode disable \
  --db-timezone Asia/Shanghai \
  --redis-host 127.0.0.1:6379 \
  --redis-auth '' \
  --redis-db 0 \
  --admin-email admin@example.com \
  --admin-phone 13800000000 \
  --admin-username admin \
  --admin-password 'CHANGE_ME_ADMIN_PASSWORD'
```

MySQL example:

```bash
bash init-project.sh \
  --non-interactive --yes \
  --project-dir ./dudu-admin-api \
  --repo-url https://github.com/seakee/dudu-admin-api.git \
  --repo-ref main \
  --env local \
  --dialect mysql \
  --name dudu-admin-api \
  --route-prefix dudu-admin-api \
  --run-mode release \
  --http-port :8080 \
  --default-lang zh-CN \
  --db-host 127.0.0.1 \
  --db-port 3306 \
  --db-name dudu-admin-api \
  --db-user dudu-admin-api \
  --db-password 'CHANGE_ME_DB_PASSWORD' \
  --redis-host 127.0.0.1:6379 \
  --redis-auth '' \
  --redis-db 0 \
  --admin-email admin@example.com \
  --admin-phone 13800000000 \
  --admin-username admin \
  --admin-password 'CHANGE_ME_ADMIN_PASSWORD'
```

If repository already exists in target path, append:

```bash
--project-dir ./dudu-admin-api --skip-clone
```

Note: `init.sql` resets related tables (includes `DROP TABLE`). Do not run directly in production.
If the PostgreSQL application database is already provisioned but the managed environment does not expose the `postgres` maintenance database, the script checks target-database connectivity first. If you explicitly do not want the script to attempt database creation, append `--no-create-db`.

## Runtime Configuration

### Config Files

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

### Environment Variables

- `RUN_ENV`: selects `bin/configs/{RUN_ENV}.json`, default `local`
- `APP_CONFIG_PATH`: explicit config file path, higher priority than `RUN_ENV`
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

The effective route prefix is configured by `system.route_prefix`; the default value is `dudu-admin-api`.

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
