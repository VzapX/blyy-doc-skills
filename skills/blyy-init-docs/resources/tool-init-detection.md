# 开发工具 /init 命令检测（Phase 0.1）

Phase 0.1 检测当前 AI 工具是否自带文档初始化命令；若支持必须先执行该命令，再进入 Phase 0.2。

## 工具 /init 检测表

| 工具 | 初始化命令 | 产物 |
|------|----------|------|
| Gemini (Google) | 自动生成 | `AGENTS.md` |
| Codex (OpenAI) | 自动生成 | `AGENTS.md` |
| Claude Code | `/init` | `CLAUDE.md` |
| Cursor | 自动/手动 | `.cursorrules` 或 `CURSOR.md` |
| Copilot | — | — |
| Windsurf | 自动 | `.windsurfrules` |

## 执行策略（硬性前置）

1. 对照上表检查当前工具。若工具支持初始化命令（如 Claude Code 的 `/init`）：
   - **必须先执行**工具自带的初始化命令，等待其完成后才能进入 Phase 0.2
   - 若执行失败，向用户报告错误并询问：重试 or 跳过（用户明确选择跳过才可继续）
   - 记录生成的文件（如 `CLAUDE.md`）供 Phase 1 整合
2. 若工具确实不支持初始化（如 Copilot）或为未识别工具 → 跳过，但**必须明确告知用户**："当前工具不支持 /init，已跳过此步"
3. **禁止静默跳过** — 无论执行还是跳过，都必须向用户输出结果
