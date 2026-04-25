# 模块复杂度评分与分级（Phase 0.3 Step 6）

Phase 0.3 清单预扫描后，主 agent 对每个模块自动评分并确定文档形态。**评分全部基于确定性清单的 shell 命令结果，不依赖 AI 判断**。

## 评分规则

| 信号 | 检测方式 | 得分 |
|------|---------|------|
| 模块源文件数 > 15 | `fd --type f <module_dir> \| wc -l` | +2 |
| 模块源文件数 5-15 | 同上 | +1 |
| 模块源文件数 < 5 | 同上 | 0 |
| 有数据库实体/模型文件 | 清单中该模块含 Entity/Model 文件 | +1 |
| 有 API 端点（Controller/Handler） | 清单中该模块含 Controller/Handler 文件 | +1 |
| 被 ≥ 3 个其他模块依赖 | 反向引用扫描（`rg "import.*<module>" --type-add ...`） | +1 |

## 分级结果

| 总分 | 级别 | 文档形态 | 说明 |
|------|------|---------|------|
| ≥ 3 | **Core** | 完整目录 `modules/<m>/`（6 个子文件） | 当前模板不变 |
| 1-2 | **Standard** | 单文件 `modules/<m>.md` | 使用 `modules-single.md.template` |
| 0 | **Lightweight** | 无独立文件，内联到 `modules.md` | 在模块注册表中展开为详细段落 |

## 执行步骤

1. 对每个模块执行评分命令，计算总分
2. 向用户展示分级结果并确认：

   ```
   📊 模块复杂度分级（共 {N} 个模块）：

   Core（完整文档目录）— {n1} 个：
     - Orders (5分): 22文件, 8表, 12端点, 被5个模块依赖
     - Users (4分): 18文件, 5表, 8端点, 被7个模块依赖
     ...

   Standard（单文件文档）— {n2} 个：
     - Notifications (2分): 8文件, 2表
     - Logging (1分): 6文件
     ...

   Lightweight（内联到 modules.md）— {n3} 个：
     - StringUtils (0分): 2文件
     - Constants (0分): 1文件
     ...

   预计文档数: {Core×6 + Standard×1 + 全局} 个（vs 无分级: {N×6 + 全局} 个）

   确认分级？(Y | 调整某模块级别)
   ```

3. 用户确认后，将分级结果持久化：
   - 标准模式：`docs/.init-temp/module-tiers.md`
   - 大型项目模式：`.init-docs/module-tiers.md`
4. Phase 1 骨架生成时，按分级结果决定每个模块的文档结构

> **分级结果影响 Phase 1 骨架**：Core 模块创建完整 `modules/<m>/` 目录；Standard 模块创建单个 `modules/<m>.md` 文件；Lightweight 模块不创建独立文件。
