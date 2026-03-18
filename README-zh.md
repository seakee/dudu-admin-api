# Dudu Admin API

**语言版本**: [English](README.md) | [中文](README-zh.md)

---

### 项目概述

`dudu-admin-api` 是从 [`seakee/go-api`](https://github.com/seakee/go-api) 的 `admin` 分支拆分出来的独立后台管理后端项目，完整保留了原始 Git 历史，当前聚焦后台认证鉴权、用户、角色、权限、菜单和操作记录等能力。

### 项目来源

- 仓库地址: `https://github.com/seakee/dudu-admin-api`
- 来源分支: `seakee/go-api:admin`
- 导入基线: `6df6cfe8aeeb27eaaaee74c7fb7e520af5f8feb2`
- 兼容说明: 当前仍保留 `/go-api/...` HTTP 路由前缀，避免拆分当下影响现有调用方

### 主要特性

- 🚀 **高性能**: 基于 Gin 框架，优化了日志和数据库连接
- 🏗️ **分层架构**: 严格遵循 Model → Repository → Service → Controller 模式
- 🔧 **依赖注入**: 清晰的架构和适当的关注点分离
- ⚙️ **配置管理**: 多环境支持，基于 JSON 的配置
- 📝 **高级日志**: 使用 Zap 的结构化日志，高性能
- 🗄️ **多数据库支持**: MySQL、PostgreSQL、SQLite、SQL Server、ClickHouse (通过 xdb/GORM) 和 MongoDB (qmgo)
- 🔐 **JWT 认证**: 内置应用认证和 JWT token
- 🌐 **国际化**: 多语言支持（中文、英文）
- 📊 **中间件系统**: CORS、认证、请求日志和自定义中间件
- ⚡ **代码生成**: 从 SQL 文件自动生成模型和仓库
- 🔄 **任务调度**: 内置作业调度系统
- 📨 **消息队列**: Kafka 生产者/消费者支持
- 🚨 **监控**: 异常恢复和通知集成
- 🐳 **Docker 支持**: 完整的 Docker 支持和优化镜像

### 快速开始

```bash
# 克隆仓库
git clone https://github.com/seakee/dudu-admin-api.git
cd dudu-admin-api

# 安装依赖
go mod download

# 复制和配置本地设置
cp bin/configs/local.json.default bin/configs/local.json
# 编辑 bin/configs/local.json 设置数据库配置

# 运行应用
make run
```

### 项目结构

```
dudu-admin-api/
├── app/                             # 应用层
│   ├── config/                     # 配置管理
│   │   └── config.go              # 配置加载器和结构
│   ├── http/                       # HTTP层
│   │   ├── controller/             # HTTP控制器
│   │   │   ├── auth/               # 认证控制器
│   │   │   │   ├── app.go          # 应用CRUD操作
│   │   │   │   ├── handler.go      # 认证处理器接口
│   │   │   │   └── jwt.go          # JWT令牌操作
│   │   │   └── base.go             # 基础控制器
│   │   ├── middleware/             # HTTP中间件
│   │   │   ├── check_app_auth.go   # JWT认证
│   │   │   ├── cors.go             # CORS处理
│   │   │   ├── handler.go          # 中间件接口
│   │   │   ├── request_logger.go   # 请求日志
│   │   │   └── set_trace_id.go     # 跟踪ID注入
│   │   ├── router/                 # 路由定义
│   │   │   ├── external/           # 外部API路由
│   │   │   │   └── service/        # 外部服务路由
│   │   │   │       └── auth/       # 认证端点
│   │   │   ├── internal/           # 内部API路由
│   │   │   │   └── service/        # 内部服务路由
│   │   │   │       └── auth/       # 认证端点
│   │   │   └── handler.go          # 主路由器
│   │   └── context.go              # HTTP上下文包装器
│   ├── model/                      # 数据模型
│   │   └── auth/                   # 认证模型
│   │       ├── app.go              # 应用模型 (MySQL)
│   │       └── app_mgo.go          # 应用模型 (MongoDB)
│   ├── pkg/                        # 工具包
│   │   ├── e/                      # 错误代码
│   │   │   └── code.go             # 错误代码定义
│   │   ├── jwt/                    # JWT工具
│   │   │   └── jwt.go              # JWT生成/解析
│   │   ├── schedule/               # 任务调度
│   │   │   └── schedule.go         # 作业调度器
│   │   └── trace/                  # 分布式跟踪
│   │       └── trace.go            # 跟踪ID生成
│   ├── repository/                 # 数据访问层
│   │   └── auth/                   # 认证仓库
│   │       └── app.go              # 应用仓库
│   ├── service/                    # 业务逻辑层
│   │   └── auth/                   # 认证服务
│   │       └── app.go              # 应用服务
│   └── worker/                     # 后台工作者
│       └── handler.go              # 工作者处理器
├── bin/                            # 运行时资源
│   ├── configs/                    # 配置文件
│   │   ├── dev.json                # 开发环境配置
│   │   ├── local.json              # 本地配置
│   │   └── prod.json               # 生产环境配置
│   ├── data/                       # 数据文件
│   │   └── sql/                    # SQL脚本
│   │       └── auth_app.sql        # 应用表结构
│   └── lang/                       # 语言文件
│       ├── en-US.json              # 英文消息
│       └── zh-CN.json              # 中文消息
├── bootstrap/                      # 应用启动
│   ├── app.go                      # 主应用初始化
│   ├── database.go                 # 数据库设置
│   ├── http.go                     # HTTP服务器设置
│   ├── kafka.go                    # Kafka设置
│   └── schedule.go                 # 调度器设置
├── command/                        # CLI命令
│   └── codegen/                    # 代码生成器
│       ├── codegen/                # 生成器逻辑
│       ├── handler.go              # CLI处理器
│       └── README.md               # 生成器文档
├── scripts/                        # 实用脚本
│   └── generate.sh                 # 项目生成器
├── docs/                           # 项目文档
│   ├── Home.md                     # Wiki首页（英文）
│   ├── Home-zh.md                  # Wiki首页（中文）
│   ├── Architecture-Design.md      # 架构设计文档
│   ├── Development-Guide.md        # 开发指南
│   ├── API-Documentation.md        # 完整API参考
│   ├── Code-Generator-Guide.md     # 代码生成工具指南
│   └── Deployment-Guide.md         # 生产部署指南
├── Dockerfile                      # Docker配置
├── Makefile                        # 构建自动化
├── docker-compose.yml              # Docker Compose
├── go.mod                          # Go模块
├── go.sum                          # 依赖项
├── main.go                         # 应用入口点
└── CONTRIBUTING.md                 # 贡献指南
```

### 核心组件

#### 1. 分层架构

框架遵循严格的4层架构：

- **模型层**: 数据结构和数据库操作
- **仓库层**: 数据访问抽象和接口
- **服务层**: 业务逻辑实现
- **控制器层**: HTTP请求处理和响应格式化

#### 2. 配置管理

支持多环境的JSON配置：

```json
{
  "system": {
    "name": "dudu-admin-api",
    "run_mode": "debug",
    "http_port": ":8080",
    "jwt_secret": "你的密钥"
  },
  "databases": [
    {
      "enable": true,
      "db_type": "mysql",
      "db_name": "dudu-admin-api",
      "db_host": "localhost",
      "db_port": 3306,
      "charset": "utf8mb4",
      "conn_max_lifetime": 3
    }
  ]
}
```

#### 3. 中间件系统

内置常用功能的中间件：

- **认证**: 基于JWT的应用认证
- **CORS**: 跨域资源共享
- **日志**: 结构化请求/响应日志
- **跟踪ID**: 分布式跟踪支持
- **异常恢复**: 自动异常恢复和通知

#### 4. 认证系统

完整的JWT认证：

```bash
# 获取JWT令牌
curl -X POST http://localhost:8080/go-api/external/service/auth/token \
  -d "app_id=your_app_id&app_secret=your_app_secret"

# 在请求中使用令牌
curl -H "Authorization: your_jwt_token" \
  http://localhost:8080/go-api/external/service/auth/app
```

### 开发指南

#### 添加新控制器

1. 创建控制器结构：

```go
// app/http/controller/user/handler.go
package user

import (
    "github.com/gin-gonic/gin"
    "github.com/seakee/dudu-admin-api/app/http"
)

type Handler interface {
    Create() gin.HandlerFunc
    GetByID() gin.HandlerFunc
}

type handler struct {
    controller.BaseController
    service userService.UserService
}

func NewHandler(appCtx *http.Context) Handler {
    return &handler{
        BaseController: controller.BaseController{
            AppCtx: appCtx,
            Logger: appCtx.Logger,
            Redis:  appCtx.Redis["dudu-admin-api"],
            I18n:   appCtx.I18n,
        },
        service: userService.NewUserService(appCtx.SqlDB["dudu-admin-api"], appCtx.Redis["dudu-admin-api"]),
    }
}
```

2. 注册路由：

```go
// app/http/router/external/service/user/user.go
func RegisterRoutes(api *gin.RouterGroup, ctx *http.Context) {
    userHandler := user.NewHandler(ctx)
    {
        api.POST("user", ctx.Middleware.CheckAppAuth(), userHandler.Create())
        api.GET("user/:id", userHandler.GetByID())
    }
}
```

#### 添加中间件

```go
// app/http/middleware/handler.go
type Middleware interface {
    CheckAppAuth() gin.HandlerFunc
    YourNewMiddleware() gin.HandlerFunc  // 添加这个
}

// app/http/middleware/your_middleware.go
func (m middleware) YourNewMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 中间件逻辑
        c.Next()
    }
}
```

#### 代码生成

从SQL文件生成模型和仓库：

```bash
# 从SQL文件生成
go run ./command/codegen/handler.go -name user_table

# 生成所有SQL文件
go run ./command/codegen/handler.go

# 自定义路径
go run ./command/codegen/handler.go -sql custom/sql -model custom/model
```

### API端点

#### 外部API（公开）

| 方法 | 端点 | 描述 | 需要认证 |
|------|------|------|----------|
| POST | `/go-api/external/service/auth/token` | 获取JWT令牌 | 否 |
| POST | `/go-api/external/service/auth/app` | 创建应用 | 是 |
| GET | `/go-api/external/service/ping` | 健康检查 | 否 |

#### 内部API（私有）

| 方法 | 端点 | 描述 | 需要认证 |
|------|------|------|----------|
| POST | `/go-api/internal/service/auth/token` | 获取JWT令牌 | 否 |
| POST | `/go-api/internal/service/auth/app` | 创建应用 | 是 |
| GET | `/go-api/internal/service/ping` | 健康检查 | 否 |

### Docker部署

#### 使用Docker Compose

```yaml
# docker-compose.yml
version: '3.8'
services:
  dudu-admin-api:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./bin/configs:/bin/configs
      - ./bin/logs:/bin/logs
    environment:
      - RUN_ENV=prod
      - APP_NAME=dudu-admin-api
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: dudu-admin-api
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
```

#### 构建和运行

```bash
# 构建Docker镜像
make docker-build

# 使用Docker Compose运行
docker-compose up -d

# 运行单个容器
make docker-run
```

### 构建命令

```bash
# 开发
make run          # 运行应用
make test         # 运行测试
make fmt          # 格式化代码
make all          # fmt + test + build

# 生产
make build        # 构建二进制文件
make docker-build # 构建Docker镜像
make docker-run   # 运行Docker容器
```

### 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `RUN_ENV` | 运行环境 | `local` |
| `APP_NAME` | 应用名称 | `dudu-admin-api` |
| `CONFIG_DIR` | 配置目录 | `./bin/configs` |

### 文档

完整的项目文档位于 `docs/` 目录：

- **[📚 GitHub Wiki](https://github.com/seakee/dudu-admin-api/wiki)** - 完整的Wiki文档
- **[Wiki首页](docs/Home.md)** - 文档索引和快速导航
- **[架构设计](docs/Architecture-Design.md)** - 系统架构和设计模式
- **[开发指南](docs/Development-Guide.md)** - 详细的开发工作流程
- **[API文档](docs/API-Documentation.md)** - 完整的API参考
- **[代码生成器](docs/Code-Generator-Guide.md)** - 代码生成工具使用指南
- **[部署指南](docs/Deployment-Guide.md)** - 生产环境部署
- **[Makefile使用指南](docs/Makefile-Usage.md)** - 构建自动化和开发工具
- **[go-api.sh使用指南](docs/go-api.sh-Usage.md)** - Shell脚本替代方案

### 贡献

我们欢迎贡献！请查看 [贡献指南](CONTRIBUTING.md) 了解：

- 代码标准和风格指南
- 拉取请求流程
- 问题报告
- 开发环境设置

### 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
