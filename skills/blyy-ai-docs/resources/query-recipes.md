# Query Recipes — 8 大技术栈的查询命令库

> **何时读取**：Mode A Phase A2 拼装 `ai-docs/code-queries.md` 时。其他时机不应读取此文件。
>
> **用途**：本文件是命令模板库。Mode A Phase A2 根据 `detected_stack` 挑选对应小节的 recipe，把占位符替换为实际值后，写入用户项目的 `ai-docs/code-queries.md`。

## 配方表索引

每条 recipe 格式：

```
### R-XXX-NN-<stack>
**用途**：一句话描述何时用这条 recipe
**命令**：
```bash
<command>
```
**预期输出形式**：单行/多行/文件清单/计数等
**fallback**（无 fd/rg 时）：
```bash
<find/grep version>
```
```

---

## 一、C# / .NET (csharp)

### R-ENT-01-cs：列出所有实体类

**命令**：
```bash
fd -e cs --type f | xargs rg -l '\b(class|record)\s+\w+\b' | xargs rg -l '\[Table\(|: DbContext|: IEntity'
```

更宽松版（按命名约定）：
```bash
fd -e cs '(Entity|Model)\.cs$' --type f
```

**预期输出**：文件路径列表
**fallback**：
```bash
find . -name '*.cs' -type f | xargs grep -l '\[Table('
```

### R-EP-01-cs：列出所有 HTTP 端点

**命令**：
```bash
rg -n --type cs '\[Http(Get|Post|Put|Delete|Patch)(Attribute)?\('
```

**预期输出**：`file:line: [HttpGet("/path")]`

### R-CFG-01-cs：列出所有配置文件

**命令**：
```bash
fd '^appsettings.*\.json$|^launchSettings\.json$' --type f
```

### R-SVC-01-cs：列出所有服务类

**命令**：
```bash
fd -e cs '(Service|Handler|UseCase)\.cs$' --type f
```

### R-DB-01-cs：列出 EF Core 迁移

**命令**：
```bash
fd -e cs --full-path '/Migrations/' --type f
```

### R-TEST-01-cs：列出测试文件

**命令**：
```bash
fd -e cs '(Tests?|Spec)\.cs$' --type f
```

---

## 二、Java / Spring (java)

### R-ENT-01-java：列出所有 JPA 实体

**命令**：
```bash
rg -l '@Entity|@Table\(' --type java
```

### R-EP-01-java：列出所有 Controller 端点

**命令**：
```bash
rg -n '@(Get|Post|Put|Delete|Patch|Request)Mapping' --type java
```

### R-CFG-01-java：列出配置文件

**命令**：
```bash
fd 'application(-\w+)?\.(yml|yaml|properties)$' --type f
```

### R-SVC-01-java：列出 Service 类

**命令**：
```bash
rg -l '@Service\b|@Component\b' --type java
```

### R-DB-01-java：列出 Flyway / Liquibase 迁移

**命令**：
```bash
fd 'V\d+__.*\.sql$|changelog.*\.(xml|yaml)$' --type f
```

### R-TEST-01-java：列出测试文件

**命令**：
```bash
fd 'Test(s)?\.java$' --type f
```

---

## 三、Python / FastAPI / Django (python)

### R-ENT-01-py-django：列出 Django 模型

**命令**：
```bash
rg -nP 'class\s+\w+\(.*models\.Model.*\):' --type py
```

### R-ENT-01-py-sqlalchemy：列出 SQLAlchemy 模型

**命令**：
```bash
rg -nP 'class\s+\w+\(.*Base.*\):' --type py
```

### R-EP-01-py-fastapi：列出 FastAPI 端点

**命令**：
```bash
rg -nP '@\w+\.(get|post|put|delete|patch)\(' --type py
```

### R-EP-01-py-django：列出 Django URL routes

**命令**：
```bash
rg -nP '\bpath\(|^\s*url\(' --type py
```

### R-CFG-01-py：列出配置入口

**命令**：
```bash
fd '(settings|config|\.env)' --type f --no-ignore --exclude .venv --exclude node_modules
```

### R-DB-01-py：列出 Alembic / Django 迁移

**命令**：
```bash
fd --full-path '/migrations/' --type f -e py
```

### R-TEST-01-py：列出测试文件

**命令**：
```bash
fd '^test_.*\.py$|.*_test\.py$' --type f
```

---

## 四、Go (go)

### R-ENT-01-go：列出 struct（疑似实体）

**命令**：
```bash
rg -nP '^type\s+\w+\s+struct\s*\{' --type go
```

### R-EP-01-go：列出 HTTP handler 注册

**命令**：
```bash
rg -nP '\.(GET|POST|PUT|DELETE|PATCH|Handle)\(' --type go
```

### R-CFG-01-go：列出配置文件

**命令**：
```bash
fd '(config|settings)\.(go|yaml|toml)$' --type f
```

### R-SVC-01-go：列出 service 包

**命令**：
```bash
fd --full-path '/(service|usecase|handler)/' --type d
```

### R-DB-01-go：列出迁移文件

**命令**：
```bash
fd --full-path '/migrations?/' --type f
```

### R-TEST-01-go：列出测试文件

**命令**：
```bash
fd '_test\.go$' --type f
```

---

## 五、Node.js / TypeScript (typescript)

### R-ENT-01-ts-typeorm：列出 TypeORM 实体

**命令**：
```bash
rg -l '@Entity\b|@Schema\(' --type ts
```

### R-ENT-01-ts-prisma：列出 Prisma model（schema 文件）

**命令**：
```bash
fd 'schema\.prisma$' --type f
```

### R-EP-01-ts-nest：列出 NestJS 端点

**命令**：
```bash
rg -nP '@(Get|Post|Put|Delete|Patch)\(' --type ts
```

### R-EP-01-ts-express：列出 Express 路由

**命令**：
```bash
rg -nP '\b(router|app)\.(get|post|put|delete|patch)\(' --type ts
```

### R-CFG-01-ts：列出配置文件

**命令**：
```bash
fd '(\.env|config\.(ts|js|json)|.*\.config\.(ts|js))$' --type f
```

### R-SVC-01-ts：列出 service 类

**命令**：
```bash
fd '\.service\.(ts|js)$' --type f
```

### R-DB-01-ts：列出迁移文件

**命令**：
```bash
fd --full-path '/migrations?/' --type f
```

### R-TEST-01-ts：列出测试文件

**命令**：
```bash
fd '\.(spec|test)\.(ts|tsx|js|jsx)$' --type f
```

---

## 六、Ruby / Rails (ruby)

### R-ENT-01-ruby：列出 ActiveRecord 模型

**命令**：
```bash
rg -nP 'class\s+\w+\s+<\s+ApplicationRecord' --type ruby
```

### R-EP-01-ruby：列出路由

**命令**：
```bash
fd 'routes\.rb$' -x cat
```

### R-CFG-01-ruby：列出配置文件

**命令**：
```bash
fd --full-path '/config/' -e rb -e yml --type f
```

### R-DB-01-ruby：列出 Rails 迁移

**命令**：
```bash
fd --full-path '/db/migrate/' --type f
```

---

## 七、PHP / Laravel (php)

### R-ENT-01-php：列出 Eloquent 模型

**命令**：
```bash
rg -l 'extends Model\b' --type php
```

### R-EP-01-php：列出路由

**命令**：
```bash
rg -nP "Route::(get|post|put|delete|patch)\(" --type php
```

### R-CFG-01-php：列出配置文件

**命令**：
```bash
fd --full-path '/config/' -e php --type f
```

### R-DB-01-php：列出 Laravel 迁移

**命令**：
```bash
fd --full-path '/database/migrations/' --type f
```

---

## 八、Rust (rust)

### R-ENT-01-rs：列出 struct

**命令**：
```bash
rg -nP '^pub\s+struct\s+\w+' --type rust
```

### R-EP-01-rs-actix：列出 actix-web handler

**命令**：
```bash
rg -nP '#\[(get|post|put|delete|patch)\(' --type rust
```

### R-EP-01-rs-axum：列出 axum router 注册

**命令**：
```bash
rg -nP '\.route\("' --type rust
```

### R-CFG-01-rs：列出配置文件

**命令**：
```bash
fd '(Cargo\.toml|config\.toml|\.env)$' --type f
```

### R-DB-01-rs：列出迁移目录

**命令**：
```bash
fd --full-path '/migrations?/' --type f
```

---

## 跨栈通用 Recipes

这些不依赖具体技术栈，所有项目都可启用。

### R-GIT-01：本月活跃文件 Top 20

```bash
git log --since='1 month ago' --pretty=format: --name-only | sort | uniq -c | sort -rn | head -20
```

### R-GIT-02：某文件的修改频率

```bash
git log --oneline -- <file> | wc -l
```

### R-GIT-03：某符号最后一次被修改

```bash
git log -p -S '<symbol>' --all | head -50
```

### R-FILE-01：项目总文件数（去除常见噪声）

```bash
fd --type f --exclude .git --exclude node_modules --exclude bin --exclude obj --exclude dist --exclude build --exclude target --exclude .venv | wc -l
```

### R-FILE-02：某模块的目录树（≤3 层）

```bash
fd --type f --max-depth 3 . <module_root>
```

---

## fd / rg 不可用时的 fallback

通用替换原则：

| fd 命令 | find 等价 |
|---------|---------|
| `fd -e cs` | `find . -name '*.cs' -type f` |
| `fd 'pattern'` | `find . -type f -name '*pattern*'` |
| `fd --full-path '/Migrations/'` | `find . -type d -name 'Migrations' -prune -o -type f -print` |

| rg 命令 | grep 等价 |
|---------|---------|
| `rg -n 'pattern' --type cs` | `grep -rn 'pattern' --include='*.cs' .` |
| `rg -l 'pattern'` | `grep -rl 'pattern' .` |
| `rg -nP 'regex'` | `grep -rnE 'regex' .` |

每条 recipe 在写入用户的 `ai-docs/code-queries.md` 时，都应同时附上 fallback 版本，避免缺工具时 AI 死循环。

---

## 给 Phase A2 的拼装算法

```
input:  detected_stack (例如 "csharp+aspnetcore+efcore")
        modules (例如 [{name: "Orders", code_root: "src/Modules/Orders/"}, ...])
output: ai-docs/code-queries.md

steps:
1. 加载 templates/code-queries.md.template 作为骨架
2. 对 detected_stack 拆分主语言 + framework 变体
3. 从本文件挑选对应小节的所有 R-XXX-NN-<stack> 条目
4. 把选中的命令填入骨架的 {{XXX_COMMAND}} 占位符
5. 对每个 module，生成 "### R-MOD-files-<module>" 段落，把 <module_root> 替换为实际路径
6. 写入 ai-docs/code-queries.md
7. 把启用的 recipe id 列表写入 MANIFEST.code_queries_registered
```
