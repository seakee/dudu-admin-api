# 代码生成器指南

**语言版本**: [English](Code-Generator-Guide.md) | [中文](Code-Generator-Guide-zh.md)

---

## 概述

Go-API框架包含一个强大的代码生成器，可以从SQL表结构自动生成Go模型和仓库代码。这个工具可以显著减少手动编写重复代码的时间，提高开发效率。

## 功能特性

- 🚀 **SQL解析**: 自动解析CREATE TABLE语句
- 📝 **模型生成**: 生成带有GORM标签的Go结构体
- 🏪 **仓库生成**: 生成完整的CRUD操作接口和实现
- 🎯 **类型映射**: 智能的SQL到Go类型转换
- 📋 **注释保留**: 保留SQL注释作为Go文档注释
- 🔧 **自定义配置**: 支持自定义输出路径和命名规则

## 安装要求

确保您的系统满足以下要求：

- Go 1.24+
- 访问项目根目录的权限
- SQL文件位于`bin/data/sql/`目录

## 快速开始

### 1. 准备SQL文件

在`bin/data/sql/`目录下创建SQL文件：

```sql
-- bin/data/sql/users.sql
CREATE TABLE `users` (
    `id` int NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username` varchar(50) NOT NULL COMMENT '用户名',
    `email` varchar(100) NOT NULL COMMENT '邮箱地址',
    `password_hash` varchar(255) NOT NULL COMMENT '密码哈希',
    `status` tinyint(1) NOT NULL DEFAULT '1' COMMENT '状态: 0=禁用, 1=启用',
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` timestamp NULL DEFAULT NULL COMMENT '删除时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_username` (`username`),
    UNIQUE KEY `unique_email` (`email`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户信息表';
```

### 2. 运行代码生成器

```bash
# 生成特定表的代码
go run ./command/codegen/handler.go -name users

# 生成所有SQL文件的代码
go run ./command/codegen/handler.go

# 使用自定义路径
go run ./command/codegen/handler.go -sql custom/sql -model custom/model -repo custom/repo
```

### 3. 查看生成的代码

生成器将创建以下文件：

```
app/
├── model/
│   └── users/
│       ├── users.go          # 模型结构体
│       └── users_mgo.go      # MongoDB版本(可选)
└── repository/
    └── users/
        └── users.go          # 仓库接口和实现
```

## 命令行选项

### 基本用法

```bash
go run ./command/codegen/handler.go [选项]
```

### 可用选项

| 选项 | 简写 | 描述 | 默认值 | 示例 |
|------|------|------|--------|------|
| `--name` | `-n` | 指定要生成的表名（不含扩展名） | 全部 | `-n users` |
| `--sql` | `-s` | SQL文件目录路径 | `bin/data/sql` | `-s custom/sql` |
| `--model` | `-m` | 模型输出目录 | `app/model` | `-m custom/model` |
| `--repo` | `-r` | 仓库输出目录 | `app/repository` | `-r custom/repo` |
| `--help` | `-h` | 显示帮助信息 | - | `-h` |

### 使用示例

```bash
# 生成单个表
go run ./command/codegen/handler.go -name users

# 生成多个指定表
go run ./command/codegen/handler.go -name users -name products

# 使用自定义路径
go run ./command/codegen/handler.go \
  -sql ./database/migrations \
  -model ./internal/model \
  -repo ./internal/repository

# 生成所有表（默认行为）
go run ./command/codegen/handler.go
```

## 生成的代码结构

### 模型文件 (users.go)

```go
// Package users provides user-related models and operations
package users

import (
    "context"
    "gorm.io/gorm"
)

// Users 用户信息表
type Users struct {
    gorm.Model
    ID           uint   `gorm:"column:id;primaryKey;autoIncrement" json:"id"`                    // 用户ID
    Username     string `gorm:"column:username;size:50;not null" json:"username"`               // 用户名
    Email        string `gorm:"column:email;size:100;not null" json:"email"`                    // 邮箱地址
    PasswordHash string `gorm:"column:password_hash;size:255;not null" json:"password_hash"`    // 密码哈希
    Status       int8   `gorm:"column:status;not null;default:1" json:"status"`                 // 状态: 0=禁用, 1=启用
    CreatedAt    *time.Time `gorm:"column:created_at;default:CURRENT_TIMESTAMP" json:"created_at"` // 创建时间
    UpdatedAt    *time.Time `gorm:"column:updated_at;default:CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" json:"updated_at"` // 更新时间
    DeletedAt    *time.Time `gorm:"column:deleted_at" json:"deleted_at"` // 删除时间
}

// TableName 返回表名
func (Users) TableName() string {
    return "users"
}

// Create 创建用户记录
//
// Parameters:
//   - ctx: 上下文
//   - db: 数据库连接
//
// Returns:
//   - uint: 创建的记录ID
//   - error: 错误信息
func (u *Users) Create(ctx context.Context, db *gorm.DB) (uint, error) {
    if err := db.WithContext(ctx).Create(u).Error; err != nil {
        return 0, err
    }
    return u.ID, nil
}

// GetByID 根据ID获取用户
//
// Parameters:
//   - ctx: 上下文
//   - db: 数据库连接
//   - id: 用户ID
//
// Returns:
//   - *Users: 用户信息
//   - error: 错误信息
func (u *Users) GetByID(ctx context.Context, db *gorm.DB, id uint) (*Users, error) {
    var user Users
    if err := db.WithContext(ctx).Where("id = ?", id).First(&user).Error; err != nil {
        return nil, err
    }
    return &user, nil
}

// Update 更新用户信息
//
// Parameters:
//   - ctx: 上下文
//   - db: 数据库连接
//   - id: 用户ID
//
// Returns:
//   - error: 错误信息
func (u *Users) Update(ctx context.Context, db *gorm.DB, id uint) error {
    return db.WithContext(ctx).Where("id = ?", id).Updates(u).Error
}

// Delete 删除用户（软删除）
//
// Parameters:
//   - ctx: 上下文
//   - db: 数据库连接
//   - id: 用户ID
//
// Returns:
//   - error: 错误信息
func (u *Users) Delete(ctx context.Context, db *gorm.DB, id uint) error {
    return db.WithContext(ctx).Where("id = ?", id).Delete(&Users{}).Error
}

// List 获取用户列表
//
// Parameters:
//   - ctx: 上下文
//   - db: 数据库连接
//   - whereUsers: 查询条件
//
// Returns:
//   - []Users: 用户列表
//   - error: 错误信息
func (u *Users) List(ctx context.Context, db *gorm.DB, whereUsers *Users) ([]Users, error) {
    var users []Users
    query := db.WithContext(ctx)
    
    if whereUsers != nil {
        if whereUsers.Status != 0 {
            query = query.Where("status = ?", whereUsers.Status)
        }
        if whereUsers.Username != "" {
            query = query.Where("username LIKE ?", "%"+whereUsers.Username+"%")
        }
    }
    
    if err := query.Find(&users).Error; err != nil {
        return nil, err
    }
    return users, nil
}
```

### 仓库文件 (users.go)

```go
// Package users provides user repository operations
package users

import (
    "context"
    "github.com/seakee/dudu-admin-api/app/model/users"
    "github.com/sk-pkg/redis"
    "gorm.io/gorm"
)

// UsersRepo 用户仓库接口
type UsersRepo interface {
    Create(ctx context.Context, users *users.Users) (uint, error)
    GetByID(ctx context.Context, id uint) (*users.Users, error)
    Update(ctx context.Context, id uint, users *users.Users) error
    Delete(ctx context.Context, id uint) error
    List(ctx context.Context, whereUsers *users.Users) ([]users.Users, error)
}

// usersRepo 用户仓库实现
type usersRepo struct {
    db    *gorm.DB
    redis *redis.Manager
}

// NewUsersRepo 创建用户仓库实例
//
// Parameters:
//   - db: 数据库连接
//   - redis: Redis管理器
//
// Returns:
//   - UsersRepo: 用户仓库接口
func NewUsersRepo(db *gorm.DB, redis *redis.Manager) UsersRepo {
    return &usersRepo{
        db:    db,
        redis: redis,
    }
}

// Create 创建用户
//
// Parameters:
//   - ctx: 上下文
//   - users: 用户信息
//
// Returns:
//   - uint: 创建的用户ID
//   - error: 错误信息
func (r *usersRepo) Create(ctx context.Context, users *users.Users) (uint, error) {
    return users.Create(ctx, r.db)
}

// GetByID 根据ID获取用户
//
// Parameters:
//   - ctx: 上下文
//   - id: 用户ID
//
// Returns:
//   - *users.Users: 用户信息
//   - error: 错误信息
func (r *usersRepo) GetByID(ctx context.Context, id uint) (*users.Users, error) {
    var user users.Users
    return user.GetByID(ctx, r.db, id)
}

// Update 更新用户
//
// Parameters:
//   - ctx: 上下文
//   - id: 用户ID
//   - users: 用户信息
//
// Returns:
//   - error: 错误信息
func (r *usersRepo) Update(ctx context.Context, id uint, users *users.Users) error {
    return users.Update(ctx, r.db, id)
}

// Delete 删除用户
//
// Parameters:
//   - ctx: 上下文
//   - id: 用户ID
//
// Returns:
//   - error: 错误信息
func (r *usersRepo) Delete(ctx context.Context, id uint) error {
    var user users.Users
    return user.Delete(ctx, r.db, id)
}

// List 获取用户列表
//
// Parameters:
//   - ctx: 上下文
//   - whereUsers: 查询条件
//
// Returns:
//   - []users.Users: 用户列表
//   - error: 错误信息
func (r *usersRepo) List(ctx context.Context, whereUsers *users.Users) ([]users.Users, error) {
    var user users.Users
    return user.List(ctx, r.db, whereUsers)
}
```

## 类型映射规则

### SQL到Go类型映射

| SQL类型 | Go类型 | 说明 |
|---------|--------|------|
| `int`, `integer` | `int` | 整型 |
| `tinyint(1)` | `int8` | 小整型/布尔型 |
| `smallint` | `int16` | 短整型 |
| `bigint` | `int64` | 长整型 |
| `varchar`, `text` | `string` | 字符串 |
| `decimal`, `float` | `float64` | 浮点型 |
| `timestamp`, `datetime` | `*time.Time` | 时间戳 |
| `date` | `*time.Time` | 日期 |
| `json` | `string` | JSON字符串 |

### GORM标签生成

- `PRIMARY KEY` → `gorm:"primaryKey"`
- `AUTO_INCREMENT` → `gorm:"autoIncrement"`
- `NOT NULL` → `gorm:"not null"`
- `DEFAULT value` → `gorm:"default:value"`
- `VARCHAR(50)` → `gorm:"size:50"`
- `UNIQUE KEY` → `gorm:"uniqueIndex"`

## 最佳实践

### SQL文件组织

1. **命名规范**:
   ```
   bin/data/sql/
   ├── users.sql           # 用户表
   ├── products.sql        # 产品表
   ├── orders.sql          # 订单表
   └── order_items.sql     # 订单项表
   ```

2. **文件内容规范**:
   ```sql
   -- 文件头注释
   -- Description: 用户信息表
   -- Author: 开发者姓名
   -- Date: 2024-01-01
   
   CREATE TABLE `users` (
       -- 每个字段都添加有意义的注释
       `id` int NOT NULL AUTO_INCREMENT COMMENT '用户唯一标识',
       -- ...
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户信息表';
   ```

### 代码生成最佳实践

1. **定期重新生成**: 当数据库结构发生变化时
2. **版本控制**: 将生成的代码纳入版本控制
3. **自定义扩展**: 在生成的代码基础上添加业务逻辑
4. **测试验证**: 为生成的代码编写单元测试

### 性能优化建议

1. **索引设计**: 在SQL中正确定义索引
2. **字段选择**: 只查询需要的字段
3. **分页查询**: 大数据量时使用分页
4. **缓存策略**: 合理使用Redis缓存

## 故障排除

### 常见问题

#### 1. SQL解析错误

**问题**: 无法解析SQL语句
```
Error: failed to parse SQL file: users.sql
```

**解决方案**:
- 检查SQL语法是否正确
- 确保使用标准的CREATE TABLE语句
- 验证字符编码为UTF-8

#### 2. 文件权限错误

**问题**: 无法写入生成的文件
```
Error: permission denied: app/model/users/users.go
```

**解决方案**:
```bash
# 检查目录权限
ls -la app/model/
# 修改权限
chmod -R 755 app/model/
```

#### 3. 导入路径错误

**问题**: 生成的代码导入路径不正确

**解决方案**:
- 确保在项目根目录运行命令
- 检查go.mod文件的module名称
- 使用绝对路径运行生成器

### 调试技巧

1. **详细日志**: 添加`-v`参数查看详细日志
2. **单独测试**: 先测试单个简单的表
3. **手动验证**: 检查生成的代码是否符合预期

## 高级用法

### 自定义模板

如果需要自定义生成的代码格式，可以修改生成器模板：

```bash
# 模板文件位置
command/codegen/codegen/template/
├── model.tpl       # 模型模板
└── repository.tpl  # 仓库模板
```

### 批量操作脚本

创建批量生成脚本：

```bash
#!/bin/bash
# generate_all.sh

echo "正在生成所有模型和仓库..."

# 生成所有表
go run ./command/codegen/handler.go

# 格式化生成的代码
go fmt ./app/model/...
go fmt ./app/repository/...

echo "代码生成完成！"
```

### 集成到构建流程

在Makefile中添加代码生成任务：

```makefile
.PHONY: generate
generate:
	@echo "生成模型和仓库代码..."
	@go run ./command/codegen/handler.go
	@go fmt ./app/model/...
	@go fmt ./app/repository/...
	@echo "代码生成完成"

.PHONY: generate-clean
generate-clean:
	@echo "清理并重新生成代码..."
	@rm -rf ./app/model/*
	@rm -rf ./app/repository/*
	@make generate
```

这样就可以使用`make generate`命令来生成代码了。