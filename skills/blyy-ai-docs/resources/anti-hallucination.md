# Anti-Hallucination Rules — 反幻觉铁律

> **何时读取**：Mode A Phase A3 启动子代理之前；全程作为参考底线。
>
> **目的**：让 AI 在生成 / 维护 ai-docs/ 时，无法绕过"必须有锚点 + 不能枚举"两条核心约束。所有规则都被设计为**默认拒绝**——AI 想偷懒就会被拒收。

---

## 一、三级事实分类（T1 / T2 / T3）

每条写入 ai-docs/ 的内容必须自标级别。

| 级别 | 含义 | 示例 | 如何处理 |
|------|------|------|---------|
| **T1** | 直接代码事实，可被 grep 验证 | "OrderService 类定义在 `src/Orders/OrderService.cs:12`" | 直接写入 |
| **T2** | 强推断，基于命名约定 / 类型签名 / 调用链 | "`CreateOrderAsync` 创建订单"（基于函数名 + 返回 OrderEntity） | 直接写入，但必须标 T2 标签 |
| **T3** | 弱推断，基于上下文猜测 | "订单创建后会通知库存" | **必须** 进入 Phase A4 Pre-Fill Review，由用户确认升级到 T2 才能写入；用户跳过则 `<!-- UNVERIFIED -->` 包裹 |

**判定依据**：

- 能用 `rg` / 类型系统直接证伪 → T1
- 不能 grep 直接验证，但有 ≥2 个独立代码信号支撑 → T2
- 仅 1 个信号 / 信号是间接的（注释、变量名）→ T3

---

## 二、锚点强制规则

### 锚点格式（按推荐度排序）

```
[path/to/file.ext#SymbolName]           # 首选 — 抗行号漂移
[path/to/file.ext#SymbolName:42-58]     # 次选 — 符号 + 范围
[path/to/file.ext]                      # 文件级 — 用于"该文件存在"类断言
[path/to/file.ext:42-58]                # 仅范围 — 不推荐，行号易漂移
```

### 强制规则

1. **每条非 boilerplate 的内容必须带锚点 OR `<!-- UNVERIFIED -->` 包裹**。boilerplate 指：标题、章节说明、表头。
2. **锚点必须可被 `rg` 验证存在**——子代理产出后，主 agent 会逐条 `rg` 校验，错的直接 reject。
3. **重载冲突**：同文件多个同名符号（重载）→ 用 `[file#Symbol(ParamType)]` 形式消歧。
4. **文件不存在 → 锚点失效 → 该断言降级为 T3 重新审查**。
5. **跨文件断言**（"X 调用 Y"）→ 必须同时给 X 锚点和 Y 锚点。

### `<!-- UNVERIFIED -->` 使用规范

```html
<!-- UNVERIFIED: 简述无法验证的部分 -->
```

- 简述必须 ≤ 30 字
- 必须出现在被包裹内容的**正上方**（同段开头）
- AI 阅读时，UNVERIFIED 段落**不得作为决策依据**
- Phase B/C 不会自动消除 UNVERIFIED——只有用户在 Pre-Fill Review 中确认才能升级

---

## 三、禁枚举铁律

> ai-docs/ 的核心承诺是"不重复代码事实"。任何**列出某类代码对象的清单**都应该是 `code-queries.md` 的活儿，不应该出现在其他文件里。

### 禁止的内容形态

1. **超过 20 行的列表型表格**（无论是表格还是无序列表）——主 agent 在写入前检查行数，超出直接拒收
2. **任何"以下是所有 X"句式**：
   - ❌ "以下是所有实体类：..."
   - ❌ "项目共有 12 个 Controller，分别是：..."
   - ✅ "实体类清单见 `code-queries.md` recipe `R-ENT-01`"
3. **总数性陈述**：
   - ❌ "项目有 23 个实体" / "约 50 个端点"
   - ✅ "运行 `R-ENT-01` 获取实体清单"
4. **文件路径清单**（除非每条都是模块入口锚点）：
   - ❌ 在 modules.md 里列出 `OrderService.cs / OrderRepo.cs / OrderEntity.cs / OrderDto.cs / ...`
   - ✅ 在 modules.md 里只写 `code_root: src/Modules/Orders/` + 入口 `[OrderService.cs#OrderService]`

### 允许的"看起来像清单"的内容

- **模块注册表**：每行 1 个模块，固定字段（name / code_root / business_summary / 入口锚点）。**这是注册表，不是文件清单**——条目数 = 模块数（通常 ≤ 30），不会爆炸
- **跨模块依赖图**：每行"模块 A 依赖模块 B"，依赖数有限
- **不变式列表**：每条不变式都有明确的代码锚点，且表达"代码里看不到的规则"
- **业务流程步骤**：每步带锚点，描述跨模块的业务事件顺序

---

## 四、Pre-Fill Review Gate（Phase A4 关卡）

> **核心原则**：所有 T3 内容**必须**经用户一次性批量确认才能进入正式文档。**这个关卡完成前，禁止开始写正式文档。**

### Step 1 — 收集所有 T3 候选

子代理产出的临时文件中，所有标记为 T3 的条目汇总到一个待审查列表。

### Step 2 — 按类型分组

- 业务定位类（"该模块用途"）
- 术语映射类（"X 业务术语对应 Y 类"）
- 流程顺序类（"A 之后会触发 B"）
- 决策动机类（"为什么用 X 而不是 Y"）
- 不变式类（"必须保持的规则"）

### Step 3 — 一次性呈现

```
📋 发现 {N} 个 T3 推测项需确认

【业务定位类】(3 项)
1. [T3] {模块名} 模块功能?
   最佳猜测: {一句话} (置信度: 高/中/低)
   代码依据: {file#Symbol}
   → 确认 / 纠正: ___

【流程顺序类】(2 项)
4. [T3] {流程描述}?
   最佳猜测: {步骤序列}
   代码依据: {一组锚点}
   → 确认 / 纠正: ___

...
```

### Step 4 — 用户响应处理

| 用户响应 | 处理 |
|---------|------|
| "确认" / "Y" | 升级为 T2，正式写入文档 |
| 提供纠正文本 | 用纠正文本替换猜测，标 T1 |
| "跳过" / "N" | `<!-- UNVERIFIED: 简述 -->` 包裹后写入 |
| 无响应 / 含糊 | 默认 "跳过" |

### Step 5 — 持久化

- 写入 `ai-docs/.init-temp/clarifications.yaml`，避免跨会话重复提问
- 同步更新进度状态（防止断点续跑时漏掉已确认项）

---

## 五、子代理通用指令

> 主 agent 在 Mode A Phase A3 给每个子代理的任务描述中**必须包含**以下内容（可逐字复用）：

```
你的任务：分析模块 {MODULE_NAME}（路径：{MODULE_ROOT}），产出
该模块的业务定位、术语候选、流程候选、决策/不变式候选。

强制规则（违反任何一条都会被主 agent 拒收）：

1. 你产出的**每一行**业务断言都必须带 [file#Symbol] 锚点。找不到锚点的
   断言改写为 <!-- UNVERIFIED: 简述 --> 包裹。

2. 禁止列出 "本模块的所有实体" / "所有控制器" / "所有服务"——这些是
   code-queries.md 的活儿，你的产物里写这种清单会被主 agent 直接拒收。

3. 每条断言必须自标 T1 / T2 / T3 级别。T1 = 直接代码事实；T2 = 强推断；
   T3 = 弱推断。T3 内容会进入 Pre-Fill Review，由用户确认。

4. 你的产出**仅包含**以下五类条目：
   - business_summary: 1-2 句"模块对外承诺什么"，必须有 entry 文件锚点
   - terms: 业务术语 ↔ 代码符号映射
   - flows: 跨模块业务流程步骤
   - decisions: 设计决策（来自 commit 信息 / ADR / 注释）
   - invariants: 必须保持的规则
   - dependencies: 调用了哪些其他模块

5. 输入文件超 800 行时分批 Read → 提取 → 追加写入临时文件，禁止一次性
   把整个模块塞进上下文。

6. 完成后输出结构化摘要：business_summary 1 条、terms N 条、flows N 步、
   decisions N 项、invariants N 项、dependencies N 个，T1/T2/T3 各 N 条，
   UNVERIFIED N 条。

7. 完成后立即把产出写入 ai-docs/.init-temp/analysis-{MODULE_NAME}.md，
   不要把内容塞回主 agent 上下文。
```

---

## 六、AI 自查清单

> Mode A Phase A6 / Mode B / Mode C 完成后，AI 必须自查以下所有项：

```
□ 所有 doc 中的非 boilerplate 段落都有锚点 OR UNVERIFIED 包裹
□ 没有任何超过 20 行的列表型段落
□ 没有任何 "项目有 N 个 X" 形式的总数陈述
□ 没有任何 "以下是所有 X" 句式
□ 所有 [file#Symbol] 锚点都能通过 rg 验证存在
□ MANIFEST.anchors 数量 ≥ 所有文档锚点的并集
□ 所有 T3 都已经过 Pre-Fill Review（要么升级、要么 UNVERIFIED）
□ code-queries.md 没有粘贴 > 3 行的输出样例
□ INDEX.md 的 Freshness 表已更新
□ MANIFEST.history 已追加本次事件
```

任意一项不通过 → 必须修正后才能完成本次执行。
