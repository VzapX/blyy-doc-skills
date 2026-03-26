# blyy-skills-doc

[English](#english) | [中文](#中文)

---

## English

### What is this?

**blyy-skills-doc** is a collection of AI coding tool skills for automated project documentation management. It works with mainstream AI coding tools including **Gemini**, **Codex**, **Cursor**, and **Claude Code**.

### Skills Included

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| **blyy-init-docs** | Initialize complete project documentation from code analysis | Day 0 — One-time setup |
| **blyy-doc-sync** | Keep documentation in sync with code changes | Day 1+ — Ongoing maintenance |

### Quick Install

#### Option A: Using Install Script

**Windows (PowerShell):**
```powershell
# Navigate to this repo, then run:
.\install.ps1 -TargetProject "C:\path\to\your\project"
```

**Linux / macOS (Bash):**
```bash
# Navigate to this repo, then run:
./install.sh /path/to/your/project
```

The script will auto-detect which AI tools your project uses and copy skills to the correct directory.

#### Option B: Manual Install

Copy the desired skill folder into your project's skill directory:

| AI Tool | Target Directory |
|---------|-----------------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

```bash
# Example: Install both skills for Gemini
cp -r skills/blyy-init-docs .agents/skills/
cp -r skills/blyy-doc-sync .agents/skills/
```

### How It Works

1. **blyy-init-docs**: Scans your codebase, identifies modules, and generates a complete documentation set (architecture, code map, data model, deployment guide, etc.)
2. **blyy-doc-sync**: After each code change, checks what documentation needs updating using a three-line-of-defense strategy

### Documentation

- [Usage Guide](docs/usage-guide.md) — Detailed usage instructions
- [Customization Guide](docs/customization.md) — How to customize templates and extend rules

### License

[MIT](LICENSE)

---

## 中文

### 这是什么？

**blyy-skills-doc** 是一套 AI 编程工具技能包，用于自动化项目文档管理。兼容主流 AI 编程工具：**Gemini**、**Codex**、**Cursor**、**Claude Code**。

### 包含的技能

| 技能 | 用途 | 使用时机 |
|------|------|---------|
| **blyy-init-docs** | 基于代码分析初始化完整项目文档 | Day 0 — 一次性初始化 |
| **blyy-doc-sync** | 保持文档与代码变更同步 | Day 1+ — 持续维护 |

### 快速安装

#### 方式 A：使用安装脚本

**Windows (PowerShell):**
```powershell
# 进入本仓库目录，然后运行：
.\install.ps1 -TargetProject "C:\path\to\your\project"
```

**Linux / macOS (Bash):**
```bash
# 进入本仓库目录，然后运行：
./install.sh /path/to/your/project
```

脚本会自动检测目标项目使用的 AI 工具，并将技能复制到对应目录。

#### 方式 B：手动安装

将所需技能文件夹复制到项目的技能目录中：

| AI 工具 | 目标目录 |
|---------|---------|
| Gemini / Codex / Cursor | `.agents/skills/` |
| Claude Code | `.claude/skills/` |

```bash
# 示例：为 Gemini 安装两个技能
cp -r skills/blyy-init-docs .agents/skills/
cp -r skills/blyy-doc-sync .agents/skills/
```

### 工作原理

1. **blyy-init-docs**：扫描代码库，识别模块，生成完整文档集（架构总览、代码地图、数据模型、部署指南等）
2. **blyy-doc-sync**：每次代码变更后，通过三道防线策略检查哪些文档需要更新

### 文档

- [使用指南](docs/usage-guide.md) — 详细使用说明
- [自定义指南](docs/customization.md) — 如何自定义模板和扩展规则

### 许可证

[MIT](LICENSE)
