# 代码生成器指南

**语言版本**: [English](Code-Generator-Guide.md) | [中文](Code-Generator-Guide-zh.md)

## 概述

代码生成器用于根据 SQL 文件快速生成 model 与 repository 基础代码。

入口文件：
- `command/codegen/handler.go`

默认 SQL 输入目录：
- `bin/data/sql`

默认输出目录：
- model：`app/model`
- repository：`app/repository`

## 前提条件

- Go `1.24.x`
- SQL 表结构文件位于 `bin/data/sql`

## 快速开始

按单表生成：

```bash
go run ./command/codegen/handler.go -name auth_app
```

按目录全量生成：

```bash
go run ./command/codegen/handler.go
```

生成单个 PostgreSQL SQL 文件：

```bash
go run ./command/codegen/handler.go -dialect=postgres -sql bin/data/sql/postgres -name oauth_app
```

自定义路径生成：

```bash
go run ./command/codegen/handler.go -sql custom/sql -model custom/model -repo custom/repo
```

## 常用参数

| 参数 | 说明 |
|---|---|
| `-name` | SQL 文件名（不含 `.sql`） |
| `-sql` | SQL 输入目录 |
| `-model` | model 输出目录 |
| `-repo` | repository 输出目录 |
| `-service` | service 输出目录（取决于生成器版本） |
| `-force` | 覆盖已存在文件 |

## SQL 文件要求

- 使用标准 MySQL `CREATE TABLE` 语句。
- 建议保留表注释与字段注释，便于生成可读代码注释。
- SQL 文件名建议与目标模块命名保持一致。

示例：

```sql
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_name` varchar(64) NOT NULL COMMENT '用户名',
  `email` varchar(128) DEFAULT NULL COMMENT '邮箱',
  `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

## 生成产物

典型输出：

- `app/model/<module>/` 下的 model 文件
- `app/repository/<module>/` 下的 repository 文件

生成内容通常包括：
- 带 tag 的结构体字段
- 基础 CRUD helper
- repository 接口与实现骨架

## 生成后的人工集成

生成完成后仍需手工完成：

1. service 逻辑接线（`app/service/...`）
2. controller 处理器编写（`app/http/controller/...`）
3. router 注册（`app/http/router/...`）
4. 测试补齐
5. 若行为用户可见，更新文档与错误码/i18n 映射

## Repository 约束提醒

Repository 层优先调用 model helper。
直接 `db.WithContext(ctx)...` 仅建议用于：
- 事务
- model helper 覆盖不到的查询场景（`Select`、`Pluck`、`Joins`）

## 验证建议

至少执行：

```bash
gofmt -w .
go test ./...
```

中大改动建议：

```bash
go test -race ./...
```

## 相关文档

- [开发指南](Development-Guide-zh.md)
- [架构设计](Architecture-Design-zh.md)
- [API 文档](API-Documentation-zh.md)
- [代码生成器 README](../command/codegen/README_ZH.MD)
