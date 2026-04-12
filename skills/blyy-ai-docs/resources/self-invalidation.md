# Self-Invalidation — 4-tier 失效检测算法

> **何时读取**：
> - Mode B Phase B1（增量同步检测）
> - Mode C Phase C0（全量审计）
>
> **目的**：在不重读所有源码的前提下，机械判断 `ai-docs/` 中哪些段落已经过期。

## 设计原则

1. **早期短路**：能在 Tier 1 / Tier 2 排除的，绝不进 Tier 3。这保证大型仓库的同步耗时随**变化量**而非仓库大小线性
2. **保守优先**：拿不准的一律标 REVIEW，不标 CLEAN——宁可让人多看一段，也不让 AI 读到错的
3. **整段重写**：STALE 不允许局部 patch，避免局部修补和未受影响内容互相不一致
4. **真相源唯一**：只有 `MANIFEST.yaml` 是状态真相，文档体内的 sha 值不可信（容易被人手编破坏）

---

## 输入与输出

```
输入:
  M_prev: ai-docs/MANIFEST.yaml 的当前内容（上次同步后的快照）
  M_curr: 当前 git 工作树（HEAD 的代码）

输出（每个 doc 一份）:
  status: CLEAN | REVIEW | STALE
  reasons: [String]              # 触发原因列表
  affected_anchors: [AnchorID]   # 哪些 anchor 引发了状态变化
```

---

## Tier 1 — 文件存在性 / 重命名检测

> **目的**：用最便宜的 git 命令排除一大批"代码完全没动"和"文件已删/已改名"两个极端。

```bash
# 1. 拉取从 M_prev 到 HEAD 的变更文件清单
git diff --name-status "${M_prev}" HEAD > /tmp/changed.txt

# 2. 解析每行：状态字母 + 文件路径
#    A=新增  M=修改  D=删除  R=重命名  C=拷贝
```

### 判定

| 文件状态 | 对引用此 path 的所有 doc 的影响 |
|---------|----------------------------|
| **未出现** in changed.txt | Tier 1 通过，进入 Tier 2 |
| `A`（仅新文件） | 不影响已有 anchor；触发 Phase B3 新模块检测 |
| `M`（修改） | 进入 Tier 2 |
| `D`（删除） | 引用此 path 的 doc 全部 **STALE**，原因 `file_deleted` |
| `R`（重命名） | 引用此 path 的 doc 全部 **STALE**，原因 `file_renamed:<新路径>`，并提示用户旧路径已迁移 |
| `C`（复制） | 不影响 anchor，但记入 history 备注 |

> 重要：`git diff --name-status` 默认会检测 rename，无需 `-M` 参数。如果误判（例如纯重写也被识别为 rename），降级处理：把它当成 D + A。

---

## Tier 2 — 文件级 sha256

> **目的**：排除 git 的"行尾噪声 / 空白调整 / 仅注释改动"——这类改动文件 sha 不变（git 用 normalized blob hash），无需进 Tier 3。

```bash
# 对 Tier 1 中标 M 的每个 path：
for path in modified_paths:
    sha_now = git hash-object "$path"
    sha_prev = M_prev.anchors[path].sha256
    if sha_now == sha_prev:
        continue  # 视为未变（罕见，但理论可能）
    else:
        进入 Tier 3
```

### 判定

| 比较 | 影响 |
|------|------|
| sha 相同 | 视为未变，跳过 |
| sha 不同 | 进入 Tier 3 |

> 注意：`git hash-object` 计算的是**当前工作树文件**的 blob hash，与 git index 一致。不要用 `git ls-tree HEAD` 的值，那是 commit 时的值，未提交修改不可见。

---

## Tier 3 — 符号级 body / 签名比对

> **目的**：精确定位"哪个符号变了"，对该符号引用的 doc 段落做差异判定。这一层是 AI 工具能耗的主战场。

### Step 1：枚举受影响符号

对 Tier 2 留下的每个文件，遍历该文件在 `M_prev.anchors[path].symbols` 下的所有符号：

```
for sym in M_prev.anchors[path].symbols:
    new_extract = extract_anchor(path, sym.name)   # 走 anchor-extraction.md 的算法
    if not new_extract.found:
        → STALE (symbol_disappeared)
    elif new_extract.signature != sym.signature:
        → STALE (signature_changed)
    elif new_extract.body_sha256 != sym.body_sha256:
        → REVIEW (body_changed)
    else:
        → CLEAN (cosmetic_only)
```

### Step 2：状态升级规则

| 单 anchor 结果 | doc 总状态升级 |
|--------------|------------|
| 任何 STALE | doc 全段 STALE（最高优先级） |
| 全部 CLEAN | 不影响 |
| ≥ 1 REVIEW，0 STALE | doc 段标 REVIEW |

> 一个 doc 引用多个 anchor 时，**最严格者胜出**：1 STALE + 99 CLEAN → STALE。

### Step 3：反向锚点索引

为了让 STALE → 段落定位高效，每条 anchor 在 MANIFEST 中都记录了 `docs:` 列表（哪些 doc 引用了它）。Phase B2 据此**只重写**列表中的 doc。

```yaml
# MANIFEST.anchors 例
- path: src/Modules/Orders/OrderService.cs
  sha256: a1b2c3...
  docs: [modules.md, flows.md]    # ← 反向索引
  symbols:
    CreateOrderAsync:
      line: 42
      body_sha256: d4e5f6...
      signature: "public Task<OrderEntity> CreateOrderAsync(CreateOrderDto dto)"
```

---

## Tier 4 — 范围锚点（仅 `[file:42-58]`）

> **目的**：兜底处理那些没有符号名、只有行号范围的锚点。**这类锚点是反模式**，但偶尔无法避免（例如 SQL 文件中没有符号概念）。

### 判定

| 情况 | 状态 |
|------|------|
| 文件未变 | CLEAN |
| 文件变了，但行号范围内的 sha 未变 | CLEAN |
| 文件变了，且行号有效但内容变 | **REVIEW**（保守） |
| 文件总行数 < 行号上界 | **STALE**（行号溢出） |

> 行号范围 sha 计算：`sed -n "${L_start},${L_end}p" "$file" | git hash-object --stdin`
>
> Phase A6 自检会**警告**用户："本次 init 写入了 N 个仅范围锚点，建议改为符号锚点"。

---

## 状态处理（Phase B2 行为）

| 状态 | 处理 |
|------|------|
| **CLEAN** | 仅 bump `MANIFEST.last_synced_commit`，不动文档 |
| **REVIEW** | 子代理读新代码，**仅修正与新代码矛盾的 claim**，未受影响内容保留 |
| **STALE** | 子代理读新代码，**整段重写**该段落（按反向锚点索引定位段落） |

### REVIEW 与 STALE 的差异

REVIEW 假设"语义未变，只是实现细节调整"——例如方法体的算法被优化但功能不变。
STALE 假设"语义可能已变"——例如签名变更、参数增减、符号被删除。

不确定时一律标 STALE。误判 STALE 的代价是多重写一段，误判 CLEAN 的代价是 AI 读到错的事实。

---

## 整体流程伪代码

```
function detect_invalidation(M_prev_yaml, M_curr_git_head):
    diff = git_diff_name_status(M_prev_yaml.last_synced_commit, M_curr_git_head)

    affected_docs = {}

    for each entry in diff:
        match entry.status:
            'D' or 'R':
                for doc in M_prev.anchors[entry.path].docs:
                    affected_docs[doc].add(STALE, reason="file_" + entry.status)
                continue

            'A':
                # 新文件，B3 阶段处理
                continue

            'M':
                if git_hash_object(entry.path) == M_prev.anchors[entry.path].sha256:
                    continue  # Tier 2 cosmetic-only

                # Tier 3
                for sym in M_prev.anchors[entry.path].symbols:
                    result = extract_anchor(entry.path, sym.name)
                    if not result.found:
                        for doc in M_prev.anchors[entry.path].docs:
                            affected_docs[doc].add(STALE, "symbol_disappeared:" + sym.name)
                    elif result.signature != sym.signature:
                        for doc in M_prev.anchors[entry.path].docs:
                            affected_docs[doc].add(STALE, "signature_changed:" + sym.name)
                    elif result.body_sha256 != sym.body_sha256:
                        for doc in M_prev.anchors[entry.path].docs:
                            affected_docs[doc].add(REVIEW, "body_changed:" + sym.name)

    # Tier 4: 仅范围锚点
    for anchor in M_prev.anchors where anchor has range_only:
        ... (按上述 Tier 4 表)

    return affected_docs
```

---

## 性能注解

| 仓库规模 | 预期同步耗时 |
|---------|------------|
| < 5k 文件，每周改动 < 50 文件 | < 5 秒 |
| 5k-50k 文件，每周改动 < 500 文件 | 5-30 秒 |
| > 50k 文件 / monorepo | 30 秒 - 几分钟（瓶颈在 Tier 3 符号定位） |

**优化建议**：
- Tier 1 输出排序后 dedupe，避免重复处理同文件
- Tier 3 的 `extract_anchor` 实现按行流式读，找到 body_end 立即停止
- 子代理并行处理不同模块的 STALE doc

---

## 失败模式与降级

| 失败 | 处理 |
|------|------|
| `M_prev` 不在当前 git 历史中（force-push） | 自动降级到 Mode C 全量审计 |
| `git diff` 输出异常 | 终止 Mode B，提示用户检查 git 状态 |
| 某 anchor 在 Tier 3 多次定位失败 | 标 STALE 并加 `extraction_failed` 备注 |
| STALE 比例 > 50% | 拒绝静默运行，提示用户改跑 Mode A |
