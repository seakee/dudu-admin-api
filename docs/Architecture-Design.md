# Architecture Design

**Languages**: [English](Architecture-Design.md) | [中文](Architecture-Design-zh.md)

## Overview

`dudu-admin-api` is an HTTP-centric admin backend built on Gin, GORM, Redis, and Kafka.
The architecture emphasizes clear layering and explicit middleware boundaries.

## Startup and Runtime Flow

Startup chain:

`main.go` -> `config.LoadConfig` -> `bootstrap.NewApp` -> `App.Start`

Runtime HTTP path:

`bootstrap/http.go` -> `app/http/router`

## Route Topology

The effective route prefix uses `system.route_prefix` first and falls back to `system.api_prefix` (default: `dudu-admin-api`).

Primary groups:
- `/{apiPrefix}/external/...`
- `/{apiPrefix}/internal/...`
- `/{apiPrefix}/internal/admin/...`
- `/{apiPrefix}/internal/service/...`

## Layering Contract

Required order:

Model -> Repository -> Service -> Controller

### Controller Layer

Location: `app/http/controller/`

Responsibilities:
- request parsing and validation
- invoking service methods
- unified response output

### Service Layer

Location: `app/service/`

Responsibilities:
- business rules and orchestration
- cross-repository coordination
- context propagation

Constraints:
- should accept `context.Context`
- should not depend on Gin request/response handling

### Repository Layer

Location: `app/repository/`

Responsibilities:
- persistence access and query composition

Constraints:
- reuse model-layer helper methods first (`Where`, `First`, `List`, `Create`, `Updates`, `Count`, etc.)
- direct `db.WithContext(ctx)...` is reserved for:
  - transactions
  - query patterns not covered by model helpers (`Select`, `Pluck`, `Joins`)

### Model Layer

Location: `app/model/`

Responsibilities:
- table/entity definitions
- shared CRUD helper methods
- pagination/sorting helper patterns used by repositories

## Middleware Boundaries

Core middleware includes:
- trace propagation (`SetTraceID`)
- CORS
- app auth (`CheckAppAuth`)
- admin auth (`CheckAdminAuth`)
- operation logging (`SaveOperationRecord`)

Admin system routes under `/{apiPrefix}/internal/admin/system/*` use both auth and operation-record controls.
Admin auth routes under `/{apiPrefix}/internal/admin/auth/*` use route-specific auth controls and do not apply `SaveOperationRecord` by default.
Sensitive payloads must not be exposed in logs.

## Configuration Design

Runtime config files:
- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

Runtime environment variables:
- `RUN_ENV` selects config profile
- `APP_NAME` optionally overrides `system.name`

## Error and i18n Model

- Error code definitions live in `app/pkg/e/*.go`
- i18n messages live in:
  - `bin/lang/en-US.json`
  - `bin/lang/zh-CN.json`

New error codes must update both language files.

## Verification Baseline

Before finalizing architecture-impacting changes:

```bash
gofmt -w .
go test ./...
```

Recommended for medium/large scope:

```bash
go test -race ./...
```

## Related Docs

- [Development Guide](Development-Guide.md)
- [API Documentation](API-Documentation.md)
- [Admin Auth](Admin-Auth.md)
- [Admin System Management](Admin-System-Management.md)
