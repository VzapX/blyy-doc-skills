# Module Tiering — 模块复杂度分级与分析深度

> **何时读取**：Mode A Phase A1（模块识别后）、Mode B Phase B3（新模块/升级信号检测）、Mode C Phase C1.5（分级全量复评）。
>
> **目的**：根据模块的确定性指标评分，决定 Phase A3 子代理的**分析深度**。核心模块值得深挖业务逻辑和设计决策，简单模块一句话定位即可。
>
> **注意**：ai-docs 是扁平结构（7 个文件），分级**不控制文件结构**（不像 docs/ 的 Core=目录、Standard=单文件、Lightweight=内联），而是控制**业务分析的深度与子代理资源分配**。

---

## 一、复杂度评分规则

对每个已确认的模块，逐项检测并累加得分：

| 信号 | 检测命令 | 得分 |
|------|---------|------|
| 源文件数 > 15 | `fd --type f {{module_dir}} \| wc -l` | +2 |
| 源文件数 5–15 | 同上 | +1 |
| 源文件数 < 5 | 同上 | 0 |
| 有数据库实体/模型文件 | `fd -e {{ext}} -p "Entity\|Model\|model" {{module_dir}} --type f` | +1 |
| 有 API 端点（Controller/Handler） | `fd -e {{ext}} -p "Controller\|Handler\|handler\|controller" {{module_dir}} --type f` | +1 |
| 被 ≥ 3 个其他模块依赖 | `rg -l "{{module_namespace}}\|{{module_name}}" {{other_module_dirs}} --type {{lang}}` 命中 ≥ 3 个模块 | +1 |

> 最高 5 分。所有检测基于 shell 命令，不依赖 AI 判断。

---

## 二、分级定义与分析深度

| 总分 | 级别 | Phase A3 分析深度 | modules.md 呈现 |
|------|------|-----------------|----------------|
| **≥ 3** | **Core** | 子代理全量提取 5 类：business_summary + terms + flows + decisions/invariants + dependencies | 完整块（含 entry_anchors + depends_on） |
| **1–2** | **Standard** | 子代理适度提取 3 类：business_summary + terms + dependencies | 适度块（含 entry_anchors） |
| **0** | **Lightweight** | 主 agent 直接写 1 行 business_summary，**跳过子代理** | 底部 Lightweight 表格单行 |

### Core 模块子代理产出要求

子代理必须覆盖全部 5 类条目（详见 `anti-hallucination.md` 五、子代理通用指令）：

1. `business_summary`：1–2 句模块对外承诺，带入口锚点
2. `terms`：业务术语 ↔ 代码符号映射，每条带 `[file#Symbol]`
3. `flows`：模块参与的跨模块业务流程步骤，每步带锚点
4. `decisions` / `invariants`：设计决策 + 必须保持的规则
5. `dependencies`：调用了哪些其他模块，带 import/using 锚点

### Standard 模块子代理产出要求

仅要求前 3 类（business_summary + terms + dependencies）。flows 和 decisions 仅当该模块在其他 Core 模块的 flow 中被引用时，才由引用方的子代理补充。

### Lightweight 模块处理

不启动子代理。主 agent 读模块入口文件（1–2 个）后直接写：

```
| {{MODULE_NAME}} | `{{code_root}}` | {{一句话}} `[{{entry_anchor}}]` |
```

---

## 三、向用户展示分级结果

Phase A1 模块识别确认后，立即展示分级：

```
📊 模块复杂度评分结果：

| 模块 | 文件数 | 实体 | API | 被依赖 | 总分 | 级别 |
|------|-------|------|-----|-------|------|------|
| Orders | 22 | ✓ | ✓ | 4 | 5 | Core |
| Users | 12 | ✓ | ✓ | 2 | 3 | Core |
| Notifications | 6 | ✗ | ✓ | 1 | 2 | Standard |
| HealthCheck | 2 | ✗ | ✓ | 0 | 1 | Standard |
| Utils | 3 | ✗ | ✗ | 5 | 1 | Standard |
| Seeders | 1 | ✗ | ✗ | 0 | 0 | Lightweight |

Core: 2 个（子代理全量分析）
Standard: 3 个（子代理适度分析）
Lightweight: 1 个（主 agent 直接写）

确认？(Y | 调整)
```

---

## 四、升降级信号检测

### Mode B — 升级信号（仅检测升级方向）

当 Mode B Phase B3 检测到新文件增删涉及某模块时：

1. 读取 MANIFEST.yaml 中该模块的 `tier` 和 `complexity_score`
2. 重新执行评分命令
3. 若新评分使模块跨越级别阈值（如 Standard 2 → 3 = Core）：

```
⬆️ 模块分析深度升级建议:
   [Notifications] Standard → Core（评分: 2 → 3，新增 2 个 Entity 文件）
   操作: 启动子代理补充 flows + decisions 分析
   执行？(Y | 稍后)
```

4. 用户确认 → 启动子代理补充缺失的分析类别，更新 modules.md 和 MANIFEST
5. 降级信号不在 Mode B 提示（避免频繁打扰），留给 Mode C 处理

### Mode C — 全量复评（双向）

Phase C1.5 对所有模块重新评分：

1. 对 MANIFEST.modules 中每个模块执行完整评分
2. 与当前 `tier` 对比，输出升降级报告：

```
📊 模块分级全量复评:

升级建议（1 个）:
  ⬆️ [Notifications] Standard → Core（评分: 2 → 4）

降级建议（1 个）:
  ⬇️ [Utils] Standard → Lightweight（评分: 1 → 0，文件已减至 2 个）

确认执行？(全部 | 逐个确认 | 跳过)
```

3. 升级 → 补充分析；降级 → 简化 modules.md 中该模块的条目
4. 更新 MANIFEST.modules 中的 `tier` 和 `complexity_score`
