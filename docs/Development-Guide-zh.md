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

### 一键初始化（含数据库与超级管理员种子数据）

`bin/data/sql/{dialect}/init.sql` 已包含完整建表与后台超级管理员初始化数据。可使用脚本一键初始化：

```bash
# 仓库内执行：默认进入交互式向导，生成最小可运行配置并初始化数据库
./scripts/init-project.sh

# 远程下载并执行（不需要提前 clone 仓库）
curl -fsSL https://raw.githubusercontent.com/seakee/dudu-admin-api/main/scripts/init-project.sh -o init-project.sh
bash init-project.sh

# 非交互模式（CI/自动化）
bash init-project.sh --non-interactive --yes \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name dudu-admin-api --db-user dudu-admin-api --db-password 'your-password'
```

如目标目录已存在仓库，可追加：

```bash
--project-dir ./dudu-admin-api --skip-clone
```

脚本会生成最小化可执行配置文件（`bin/configs/{RUN_ENV}.json`），并设置：
- `system.name`
- `system.route_prefix`
- `system.run_mode`
- `system.http_port`
- `system.api_prefix`
- `system.default_lang`
- `system.jwt_secret`
- `system.admin.jwt_secret`

补充说明：
- 生效路由前缀遵循 `system.route_prefix` 优先、`system.api_prefix` 回退的规则。
- 若设置 `--admin-password`，脚本会写入 `bcrypt(md5(明文密码))`，并清理 `user_id=1` 的预置 TOTP 状态。
- 初始化脚本会在执行 `init.sql` 前，将种子 RBAC 权限路径改写为当前生效前缀。
- 若通过 `--config` 写入自定义路径，请使用 `APP_CONFIG_PATH=/path/to/config.json` 启动服务。

### CI/自动化（非交互）

PostgreSQL 示例：

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
  --api-prefix dudu-admin-api \
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

MySQL 示例：

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
  --api-prefix dudu-admin-api \
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

若仓库已在目标目录，可追加：

```bash
--project-dir ./dudu-admin-api --skip-clone
```

注意：`init.sql` 会重置相关表（包含 `DROP TABLE`），请勿在生产环境直接执行。
若 PostgreSQL 应用库已预先创建、但托管环境不开放 `postgres` 维护库，脚本会优先检测目标库可连通性；若你明确不希望尝试建库，也可追加 `--no-create-db`。

## 运行配置

### 配置文件

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

### 环境变量

- `RUN_ENV`：选择 `bin/configs/{RUN_ENV}.json`，默认 `local`
- `APP_CONFIG_PATH`：显式配置文件路径，优先级高于 `RUN_ENV`
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

生效路由前缀优先使用 `system.route_prefix`，若为空则回退到 `system.api_prefix`；默认值为 `dudu-admin-api`。

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
