# Makefile 使用指南

## 概述

项目通过 `Makefile` 提供常用开发与运行命令。
本文档内容与仓库当前 `Makefile` 保持一致。

## 前提条件

- Go `1.24.x`
- `gofmt`
- `goimports`（`make fmt` 会调用）
- Docker（使用 Docker 相关目标时）

安装 `goimports`：

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

## 可用目标

### 开发目标

| 目标 | 说明 |
|---|---|
| `make all` | 依次执行 `fmt`、`test`、`build` |
| `make fmt` | 执行 `gofmt -w .` 和 `goimports -w .` |
| `make test` | 执行 `go test -v ./...` |
| `make build` | 生成 `./bin/${APP_NAME}` |
| `make run` | 运行 `./bin/${APP_NAME}` |
| `make clean` | 删除构建产物 |

### Docker 目标

| 目标 | 说明 |
|---|---|
| `make docker-build` | 构建 `${IMAGE_NAME}` 镜像 |
| `make docker-run` | 运行 `${APP_NAME}` 容器 |
| `make docker-clean` | 停止并删除 `${APP_NAME}` 容器 |

## 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `APP_NAME` | `dudu-admin-api` | 二进制和容器名称 |
| `TZ` | `Asia/Shanghai` | Docker 构建时区参数 |
| `IMAGE_NAME` | `${APP_NAME}:latest` | Docker 镜像名 |
| `CONFIG_DIR` | `${PWD}/bin/configs` | 容器配置挂载目录 |
| `RUN_ENV` | `local` | 传入容器运行环境 |

## 示例

基础流程：

```bash
make all
make run
```

Docker 流程：

```bash
make docker-build
RUN_ENV=prod make docker-run
make docker-clean
```

自定义名称：

```bash
APP_NAME=dudu-admin-api-dev make build
IMAGE_NAME=my-registry/dudu-admin-api:v1.0.0 make docker-build
```

## 常见问题

`goimports: command not found`：

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

`make run` 找不到二进制：

```bash
make build
make run
```

Docker 权限问题：

```bash
sudo make docker-build
sudo make docker-run
```

## 相关文档

- [make.sh 使用指南](make.sh-Usage-zh.md)
- [开发指南](Development-Guide-zh.md)
- [部署指南](Deployment-Guide-zh.md)
