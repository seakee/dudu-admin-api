# 开发指南

**语言版本**: [English](Development-Guide.md) | [中文](Development-Guide-zh.md)

## 前提条件

- Go `1.24.x`（项目当前为 `go 1.24.13`）
- MySQL 与 Redis
- `make` 与标准 Go 工具链（`gofmt`、`go test`）

## 项目初始化

```bash
git clone https://github.com/seakee/dudu-admin-api.git
cd dudu-admin-api

go mod download
cp bin/configs/local.json.default bin/configs/local.json
# 按需修改 bin/configs/local.json

make build
make run
```

## 运行配置

### 配置文件

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

### 环境变量

- `RUN_ENV`：选择 `bin/configs/{RUN_ENV}.json`，默认 `local`
- `APP_NAME`：运行时覆盖 `system.name`

## 架构与分层

### 启动链路

`main.go` -> `bootstrap.NewApp` -> `App.Start` -> `bootstrap/http.go` -> `app/http/router`

### 分层顺序

Model -> Repository -> Service -> Controller

- Controller 不应直接调用 Repository。
- Service 使用 `context.Context`，不处理 Gin 请求/响应细节。
- Repository 只负责数据访问，不承担业务编排。

### Repository 层 DB 访问约束

优先复用 model 层方法（如 `Where`、`First`、`List`、`Create`、`Updates`、`Count`、`FindWithPagination`、`BatchInsert`）。

Repository 内直接 `db.WithContext(ctx)...` 仅用于：
- 事务（`Transaction(...)`）
- model helper 无法覆盖的查询（如 `Select`、`Pluck`、`Joins`）

## 路由结构

默认 API 前缀为 `dudu-admin-api`（`system.api_prefix`）。

- `/{apiPrefix}/external/...`
- `/{apiPrefix}/internal/...`
- `/{apiPrefix}/internal/admin/...`
- `/{apiPrefix}/internal/service/...`

新增接口时需明确：
- 鉴权中间件（`CheckAppAuth` 和/或 `CheckAdminAuth`）
- 是否记录操作日志（`SaveOperationRecord`）
- 敏感字段是否需要脱敏或不入日志

## 功能开发流程

1. 定义或更新 Model
2. 基于 model helper 实现 Repository
3. 实现 Service 业务逻辑
4. 新增 Controller 处理器
5. 在正确模块下注册路由
6. 编写测试
7. 若涉及用户可见行为，更新中英文文档与错误码/i18n 映射

## 代码生成

生成器入口：`command/codegen/handler.go`

```bash
# 按文件名生成
go run ./command/codegen/handler.go -name auth_app

# 生成单个 PostgreSQL SQL 文件
go run ./command/codegen/handler.go -dialect=postgres -sql bin/data/sql/postgres -name oauth_app

# 扫描 SQL 全量生成
go run ./command/codegen/handler.go
```

默认 SQL 目录：
- `bin/data/sql`

生成后仍需手工完成：
- service 层接线
- controller/router 接线
- 测试补齐
- 文档与错误码更新（按需要）

## 测试与格式化

提交前至少执行：

```bash
gofmt -w .
go test ./...
```

中大改动建议执行：

```bash
go test -race ./...
```

## 构建与运行命令

```bash
make fmt
make test
make build
make run
```

Shell 脚本等价命令：

```bash
./scripts/make.sh all
./scripts/make.sh run
```

## 相关文档

- [架构设计](Architecture-Design-zh.md)
- [API 文档](API-Documentation-zh.md)
- [后台鉴权文档](Admin-Auth-zh.md)
- [系统管理接口文档](Admin-System-Management-zh.md)
- [代码生成器指南](Code-Generator-Guide-zh.md)
- [Makefile 使用指南](Makefile-Usage-zh.md)
- [make.sh 使用指南](make.sh-Usage-zh.md)
- [部署指南](Deployment-Guide-zh.md)
