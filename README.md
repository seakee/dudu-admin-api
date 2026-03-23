# Dudu Admin API

**Languages**: [English](README.md) | [中文](README-zh.md)

A ready-to-use Go admin backend for internal tools, management consoles, and operations dashboards.

## Overview

`dudu-admin-api` helps you launch a Dudu-style admin system faster with the backend capabilities most teams need from day one.
It brings together admin auth, RBAC, menus, user and role management, permissions, and audit logs so you can focus on business workflows instead of rebuilding common admin infrastructure.

- Built for: internal tools, management consoles, and operations dashboards
- Core capabilities: admin auth, RBAC, menus, users, roles, permissions, and operation records
- Related frontend: `https://github.com/seakee/dudu-admin`
- Repository: `https://github.com/seakee/dudu-admin-api`
- Project background: extracted from `seakee/dudu-admin-api:admin`
- Import baseline: `6df6cfe8aeeb27eaaaee74c7fb7e520af5f8feb2`

## Features

- Ready-to-use admin backend baseline for new internal systems and existing projects
- Built-in admin auth, RBAC, menus, users, roles, and permission management
- Fast bootstrap flow for generating a project or initializing the current repository
- Straightforward frontend integration with the related `dudu-admin` project

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

### Single-entry Bootstrap / Project Generation

```bash
# Remote download and generate the default ./dudu-admin-api directory
curl -fsSL https://raw.githubusercontent.com/seakee/dudu-admin-api/main/scripts/init-project.sh -o init-project.sh
bash init-project.sh

# Remote download and generate a custom project
bash init-project.sh --project-name my-api --module-name github.com/acme/my-api

# Run inside repository: initialize the current repository
./scripts/init-project.sh
```

`init-project.sh` is the single recommended bootstrap entry. It can either generate a new project from the template or initialize the current/existing repository.
The script generates a minimal runnable config (`bin/configs/{RUN_ENV}.json`), initializes database tables/data, and seeds super-admin records.
When `--admin-password` overrides `user_id=1`, the script stores the password using the admin login credential format and clears the preset TOTP state.
If `--config` writes to a custom path, start the service with `APP_CONFIG_PATH=/path/to/config.json`.
If `--module-name` is not a remote repository path and you are not running inside the template repository, pass `--repo-url` explicitly.

### Non-interactive Mode

```bash
# Generate and initialize a new project non-interactively
bash init-project.sh --non-interactive --yes \
  --project-name my-api \
  --module-name github.com/acme/my-api \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name my-api --db-user my-api --db-password 'CHANGE_ME_DB_PASSWORD'

# Initialize an existing repository non-interactively
bash init-project.sh --non-interactive --yes \
  --project-dir ./dudu-admin-api --skip-clone \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name dudu-admin-api --db-user dudu-admin-api --db-password 'CHANGE_ME_DB_PASSWORD'
```

### Bootstrap Troubleshooting

Database connectivity (PostgreSQL, check the target database first):

```bash
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d dudu-admin-api -c 'select current_database();'
```

Auto-create path check (PostgreSQL, only when the target database does not exist and you rely on the script to create it):

```bash
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d postgres -c 'select version();'
```

Database connectivity (MySQL):

```bash
mysql -h 127.0.0.1 -P 3306 -u dudu-admin-api -p -e 'select version();'
```

Database privilege check (PostgreSQL, only when you rely on the script to create the database):

```bash
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d postgres -c 'create database dudu_admin_api_perm_test;'
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d postgres -c 'drop database if exists dudu_admin_api_perm_test;'
```

Database privilege check (MySQL):

```bash
mysql -h 127.0.0.1 -P 3306 -u dudu-admin-api -p -e 'create database if not exists dudu_admin_api_perm_test; drop database dudu_admin_api_perm_test;'
```

Redis connectivity:

```bash
redis-cli -h 127.0.0.1 -p 6379 ping
```

SQL file accessibility:

```bash
ls -l ./dudu-admin-api/bin/data/sql/postgres/init.sql
ls -l ./dudu-admin-api/bin/data/sql/mysql/init.sql
```

## Runtime Configuration

### Environment Variables

| Variable | Description | Default |
|---|---|---|
| `APP_CONFIG_PATH` | Explicit config file path, higher priority than `RUN_ENV` | empty |
| `RUN_ENV` | Config profile (`bin/configs/{RUN_ENV}.json`) | `local` |
| `APP_NAME` | Override `system.name` at runtime | from config |

### Config Files

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

The bootstrap script generates required minimal fields including:
- `system.name`
- `system.route_prefix`
- `system.run_mode`
- `system.http_port`
- `system.default_lang`
- `system.jwt_secret`
- `system.admin.jwt_secret`

### API Prefix

The effective route prefix is configured by `system.route_prefix`.  
Default: `dudu-admin-api`.

## Frontend Integration

- Related frontend project: [`dudu-admin`](https://github.com/seakee/dudu-admin)
- Recommended local frontend address: `http://localhost:3000`
- Recommended local backend address: `http://127.0.0.1:8080`

When using the default local setup:

- keep frontend `VITE_API_ROUTE_PREFIX=/dudu-admin-api` aligned with backend `system.route_prefix`
- keep frontend `VITE_API_BASE_URL=/` and let the Vite dev server proxy `/{apiPrefix}` requests to `127.0.0.1:8080`
- keep `system.admin.oauth.redirect_url` pointing to the current frontend callback route `/auth/callback`, for example `http://localhost:3000/auth/callback`
- keep `system.admin.webauthn.rp_origins` including `http://localhost:3000` for local Passkey debugging

Frontend README and local setup:

- [dudu-admin README](https://github.com/seakee/dudu-admin/blob/main/README.md)
- [dudu-admin README (ZH)](https://github.com/seakee/dudu-admin/blob/main/README-zh.md)

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
