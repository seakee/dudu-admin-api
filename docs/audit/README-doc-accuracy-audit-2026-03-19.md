# README 链路文档准确性核对记录（2026-03-19）

## 1. 目的与范围

- 目的：从 `README.md` / `README-zh.md` 出发，按链接自上而下核对文档准确性与完整度，形成后续修复依据。
- 范围：
  - `README.md`、`README-zh.md`
  - `docs/*.md`（README 直接链接到的文档）
  - 关键代码路径：`main.go`、`bootstrap/*`、`app/http/router/*`、`app/config/*`、`command/codegen/*`、`Makefile`、`scripts/make.sh`、`go.mod`

## 2. 核对方法（防遗忘策略）

- 固定批次：按 README 链接顺序分批核对（Home -> Architecture -> Development -> Deployment -> API -> Admin Auth -> Admin System -> Code Generator -> Tooling -> Contributing/License）。
- 固定维度：每篇文档统一核对链接有效性、命令可执行性、配置项存在性、路由与中间件一致性、双语语义一致性。
- 固定记录：每条问题都记录问题编号、影响、证据文件与行号、建议修复方向。

## 3. 基线结果

### 3.1 链接完整性

- README + docs 内部 Markdown 链接总数：`208`
- 本地相对链接断链：`0`

### 3.2 已验证一致的关键点

- 启动链路描述与代码主流程一致（`main.go -> bootstrap.NewApp -> App.Start`）。
- 默认路由前缀 `dudu-admin-api` 与代码默认值一致。
- `Admin-System-Management` 记录的 system 模块路由集合与 `app/http/router/internal/admin/system/*.go` 注册结果总体一致。

## 4. 问题清单（待修复）

### DOC-001（高）README Go 版本与源码不一致

- 现象：
  - README 写 `Go >= 1.23`
  - 实际模块基线为 `go 1.24.13`
- 影响：新环境按 README 准备版本可能与真实依赖基线不一致。
- 证据：
  - `README.md:18`
  - `README-zh.md:17`
  - `go.mod:3`
- 建议：
  - README 双语统一改为 `Go 1.24.x`（或至少 `>=1.24`），与 `go.mod` 保持一致。

### DOC-002（高）多处文档将 `SaveOperationRecord` 作用域写大

- 现象：
  - 文档多处写成 `/internal/admin/*` 全量都会经过 `SaveOperationRecord`。
  - 代码中 `SaveOperationRecord` 实际挂在 `admin/system` 分组，不是整个 `admin/*`。
- 影响：对 auth 相关接口的日志行为判断错误，易导致安全与审计预期偏差。
- 证据（文档）：
  - `docs/Architecture-Design.md:89`
  - `docs/Architecture-Design-zh.md:89`
  - `docs/API-Documentation.md:95`
  - `docs/API-Documentation-zh.md:95`
  - `docs/Admin-Auth.md:14`
  - `docs/Admin-Auth.md:88`
  - `docs/Admin-Auth-zh.md:14`
  - `docs/Admin-Auth-zh.md:88`
  - `docs/Admin-System-Management.md:22`
  - `docs/Admin-System-Management-zh.md:22`
- 证据（代码）：
  - `app/http/router/internal/admin/handler.go:15`
  - `app/http/router/internal/admin/handler.go:18`
- 建议：
  - 所有相关文档改为精确表述：
    - `admin/system` 分组：`SaveOperationRecord + CheckAdminAuth`
    - `admin/auth` 分组：按子路由是否挂 `CheckAdminAuth`，并说明不默认经过 `SaveOperationRecord`。

### DOC-003（中）Home 双语中英互链不完整

- 现象：
  - `Home.md` 的 Chinese Documentation 未列出 `Makefile-Usage-zh`、`make.sh-Usage-zh`。
  - `Home-zh.md` 的英文文档入口未列出 `Makefile-Usage.md`、`make.sh-Usage.md`。
- 影响：跨语言导航不完整，读者容易遗漏工具文档。
- 证据：
  - `docs/Home.md:48`
  - `docs/Home-zh.md:48`
  - 对照已有工具文档入口：`docs/Home.md:21-24`、`docs/Home-zh.md:21-24`
- 建议：
  - 双语入口都补齐 `Makefile`/`make.sh` 对应文档链接。

### DOC-004（中）Development Guide 双语 related docs 不对齐

- 现象：
  - 中文版包含 `Makefile-Usage-zh` 与 `make.sh-Usage-zh`；
  - 英文版 related docs 未包含对应两篇。
- 影响：双语信息密度不一致。
- 证据：
  - `docs/Development-Guide-zh.md:143`
  - `docs/Development-Guide-zh.md:144`
  - `docs/Development-Guide.md:136`（相关区段对比）
- 建议：
  - English related docs 补齐 `Makefile-Usage.md`、`make.sh-Usage.md`。

### DOC-005（中）Code Generator 指令示例有误导风险

- 现象：
  - 文档示例使用 `-name users`，但仓库 SQL 文件集合中不存在 `users.sql`。
  - 现有示例与 generator 自身 README 的 `auth_app` 示例不一致。
- 影响：按文档执行会直接失败，影响新开发者使用体验。
- 证据：
  - `docs/Code-Generator-Guide.md:29`
  - `docs/Code-Generator-Guide-zh.md:29`
  - `command/codegen/README.md:52`
  - `command/codegen/README_ZH.MD:52`
  - `bin/data/sql` 实际文件名集合：`auth_app.sql`, `oauth_app.sql`, `sys_user.sql` 等（无 `users.sql`）。
- 建议：
  - 将示例改成仓库真实存在文件（如 `-name auth_app`）。
  - 追加方言示例，明确 `-dialect=postgres -sql bin/data/sql/postgres -name oauth_app`。

## 5. 追踪与修复建议

- 建议按以下顺序修复并回归：
  1. DOC-002（中间件作用域，安全与审计语义）
  2. DOC-001（Go 版本基线）
  3. DOC-005（codegen 可执行示例）
  4. DOC-003 / DOC-004（双语与导航完整度）
- 每修复一项，建议在本文件追加“修复记录”：
  - 修复时间
  - 修改文件
  - 变更摘要
  - 回归结果（链接检查/命令验证）

## 6. 当前状态

- 本文件已更新为“核对 + 首轮修复”记录。

## 7. 修复记录（2026-03-19）

### 7.1 已完成项

- DOC-001：已修复（README 双语 Go 版本改为 `1.24.x`）。
- DOC-002：已修复（`SaveOperationRecord` 作用域改为 `internal/admin/system/*`，并补充 `admin/auth` 的真实行为）。
- DOC-003：已修复（`Home` 双语补齐 `Makefile/make.sh` 跨语言入口）。
- DOC-004：已修复（`Development-Guide.md` Related Docs 补齐 `Makefile/make.sh`）。
- DOC-005：已修复（codegen 示例从 `-name users` 改为 `-name auth_app`，并补充 postgres 示例；新增指向 `command/codegen/README*` 的参考链接）。

### 7.2 本次修改文件

- `README.md`
- `README-zh.md`
- `docs/Architecture-Design.md`
- `docs/Architecture-Design-zh.md`
- `docs/API-Documentation.md`
- `docs/API-Documentation-zh.md`
- `docs/Admin-Auth.md`
- `docs/Admin-Auth-zh.md`
- `docs/Admin-System-Management.md`
- `docs/Admin-System-Management-zh.md`
- `docs/Home.md`
- `docs/Home-zh.md`
- `docs/Development-Guide.md`
- `docs/Development-Guide-zh.md`
- `docs/Code-Generator-Guide.md`
- `docs/Code-Generator-Guide-zh.md`

### 7.3 回归结果

- 文档链接：本地相对链接检查通过（无断链）。
- 关键语义：
  - Go 版本基线已与 `go.mod` 对齐。
  - `SaveOperationRecord` 作用域描述已与路由注册一致。
  - codegen 示例已与 `command/codegen/README*` 和仓库 SQL 文件名集合一致。
