# Phase 3 — 最终检查与完成报告（详细流程）

> **何时读取本文件**：进入 Phase 3 时。本文件包含完整的 14 项检查项、基线快照 YAML 模板、INIT-REPORT 完整模板。
>
> SKILL.md 中只保留入口指引；具体执行细节以本文件为准。

## 检查项清单

> **核心原则**：Phase 3 的完整性验证基于**确定性清单比对**，而非重新扫描代码。从预扫描清单文件（`inventory.md`）中读取各类别的基线数量，与文档中实际覆盖的条目数逐一比对。这避免了 AI 重新扫描代码时再次遗漏的问题。

1. 确认所有文档的 YAML 元数据正确
2. 确认 `ARCHITECTURE.md` 文档索引覆盖所有生成的文档
3. 确认无断链引用
4. **模块完整性**：对比确定性清单中识别到的所有模块与 `modules.md` 注册表，确认无遗漏
5. **实体完整性**：对比确定性清单中的实体/模型文件数量与 `data-model.md`（含模块级）中列出的实体数量，未覆盖的必须逐一列出文件名并补充或标注原因
6. **配置完整性**：对比确定性清单中的配置文件数量与 `config.md` 中列出的配置项数量，确认无遗漏
7. **API 完整性**（若项目有 API）：对比确定性清单中的控制器/路由文件数量与 `api-reference.md` 或 `features.md` 中的端点数量
8. **测试完整性**：确认 `testing.md` 中测试分层策略与实际测试目录结构一致
9. **监控完整性**（若生成了 `monitoring.md`）：确认核心指标表与代码中的监控埋点一致
10. **旧文档回收率**（仅当存在 `docs-old/` 时）：对比 Phase 1.5 提取的条目总数与新文档中实际包含的条目数，向用户报告回收情况及差异清单
11. **文档可信度统计**：统计所有生成文档中的内容事实级别分布和 `<!-- UNVERIFIED -->` 标记数量：
    - T1 确定性事实：N 个 (X%)
    - T2 高置信推断：M 个 (Y%)
    - T3 未验证推测：K 个 (Z%) — 逐一列出所在文档和位置
12. **基线数据保留（供 doc-sync 使用）**：将确定性清单的精简版写入 `docs/doc-maintenance.md` 的「基线快照」章节。基线**必须**采用 YAML 格式（便于 doc-sync 防线 3 程序化解析），包含同步状态、清单计数、TODO/UNVERIFIED 标记统计、文档分层分布四类数据：

    ````markdown
    ## 基线快照（blyy-init-docs 自动生成）

    ```yaml
    snapshot_date: YYYY-MM-DD
    snapshot_commit: <git rev-parse HEAD 当前 commit>
    last_synced_commit: <同上，doc-sync 后续会更新此字段>
    skill_version: blyy-init-docs v0.3.0

    inventory:
      modules: P
      entities: N
      controllers: M
      services: K
      config_files: L
      api_endpoints: Q
      tests: T

    markers:
      todo_total: X
      todo_by_priority:
        p0: 0
        p1: 0
        p2: 0
        p3: 0
      todo_by_type:
        business-context: 0
        design-rationale: 0
        ops-info: 0
        security-info: 0
        external-link: 0
        metric-baseline: 0
      unverified_total: Y

    layer_distribution:
      layer1_core: 5         # ARCHITECTURE/README/AGENTS/modules/code-map
      layer2_modules: P
      layer3_aggregate: 7
      layer4_ops: 6

    fact_levels:
      t1_count: N1
      t2_count: N2
      t3_count: N3
    ```

    ## 历史快照趋势

    > doc-sync 防线 3 每次执行后追加一行，便于发现腐烂趋势。

    | 日期 | commit | 实体 | 服务 | TODO 总数 | UNVERIFIED | 备注 |
    |------|--------|------|------|-----------|------------|------|
    | YYYY-MM-DD | abc1234 | N | K | X | Y | init |
    ````

    此数据供 `blyy-doc-sync` 防线 3 定期审计时作为历史对比基准（对比 inventory 偏差、markers 增长趋势、layer_distribution 失衡情况）。
13. 大型项目模式下，清理 `.init-docs/` 目录（或保留供后续参考，由用户决定）
14. 标准模式下，清理 `docs/.init-temp/` 临时目录（但若用户在 Layer 交付时选择暂停，保留临时文件供后续恢复）

## 生成完成报告（`docs/INIT-REPORT.md`）

此报告为**一次性文档**，仅用于交付文档初始化结果，不参与后续功能开发。

报告内容：

```markdown
# 文档初始化报告

> 本文档为一次性报告，仅记录 blyy-init-docs 执行结果，不参与后续开发参考。
> 确认无误后可安全删除。

## 总体情况
- 执行日期：YYYY-MM-DD
- 项目规模：N 个源文件，M 个模块
- 执行模式：标准 / 大型项目
- 生成文档数：X 个（含模块级文档）
- AI 上下文文件：AGENTS.md / CLAUDE.md / ...

## 已自动填充的文档
| 文档 | 填充程度 | 说明 |
|------|---------|------|
| README.md | ██████████ 100% | 已完整填充 |
| modules.md | ████████░░ 80% | 2 个模块职责待确认 |
| ... | ... | ... |

## 需要手动补充的内容

以下内容无法通过代码自动推断，需要人工补充：

| 待补充项 | 所在文档 | 位置链接 |
|---------|---------|----------|
| 项目愿景与目标 | README.md | [→ 前往补充](../README.md#项目简介) |
| 核心业务场景描述 | core-flow.md | [→ 前往补充](core-flow.md#主流程) |
| 运维联系人 | runbook.md | [→ 前往补充](runbook.md#联系人) |
| ... | ... | ... |

## 完整性校验（基于确定性清单比对）

| 维度 | 确定性清单基线 | 文档中覆盖 | 覆盖率 | 未覆盖条目 |
|------|-------------|------------|--------|-----------|
| 模块 | N | M | M/N% | [逐一列出文件名] |
| 实体/模型 | N | M | M/N% | [逐一列出文件名] |
| 控制器/路由 | N | M | M/N% | [逐一列出文件名] |
| 服务 | N | M | M/N% | [逐一列出文件名] |
| 配置文件 | N | M | M/N% | [逐一列出文件名] |
| API 端点 | N | M | M/N% | [逐一列出] |
| 测试分层 | N | M | M/N% | [清单] |
| 监控指标 | N | M | M/N% | [清单] |

> 旧文档回收率：X/Y (Z%)（仅当存在 docs-old/ 时显示）

## 文档可信度

| 事实级别 | 条目数 | 占比 | 说明 |
|---------|--------|------|------|
| T1 确定性事实 | N | X% | 直接从代码/文件/配置提取 |
| T2 高置信推断 | M | Y% | 从命名/框架模式推断 |
| T3 未验证推测 | K | Z% | 需用户后续确认 |

**T3 未验证条目详情：**

| 条目 | 所在文档 | 位置 |
|------|---------|------|
| {T3 条目描述} | {文档名} | [→ 前往确认]({链接}) |
| ... | ... | ... |

## CHANGELOG 填充状态
- [ ] 用户选择：已自动填充 / 用户选择手动维护
```

向用户呈现此报告，完成交付。
