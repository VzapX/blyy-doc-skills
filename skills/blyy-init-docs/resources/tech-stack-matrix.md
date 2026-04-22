# 技术栈与模块识别矩阵

本文档从 `doc-guide.md` 四 "Phase 2 填充规则" 拆分而来，集中存放**技术栈相关的确定性矩阵与识别策略**。Phase 0.1 / Phase 0.3 / Phase 1.5 / Phase 2 在需要执行清单扫描或模块识别时读取本文件。

---

## 一、确定性清点命令矩阵

Phase 2 「穷举式枚举」原则依赖确定性清单预扫描。主 agent 在 Phase 2 开始前必须使用 shell 命令（`fd` / `rg`，非 AI 阅读）按下表生成项目的完整文件清单：

| 技术栈 | 实体/模型清点 | 控制器/路由清点 | 服务清点 | 配置清点 |
|--------|-------------|---------------|---------|---------|
| C# / .NET | `fd -e cs -p "Entity\|Model" --type f` | `fd -e cs -p "Controller" --type f` | `fd -e cs -p "Service" --type f` | `fd "appsettings" --type f` |
| Java / Spring | `rg -l "@Entity\|@Table" --type java` | `rg -l "@RestController\|@Controller" --type java` | `rg -l "@Service" --type java` | `fd "application" -e yml -e yaml -e properties` |
| Python | `rg "class.*Model" -l --type py` | `fd "views.py\|routers" --type f -e py` | `fd "services" --type f -e py` | `fd "settings.py\|config.py\|.env" --type f` |
| Go | `fd "_model.go\|model.go" --type f` | `fd "handler\|routes" -e go --type f` | `fd "service" -e go --type f` | `fd "config" -e go -e yaml -e toml` |
| Node.js / TS | `fd -e ts -p "entity\|model" --type f` | `fd -e ts -p "controller" --type f` | `fd -e ts -p "service" --type f` | `fd "config" -e ts -e js --type f` |
| Ruby / Rails | `fd -e rb --type f app/models/` | `fd -e rb --type f app/controllers/` | `fd -e rb --type f app/services/` | `fd "database.yml\|credentials" --type f` |
| PHP / Laravel | `fd -e php --type f app/Models/` | `fd -e php --type f app/Http/Controllers/` | `fd -e php --type f app/Services/` | `fd -e php --type f config/` |
| Rust | `fd "model\|schema" -e rs --type f` | `fd "handler\|routes" -e rs --type f` | `fd "service" -e rs --type f` | `fd "config" -e rs -e toml` |

清单持久化位置：

- 标准模式：`docs/.init-temp/inventory.md`
- 大型项目模式：`.init-docs/inventory.md`

每个子代理接收其负责范围内的**文件清单作为强制检查表**，指令要求逐一核对；子代理输出必须包含**检查表覆盖率**（如 `23/23 ✓`），未覆盖的文件必须说明原因。Phase 3 验证时将文档条目数与预扫描清单数**逐一比对**。

---

## 二、字段说明提取矩阵

`data-model.md` 中所有表结构详情表的「说明」列**禁止留空**。按以下优先级提取字段语义描述：

**字段说明提取优先级**（1 最高）：

1. 代码文档注释（属性/字段上方或行尾的注释）
2. 数据注解/装饰器中的说明参数
3. 迁移文件中的列注释
4. 字段名语义推断（T2 级别）
5. 无法确定时标注 `<!-- TODO[p2,business-context,user]: 请补充字段说明 -->`

**各技术栈注释提取来源矩阵**：

| 技术栈 | 文档注释 | 数据注解/装饰器 | 迁移文件注释 |
|--------|---------|---------------|-------------|
| C# / .NET | `/// <summary>` XML 文档注释 | `[Comment("...")]`（EF Core）、`[Description("...")]` | `.HasComment("...")`（Fluent API） |
| Java / Spring | `/** */` JavaDoc | `@Comment("...")`（Hibernate 6+）、`@Column(columnDefinition="COMMENT '...'")`、`columnDefinition` | Flyway/Liquibase 迁移中的 `COMMENT ON COLUMN` |
| Python / Django | `#` 行注释、`"""` 文档字符串 | `help_text=`（Django Field）、`comment=`（SQLAlchemy Column）、`doc=`（Pydantic Field） | 迁移文件中的 `comment` 参数 |
| Go | `//` 行注释 | `gorm:"comment:..."` tag、`ent.Field().Comment("...")` | migrate SQL 中的 `COMMENT` |
| Node.js / TS | `/** */` JSDoc | `{ comment: "..." }`（TypeORM @Column）、`/// @description`（Prisma schema） | Knex `.comment("...")`、Prisma `/// 注释` |
| Ruby / Rails | `#` 行注释 | — | `t.column ... comment: "..."`（迁移文件） |
| PHP / Laravel | `/** */` PHPDoc | — | `$table->string('name')->comment("...")`（迁移文件） |
| Rust | `///` 文档注释 | `#[sea_orm(comment = "...")]`、diesel schema 注释 | `COMMENT ON COLUMN` SQL |

**字段名推断规则**（优先级 4，T2 级别）：

| 字段名模式 | 推断说明 |
|-----------|---------|
| `id` / `*_id` | 主键 / 外键关联 |
| `created_at` / `create_time` / `gmt_create` | 创建时间 |
| `updated_at` / `update_time` / `gmt_modified` | 更新时间 |
| `deleted_at` / `is_deleted` / `is_active` | 软删除标记 / 启用状态 |
| `name` / `title` / `label` | 名称 / 标题 |
| `status` / `state` | 状态 |
| `type` / `kind` / `category` | 类型 / 分类 |
| `sort` / `order` / `seq` / `position` | 排序号 |
| `remark` / `memo` / `note` / `description` | 备注 / 描述 |
| `version` / `revision` | 乐观锁版本号 |
| `tenant_id` / `org_id` | 租户/组织标识 |

> **三级事实分类对应**：优先级 1-3 的来源为 T1（直接提取），优先级 4 为 T2（高置信推断），优先级 5 为待确认标记。详见 `fact-classification.md`。

---

## 三、技术栈识别

| 项目文件 | 技术栈 | 框架提示 |
|---------|--------|----------|
| `*.csproj` / `*.sln` | C# / .NET | ASP.NET Core, WPF, MAUI |
| `package.json` | Node.js / JS/TS | 检查 dependencies 区分前端/后端/全栈 |
| `go.mod` | Go | Gin, Echo, Fiber |
| `Cargo.toml` | Rust | Actix, Axum, Rocket |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python | Django, FastAPI, Flask |
| `pom.xml` / `build.gradle` / `build.gradle.kts` | Java / Kotlin | Spring Boot, Quarkus |
| `Gemfile` | Ruby | Rails, Sinatra |
| `composer.json` | PHP | Laravel, Symfony |

**前端框架识别**（从 `package.json` dependencies 提取）：

| 依赖关键字 | 框架 |
|-----------|------|
| `vue` | Vue 2/3（检查版本号区分） |
| `react` / `react-dom` | React |
| `@angular/core` | Angular |
| `svelte` | Svelte |
| `next` | Next.js (React SSR) |
| `nuxt` | Nuxt (Vue SSR) |

**Monorepo 识别**：

| 文件 | 工具 |
|------|------|
| `pnpm-workspace.yaml` | pnpm workspace |
| `lerna.json` | Lerna |
| `nx.json` | Nx |
| `turbo.json` | Turborepo |

---

## 四、锚点文件矩阵

锚点文件是以最小阅读量获取最大结构信息的关键文件。根据识别到的技术栈选择对应矩阵。

### 后端锚点

| 锚点类型 | C# / .NET | Java / Spring | Python / Django·FastAPI | Go | Node.js / TS |
|----------|-----------|---------------|------------------------|----|--------------|
| **入口点** | `Program.cs`、`Startup.cs` | `*Application.java`、`@SpringBootApplication` | `manage.py`、`main.py`、`app.py` | `main.go`、`cmd/` | `index.ts`、`app.ts`、`server.ts` |
| **DI/IoC** | `ServiceCollectionExtensions.cs` | `@Configuration`、`@Bean` 类 | `settings.py`(INSTALLED_APPS)、`container.py` | `wire.go`、`fx.go` | `module.ts`(NestJS)、`container.ts` |
| **接口/抽象** | `I*Service.cs`、`I*Repository.cs` | `*Service.java`(接口)、`*Repository.java` | `abc.ABC` 子类、Protocol 类 | `interface` 定义文件 | `*.interface.ts`、`*.abstract.ts` |
| **配置模型** | `*Options.cs`、`*Settings.cs` | `*Properties.java`、`application*.yml` | `*Settings`(Pydantic)、`settings.py` | `config.go`、`*.yaml` | `config.ts`、`*.config.js` |
| **实体/模型** | `*Entity.cs`、`*Model.cs` | `@Entity`、`@Table` 类 | `models.py`、`*Model` 类 | `*_model.go`、`ent/schema/` | `*.entity.ts`、`*.model.ts` |
| **控制器/路由** | `*Controller.cs` | `@RestController`、`@Controller` | `views.py`、`routers/*.py` | `handler*.go`、`routes.go` | `*.controller.ts`、`routes/*.ts` |
| **数据库迁移** | `Migrations/*.cs` | `db/migration/`、Flyway/Liquibase | `migrations/*.py` | `migrate/*.sql`、goose | `migrations/*.ts`、Knex/Prisma |

### 前端锚点

| 锚点类型 | Vue (2/3) | React | Angular |
|----------|-----------|-------|---------|
| **入口点** | `main.ts`、`App.vue` | `index.tsx`、`App.tsx` | `main.ts`、`app.module.ts` |
| **路由** | `router/index.ts` | `routes.tsx`、React Router 配置 | `app-routing.module.ts` |
| **状态管理** | `store/index.ts`(Vuex/Pinia) | `store.ts`(Redux/Zustand) | `*.service.ts`(RxJS)、NgRx |
| **API 层** | `api/*.ts`、`services/*.ts` | `api/*.ts`、`services/*.ts` | `*.service.ts`(HttpClient) |
| **组件** | `components/*.vue` | `components/*.tsx` | `*.component.ts` |
| **页面/视图** | `views/*.vue`、`pages/*.vue` | `pages/*.tsx`、`views/*.tsx` | `*-page.component.ts` |
| **类型定义** | `types/*.ts`、`*.d.ts` | `types/*.ts`、`*.d.ts` | `*.model.ts`、`*.interface.ts` |

### 补充后端锚点

| 锚点类型 | Rust | Ruby / Rails | PHP / Laravel | Kotlin / Android |
|----------|------|-------------|---------------|-----------------|
| **入口点** | `main.rs`、`lib.rs` | `config.ru`、`app/` | `public/index.php`、`artisan` | `*Application.kt`、`MainActivity.kt` |
| **DI/IoC** | `mod.rs`（模块声明） | `config/initializers/` | `app/Providers/*ServiceProvider.php` | `@Module`(Dagger/Hilt)、`di/` |
| **接口/抽象** | `trait` 定义文件 | `app/services/`、concerns | `app/Contracts/`、`*Interface.php` | `interface` 定义、`*Repository.kt` |
| **配置模型** | `config.rs`、`*.toml` | `config/*.rb`、`database.yml` | `config/*.php`、`.env` | `*Properties.kt`、`application*.yml` |
| **实体/模型** | `models/`、`schema.rs` | `app/models/*.rb` | `app/Models/*.php` | `@Entity`、`*Entity.kt` |
| **控制器/路由** | `handlers/`、`routes.rs` | `app/controllers/*.rb`、`routes.rb` | `app/Http/Controllers/*.php`、`routes/*.php` | `@RestController`、`*Controller.kt` |
| **数据库迁移** | `migrations/*.sql`、diesel | `db/migrate/*.rb` | `database/migrations/*.php` | `db/migration/`、Room `*_Migration.kt` |

### 补充前端锚点

| 锚点类型 | Svelte / SvelteKit | Next.js | Nuxt |
|----------|-------------------|---------|------|
| **入口点** | `src/routes/+layout.svelte` | `app/layout.tsx` 或 `pages/_app.tsx` | `app.vue`、`nuxt.config.ts` |
| **路由** | `src/routes/` 目录结构 | `app/` 目录结构（App Router）或 `pages/` | `pages/` 目录结构 |
| **状态管理** | `$lib/stores/*.ts` | `store.ts`(Zustand/Redux) | `composables/`、`store/`(Pinia) |
| **API 层** | `src/routes/api/`(SvelteKit) | `app/api/`(Route Handlers) | `server/api/` |
| **组件** | `src/lib/components/*.svelte` | `components/*.tsx` | `components/*.vue` |
| **页面/视图** | `src/routes/*/+page.svelte` | `app/*/page.tsx` 或 `pages/*.tsx` | `pages/*.vue` |
| **类型定义** | `src/lib/types/*.ts` | `types/*.ts`、`*.d.ts` | `types/*.ts`、`*.d.ts` |

> **SSR 与 SPA 差异**：Next.js / Nuxt / SvelteKit 等元框架的锚点以 `app/` 或 `pages/` 目录结构为核心（文件系统路由），与纯 SPA 的 `router/index.ts` 方式不同。识别到元框架时应优先使用上表。

### 搜索示例

```bash
# C#
fd -e cs "(Program|Startup|I[A-Z].*Service)" --type f
# Java
rg -l "@SpringBootApplication|@RestController|@Entity" --type java
# Python
fd "(manage|main|app|settings|models|views)" -e py --type f
# Go
fd "(main|handler|routes|config)" -e go --type f
# Rust
fd "(main|lib|mod|routes|config)" -e rs --type f
# Ruby
fd "(application|routes|schema)" -e rb --type f
# PHP
fd "(Controller|Model|Provider|routes)" -e php --type f
# Vue
fd -e vue -e ts "(App|main|router|store)" --type f
# React / Next.js
fd -e tsx -e ts "(App|index|routes|store|layout|page)" --type f
# Svelte
fd -e svelte -e ts "(layout|page|store)" --type f
```

---

## 五、模块识别策略（两级识别）

### Step 1 — 识别项目（第一级）

| 语言/框架 | 项目来源 | 一个「项目」对应什么 |
|----------|---------|-------------------|
| C# / .NET | `.sln` 中的 `.csproj` | 一个 .csproj 项目 |
| Java | `pom.xml` 的 modules / `settings.gradle` | 一个 Maven module 或 Gradle subproject |
| Python | Monorepo 的 packages / 顶层 `src/` 子目录 | 一个 Python 包 |
| Go | `go.work` 模块 / 顶层 `cmd/` + `internal/` | 一个 Go module 或 cmd |
| Node.js / TS | `workspaces` / `pnpm-workspace.yaml` | 一个 workspace 包 |
| Vue / React / Angular | `src/` 下的组织方式 | 通常整个前端是一个项目 |

### Step 2 — 项目性质判断

| 性质 | 识别特征 | 处理 |
|------|---------|------|
| 测试项目 | 名称含 `Tests`/`Test`/`test`/`spec`、目录为 `tests/`/`__tests__/` | 隶属被测项目 |
| 共享库 | 名称含 `Common`/`Shared`/`Core`/`Utils`/`Lib`，被多项目引用 | 独立模块 |
| 文档/工具 | 名称含 `docs`/`tools`/`scripts` | 通常跳过 |
| 业务项目 | 其他 | 进入 Step 2.5 |

### Step 2.5 — 架构布局检测（分层 vs 领域）

在识别子模块之前，必须先判断项目的代码组织模式。不同的组织模式需要不同的模块识别策略。

**检测方法：**

1. 列出项目源代码目录下的所有顶层子目录（排除构建产物、配置、工具目录）
2. 将每个目录名与以下两类关键词对比分类：

| 类别 | 关键词（不区分大小写） |
|------|---------------------|
| **技术层关键词** | Controllers, Services, Repositories, Models, Entities, Handlers, Middleware, Infrastructure, Domain, Application, Persistence, Presentation, DTOs, ViewModels, Validators, Providers, Mappers, Helpers, Utils, Common, Shared, Extensions, Filters, Interceptors, Guards, Pipes, Decorators |
| **业务域关键词** | 非技术层关键词的业务语义词（如 Orders, Users, Products, Auth, Payment, Inventory, Notification, Billing, Shipping 等） |

3. 判断矩阵：

| 顶层目录主要是... | 架构模式 | 模块策略 |
|------------------|---------|---------|
| 业务域目录（如 `Orders/`, `Users/`, `Auth/`） | 领域组织 | 直接用 Step 3 的目录级识别 |
| 技术层目录（如 `Controllers/`, `Services/`, `Models/`） | 分层架构 | **必须**执行 Step 2.6 跨层业务领域提取 |
| 混合或不确定 | 混合架构 | 检查技术层目录内是否有二级业务子目录；若有则按二级目录识别；若仍不确定，向用户展示候选方案让其选择 |

> **重要**：大量真实项目采用分层架构，模块不是按目录划分而是按业务概念跨层存在。如果跳过此步直接用目录识别，会错误地将 `Controllers`、`Services`、`Models` 识别为模块，而非 `订单`、`用户`、`支付` 等业务模块。

### Step 2.6 — 跨层业务领域提取（分层架构专用）

> 仅当 Step 2.5 检测到**分层架构**时执行。

**目标：** 从分散在各技术层目录中的文件命名中提取业务概念，将同一业务概念的跨层文件聚合为一个模块。

**算法步骤：**

1. 对每个技术层目录（Controllers/, Services/, Models/, Repositories/ 等），列出所有源文件名
2. 从文件名中剥离技术层后缀，提取业务概念前缀：
   - `OrderController.cs` → `Order`
   - `OrderService.cs` → `Order`
   - `UserRepository.cs` → `User`
   - `PaymentModel.cs` → `Payment`

3. 各技术栈后缀剥离规则：

| 技术栈 | 剥离后缀（不区分大小写） |
|--------|----------------------|
| C# / .NET | Controller, Service, Repository, Model, Entity, Handler, Validator, DTO, ViewModel, Options, Extensions, Manager, Provider, Factory, Middleware, Filter, Attribute, Profile |
| Java / Spring | Controller, Service, ServiceImpl, Repository, Entity, DTO, VO, Mapper, Config, Converter, Listener, Aspect, Interceptor, Handler |
| Python | View, ViewSet, Serializer, Model, Form, Admin, Signal, Task, Command, Manager, Mixin, Filter |
| Go | Handler, Service, Repository, Model, Store, Controller, Middleware, Router |
| Node.js / TS | Controller, Service, Module, Entity, DTO, Guard, Pipe, Interceptor, Middleware, Gateway, Resolver, Subscriber |
| Ruby / Rails | Controller, Model, Serializer, Service, Job, Mailer, Policy, Decorator |
| PHP / Laravel | Controller, Model, Service, Repository, Request, Resource, Policy, Event, Listener, Job, Mail, Notification |

4. 统计每个业务概念出现在多少个技术层中：

| 业务概念 | 出现的技术层 | 层数 |
|---------|------------|------|
| Order | Controller, Service, Repository, Model | 4 |
| User | Controller, Service, Model | 3 |
| Payment | Service, Model | 2 |
| Startup | — (无层后缀) | 0 |

5. **模块候选规则**：
   - 出现在 **2+ 个**技术层中的业务概念 = **一个模块候选**
   - 仅出现在 1 个层中的 = 归入「公共/共享」模块或暂不归类
   - 无法剥离后缀的文件（如 `Program.cs`、`Startup.cs`） = 基础设施文件，不参与模块划分

6. **确定性 shell 命令执行**（不依赖 AI 阅读代码）：

```bash
# C# / .NET 示例
fd -e cs --type f Controllers/ Services/ Models/ Repositories/ | \
  xargs -I{} basename {} .cs | \
  sed -E 's/(Controller|Service|Repository|Model|Entity|Handler|Validator|DTO|ViewModel|Options|Manager|Provider)$//' | \
  sort | uniq -c | sort -rn

# Java / Spring 示例
fd -e java --type f controller/ service/ model/ repository/ | \
  xargs -I{} basename {} .java | \
  sed -E 's/(Controller|Service|ServiceImpl|Repository|Entity|DTO|VO|Mapper)$//' | \
  sort | uniq -c | sort -rn

# Python 示例
fd -e py --type f views/ serializers/ models/ | \
  xargs -I{} basename {} .py | \
  sed -E 's/(View|ViewSet|Serializer|Model|Form|Admin)$//' | \
  sort | uniq -c | sort -rn

# Go 示例
fd -e go --type f handler/ service/ model/ repository/ | \
  xargs -I{} basename {} .go | \
  sed -E 's/(Handler|Service|Repository|Model|Store)$//' | \
  sort | uniq -c | sort -rn

# Node.js / TS 示例（NestJS 等）
fd -e ts --type f controllers/ services/ entities/ | \
  xargs -I{} basename {} .ts | \
  sed -E 's/\.(controller|service|entity|module|dto|guard|pipe)$//' | \
  sort | uniq -c | sort -rn

# Ruby / Rails 示例
fd -e rb --type f app/controllers/ app/models/ app/services/ | \
  xargs -I{} basename {} .rb | \
  sed -E 's/(Controller|Model|Service|Serializer|Job|Policy)$//' | \
  sort | uniq -c | sort -rn

# PHP / Laravel 示例
fd -e php --type f app/Http/Controllers/ app/Models/ app/Services/ | \
  xargs -I{} basename {} .php | \
  sed -E 's/(Controller|Model|Service|Repository|Request|Resource|Policy)$//' | \
  sort | uniq -c | sort -rn
```

命令输出示例：
```
   4 Order
   3 User
   2 Payment
   1 Startup
   1 Program
```

7. **向用户展示模块候选清单**（必须确认）：

```
📊 跨层业务领域分析结果：

| 模块候选 | 覆盖层数 | 涉及文件 |
|---------|---------|---------|
| Order | 4 层 | OrderController, OrderService, OrderRepository, OrderModel |
| User | 3 层 | UserController, UserService, UserModel |
| Payment | 2 层 | PaymentService, PaymentModel |

未归类文件：Program.cs, Startup.cs → 归入基础设施

请确认以上模块划分是否正确，或提出调整。
```

### Step 3 — 子模块识别（第二级）

> **前置条件**：执行 Step 3 前必须先完成 Step 2.5（架构布局检测）。若 Step 2.5 检测到**分层架构**，必须使用 Step 2.6 的跨层提取结果作为模块清单，**跳过**下方的目录级识别。仅当检测到**领域组织**或**混合架构**时，才使用下方规则。

判断项目内部是否需进一步拆分：

| 语言/框架 | 有子模块的特征 | 示例 |
|----------|-------------|------|
| C# / .NET | 有 `Areas/`、`Features/`、`Modules/` 目录；或顶层 3+ 个业务语义子目录 | `Areas/Auth/` |
| Java / Spring | 3+ 个并列业务包；多个 `@Configuration` 分区 | `com.app.auth` |
| Python / Django | 多个 Django app（含 `models.py` + `views.py`） | `apps/auth/` |
| Python / FastAPI | `routers/` 下 3+ 个路由模块 | `routers/users.py` |
| Go | `internal/` 下 3+ 个业务子包 | `internal/auth/` |
| Node.js / NestJS | 多个 `@Module()` 定义；`modules/` 3+ 个子目录 | `modules/auth/` |
| Vue | `views/` 下 3+ 个功能分区；Pinia store 3+ 个 | `views/dashboard/` |
| React | `features/` 下 3+ 个功能分区；Redux slice 3+ 个 | `features/auth/` |
| Angular | 3+ 个 Feature Module | `auth.module.ts` |

**通用兜底**：顶层 3+ 个业务语义子目录（排除构建产物、配置、工具目录）且用户确认 → 拆为子模块。

### Step 4 — 高级架构模式识别

部分项目采用特殊架构模式，标准的目录级识别不适用。遇到以下模式时按对应规则处理：

| 架构模式 | 识别特征 | 模块划分规则 |
|----------|---------|------------|
| **微前端** | `packages/app-shell` + `packages/feature-*`；或使用 Module Federation（`webpack.config` 含 `ModuleFederationPlugin`） | 每个远程模块/子应用视为独立模块，`app-shell` 为独立模块 |
| **插件架构** | `plugins/` 目录下有多个独立子目录，各自含入口文件；或配置文件中有插件注册列表 | 每个插件视为独立模块（即使代码量小），核心系统为一个模块 |
| **六边形/Clean 架构** | 存在 `domain/`（或 `core/`）+ `ports/`（或 `interfaces/`）+ `adapters/`（或 `infrastructure/`） | 按业务能力（非分层）划分模块；`domain` 内的聚合根/限界上下文为模块边界 |
| **DDD 限界上下文** | 目录名含 `bounded-context`、`context/`；或有明确的上下文映射图 | 每个限界上下文为一个模块 |
| **嵌套 Monorepo** | 多层嵌套如 `packages/core/modules/auth/` | **最深匹配规则**：在嵌套层中找到最深的项目标记文件（`package.json`、`.csproj` 等）所在层级作为模块边界 |
| **分层架构（Layered）** | 顶层目录为 `Controllers/`、`Services/`、`Models/`、`Repositories/` 等技术层目录；文件名中包含业务概念前缀（如 `OrderController`、`UserService`） | 使用 Step 2.6 跨层业务领域提取算法；每个在 2+ 层中出现的业务概念 = 一个模块 |

**判断优先级**：先执行 Step 2.5 架构布局检测，再检查是否匹配高级架构模式（Step 4），最后回退到标准的 Step 1-3 流程。若无法确定，向用户展示候选模块划分方案让其选择。

---

## 六、配置识别策略

| 语言/框架 | 配置文件 | 配置类 |
|----------|---------|--------|
| C# / .NET | `appsettings*.json` | `IOptions<T>` 实现、`*Options.cs` |
| Java / Spring | `application*.yml`、`application*.properties` | `@ConfigurationProperties` 类 |
| Python | `.env`、`settings.py`、`config.py` | Pydantic `BaseSettings` 子类 |
| Node.js / TS | `.env`、`config/`、`*.config.ts` | NestJS `@Module` 中的 config |
| Go | `*.yaml`、`*.toml` | `config.go`、Viper 配置 |
| 前端 | `.env.*`、`vite.config.ts`、`next.config.js` | 环境变量 `VITE_*`、`NEXT_PUBLIC_*` |
