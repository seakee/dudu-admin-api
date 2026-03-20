# Dudu Admin API

**语言版本**: [English](README.md) | [中文](README-zh.md)

## 项目概述

`dudu-admin-api` 是从 `seakee/dudu-admin-api` 的 `admin` 分支拆分出的后台管理后端项目，聚焦后台认证鉴权、用户、角色、权限、菜单、操作记录等能力。

- 仓库地址: `https://github.com/seakee/dudu-admin-api`
- 来源分支: `seakee/dudu-admin-api:admin`
- 导入基线: `6df6cfe8aeeb27eaaaee74c7fb7e520af5f8feb2`

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

### 远程初始化（交互模式）

```bash
curl -fsSL https://raw.githubusercontent.com/seakee/dudu-admin-api/main/scripts/init-project.sh -o init-project.sh
bash init-project.sh
```

脚本支持自动 clone 仓库、生成最小可执行配置文件（`bin/configs/{RUN_ENV}.json`）、初始化数据库表与种子数据，并初始化超级管理员记录。
若通过 `--admin-password` 覆盖 `user_id=1`，脚本会按后台登录口径写入密码，并同步清理预置 TOTP 状态。

### 远程初始化（非交互模式）

```bash
curl -fsSL https://raw.githubusercontent.com/seakee/dudu-admin-api/main/scripts/init-project.sh -o init-project.sh
bash init-project.sh --non-interactive --yes \
  --dialect postgres \
  --db-host 127.0.0.1 --db-port 5432 \
  --db-name dudu-admin-api --db-user dudu-admin-api --db-password 'CHANGE_ME_DB_PASSWORD'
```

说明：若目标目录已存在仓库，可追加 `--project-dir ./dudu-admin-api --skip-clone` 禁止脚本自动 clone。

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
- `system.api_prefix`
- `system.default_lang`
- `system.jwt_secret`
- `system.admin.jwt_secret`

### 路由前缀

生效路由前缀优先使用 `system.route_prefix`，若为空则回退到 `system.api_prefix`。  
默认值: `dudu-admin-api`。

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
