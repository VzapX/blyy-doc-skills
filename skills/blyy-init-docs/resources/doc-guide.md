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
| `AGENTS.md` | AI 工具 + 开发者 | 构建/运行/测试命令、项目结构、编码规范 | 必须 |
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
| `api-reference.md` | API 接口参考 | 接口变更 |

### 模块级文档

| 文档 | 核心职责 |
|------|---------|
| `README.md` | 模块概述、职责、边界、对外接口 |
| `flow.md` | 模块内部业务流程 |
| `data-model.md` | 模块内数据模型、表结构 |
| `code-map.md` | 模块内文件→职责映射 |
| `database/` | 模块内表 schema |

---

## 三、全局与模块文档分工

| 维度 | 全局文档 | 模块文档 |
|------|---------|---------|
| **流程** | `core-flow.md`：跨模块主流程 | `modules/<m>/flow.md`：模块内部流程 |
| **数据** | `data-model.md`：公共模型 + 索引 | `modules/<m>/data-model.md`：模块内模型 |
| **模块** | `modules.md`：注册表（一行摘要） | `modules/<m>/README.md`：详细说明 |
| **代码地图** | `code-map.md`：总览 + 模块链接 | `modules/<m>/code-map.md`：模块内映射 |
| **数据库** | `database/`：公共表 + 模块链接 | `modules/<m>/database/`：模块内表 schema |

---

## 四、Phase 2 填充规则

### 填充原则

1. **基于代码事实**：只填充能从代码中确认的信息，不臆测不编造
2. **不确定必澄清**：从已有文档或代码中提取信息写入新文档时，若对准确性、完整性存在不确定（包括但不限于：重要业务流程、模块边界与职责划分、关键设计决策、数据流向等），**必须先向用户澄清确认后再写入**
3. **保留占位符**：无法推断且用户暂未确认的部分使用 `<!-- TODO: 请补充 xxx -->` 标记
4. **更新元数据**：所有文档的 `last_updated` 设为生成当天

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

#### 搜索示例

```bash
# C#
fd -e cs "(Program|Startup|I[A-Z].*Service)" --type f
# Java
rg -l "@SpringBootApplication|@RestController|@Entity" --type java
# Python
fd "(manage|main|app|settings|models|views)" -e py --type f
# Vue
fd -e vue -e ts "(App|main|router|store)" --type f
# React
fd -e tsx -e ts "(App|index|routes|store)" --type f
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
| 业务项目 | 其他 | 进入 Step 3 |

#### Step 3 — 子模块识别（第二级）

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

## 五、文档模板占位符说明

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
| `<!-- Phase 2 自动填充 -->` | Phase 2 阶段由代码分析自动填充 |
| `<!-- TODO: xxx -->` | 需要人工补充的内容 |
