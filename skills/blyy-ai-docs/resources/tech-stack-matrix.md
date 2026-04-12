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

## 六、与 blyy-init-docs 的边界

> **重要**：本文件**不**调用 / 引用 `blyy-init-docs/resources/doc-guide.md`。两个 skill 是完全独立的。
>
> 如果未来发现两边的栈识别表需要同步更新，由 docs/architecture.md 的"维护清单"明确——不要在 SKILL 之间互相 require。
