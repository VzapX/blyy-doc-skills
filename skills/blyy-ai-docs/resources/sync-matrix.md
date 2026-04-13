# Sync Matrix — 代码变更→文档更新映射

> **何时读取**：Mode B Phase B1（与 4-tier 失效检测并行使用）。
>
> **目的**：让 Mode B 在跑被动 sha 检测之前，先根据代码变更类型**主动判断**哪些 ai-docs 文件需要更新。两者互补——矩阵提供快速首轮定位，4-tier 捕获矩阵遗漏的细粒度变化。
>
> **与 docs/ 的区别**：ai-docs 只有 7 个文件且禁止重复代码事实，因此映射表远比 docs/ 的 48 条精简。

---

## 一、变更类型→文档映射

| 代码变更类型 | 需检查的 ai-docs 文件 | 更新内容 |
|-------------|---------------------|---------|
| **模块级变更** | | |
| 新增业务模块目录 | `modules.md` + `MANIFEST.yaml` | 评分分级→注册新模块→更新 MANIFEST.modules |
| 删除业务模块目录 | `modules.md` + `glossary.md` + `flows.md` + `MANIFEST.yaml` | 移除模块条目 + 清理引用该模块的术语/流程 |
| 模块职责变更（入口文件重构） | `modules.md` | 更新 business_summary + entry_anchors |
| 模块间依赖变化（import/using 增删） | `modules.md` | 更新 depends_on + Cross-Module Dependency Graph |
| **术语与数据模型变更** | | |
| 新增/重命名核心实体类 | `glossary.md` | 新增/更新术语 ↔ 符号映射行 |
| 废弃业务术语/实体 | `glossary.md` | 标注 deprecated 或移除 |
| 引入新业务缩写 | `glossary.md` | 补充同义词/缩写 |
| **业务流程变更** | | |
| 跨模块业务流程变化 | `flows.md` | 更新流程步骤 + 锚点 |
| 模块内流程重构（影响跨模块调用） | `flows.md` + `modules.md` | 更新流程步骤 + depends_on |
| **架构决策变更** | | |
| 新增架构决策（ADR / 注释中 "why"） | `decisions.md` | 新增决策条目 |
| 修改/废弃已有不变式 | `decisions.md` | 更新/标注废弃 |
| **技术栈变更** | | |
| 切换框架/ORM/HTTP 库 | `code-queries.md` + `MANIFEST.yaml` | 更新 recipe 命令 + detected_stack.variants |
| 新增语言栈（如加前端） | `code-queries.md` + `modules.md` | 补充该栈的 recipe + 注册新模块 |
| **基础设施变更** | | |
| 文件重命名/移动 | 涉及锚点的所有文件 | 4-tier Tier 1 会捕获→STALE，但矩阵可加速定位 |
| 大规模重构（>30% 文件变更） | 建议降级到 Mode A | 提示用户 |

> **未列出的变更类型**（纯内容修改、bug 修复等）：由 4-tier 失效检测的 Tier 2/3（sha 比对）自动捕获，无需矩阵映射。

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
