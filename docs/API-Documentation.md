# API Documentation

**Languages**: [English](API-Documentation.md) | [中文](API-Documentation-zh.md)

## Overview

This document provides API entry points and common contracts.
Detailed admin API behavior is documented in:

- [Admin Auth](Admin-Auth.md)
- [Admin System Management](Admin-System-Management.md)

## Base URL

Local:

```text
http://localhost:8080
```

Full route prefix:

```text
/{apiPrefix}/...
```

Default `apiPrefix`: `dudu-admin-api`.

## Route Groups

### External

- `/{apiPrefix}/external/ping`
- `/{apiPrefix}/external/service/auth/token`
- `/{apiPrefix}/external/service/auth/app`

### Internal Service

- `/{apiPrefix}/internal/ping`
- `/{apiPrefix}/internal/service/auth/token`
- `/{apiPrefix}/internal/service/auth/app`

### Internal Admin Auth

Mounted under:

- `/{apiPrefix}/internal/admin/auth/...`

See full route list and flow:

- [Admin Auth](Admin-Auth.md)

### Internal Admin System

Mounted under:

- `/{apiPrefix}/internal/admin/system/...`

Main modules:
- `menu`
- `permission`
- `role`
- `user`
- `record`

See full route list and payload contracts:

- [Admin System Management](Admin-System-Management.md)

## Authentication

### App APIs

Protected app APIs use:

```text
Authorization: Bearer <app-token>
```

Token endpoint:

```text
POST /{apiPrefix}/external/service/auth/token
```

### Admin APIs

Admin APIs use `CheckAdminAuth`.
Token can be provided by:
- `Authorization: Bearer <admin-token>`
- Cookie `admin-token`

## Operation Logging

Routes under `/{apiPrefix}/internal/admin/system/*` are recorded by `SaveOperationRecord`.
Admin auth routes (`/{apiPrefix}/internal/admin/auth/*`) do not apply `SaveOperationRecord` by default.
Sensitive payloads should be redacted or omitted.

## Common Response Format

```json
{
  "code": 0,
  "message": "ok",
  "data": {}
}
```

## Health Check

External:

```text
GET /{apiPrefix}/external/ping
```

Internal:

```text
GET /{apiPrefix}/internal/ping
```

## Error Codes and i18n

- Error code definitions: `app/pkg/e/*.go`
- i18n message files:
  - `bin/lang/en-US.json`
  - `bin/lang/zh-CN.json`

When adding new error codes, update both language files.

## Related Docs

- [Development Guide](Development-Guide.md)
- [Deployment Guide](Deployment-Guide.md)
- [Admin Auth](Admin-Auth.md)
- [Admin System Management](Admin-System-Management.md)
