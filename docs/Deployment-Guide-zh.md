# 部署指南

**语言版本**: [English](Deployment-Guide.md) | [中文](Deployment-Guide-zh.md)

## 前提条件

- Linux 主机（推荐）
- Docker 20.10+（若采用容器部署）
- 服务可访问 MySQL 与 Redis
- 已准备 `bin/configs/prod.json`

## 生产配置

先从模板生成生产配置：

```bash
cp bin/configs/local.json.default bin/configs/prod.json
```

重点检查 `bin/configs/prod.json`：
- `system.run_mode`（`release`）
- `system.http_port`
- `system.jwt_secret`
- `system.route_prefix`
- `databases[*]`
- `redis[*]`
- `log`

## 运行环境变量

- `RUN_ENV=prod`：加载 `bin/configs/prod.json`
- `APP_NAME`：可选运行时覆盖

示例：

```bash
export RUN_ENV=prod
export APP_NAME=dudu-admin-api
```

## 部署方式

### 方案 A：二进制 + 进程守护

```bash
make build
RUN_ENV=prod ./bin/dudu-admin-api
```

推荐配合：
- `systemd`
- `supervisord`
- 容器编排运行时

### 方案 B：Docker 单容器

构建镜像：

```bash
make docker-build
```

运行容器：

```bash
RUN_ENV=prod make docker-run
```

默认行为（来自 `Makefile`）：
- 容器名：`dudu-admin-api`
- 配置挂载：`${PWD}/bin/configs:/bin/configs`
- 端口映射：`8080:8080`

### 方案 C：自定义 Compose（按团队运维规范）

当前仓库默认未提交 `docker-compose.yml`。
若团队使用 Compose，建议在独立运维仓库或本地运维目录维护对应文件。

## 健康检查与冒烟验证

外部健康检查：

```bash
API_PREFIX="${API_PREFIX:-dudu-admin-api}"
curl -i "http://127.0.0.1:8080/${API_PREFIX}/external/ping"
```

内部健康检查：

```bash
API_PREFIX="${API_PREFIX:-dudu-admin-api}"
curl -i "http://127.0.0.1:8080/${API_PREFIX}/internal/ping"
```

若你自定义了 `system.route_prefix`，执行命令前先把 `API_PREFIX` 设置为对应的生效值。

## 日志与监控

- 通过 `log.driver=file` 与 `log.path` 启用文件日志
- 后台管理路由保留 `SaveOperationRecord` 操作日志记录
- 配置 `monitor.panic_robot` 与 `notify` 做异常告警

## 安全检查清单

- `system.jwt_secret` 与后台 OAuth/Passkey 等密钥使用高强度值
- 限制 MySQL/Redis 的网络暴露范围
- 配置文件与日志目录设置最小权限
- 敏感请求/响应字段在操作日志中应脱敏或不落盘

## 备份建议

- 数据库备份（日备 + 保留策略）
- `bin/configs` 备份并纳入安全的版本管理
- 发布前在预发环境做一次恢复演练

## 相关文档

- [开发指南](Development-Guide-zh.md)
- [API 文档](API-Documentation-zh.md)
- [后台鉴权文档](Admin-Auth-zh.md)
- [系统管理接口文档](Admin-System-Management-zh.md)
- [Makefile 使用指南](Makefile-Usage-zh.md)
- [make.sh 使用指南](make.sh-Usage-zh.md)
