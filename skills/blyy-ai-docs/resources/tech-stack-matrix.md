# Tech Stack Matrix — 技术栈探测与锚点候选

> **何时读取**：Mode A Phase A0 (环境探测) + Phase A1 (模块识别)。其他时机不应读取此文件。
>
> **目的**：让 Phase A0 用最少的命令识别项目技术栈，让 Phase A1/A3 知道每种栈下"业务入口"通常在哪些文件，从而把锚点提取集中在高信号文件上。
>
> **本文件不复制 blyy-init-docs 的 doc-guide.md**。我们只保留 ai-docs 必需的最小子集：8 大主流栈的依赖识别 + 后端业务锚点矩阵 + 模块根目录候选。

---

## 一、依赖文件 → 主语言/框架探测

Phase A0 按下表运行 `fd -d 2` 在仓库根目录查找首个匹配，命中即可定 `detected_stack.primary`。

| 命中文件 | primary | 默认 variants 候选 | package_manager |
|---------|---------|------------------|-----------------|
| `*.csproj` / `*.sln` / `Directory.Build.props` | `csharp` | `aspnetcore`, `efcore`, `dapper`, `mediatr` | `nuget` |
| `pom.xml` / `build.gradle*` | `java` | `spring`, `springboot`, `quarkus`, `jpa`, `mybatis` | `maven` / `gradle` |
| `pyproject.toml` / `setup.py` / `requirements.txt` | `python` | `django`, `fastapi`, `flask`, `sqlalchemy`, `pydantic` | `pip` / `poetry` / `uv` |
| `go.mod` | `go` | `gin`, `echo`, `fiber`, `gorm`, `sqlx` | `gomod` |
| `package.json`（无前端框架） | `typescript` | `nestjs`, `express`, `fastify`, `prisma`, `typeorm` | `npm` / `pnpm` / `yarn` |
| `package.json`（含前端框架） | `typescript` | `react`, `vue`, `svelte`, `next`, `nuxt`, `angular` | 同上 |
| `Cargo.toml` | `rust` | `actix`, `axum`, `rocket`, `sqlx`, `diesel` | `cargo` |
| `Gemfile` | `ruby` | `rails`, `sinatra`, `activerecord` | `bundler` |
| `composer.json` | `php` | `laravel`, `symfony`, `eloquent`, `doctrine` | `composer` |

### 多栈混合

允许 `primary` 为单值，`variants` 为列表。**前后端混合** 项目（例如同时有 `*.csproj` 和 `package.json`）→ 以 `*.csproj` 命中位置最深的目录为后端 root，以 `package.json` 命中位置最深的目录为前端 root。Phase A1 会把它们分别注册成两个模块。

### Variants 的探测命令（按需运行）

```bash
# csharp
rg -l 'Microsoft.EntityFrameworkCore' --type-add 'csproj:*.csproj' -tcsproj   # → +efcore
rg -l 'MediatR' --type-add 'csproj:*.csproj' -tcsproj                          # → +mediatr

# python
rg -l '^fastapi' requirements.txt pyproject.toml 2>/dev/null                   # → +fastapi
rg -l '^django' requirements.txt pyproject.toml 2>/dev/null                    # → +django

# typescript
rg -l '"@nestjs/core"' package.json                                            # → +nestjs
rg -l '"@prisma/client"' package.json                                          # → +prisma
rg -l '"react"' package.json                                                   # → +react
```

> **不要**在 Phase A0 一次性探测所有 variants，**仅探测**会影响 Phase A2 选 recipe 的那些（数据访问层、HTTP 框架、ORM）。其余的 variants 留给 Phase A3 子代理在分析时按需补充。

---

## 二、后端业务锚点候选矩阵

> 本表的用途：Phase A1 识别模块时，按本表去模块根下找"看一眼就能猜出业务"的文件（入口/Controller/实体/配置）。Phase A3 子代理给模块写 `business_summary` 时，从这些文件提取首句锚点。
>
> **不**用本表去搞清单——清单是 `code-queries.md` 的活儿。

| 锚点类型 | csharp | java | python | go | typescript | rust | ruby | php |
|---------|--------|------|--------|----|-----------|------|------|-----|
| **入口点** | `Program.cs`、`Startup.cs` | `*Application.java` | `manage.py`、`main.py`、`app.py` | `main.go`、`cmd/*/main.go` | `main.ts`、`index.ts`、`app.ts` | `main.rs`、`lib.rs` | `config.ru`、`config/application.rb` | `public/index.php`、`artisan` |
| **DI/IoC** | `*ServiceCollectionExtensions.cs`、`Program.cs` | `@Configuration` 类 | `containers.py`、`settings.py` | `wire.go`、`fx.go` | `*.module.ts`(Nest)、`container.ts` | `mod.rs` 中 `pub use` | `config/initializers/` | `app/Providers/*ServiceProvider.php` |
| **接口/抽象** | `I*Service.cs`、`I*Repository.cs` | `*Service.java`(interface) | `Protocol` / `abc.ABC` | 包级 `interface{}` | `*.interface.ts`、`*.abstract.ts` | `trait` 定义 | `app/services/` | `app/Contracts/` |
| **配置模型** | `*Options.cs`、`*Settings.cs` | `*Properties.java` | `Settings`(Pydantic) | `config.go` | `*.config.ts` | `config.rs` | `config/*.rb` | `config/*.php` |
| **实体/模型** | `*Entity.cs`、`*Model.cs` | `@Entity` 类 | `models.py` | `*_model.go`、`ent/schema/` | `*.entity.ts`、`*.model.ts`、`schema.prisma` | `models/`、`schema.rs` | `app/models/*.rb` | `app/Models/*.php` |
| **Controller/Handler** | `*Controller.cs` | `@RestController` | `views.py`、`routers/*.py` | `handler*.go` | `*.controller.ts`、`routes/*.ts` | `handlers/`、`routes.rs` | `app/controllers/*.rb` | `app/Http/Controllers/*.php` |
| **数据库迁移** | `Migrations/*.cs` | `db/migration/V*.sql` | `migrations/*.py` | `migrate/*.sql` | `migrations/*.ts` | `migrations/*.sql` | `db/migrate/*.rb` | `database/migrations/*.php` |
| **领域事件** | `*Event.cs`、`*Notification.cs` | `*Event.java`、`@EventListener` | `signals.py` | `events.go` | `*.event.ts` | `events.rs` | `app/events/` | `app/Events/` |

> **使用规则**：
> 1. 这些是**候选**——找不到不强制；找到也不一定是最佳锚点。
> 2. Phase A3 子代理读这些文件时，**只读到能写出 1-2 句业务定位为止**，禁止把整文件 dump 进上下文。
> 3. 任何从这些文件提取的断言都必须落到 `[file#Symbol]` 锚点格式。

---

## 三、前端业务锚点候选矩阵

| 锚点类型 | react | vue | angular | svelte | next | nuxt |
|---------|-------|-----|---------|--------|------|------|
| **入口点** | `index.tsx`、`App.tsx` | `main.ts`、`App.vue` | `main.ts`、`app.module.ts` | `src/routes/+layout.svelte` | `app/layout.tsx`、`pages/_app.tsx` | `app.vue`、`nuxt.config.ts` |
| **路由** | `routes.tsx`、React Router | `router/index.ts` | `app-routing.module.ts` | `src/routes/` 目录 | `app/` 或 `pages/` 目录 | `pages/` 目录 |
| **全局状态** | `store.ts`(Redux/Zustand) | `store/index.ts`(Pinia/Vuex) | NgRx、`*.service.ts`(RxJS) | `$lib/stores/` | `store.ts` | `composables/`、`store/` |
| **API/数据层** | `api/*.ts`、`services/*.ts` | `api/*.ts` | `*.service.ts`(HttpClient) | `src/lib/api/` | `app/api/` | `server/api/` |
| **页面** | `pages/*.tsx` | `views/*.vue` | `*-page.component.ts` | `src/routes/*/+page.svelte` | `app/*/page.tsx` | `pages/*.vue` |

> 元框架（Next / Nuxt / SvelteKit）以**目录结构为路由约定**——Phase A3 应优先按目录树识别"页面群"，再到每个页面里找业务符号，而不是把页面当独立模块。

---

## 四、模块根目录候选启发式

Phase A1 在各栈下应优先扫描以下目录（按优先级），命中的子目录即为模块候选：

| primary | 优先模块根（按优先级） |
|---------|----------------------|
| `csharp` | `src/Modules/*/`、`src/*/`、`*/src/`（顶层项目目录）|
| `java` | `src/main/java/<package>/<feature>/`、Gradle subprojects 根 |
| `python` | `src/<package>/<feature>/`、顶层 `<package>/<feature>/`、Django app 根 |
| `go` | `internal/<feature>/`、`pkg/<feature>/`、`cmd/<binary>/` |
| `typescript` | `src/modules/*/`(Nest)、`src/features/*/`、`apps/<app>/`(monorepo)、`packages/<pkg>/`(monorepo) |
| `rust` | `crates/<crate>/`(workspace)、`src/<module>/` |
| `ruby` | `app/<concept>/`(Rails 7 components)、`engines/*/`(Rails engines) |
| `php` | `app/<DomainName>/`(DDD)、`modules/<module>/` |

### 通用降级规则

1. 上表全空 → fallback 到顶层目录中**非配置/非脚本/非测试**的目录
2. 顶层只有 1 个有意义目录 → 整项目视为单模块（命名为项目名）
3. 候选模块 > 30 个 → 提示用户："识别出 {N} 个候选模块，疑似 monorepo，是否分批生成？"

---

## 五、识别失败时的处理

| 情况 | Phase A0 行为 |
|------|--------------|
| 没匹配到任何依赖文件 | 提示用户手动指定 `primary`，写入 MANIFEST 后继续 |
| 多个 primary 同时命中（罕见） | 选**仓库文件最多**的那一个，把其余写入 `variants` |
| 探测命令报错（缺 fd/rg） | 用 `find` / `grep` fallback；fallback 也失败 → 终止 Mode A，要求用户安装 fd/rg |
| 单仓库 monorepo | v0.1：仍然在仓库根写一份 ai-docs/，每个 package 视为顶层模块 |

---

## 六、架构布局检测（分层 vs 领域）

> Phase A1 在识别子模块之前，必须先判断项目的代码组织模式。不同的组织模式需要不同的模块识别策略。

### 检测方法

1. 列出项目源代码目录下的所有顶层子目录（排除构建产物、配置、工具目录）
2. 将每个目录名与以下两类关键词对比分类：

| 类别 | 关键词（不区分大小写） |
|------|---------------------|
| **技术层关键词** | Controllers, Services, Repositories, Models, Entities, Handlers, Middleware, Infrastructure, Domain, Application, Persistence, Presentation, DTOs, ViewModels, Validators, Providers, Mappers, Helpers, Utils, Common, Shared, Extensions, Filters, Interceptors, Guards, Pipes, Decorators |
| **业务域关键词** | 非技术层关键词的业务语义词（如 Orders, Users, Products, Auth, Payment, Inventory, Notification, Billing, Shipping 等） |

3. 判断矩阵：

| 顶层目录主要是... | 架构模式 | 模块策略 |
|------------------|---------|---------|
| 业务域目录（如 `Orders/`, `Users/`, `Auth/`） | 领域组织 | 直接用 Section 四的目录级识别 |
| 技术层目录（如 `Controllers/`, `Services/`, `Models/`） | 分层架构 | **必须**执行 Section 七的跨层业务领域提取 |
| 混合或不确定 | 混合架构 | 检查技术层目录内是否有二级业务子目录；若有则按二级目录识别；否则向用户展示候选方案让其选择 |

> **重要**：大量真实项目采用分层架构，模块不是按目录划分而是按业务概念跨层存在。如果跳过此步直接用目录识别，会错误地将 `Controllers`、`Services`、`Models` 识别为模块，而非 `订单`、`用户`、`支付` 等业务模块。

---

## 七、跨层业务领域提取（分层架构专用）

> 仅当 Section 六检测到**分层架构**时执行。

**目标**：从分散在各技术层目录中的文件命名中提取业务概念，将同一业务概念的跨层文件聚合为一个模块。

### 算法步骤

1. 对每个技术层目录（Controllers/, Services/, Models/ 等），列出所有源文件名
2. 从文件名中剥离技术层后缀，提取业务概念前缀

### 各技术栈后缀剥离规则

| 技术栈 | 剥离后缀（不区分大小写） |
|--------|----------------------|
| C# / .NET | Controller, Service, Repository, Model, Entity, Handler, Validator, DTO, ViewModel, Options, Extensions, Manager, Provider, Factory, Middleware, Filter, Attribute, Profile |
| Java / Spring | Controller, Service, ServiceImpl, Repository, Entity, DTO, VO, Mapper, Config, Converter, Listener, Aspect, Interceptor, Handler |
| Python | View, ViewSet, Serializer, Model, Form, Admin, Signal, Task, Command, Manager, Mixin, Filter |
| Go | Handler, Service, Repository, Model, Store, Controller, Middleware, Router |
| Node.js / TS | Controller, Service, Module, Entity, DTO, Guard, Pipe, Interceptor, Middleware, Gateway, Resolver, Subscriber |
| Ruby / Rails | Controller, Model, Serializer, Service, Job, Mailer, Policy, Decorator |
| PHP / Laravel | Controller, Model, Service, Repository, Request, Resource, Policy, Event, Listener, Job, Mail, Notification |
| Rust | Handler, Service, Repository, Model, Store, Router |

### 确定性 shell 命令

```bash
# C# / .NET
fd -e cs --type f Controllers/ Services/ Models/ Repositories/ | \
  xargs -I{} basename {} .cs | \
  sed -E 's/(Controller|Service|Repository|Model|Entity|Handler|Validator|DTO|ViewModel|Options|Manager|Provider)$//' | \
  sort | uniq -c | sort -rn

# Java / Spring
fd -e java --type f controller/ service/ model/ repository/ | \
  xargs -I{} basename {} .java | \
  sed -E 's/(Controller|Service|ServiceImpl|Repository|Entity|DTO|VO|Mapper)$//' | \
  sort | uniq -c | sort -rn

# Python
fd -e py --type f views/ serializers/ models/ | \
  xargs -I{} basename {} .py | \
  sed -E 's/(View|ViewSet|Serializer|Model|Form|Admin)$//' | \
  sort | uniq -c | sort -rn

# Go
fd -e go --type f handler/ service/ model/ repository/ | \
  xargs -I{} basename {} .go | \
  sed -E 's/(Handler|Service|Repository|Model|Store)$//' | \
  sort | uniq -c | sort -rn

# Node.js / TS (NestJS)
fd -e ts --type f controllers/ services/ entities/ | \
  xargs -I{} basename {} .ts | \
  sed -E 's/\.(controller|service|entity|module|dto|guard|pipe)$//' | \
  sort | uniq -c | sort -rn

# Ruby / Rails
fd -e rb --type f app/controllers/ app/models/ app/services/ | \
  xargs -I{} basename {} .rb | \
  sed -E 's/(Controller|Model|Service|Serializer|Job|Policy)$//' | \
  sort | uniq -c | sort -rn

# PHP / Laravel
fd -e php --type f app/Http/Controllers/ app/Models/ app/Services/ | \
  xargs -I{} basename {} .php | \
  sed -E 's/(Controller|Model|Service|Repository|Request|Resource|Policy)$//' | \
  sort | uniq -c | sort -rn
```

### 模块候选规则

- 出现在 **2+ 个**技术层中的业务概念 = **一个模块候选**
- 仅出现在 1 个层中的 = 归入「公共/共享」模块或暂不归类
- 无法剥离后缀的文件（如 `Program.cs`、`Startup.cs`）= 基础设施文件，不参与模块划分

### 向用户确认

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
