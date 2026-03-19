# Code Generator Guide

**Languages**: [English](Code-Generator-Guide.md) | [中文](Code-Generator-Guide-zh.md)

## Overview

The code generator creates model and repository boilerplate from SQL files.

Entry point:
- `command/codegen/handler.go`

Default SQL input directory:
- `bin/data/sql`

Default output directories:
- model: `app/model`
- repository: `app/repository`

## Prerequisites

- Go `1.24.x`
- SQL schema files under `bin/data/sql`

## Quick Start

Generate one table:

```bash
go run ./command/codegen/handler.go -name auth_app
```

Generate all SQL files:

```bash
go run ./command/codegen/handler.go
```

Generate one PostgreSQL SQL file:

```bash
go run ./command/codegen/handler.go -dialect=postgres -sql bin/data/sql/postgres -name oauth_app
```

Generate with custom paths:

```bash
go run ./command/codegen/handler.go -sql custom/sql -model custom/model -repo custom/repo
```

## Common Options

| Option | Description |
|---|---|
| `-name` | SQL file name without `.sql` |
| `-sql` | SQL input directory |
| `-model` | Model output directory |
| `-repo` | Repository output directory |
| `-service` | Service output directory (if supported by generator version) |
| `-force` | Overwrite existing files |

## SQL File Requirements

- Use standard MySQL `CREATE TABLE` statements.
- Keep table/column comments if you want meaningful generated field comments.
- Keep SQL file name aligned with generated module name.

Example:

```sql
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
  `user_name` varchar(64) NOT NULL COMMENT 'User name',
  `email` varchar(128) DEFAULT NULL COMMENT 'Email',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Status',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Users';
```

## Generated Artifacts

Typical generated outputs:

- model file in `app/model/<module>/`
- repository file in `app/repository/<module>/`

Generated code usually includes:
- struct fields with tags
- basic CRUD helpers
- repository interface and implementation skeleton

## Required Manual Integration

After generation, you still need to:

1. Wire service logic (`app/service/...`)
2. Add controller handlers (`app/http/controller/...`)
3. Register routes (`app/http/router/...`)
4. Add/update tests
5. Update docs and error-code/i18n mapping if behavior is user-facing

## Repository Rule Reminder

In repository code, prefer model-layer helper methods first.
Direct `db.WithContext(ctx)...` should be limited to:
- transactions
- query shapes not covered by model helpers (`Select`, `Pluck`, `Joins`)

## Verification

Run at least:

```bash
gofmt -w .
go test ./...
```

Recommended for medium/large changes:

```bash
go test -race ./...
```

## Related Docs

- [Development Guide](Development-Guide.md)
- [Architecture Design](Architecture-Design.md)
- [API Documentation](API-Documentation.md)
- [Codegen README](../command/codegen/README.md)
