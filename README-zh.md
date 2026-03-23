# Dudu Admin API

**语言版本**: [English](README.md) | [中文](README-zh.md)

一个开箱可用的 Go 管理后台后端，适合内部管理平台、管理控制台与运营后台。

## 项目概述

`dudu-admin-api` 帮助你更快搭建 Dudu 风格后台系统，提供多数团队从第一天就会用到的后台基础能力。
它将后台认证鉴权、RBAC、菜单、用户与角色管理、权限控制、操作记录整合在一起，让你把精力放在业务流程，而不是重复搭建通用后台基础设施。

- 适用场景: 内部管理平台、管理控制台、运营后台
- 核心能力: 后台认证鉴权、RBAC、菜单、用户、角色、权限、操作记录
- 配套前端: `https://github.com/seakee/dudu-admin`
- 仓库地址: `https://github.com/seakee/dudu-admin-api`
- 项目来源: 从 `seakee/dudu-admin-api:admin` 拆分而来
- 导入基线: `6df6cfe8aeeb27eaaaee74c7fb7e520af5f8feb2`

## 产品特性

- 为新项目和现有项目提供开箱可用的后台基础能力
- 内置后台认证鉴权、RBAC、菜单、用户、角色与权限管理
- 提供快速初始化流程，可生成项目或直接初始化当前仓库
- 可与配套前端 `dudu-admin` 直接配合完成前后端联调

## 快速开始

### 运行依赖

- Go `1.24.x`
- MySQL 和 Redis（本地或远端）

### 本地运行

```bash
git clone https://github.com/seakee/dudu-admin-api.git
cd dudu-admin-api

go mod download
cp bin/configs/local.json.default bin/configs/local.json
# 按需修改 bin/configs/local.json

make build
make run
```

### 单入口初始化 / 生成

```bash
# 远程下载并直接生成默认目录 ./dudu-admin-api
curl -fsSL https://raw.githubusercontent.com/seakee/dudu-admin-api/main/scripts/init-project.sh -o init-project.sh
bash init-project.sh

# 远程下载并生成自定义项目
bash init-project.sh --project-name my-api --module-name github.com/acme/my-api

# 仓库内执行：初始化当前仓库
./scripts/init-project.sh
```

`init-project.sh` 是唯一推荐的项目引导入口，既可以从模板生成新项目，也可以初始化当前/现有仓库。
脚本会生成最小可执行配置文件（`bin/configs/{RUN_ENV}.json`）、初始化数据库表与种子数据，并初始化超级管理员记录。
若通过 `--admin-password` 覆盖 `user_id=1`，脚本会按后台登录口径写入密码，并同步清理预置 TOTP 状态。
若通过 `--config` 写入自定义路径，请使用 `APP_CONFIG_PATH=/path/to/config.json` 启动服务。
若 `--module-name` 不是远端仓库路径，且当前不在模板仓库内执行，请显式传入 `--repo-url`。

### 非交互模式

```bash
# 非交互生成并初始化新项目
bash init-project.sh --non-interactive --yes \
  --project-name my-api \
  --module-name github.com/acme/my-api \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name my-api --db-user my-api --db-password 'CHANGE_ME_DB_PASSWORD'

# 非交互初始化现有仓库
bash init-project.sh --non-interactive --yes \
  --project-dir ./dudu-admin-api --skip-clone \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name dudu-admin-api --db-user dudu-admin-api --db-password 'CHANGE_ME_DB_PASSWORD'
```

### 初始化失败排查

数据库连通性（PostgreSQL，优先检查目标库）：

```bash
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d dudu-admin-api -c 'select current_database();'
```

自动建库链路检查（PostgreSQL，仅当目标库不存在且需要脚本自动建库时）：

```bash
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d postgres -c 'select version();'
```

数据库连通性（MySQL）：

```bash
mysql -h 127.0.0.1 -P 3306 -u dudu-admin-api -p -e 'select version();'
```

数据库权限检查（PostgreSQL，仅当依赖脚本自动建库时）：

```bash
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d postgres -c 'create database dudu_admin_api_perm_test;'
PGPASSWORD='YOUR_DB_PASSWORD' psql -h 127.0.0.1 -p 5432 -U dudu-admin-api -d postgres -c 'drop database if exists dudu_admin_api_perm_test;'
```

数据库权限检查（MySQL）：

```bash
mysql -h 127.0.0.1 -P 3306 -u dudu-admin-api -p -e 'create database if not exists dudu_admin_api_perm_test; drop database dudu_admin_api_perm_test;'
```

Redis 连通性：

```bash
redis-cli -h 127.0.0.1 -p 6379 ping
```

SQL 文件可访问性：

```bash
ls -l ./dudu-admin-api/bin/data/sql/postgres/init.sql
ls -l ./dudu-admin-api/bin/data/sql/mysql/init.sql
```

## 运行配置

### 环境变量

| 变量 | 说明 | 默认值 |
|---|---|---|
| `APP_CONFIG_PATH` | 显式配置文件路径，优先级高于 `RUN_ENV` | 空 |
| `RUN_ENV` | 读取 `bin/configs/{RUN_ENV}.json` | `local` |
| `APP_NAME` | 运行时覆盖 `system.name` | 使用配置文件值 |

### 配置文件

- `bin/configs/local.json`
- `bin/configs/dev.json`
- `bin/configs/prod.json`

初始化脚本会生成最小必需字段，包括：
- `system.name`
- `system.route_prefix`
- `system.run_mode`
- `system.http_port`
- `system.default_lang`
- `system.jwt_secret`
- `system.admin.jwt_secret`

### 路由前缀

生效路由前缀由 `system.route_prefix` 配置。  
默认值: `dudu-admin-api`。

## 前后端联调

- 配套前端项目: [`dudu-admin`](https://github.com/seakee/dudu-admin)
- 推荐本地前端地址: `http://localhost:3000`
- 推荐本地后端地址: `http://127.0.0.1:8080`

采用默认本地联调方案时，建议保持以下配置一致：

- 前端 `VITE_API_ROUTE_PREFIX=/dudu-admin-api` 与后端 `system.route_prefix` 对齐
- 前端 `VITE_API_BASE_URL=/`，通过 Vite 开发代理把 `/{apiPrefix}` 请求转发到 `127.0.0.1:8080`
- 本地 OAuth 回调调试时，`system.admin.oauth.redirect_url` 应指向当前前端回调路由 `/auth/callback`，例如 `http://localhost:3000/auth/callback`
- 本地 Passkey 调试时，`system.admin.webauthn.rp_origins` 包含 `http://localhost:3000`

前端 README 与本地启动说明：

- [dudu-admin README](https://github.com/seakee/dudu-admin/blob/main/README.md)
- [dudu-admin README（中文）](https://github.com/seakee/dudu-admin/blob/main/README-zh.md)

## 架构说明

### 启动链路

`main.go` -> `bootstrap.NewApp` -> `App.Start` -> `bootstrap/http.go` -> `app/http/router`

### 路由根

- `/{apiPrefix}/external/...`
- `/{apiPrefix}/internal/...`
- `/{apiPrefix}/internal/admin/...`
- `/{apiPrefix}/internal/service/...`

### 分层约束

Model -> Repository -> Service -> Controller。

- Controller 不应直接调用 Repository。
- Service 使用 `context.Context`，不直接依赖 Gin 请求/响应对象。

## 开发命令

```bash
make fmt
make test
make build
make run

make docker-build
make docker-run
make docker-clean
```

Shell 脚本等价命令：

```bash
./scripts/make.sh all
./scripts/make.sh run
```

## 文档索引

### 入口

- [文档首页（中文）](docs/Home-zh.md)
- [Docs Home (EN)](docs/Home.md)

### 核心指南

- [架构设计（中文）](docs/Architecture-Design-zh.md)
- [Architecture Design (EN)](docs/Architecture-Design.md)
- [开发指南（中文）](docs/Development-Guide-zh.md)
- [Development Guide (EN)](docs/Development-Guide.md)
- [部署指南（中文）](docs/Deployment-Guide-zh.md)
- [Deployment Guide (EN)](docs/Deployment-Guide.md)

### API 与业务文档

- [API 文档（中文）](docs/API-Documentation-zh.md)
- [API Documentation (EN)](docs/API-Documentation.md)
- [后台鉴权文档（中文）](docs/Admin-Auth-zh.md)
- [Admin Auth (EN)](docs/Admin-Auth.md)
- [系统管理接口（中文）](docs/Admin-System-Management-zh.md)
- [Admin System Management (EN)](docs/Admin-System-Management.md)

### 工具文档

- [代码生成器指南（中文）](docs/Code-Generator-Guide-zh.md)
- [Code Generator Guide (EN)](docs/Code-Generator-Guide.md)
- [Makefile 使用指南](docs/Makefile-Usage-zh.md)
- [make.sh 使用指南](docs/make.sh-Usage-zh.md)

## 贡献

详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

MIT License，详见 [LICENSE](LICENSE)。
