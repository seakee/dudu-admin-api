# make.sh 使用指南

## 概述

`scripts/make.sh` 是 `Makefile` 的 shell 等价入口。
在不使用 `make` 的场景下可以直接使用该脚本。

## 前提条件

- Go `1.24.x`
- `gofmt`
- `goimports`
- Docker（使用 Docker 命令时）

赋予执行权限：

```bash
chmod +x scripts/make.sh
```

## 可用命令

| 命令 | 说明 |
|---|---|
| `./scripts/make.sh all` | 依次执行 `fmt`、`test`、`build` |
| `./scripts/make.sh fmt` | 执行 `gofmt -w .` 和 `goimports -w .` |
| `./scripts/make.sh test` | 执行 `go test -v ./...` |
| `./scripts/make.sh build` | 生成 `./bin/${APP_NAME}` |
| `./scripts/make.sh run` | 以 `RUN_ENV` 运行二进制 |
| `./scripts/make.sh docker-build` | 构建 Docker 镜像 |
| `./scripts/make.sh docker-run` | 运行 Docker 容器 |
| `./scripts/make.sh docker-clean` | 停止并删除容器 |
| `./scripts/make.sh clean` | 删除构建产物 |

## 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `APP_NAME` | `dudu-admin-api` | 二进制和容器名称 |
| `IMAGE_NAME` | `${APP_NAME}:latest` | Docker 镜像名称 |
| `CONFIG_DIR` | `${PWD}/bin/configs` | 配置挂载目录 |
| `TZ` | `Asia/Shanghai` | Docker 构建时区 |
| `RUN_ENV` | `local` | 运行环境 |

## 示例

```bash
./scripts/make.sh all
./scripts/make.sh run
```

```bash
RUN_ENV=prod ./scripts/make.sh docker-build
RUN_ENV=prod ./scripts/make.sh docker-run
./scripts/make.sh docker-clean
```

```bash
APP_NAME=dudu-admin-api-dev ./scripts/make.sh build
IMAGE_NAME=my-registry/dudu-admin-api:v1.0.0 ./scripts/make.sh docker-build
```

## 常见问题

无执行权限：

```bash
chmod +x scripts/make.sh
```

`goimports: command not found`：

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

Docker daemon 不可用：

```bash
docker info
```

## 相关文档

- [Makefile 使用指南](Makefile-Usage-zh.md)
- [开发指南](Development-Guide-zh.md)
- [部署指南](Deployment-Guide-zh.md)
