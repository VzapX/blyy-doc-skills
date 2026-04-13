# Sync Matrix — 代码变更→文档更新映射

> **何时读取**：Mode B Phase B1（与 4-tier 失效检测并行使用）。
>
> **目的**：让 Mode B 在跑被动 sha 检测之前，先根据代码变更类型**主动判断**哪些 ai-docs 文件需要更新。两者互补——矩阵提供快速首轮定位，4-tier 捕获矩阵遗漏的细粒度变化。
>
> **与 docs/ 的区别**：ai-docs 采用 Hub-and-Spoke 结构（INDEX.md + 每模块独立详情文件），禁止重复代码事实，因此映射表远比 docs/ 精简。

---

## 一、变更类型→文档映射

> v2 架构下，大部分变更类型指向具体的模块文件 `modules/{slug}.md`（或目录模式的 topic 文件），而非全局平面文件。

| 代码变更类型 | 需检查的 ai-docs 文件 | 更新内容 |
|-------------|---------------------|---------|
| **模块级变更** | | |
| 新增业务模块目录 | `INDEX.md` + `MANIFEST.yaml` | 评分分级→创建 `modules/{slug}.md`→更新 INDEX Module Quick Index + MANIFEST.modules |
| 删除业务模块目录 | `INDEX.md` + `MANIFEST.yaml` | 删除 `modules/{slug}.md`（或 `modules/{slug}/` 目录）+ INDEX 移除行 + 清理其他模块文件中的跨引用 |
| 模块职责变更（入口文件重构） | `modules/{slug}.md` 或 `modules/{slug}/_index.md` | 更新 Business Summary + Entry Anchors |
| 模块间依赖变化（import/using 增删） | 涉及的模块详情文件 + `INDEX.md` | 更新 Dependencies 章节 + INDEX Dependency Graph |
| **术语与数据模型变更** | | |
| 新增/重命名核心实体类 | `modules/{slug}.md` Terms 章节（或 `modules/{slug}/terms.md`） | 新增/更新术语 ↔ 符号映射行 |
| 废弃业务术语/实体 | 同上 | 标注 deprecated 或移除 |
| 引入新业务缩写 | 同上 | 补充同义词/缩写 |
| **业务流程变更** | | |
| 跨模块业务流程变化 | trigger 模块的详情文件 Flows 章节（或 `modules/{slug}/flows.md`）+ `INDEX.md` Flow Catalog | 更新流程步骤 + 锚点 + INDEX 路由行 |
| 模块内流程重构（影响跨模块调用） | trigger 模块 Flows 章节 + 涉及模块的 Dependencies | 更新流程步骤 + 依赖关系 |
| **架构决策变更** | | |
| 新增架构决策（ADR / 注释中 "why"） | 归属模块的详情文件 Decisions 章节；全局决策 → `INDEX.md` Global Decisions | 新增决策条目 |
| 修改/废弃已有不变式 | 同上 | 更新/标注废弃 |
| **技术栈变更** | | |
| 切换框架/ORM/HTTP 库 | `code-queries.md` + `MANIFEST.yaml` | 更新 recipe 命令 + detected_stack.variants |
| 新增语言栈（如加前端） | `code-queries.md` + `INDEX.md` + 新模块详情文件 | 补充该栈的 recipe + 注册新模块 |
| **基础设施变更** | | |
| 文件重命名/移动 | `MANIFEST.anchors[].docs` 指向的具体模块文件 | 4-tier Tier 1 会捕获→STALE，矩阵加速定位到具体模块文件 |
| 大规模重构（>30% 文件变更） | 建议降级到 Mode A | 提示用户 |

> **未列出的变更类型**（纯内容修改、bug 修复等）：由 4-tier 失效检测的 Tier 2/3（sha 比对）自动捕获，`MANIFEST.anchors[].docs` 反向索引精确指向受影响的模块文件，无需矩阵映射。

---

## 二、使用方式

Mode B Phase B1 的推荐执行顺序：

1. **读 `git diff --name-status` 输出**，分类变更文件
2. **查本矩阵**，快速标记"确定需要检查"的 ai-docs 文件
3. **跑 4-tier 失效检测**（`self-invalidation.md`），精确定位每个 anchor 的 CLEAN/REVIEW/STALE 状态
4. **合并两者结果**：矩阵命中但 4-tier 为 CLEAN → 可能是"业务语义变了但代码符号没变"，需人工判断；4-tier 命中但矩阵未覆盖 → 纯代码事实变化，正常处理

---

## 三、渐进式 TODO 填充

> **核心理念**：`blyy-ai-docs` 在 Mode A 可能留下 `<!-- UNVERIFIED: ... -->` 和 `<!-- TODO[p0-p3, type]: ... -->` 标记。每次 Mode B 同步都是填充这些标记的机会。

### 填充流程

1. 在本次变更涉及的 ai-docs 文件中搜索标记：
   ```
   rg "<!-- (TODO\[|UNVERIFIED:)" ai-docs/
   ```

2. **按 priority 顺序处理**：p0 → p1 → p2 → p3 → UNVERIFIED

3. 按 `type` 字段判断是否可填充：
   - `business-context` — 检查变更的代码是否提供了新的业务上下文（函数名、注释、调用链）
   - `design-rationale` — 检查是否有新 ADR、commit message 或注释解释 "why"
   - `invariant-gap` — 检查是否有新的断言/约束被加入代码

4. 判断当前代码变更是否提供了足够证据：
   - **示例**：`<!-- UNVERIFIED: 订单创建后是否通知仓库 -->`，而本次变更中 `OrderService.CreateAsync` 新增了 `NotificationService.NotifyWarehouse()` 调用 → 可以填充，升级为 T2
   - **示例**：`<!-- TODO[p1, business-context]: 支付模块的对外承诺 -->`，而本次变更完成了 `PaymentService` 的全部方法实现 → 可以从方法签名提取 business_summary

5. 若能填充 → 替换标记，向用户汇报：
   ```
   ✅ 已填充 UNVERIFIED（flows.md: 订单创建→库存通知流程）
   ```

6. 若不确定 → 保留标记不动，**绝不猜测填充**

### 原则

- 只有 T1/T2 级别的代码证据才能填充标记
- TODO 填充是**顺手的副作用**，不是 Mode B 的主要任务——不要为了填充 TODO 而扩大代码阅读范围
- UNVERIFIED 标记的消除仍然以用户在 Pre-Fill Review 中确认为主要途径
