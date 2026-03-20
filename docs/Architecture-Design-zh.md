# 架构设计

**语言版本**: [English](Architecture-Design.md) | [中文](Architecture-Design-zh.md)

## 概述

`dudu-admin-api` 是一个以 HTTP 为核心的后台管理服务，基于 Gin、GORM、Redis、Kafka 构建。
架构重点是分层清晰和中间件边界明确。

## 启动与运行链路

启动链路：

`main.go` -> `config.LoadConfig` -> `bootstrap.NewApp` -> `App.Start`

HTTP 运行链路：

`bootstrap/http.go` -> `app/http/router`

## 路由拓扑

生效路由前缀优先使用 `system.route_prefix`，若为空则回退到 `system.api_prefix`（默认 `dudu-admin-api`）。

主要分组：
- `/{apiPrefix}/external/...`
- `/{apiPrefix}/internal/...`
- `/{apiPrefix}/internal/admin/...`
- `/{apiPrefix}/internal/service/...`

## 分层契约

固定顺序：

Model -> Repository -> Service -> Controller

### Controller 层

目录：`app/http/controller/`

职责：
- 请求解析与参数校验
- 调用 service
- 统一响应输出

### Service 层

目录：`app/service/`

职责：
- 业务规则与业务编排
- 跨 repository 协作
- 上下文传递

约束：
- 使用 `context.Context`
- 不依赖 Gin 请求/响应处理细节

### Repository 层

目录：`app/repository/`

职责：
- 数据持久化访问与查询组织

约束：
- 优先复用 model helper（`Where`、`First`、`List`、`Create`、`Updates`、`Count` 等）
- 直接 `db.WithContext(ctx)...` 仅用于：
  - 事务
  - model helper 无法覆盖的查询（`Select`、`Pluck`、`Joins`）

### Model 层

目录：`app/model/`

职责：
- 表结构/实体定义
- 通用 CRUD helper
- 仓库层复用的分页/排序辅助能力

## 中间件边界

核心中间件包括：
- 链路追踪（`SetTraceID`）
- CORS
- 应用鉴权（`CheckAppAuth`）
- 后台鉴权（`CheckAdminAuth`）
- 操作日志（`SaveOperationRecord`）

`/{apiPrefix}/internal/admin/system/*` 路由同时经过后台鉴权与操作日志控制。
`/{apiPrefix}/internal/admin/auth/*` 路由按子路由规则挂载鉴权中间件，默认不经过 `SaveOperationRecord`。
敏感数据不能直接落入操作日志。

## 配置设计

运行配置文件：
- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

运行环境变量：
- `RUN_ENV` 选择配置环境
- `APP_NAME` 可选覆盖 `system.name`

## 错误码与国际化

- 错误码定义在 `app/pkg/e/*.go`
- 语言文件位于：
  - `bin/lang/en-US.json`
  - `bin/lang/zh-CN.json`

新增错误码需同步更新中英文语言文件。

## 验证基线

涉及架构相关改动时，至少执行：

```bash
gofmt -w .
go test ./...
```

中大改动建议执行：

```bash
go test -race ./...
```

## 相关文档

- [开发指南](Development-Guide-zh.md)
- [API 文档](API-Documentation-zh.md)
- [后台鉴权文档](Admin-Auth-zh.md)
- [系统管理接口文档](Admin-System-Management-zh.md)
