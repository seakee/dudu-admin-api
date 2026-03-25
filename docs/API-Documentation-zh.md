# API 文档

**语言版本**: [English](API-Documentation.md) | [中文](API-Documentation-zh.md)

## 概述

本文档提供 API 入口与通用约定。
后台管理接口的详细行为请查看：

- [后台鉴权文档](Admin-Auth-zh.md)
- [系统管理接口文档](Admin-System-Management-zh.md)

## 基础地址

本地开发：

```text
http://localhost:8080
```

完整路由前缀：

```text
/{apiPrefix}/...
```

默认 `apiPrefix` 为 `dudu-admin-api`。

## 路由分组

### 外部接口

- `/{apiPrefix}/external/ping`
- `/{apiPrefix}/external/service/auth/token`
- `/{apiPrefix}/external/service/auth/app`

### 内部服务接口

- `/{apiPrefix}/internal/ping`
- `/{apiPrefix}/internal/service/auth/token`
- `/{apiPrefix}/internal/service/auth/app`

### 内部后台鉴权接口

挂载路径：

- `/{apiPrefix}/internal/admin/auth/...`

完整路由与流程说明：

- [后台鉴权文档](Admin-Auth-zh.md)

### 内部后台系统接口

挂载路径：

- `/{apiPrefix}/internal/admin/system/...`

主要模块：
- `menu`
- `permission`
- `role`
- `user`
- `record`

完整路由与数据结构说明：

- [系统管理接口文档](Admin-System-Management-zh.md)

## 鉴权方式

### 应用接口鉴权

受保护接口使用：

```text
Authorization: Bearer <app-token>
```

取 token 接口：

```text
POST /{apiPrefix}/external/service/auth/token
```

### 后台接口鉴权

后台接口使用 `CheckAdminAuth`。
支持以下 token 来源：
- `Authorization: Bearer <admin-token>`
- Cookie `admin-token`

## 操作日志

`/{apiPrefix}/internal/admin/system/*` 路由会经过 `SaveOperationRecord` 并记录操作日志。
`/{apiPrefix}/internal/admin/auth/*` 路由默认不经过 `SaveOperationRecord`。
敏感请求/响应字段应脱敏或不入日志。

## 通用响应格式

```json
{
  "code": 0,
  "msg": "ok",
  "trace": {
    "id": "afeade2f5957-tcdtjo-gdmaj",
    "desc": ""
  },
  "data": {}
}
```

## 健康检查

外部健康检查：

```text
GET /{apiPrefix}/external/ping
```

内部健康检查：

```text
GET /{apiPrefix}/internal/ping
```

## 错误码与国际化

- 错误码定义：`app/pkg/e/*.go`
- 语言文件：
  - `bin/lang/en-US.json`
  - `bin/lang/zh-CN.json`

新增错误码时，需同步更新中英文语言文件。

## 相关文档

- [开发指南](Development-Guide-zh.md)
- [部署指南](Deployment-Guide-zh.md)
- [后台鉴权文档](Admin-Auth-zh.md)
- [系统管理接口文档](Admin-System-Management-zh.md)
- [Makefile 使用指南](Makefile-Usage-zh.md)
- [make.sh 使用指南](make.sh-Usage-zh.md)
