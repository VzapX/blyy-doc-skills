# 文档架构指南

本文档是 `blyy-init-docs` skill 的参考资源，说明文档架构设计理念、各文档职责以及 Phase 2 填充规则。

---

## 一、文档架构总览

```
项目根目录/
├── README.md              ← 项目入口：快速了解项目
├── AGENTS.md              ← AI/开发者指南：构建、运行、代码规范
├── CHANGELOG.md           ← 版本变更记录
├── CONTRIBUTING.md        ← 贡献指南（可选）
├── SECURITY.md            ← 安全策略（按需）
└── docs/
    ├── ARCHITECTURE.md    ← 系统总览 + 文档索引（入口文档）
    ├── code-map.md        ← 总览简述 + 各模块链接
    ├── modules.md         ← 模块注册表 + 模块间依赖
    ├── core-flow.md       ← 跨模块核心业务流程
    ├── config.md          ← 配置项参考
    ├── features.md        ← 功能列表 + 术语表
    ├── DECISIONS.md       ← 架构决策记录（ADR）
    ├── doc-maintenance.md ← 文档维护规则（AI 工具专用）
    ├── data-model.md      ← 公共数据模型 + 模块索引
    ├── runbook.md         ← 运维手册
    ├── deployment.md      ← 部署流程
    ├── api-reference.md   ← API 参考（按需）
    ├── database/          ← 公共/跨模块表 + 各模块链接
    └── modules/           ← 模块级文档
        └── <module>/
            ├── README.md      ← 模块职责与边界
            ├── flow.md        ← 模块内业务流程
            ├── data-model.md  ← 模块内数据模型
            ├── code-map.md    ← 模块内文件→职责映射
            └── database/      ← 模块内表 schema
```

---

## 二、各文档职责定义

### 根目录文档

| 文档 | 目标读者 | 核心职责 | 必要性 |
|------|---------|---------|--------|
| `README.md` | 所有人 | 项目第一印象：做什么、怎么用、怎么跑 | 必须 |
| `AGENTS.md` | AI 工具 + 开发者 | **任务入口协议**（必须先读 `docs/ARCHITECTURE.md`）+ 构建/运行/测试命令、项目结构、编码规范 | 必须 |
| `CHANGELOG.md` | 用户 + 开发者 | 每个版本的变更记录 | 必须 |
| `CONTRIBUTING.md` | 外部贡献者 | 如何参与项目 | 可选 |
| `SECURITY.md` | 安全研究者 | 漏洞报告流程、安全策略 | 按需 |

### docs/ 目录文档

| 文档 | 核心职责 | 更新触发器 |
|------|---------|-----------|
| `ARCHITECTURE.md` | 系统总览 + 架构图 + **文档索引入口** | 模块/数据流/文件变动 |
| `code-map.md` | 总览简述 + 各模块 code-map 链接 | 文件增/删/重命名 |
| `modules.md` | 模块注册表：模块摘要 + 链接到模块文档 | 模块增/删/职责变更 |
| `core-flow.md` | **跨模块**主业务流程 | 业务流程变化 |
| `config.md` | 所有配置项参考 | 配置变更 |
| `features.md` | 功能清单 + 术语表 | 功能增/删 |
| `DECISIONS.md` | 架构决策记录（ADR 格式） | 新决策 |
| `doc-maintenance.md` | AI 文档维护规则 | 规则变更 |
| `data-model.md` | 公共数据模型 + **模块索引** | 数据结构变更 |
| `runbook.md` | 运维手册 + 事故剧本 | 故障/运维变更 |
| `deployment.md` | 部署流程 + 回滚方案 | 部署方式变更 |
| `api-reference.md` | API 公共信息 + **模块索引** | 全局认证/错误码变更 |

### 模块级文档（按复杂度分级）

模块文档采用**三级文档形态**，根据模块复杂度评分自动决定：

#### 模块复杂度评分规则

| 信号 | 检测方式 | 得分 |
|------|---------|------|
| 模块源文件数 > 15 | `fd --type f <module_dir> \| wc -l` | +2 |
| 模块源文件数 5-15 | 同上 | +1 |
| 模块源文件数 < 5 | 同上 | 0 |
| 有数据库实体/模型文件 | 确定性清单中检测 | +1 |
| 有 API 端点（Controller/Handler） | 确定性清单中检测 | +1 |
| 被 ≥ 3 个其他模块依赖 | 反向引用扫描 | +1 |

#### 三级文档形态

| 总分 | 级别 | 文档形态 | 文件数 |
|------|------|---------|--------|
| ≥ 3 | **Core** | 完整目录 `modules/<m>/`（见下表） | 6 |
| 1-2 | **Standard** | 单文件 `modules/<m>.md`（所有章节合并） | 1 |
| 0 | **Lightweight** | 无独立文件，内联到 `modules.md` | 0 |

**Core 模块文档清单**（完整目录）：

| 文档 | 核心职责 |
|------|---------|
| `README.md` | 模块概述、职责、边界、对外接口 |
| `flow.md` | 模块内部业务流程 |
| `data-model.md` | 模块内数据模型、表结构 |
| `api-reference.md` | 模块内 API 接口详情 |
| `code-map.md` | 模块内文件→职责映射 |
| `database/` | 模块内表 schema |

**Standard 模块文档**（单文件 `modules/<m>.md`）：

使用 `templates/modules-single.md.template`，将上述 6 个文件的内容合并为一个文档的不同 H2 章节：概述 → 职责与边界 → 对外接口 → 依赖关系 → 代码地图 → 业务流程 → 数据模型 → API 参考。无内容的章节可删除（如无 API 的模块删除 API 参考章节）。

**Lightweight 模块**（内联到 `modules.md`）：

不生成独立文件。在 `modules.md` 模块注册表的 Lightweight 区域以展开段落呈现：职责、代码位置、文件数、关键类/函数、依赖方。

#### 级别升降规则

模块复杂度会随项目演进变化。级别变更由 `blyy-doc-sync` 检测触发：
- **升级**（如 Standard → Core）：创建模块目录，将单文件内容拆分为子文件
- **降级**（如 Core → Standard）：将目录下子文件合并为单文件，删除原目录
- 详见 `blyy-doc-sync` 防线 1 升级信号检测 + 防线 3 全量复评

---

## 三、全局与模块文档分工

> 下表中「模块文档」列仅适用于 **Core** 级别模块。Standard 模块的对应内容在单文件中以章节呈现，Lightweight 模块的内容内联在 `modules.md` 中。

| 维度 | 全局文档 | 模块文档（Core 级别） |
|------|---------|---------|
| **流程** | `core-flow.md`：跨模块主流程 | `modules/<m>/flow.md`：模块内部流程 |
| **数据** | `data-model.md`：公共模型 + 索引 | `modules/<m>/data-model.md`：模块内模型 |
| **模块** | `modules.md`：注册表 + Lightweight 内联 | `modules/<m>/README.md`：详细说明 |
| **代码地图** | `code-map.md`：总览 + 模块链接 | `modules/<m>/code-map.md`：模块内映射 |
| **API** | `api-reference.md`：公共信息 + 模块索引 | `modules/<m>/api-reference.md`：模块接口详情 |
| **数据库** | `database/`：公共表 + 模块链接 | `modules/<m>/database/`：模块内表 schema |

---

## 四、Phase 2 填充规则

### 填充原则

1. **穷举式枚举，禁止节选**：文档中所有列表型内容（实体类列表、配置项列表、API 端点列表、模块列表、数据库表列表等）必须**穷举**项目中的所有条目。严禁仅列举「代表性示例」后加省略号。若项目有 30 个实体类，文档中必须列出全部 30 个，每个一行。子代理在输出分析素材时同样遵守此原则。此要求适用于表格行、列表项等所有枚举性内容

   **强制执行机制 — 确定性清单预扫描**：「穷举式枚举」原则通过以下确定性机制保证执行，而非仅依赖 AI 的阅读能力：
   1. Phase 2 开始前，主 agent 使用 **shell 命令**（`fd`/`rg`，非 AI 阅读）生成项目的完整文件清单（按类别分类），建立确定性基线数量
   2. 每个子代理接收其负责范围内的**文件清单作为强制检查表**，指令要求逐一核对
   3. 子代理输出必须包含**检查表覆盖率**（如 `23/23 ✓`），未覆盖的文件必须说明原因
   4. Phase 3 验证时，将文档中的条目数与预扫描清单条目数**逐一比对**，而非重新扫描代码（避免再次遗漏）

   **确定性清点命令矩阵**（按技术栈选用）：

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

2. **字段说明必填**：`data-model.md` 中所有表结构详情表的「说明」列**禁止留空**。按以下优先级提取字段语义描述：

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

   > **三级事实分类对应**：优先级 1-3 的来源为 T1（直接提取），优先级 4 为 T2（高置信推断），优先级 5 为待确认标记。

3. **基于代码事实**：只填充能从代码中确认的信息，不臆测不编造
4. **不确定必澄清（批量模式）**：对准确性/完整性存在不确定的内容（业务流程、模块边界、设计决策、数据流向等），**必须先向用户澄清确认后再写入**，不得自行推测。但澄清方式采用**批量模式**：
   - 所有子代理完成后，主 agent 将不确定项按类别分组（模块边界类、业务流程类、数据模型类、配置类等），**一次性**呈现给用户
   - 每组以编号列表呈现，每个不确定项附带「最佳猜测」和置信度（高/中/低），用户可直接确认猜测或纠正
   - 大型项目模式下，不确定项集中在检查点 ③（Phase 2C 后）统一澄清
   - **禁止在填充过程中逐条打断用户** — 先收集，后批量
5. **保留占位符**：无法推断且用户暂未确认的部分使用 `<!-- TODO: 请补充 xxx -->` 标记
6. **更新元数据**：所有文档的 `last_updated` 设为生成当天

### 三级事实分类（Three-Tier Fact Classification）

所有写入文档的内容必须按以下三个级别分类，确保文档内容的可信度透明可控：

| 级别 | 定义 | 来源示例 | 处理方式 |
|------|------|---------|---------|
| **T1 — 确定性事实** | 直接从代码/文件名/配置中提取，无需推断 | shell 命令输出、文件名、类名、配置值、代码中的字面量、依赖版本号 | 直接写入文档，无需标记 |
| **T2 — 高置信推断** | 从代码模式中高置信推断，错误概率 < 10% | 命名约定推断（OrderService → 负责订单逻辑）、标准框架模式推断、依赖关系推断 | 直接写入文档，无需标记 |
| **T3 — 推测性内容** | 无法仅从代码确认，需要业务知识或设计意图 | 业务流程顺序、设计决策的动机、模块边界的"为什么"、性能/安全意图、非标准命名的语义 | 标记 `<!-- UNVERIFIED: {简述} -->` + 加入澄清批次 |

**分类示例：**

| 内容 | 级别 | 理由 |
|------|------|------|
| "项目包含 23 个实体类" | T1 | 来自 `fd` 命令清点结果 |
| "数据库类型: PostgreSQL" | T1 | 来自配置文件或依赖声明 |
| "OrderService 负责订单业务逻辑" | T2 | 类名 + 方法签名（CreateOrder, UpdateOrder）推断 |
| "Auth 模块处理认证和授权" | T2 | 标准命名 + 框架模式 |
| "订单创建后先扣库存再扣款" | T3 | 代码中存在调用链但执行顺序的业务语义需确认 |
| "选择 Redis 是为了高并发缓存" | T3 | 设计动机无法从代码推断 |
| "该模块计划在 v3.0 重构" | T3 | 路线图信息不在代码中 |

**规则：**

1. 子代理在输出分析素材时，**必须**为每个条目标注 T1/T2/T3 级别
2. T1 和 T2 内容可直接写入文档
3. **T3 内容禁止直接写入正式文档内容** — 必须用 `<!-- UNVERIFIED: {简述} -->` 注释包裹，同时加入填充前审查关卡的澄清批次
4. 用户在审查关卡中确认的 T3 → 升级为 T2，移除 `UNVERIFIED` 标记
5. 用户纠正的 T3 → 按用户输入修正后写入
6. 用户跳过的 T3 → 保留 `<!-- UNVERIFIED -->` 标记在文档中
7. Phase 3 验证时，统计文档中 `<!-- UNVERIFIED -->` 的数量，作为文档可信度指标

**子代理输出格式要求：**

每个分析条目必须包含事实级别标注：

| # | 条目 | 级别 | 代码依据 | 描述 |
|---|------|------|---------|------|
| 1 | OrderEntity | T1 | 文件 `Models/OrderEntity.cs` 存在 | 订单实体类，包含 Id, Status, Total 等字段 |
| 2 | OrderService 负责订单 CRUD | T2 | 类名 + 方法签名 `CreateOrder`/`UpdateOrder` | 从命名和方法推断 |
| 3 | 订单创建后自动通知仓库 | T3 | `OrderService.Create()` 末尾调用了 `NotificationService` | 不确定是通知仓库还是通知用户 |

### 技术栈识别

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

### 锚点文件矩阵

锚点文件是以最小阅读量获取最大结构信息的关键文件。根据识别到的技术栈选择对应矩阵。

#### 后端锚点

| 锚点类型 | C# / .NET | Java / Spring | Python / Django·FastAPI | Go | Node.js / TS |
|----------|-----------|---------------|------------------------|----|--------------|
| **入口点** | `Program.cs`、`Startup.cs` | `*Application.java`、`@SpringBootApplication` | `manage.py`、`main.py`、`app.py` | `main.go`、`cmd/` | `index.ts`、`app.ts`、`server.ts` |
| **DI/IoC** | `ServiceCollectionExtensions.cs` | `@Configuration`、`@Bean` 类 | `settings.py`(INSTALLED_APPS)、`container.py` | `wire.go`、`fx.go` | `module.ts`(NestJS)、`container.ts` |
| **接口/抽象** | `I*Service.cs`、`I*Repository.cs` | `*Service.java`(接口)、`*Repository.java` | `abc.ABC` 子类、Protocol 类 | `interface` 定义文件 | `*.interface.ts`、`*.abstract.ts` |
| **配置模型** | `*Options.cs`、`*Settings.cs` | `*Properties.java`、`application*.yml` | `*Settings`(Pydantic)、`settings.py` | `config.go`、`*.yaml` | `config.ts`、`*.config.js` |
| **实体/模型** | `*Entity.cs`、`*Model.cs` | `@Entity`、`@Table` 类 | `models.py`、`*Model` 类 | `*_model.go`、`ent/schema/` | `*.entity.ts`、`*.model.ts` |
| **控制器/路由** | `*Controller.cs` | `@RestController`、`@Controller` | `views.py`、`routers/*.py` | `handler*.go`、`routes.go` | `*.controller.ts`、`routes/*.ts` |
| **数据库迁移** | `Migrations/*.cs` | `db/migration/`、Flyway/Liquibase | `migrations/*.py` | `migrate/*.sql`、goose | `migrations/*.ts`、Knex/Prisma |

#### 前端锚点

| 锚点类型 | Vue (2/3) | React | Angular |
|----------|-----------|-------|---------|
| **入口点** | `main.ts`、`App.vue` | `index.tsx`、`App.tsx` | `main.ts`、`app.module.ts` |
| **路由** | `router/index.ts` | `routes.tsx`、React Router 配置 | `app-routing.module.ts` |
| **状态管理** | `store/index.ts`(Vuex/Pinia) | `store.ts`(Redux/Zustand) | `*.service.ts`(RxJS)、NgRx |
| **API 层** | `api/*.ts`、`services/*.ts` | `api/*.ts`、`services/*.ts` | `*.service.ts`(HttpClient) |
| **组件** | `components/*.vue` | `components/*.tsx` | `*.component.ts` |
| **页面/视图** | `views/*.vue`、`pages/*.vue` | `pages/*.tsx`、`views/*.tsx` | `*-page.component.ts` |
| **类型定义** | `types/*.ts`、`*.d.ts` | `types/*.ts`、`*.d.ts` | `*.model.ts`、`*.interface.ts` |

#### 补充后端锚点

| 锚点类型 | Rust | Ruby / Rails | PHP / Laravel | Kotlin / Android |
|----------|------|-------------|---------------|-----------------|
| **入口点** | `main.rs`、`lib.rs` | `config.ru`、`app/` | `public/index.php`、`artisan` | `*Application.kt`、`MainActivity.kt` |
| **DI/IoC** | `mod.rs`（模块声明） | `config/initializers/` | `app/Providers/*ServiceProvider.php` | `@Module`(Dagger/Hilt)、`di/` |
| **接口/抽象** | `trait` 定义文件 | `app/services/`、concerns | `app/Contracts/`、`*Interface.php` | `interface` 定义、`*Repository.kt` |
| **配置模型** | `config.rs`、`*.toml` | `config/*.rb`、`database.yml` | `config/*.php`、`.env` | `*Properties.kt`、`application*.yml` |
| **实体/模型** | `models/`、`schema.rs` | `app/models/*.rb` | `app/Models/*.php` | `@Entity`、`*Entity.kt` |
| **控制器/路由** | `handlers/`、`routes.rs` | `app/controllers/*.rb`、`routes.rb` | `app/Http/Controllers/*.php`、`routes/*.php` | `@RestController`、`*Controller.kt` |
| **数据库迁移** | `migrations/*.sql`、diesel | `db/migrate/*.rb` | `database/migrations/*.php` | `db/migration/`、Room `*_Migration.kt` |

#### 补充前端锚点

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

#### 搜索示例

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

### 模块识别策略（两级识别）

#### Step 1 — 识别项目（第一级）

| 语言/框架 | 项目来源 | 一个「项目」对应什么 |
|----------|---------|-------------------|
| C# / .NET | `.sln` 中的 `.csproj` | 一个 .csproj 项目 |
| Java | `pom.xml` 的 modules / `settings.gradle` | 一个 Maven module 或 Gradle subproject |
| Python | Monorepo 的 packages / 顶层 `src/` 子目录 | 一个 Python 包 |
| Go | `go.work` 模块 / 顶层 `cmd/` + `internal/` | 一个 Go module 或 cmd |
| Node.js / TS | `workspaces` / `pnpm-workspace.yaml` | 一个 workspace 包 |
| Vue / React / Angular | `src/` 下的组织方式 | 通常整个前端是一个项目 |

#### Step 2 — 项目性质判断

| 性质 | 识别特征 | 处理 |
|------|---------|------|
| 测试项目 | 名称含 `Tests`/`Test`/`test`/`spec`、目录为 `tests/`/`__tests__/` | 隶属被测项目 |
| 共享库 | 名称含 `Common`/`Shared`/`Core`/`Utils`/`Lib`，被多项目引用 | 独立模块 |
| 文档/工具 | 名称含 `docs`/`tools`/`scripts` | 通常跳过 |
| 业务项目 | 其他 | 进入 Step 2.5 |

#### Step 2.5 — 架构布局检测（分层 vs 领域）

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

#### Step 2.6 — 跨层业务领域提取（分层架构专用）

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

#### Step 3 — 子模块识别（第二级）

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

#### Step 4 — 高级架构模式识别

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

### 配置识别策略

| 语言/框架 | 配置文件 | 配置类 |
|----------|---------|--------|
| C# / .NET | `appsettings*.json` | `IOptions<T>` 实现、`*Options.cs` |
| Java / Spring | `application*.yml`、`application*.properties` | `@ConfigurationProperties` 类 |
| Python | `.env`、`settings.py`、`config.py` | Pydantic `BaseSettings` 子类 |
| Node.js / TS | `.env`、`config/`、`*.config.ts` | NestJS `@Module` 中的 config |
| Go | `*.yaml`、`*.toml` | `config.go`、Viper 配置 |
| 前端 | `.env.*`、`vite.config.ts`、`next.config.js` | 环境变量 `VITE_*`、`NEXT_PUBLIC_*` |

---

## 五、项目类型适配指南

不同类型的项目对文档的侧重点不同。Phase 0 识别技术栈后，应根据项目类型调整文档生成策略。

### 适配矩阵

| 项目类型 | 必须生成 | 建议生成 | 可跳过 | 特殊说明 |
|----------|---------|---------|--------|---------|
| **标准后端服务** | 全部基础文档 | `api-reference.md`、`monitoring.md` | — | 默认模式 |
| **全栈项目** | 全部基础文档 | `api-reference.md`、`testing.md` | — | 前后端分别作为模块处理 |
| **CLI 工具/库** | 基础文档（不含 `deployment.md`、`runbook.md`） | `api-reference.md`（作为 CLI 参数参考） | `monitoring.md`、`runbook.md` | `features.md` 侧重命令/参数列表 |
| **微服务** | 全部基础文档 + `monitoring.md` | `api-reference.md` | — | 每个服务作为一个模块；`deployment.md` 需覆盖多服务编排 |
| **数据管道/ETL** | 基础文档 | `monitoring.md` | `api-reference.md` | `core-flow.md` 侧重数据流而非业务流；`data-model.md` 侧重 schema 演化 |
| **前端 SPA** | 基础文档（不含数据库相关） | `testing.md` | `database/`、`data-model.md`、`runbook.md` | `features.md` 侧重页面/路由；模块按功能分区 |
| **基础设施项目** | 基础文档 | `monitoring.md` | `api-reference.md`、`data-model.md` | `deployment.md` 是核心文档；`config.md` 侧重环境变量和 IaC 变量 |

### 适配规则

1. Phase 0 识别技术栈后，自动匹配上表中的项目类型
2. 若匹配结果不确定（如全栈 vs 纯后端），向用户确认
3. **「可跳过」不等于「禁止生成」** — 用户明确要求时仍应生成
4. 无论项目类型，`ARCHITECTURE.md`、`code-map.md`、`modules.md`、`doc-maintenance.md` 始终生成

### 模板条件化生成清单

Phase 1 骨架生成时，根据项目类型决定哪些模板实例化。以下为各文档的生成条件：

| 文档 | 生成条件 | 渐进层级 |
|------|---------|---------|
| `README.md` | 始终生成 | Layer 1 |
| `AGENTS.md` / AI 上下文 | 始终生成 | Layer 1 |
| `ARCHITECTURE.md` | 始终生成 | Layer 1 |
| `modules.md` | 始终生成 | Layer 1 |
| `code-map.md` | 始终生成 | Layer 1 |
| `modules/<name>/*` | 每个识别到的模块 | Layer 2 |
| `modules/<name>/api-reference.md` | 模块有 API 接口（控制器/路由） | Layer 2 |
| `core-flow.md` | 始终生成 | Layer 3 |
| `config.md` | 始终生成 | Layer 3 |
| `data-model.md` | 项目有数据库或 ORM | Layer 3 |
| `features.md` | 始终生成 | Layer 3 |
| `DECISIONS.md` | 始终生成 | Layer 3 |
| `database/` | 项目有数据库 | Layer 3 |
| `CHANGELOG.md` | 始终生成（内容用户可选） | Layer 3 |
| `deployment.md` | 非 CLI/库项目 | Layer 4 |
| `testing.md` | 项目有测试目录或测试框架 | Layer 4 |
| `runbook.md` | 非 CLI/库/前端 SPA 项目 | Layer 4 |
| `monitoring.md` | 项目有监控配置或为微服务 | Layer 4 |
| `api-reference.md` | 项目有 API（控制器/路由） | Layer 4 |
| `doc-maintenance.md` | 始终生成 | Layer 4 |
| `CONTRIBUTING.md` | 用户确认后生成 | Layer 4 |
| `SECURITY.md` | 用户确认后生成 | Layer 4 |

**条件判断方法**（Phase 0/1 执行）：

| 条件 | 判断命令 |
|------|---------|
| 项目有数据库 | 存在迁移文件、ORM 配置、`database.yml`、`*.dbcontext*` 等 |
| 项目有 API | 存在控制器/路由文件（确定性清点结果中控制器数量 > 0） |
| 项目有测试 | 存在 `tests/`、`__tests__/`、`*_test.*`、`*.spec.*` 等 |
| 项目有监控 | 存在 `prometheus`、`grafana`、`datadog`、`newrelic` 相关配置 |
| 非 CLI/库 | 不满足 CLI/库条件（无 `bin/` 入口、非 npm 包等） |

**Phase 1 骨架生成时**：
1. 根据上表自动判断，仅创建满足条件的文档骨架
2. 向用户展示将要生成的文档清单，标注哪些被跳过及原因
3. 用户可追加被跳过的文档（`「可跳过」不等于「禁止生成」`）

---

## 六、文档模板占位符说明

| 占位符 | 含义 |
|--------|------|
| `{{PROJECT_NAME}}` | 项目名称 |
| `{{DATE}}` | 当前日期（YYYY-MM-DD） |
| `{{MODULE_NAME}}` | 模块名称 |
| `{{TABLE_NAME}}` | 数据库表名 |
| `{{RUNTIME}}` | 运行时（如 .NET 8、Node.js 20） |
| `{{VERSION}}` | 运行时版本 |
| `{{BUILD_COMMAND}}` | 构建命令 |
| `{{RUN_COMMAND}}` | 运行命令 |
| `{{TEST_COMMAND}}` | 测试命令 |
| `{{INSTALL_COMMAND}}` | 安装命令 |
| `{{PUBLISH_COMMAND}}` | 发布命令 |
| `{{INDENT_STYLE}}` | 缩进风格 |
| `{{LANGUAGE}}` | 编程语言 |
| `{{FRAMEWORK}}` | 框架 |
| `{{PROJECT_STRUCTURE}}` | 项目目录结构 |
| `{{DATABASE_TYPE}}` | 数据库类型（如 PostgreSQL、MongoDB、SQLite） |
| `{{DEPLOYED_URL}}` | 部署访问地址（各环境） |
| `{{MONITORING_DASHBOARD_URL}}` | 监控仪表盘地址 |
| `{{LOG_SYSTEM}}` | 日志聚合系统（如 ELK、Loki、DataDog） |
| `{{RELEASE_CADENCE}}` | 发布节奏（如 每周、每两周、持续部署） |
| `<!-- Phase 2 自动填充 -->` | Phase 2 阶段由代码分析自动填充 |
| `<!-- TODO[priority,type,owner]: xxx -->` | 需要人工补充的内容（结构化 TODO，详见七.2） |
| `<!-- UNVERIFIED: xxx -->` | T3 推测性内容，待用户确认 |
| `<!-- AI-READ-HINT ... -->` | 文档头部 AI 阅读提示块（详见七.3） |
| `<!-- AI-RULE: xxx -->` | 针对 AI 的硬约束（详见七.3） |

---

## 七、YAML Front Matter 字段标准

> 所有 `docs/*.md` 与 `docs/modules/<m>/*.md` 模板的 YAML front matter 必须遵循下方的标准字段集。
> 字段分为两类：**结构性字段**（影响 AI 路由与渐进式披露）和**维护性字段**（影响 doc-sync 同步）。

### 七.1 标准字段集

```yaml
---
# === 维护性字段 ===
last_updated: 2026-04-08          # 文档最后修改日期（YYYY-MM-DD）
last_synced_commit: a1b2c3d        # 最后一次与代码同步时的 Git short SHA（doc-sync 防线 3 用于趋势对比）

# === 结构性字段 ===
audience: ai-and-human             # 取值: ai-only | human-only | ai-and-human
read_priority: 2                   # 取值: 1-4，对应 Layer 1-4 渐进式披露层级
max_lines: 200                     # 体积硬约束。doc-sync 防线 2 在超标时告警，提示拆分
parent_doc: ARCHITECTURE.md        # 文档树上的父节点，根节点为空
code_anchors:                      # 本文档对应的代码路径（用于 AI 反向定位）
  - src/Modules/Orders/
  - src/Services/OrderService.cs
applicable_project_types:          # 适用的项目类型，用于 Phase 1 骨架按 front matter 自动过滤
  - backend-service
  - microservice
  - fullstack

# === 同步触发器 ===
change_triggers:
  - 业务流程变化
  - 模块边界调整
---
```

### 七.2 字段释义

| 字段 | 类型 | 必填 | 取值 | 用途 |
|------|------|------|------|------|
| `last_updated` | date | 是 | YYYY-MM-DD | 最后修改日期。doc-sync 每次更新必须刷新 |
| `last_synced_commit` | string | 是 | Git short SHA（7 位）或 `init` | 与代码同步基线。doc-sync 防线 3 据此判断"自上次同步是否真有相关变更" |
| `audience` | enum | 是 | `ai-only` / `human-only` / `ai-and-human` | AI 是否应读取此文档 |
| `read_priority` | int | 是 | 1 / 2 / 3 / 4 | Layer 层级。1 = 核心入口（每次都读），4 = 按需查阅 |
| `max_lines` | int | 是 | 推荐: 入口型 ≤150, 模块型 ≤300, 参考型 ≤500 | 体积上限。超标告警 |
| `parent_doc` | path | 否 | 相对路径或为空 | 文档树父节点，构建文档导航关系 |
| `code_anchors` | list | 否 | 文件/目录路径 | 反向定位代码用 |
| `applicable_project_types` | list | 否 | 见下表 | Phase 1 骨架按此过滤生成 |
| `change_triggers` | list | 是 | 自然语言描述 | 触发文档更新的事件清单 |

**项目类型枚举值**（与五、项目类型适配指南对齐）：
- `backend-service` — 标准后端服务
- `microservice` — 微服务
- `fullstack` — 全栈项目
- `frontend-spa` — 前端 SPA
- `cli-tool` — CLI 工具
- `library` — 库
- `data-pipeline` — 数据管道/ETL
- `infrastructure` — 基础设施

**`audience` 字段使用规则：**
- `ai-only` — 只供 AI 工具使用，人类无需阅读（如 `doc-maintenance.md`）
- `human-only` — 只供人类阅读（如 `CONTRIBUTING.md` 部分章节）
- `ai-and-human` — 默认值，两者都需要

### 七.3 文档头部 AI 提示块（AI-READ-HINT）

每个 `read_priority ≥ 2` 的模板都应在 H1 标题后紧跟一个 AI 提示块，告诉 AI 何时读、何时跳过：

```markdown
# 运维手册

<!-- AI-READ-HINT
PURPOSE: 排查线上故障、制定运维操作步骤。
READ-WHEN: 用户提到「告警 / 宕机 / 性能问题 / 备份恢复 / 监控异常」。
SKIP-WHEN: 写新代码、改业务逻辑、修业务 bug（除非 bug 与运维相关）。
PAIRED-WITH: monitoring.md（指标）, deployment.md（发布）
-->
```

针对模板内某个章节的硬约束，使用 `AI-RULE`：

```markdown
```mermaid
%% AI-RULE: 此图必须基于实际入口点分析生成。若无法生成 ≥3 个真实节点，删除整个代码块。
```
```

### 七.4 结构化 TODO 标记

旧的 `<!-- TODO: xxx -->` 升级为结构化格式（**位置参数，逗号分隔，无 `key=` 前缀**，便于正则解析）：

```markdown
<!-- TODO[p1,design-rationale,user]: 请补充订单创建后的通知策略 -->
```

格式：`<!-- TODO[<priority>,<type>,<owner>]: <简述> -->`

| 字段 | 取值 | 含义 |
|------|------|------|
| `priority` | `p0` / `p1` / `p2` / `p3` | p0 = 阻塞文档使用（必须立即处理），p1 = 阻塞文档可用性，p2 = 重要补充，p3 = 锦上添花 |
| `type` | 见下表 | TODO 的内容类型，决定 doc-sync 的处理路由 |
| `owner` | `user` / `dev-team` / `ops-team` / `security-team` / 具体负责人名 | 应由谁补充 |

**type 枚举值**：

| 值 | 含义 | doc-sync 处理策略 |
|----|------|------------------|
| `business-context` | 业务上下文（流程、规则、领域知识） | 防线 1 Step 4 检查代码事实，能填则填；否则按 owner 分组提问 |
| `design-rationale` | 设计决策与理由 | 等待 ADR 或代码注释支撑；满足则升级为正式条目 |
| `ops-info` | 运维操作信息（备份、剧本、维护窗口） | 等待 ops-team 输入或运维代码补充 |
| `security-info` | 安全相关信息（漏洞处理、密钥轮换） | 等待 security-team 输入；防线 1 不自动填充 |
| `external-link` | 外部资源 URL（仪表盘、文档站、注册中心） | 等待用户提供链接 |
| `metric-baseline` | 指标基线值（SLA、性能基准） | 等待实测或配置补充 |

doc-sync 防线 1 Step 4 按 `priority` 顺序处理（p0 → p3），按 `type` 路由处理策略并按 `owner` 分组提问；防线 3 Step 4 按 `priority`/`type`/`owner` 三维度聚合统计。

### 七.5 体积约束（max_lines）的执行

- Phase 3 验证时统计每个文档实际行数，超标列入完成报告
- doc-sync 防线 2（提交前验证）执行 `wc -l docs/**/*.md` 与 front matter 中的 `max_lines` 比对，超标即告警
- 超标处理建议：拆分为多个小文档 + 在原文档保留索引
