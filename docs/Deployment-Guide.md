# Deployment Guide

**Languages**: [English](Deployment-Guide.md) | [中文](Deployment-Guide-zh.md)

## Prerequisites

- Linux host (recommended)
- Docker 20.10+ (if using container deployment)
- MySQL and Redis accessible from the service
- `bin/configs/prod.json` prepared

## Production Configuration

Create production config from template:

```bash
cp bin/configs/local.json.default bin/configs/prod.json
```

Key fields to review in `bin/configs/prod.json`:
- `system.run_mode` (`release`)
- `system.http_port`
- `system.jwt_secret`
- `system.route_prefix`
- `databases[*]`
- `redis[*]`
- `log`

## Runtime Environment Variables

- `RUN_ENV=prod` to load `bin/configs/prod.json`
- `APP_NAME` optional runtime override

Example:

```bash
export RUN_ENV=prod
export APP_NAME=dudu-admin-api
```

## Deployment Options

### Option A: Binary + Process Manager

```bash
make build
RUN_ENV=prod ./bin/dudu-admin-api
```

Recommended process managers:
- `systemd`
- `supervisord`
- container orchestrator runtime

### Option B: Docker (single container)

Build image:

```bash
make docker-build
```

Run container:

```bash
RUN_ENV=prod make docker-run
```

This uses `Makefile` defaults:
- container name: `dudu-admin-api`
- config mount: `${PWD}/bin/configs:/bin/configs`
- port: `8080:8080`

### Option C: Custom Compose (project-specific)

This repository does not provide a committed `docker-compose.yml` by default.
If your team uses Compose, create a local compose file and keep it in your infra repository or local ops directory.

## Health Check and Smoke Test

Public health endpoint:

```bash
API_PREFIX="${API_PREFIX:-dudu-admin-api}"
curl -i "http://127.0.0.1:8080/${API_PREFIX}/external/ping"
```

Internal health endpoint:

```bash
API_PREFIX="${API_PREFIX:-dudu-admin-api}"
curl -i "http://127.0.0.1:8080/${API_PREFIX}/internal/ping"
```

If `system.route_prefix` is customized, export `API_PREFIX` with that effective value before running the commands.

## Logging and Monitoring

- Enable file logging via `log.driver=file` and `log.path`
- Keep operation records enabled for admin routes (`SaveOperationRecord`)
- Configure `monitor.panic_robot` and `notify` channels for panic alerts

## Security Checklist

- Use strong values for `system.jwt_secret` and admin OAuth/passkey related secrets
- Restrict MySQL/Redis network exposure
- Protect config files and logs with proper OS permissions
- Ensure sensitive payloads are redacted or omitted in operation logs

## Backup Recommendations

- Database backup (daily + retention policy)
- `bin/configs` backup with version control in secure private storage
- Restore drill in staging before production rollout

## Related Docs

- [Development Guide](Development-Guide.md)
- [API Documentation](API-Documentation.md)
- [Admin Auth](Admin-Auth.md)
- [Admin System Management](Admin-System-Management.md)
