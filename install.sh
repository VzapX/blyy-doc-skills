#!/usr/bin/env bash
#
# blyy-skills-doc 安装脚本
# 自动检测目标项目使用的 AI 工具，将技能复制到对应的目录结构中。
#
# 用法:
#   ./install.sh /path/to/your/project
#   ./install.sh /path/to/your/project --tool claude
#   ./install.sh /path/to/your/project --skills blyy-init-docs
#
# 选项:
#   --tool <gemini|claude|cursor|all>  指定 AI 工具，跳过自动检测
#   --skills <name,...>                要安装的技能（逗号分隔），默认全部

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SOURCE_DIR="$SCRIPT_DIR/skills"

# Defaults
TARGET_PROJECT=""
TOOL=""
SKILLS="blyy-init-docs,blyy-doc-sync"

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool)
            TOOL="$2"
            shift 2
            ;;
        --skills)
            SKILLS="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 <target-project> [--tool <gemini|claude|cursor|all>] [--skills <name,...>]"
            echo ""
            echo "示例:"
            echo "  $0 /path/to/project"
            echo "  $0 /path/to/project --tool claude"
            echo "  $0 /path/to/project --skills blyy-init-docs"
            exit 0
            ;;
        *)
            TARGET_PROJECT="$1"
            shift
            ;;
    esac
done

if [[ -z "$TARGET_PROJECT" ]]; then
    echo "错误: 请指定目标项目路径"
    echo "用法: $0 <target-project> [--tool <gemini|claude|cursor|all>] [--skills <name,...>]"
    exit 1
fi

if [[ ! -d "$TARGET_PROJECT" ]]; then
    echo "错误: 目标项目不存在: $TARGET_PROJECT"
    exit 1
fi

# Convert skills string to array
IFS=',' read -ra SKILL_ARRAY <<< "$SKILLS"

for skill in "${SKILL_ARRAY[@]}"; do
    if [[ ! -d "$SKILLS_SOURCE_DIR/$skill" ]]; then
        echo "错误: 技能不存在: $skill (路径: $SKILLS_SOURCE_DIR/$skill)"
        exit 1
    fi
done

# --- Detect AI Tools ---
detect_tools() {
    local project_path="$1"
    local detected=()

    # Gemini / Codex / Cursor (.agents/)
    if [[ -d "$project_path/.agents" ]] || [[ -d "$project_path/.gemini" ]] || [[ -f "$project_path/AGENTS.md" ]]; then
        detected+=("gemini")
    fi

    # Cursor (.cursor/)
    if [[ -d "$project_path/.cursor" ]]; then
        detected+=("cursor")
    fi

    # Claude Code (.claude/)
    if [[ -d "$project_path/.claude" ]] || [[ -f "$project_path/CLAUDE.md" ]]; then
        detected+=("claude")
    fi

    # Default
    if [[ ${#detected[@]} -eq 0 ]]; then
        echo "[INFO] 未检测到已有 AI 工具配置，默认使用 .agents/skills/ (兼容 Gemini/Codex/Cursor)" >&2
        detected+=("gemini")
    fi

    echo "${detected[@]}"
}

get_target_dir() {
    local tool_name="$1"
    local project_path="$2"

    case "$tool_name" in
        gemini|cursor) echo "$project_path/.agents/skills" ;;
        claude)        echo "$project_path/.claude/skills" ;;
        *)             echo "$project_path/.agents/skills" ;;
    esac
}

# --- Main ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       blyy-skills-doc 安装工具           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

tools=()
if [[ "$TOOL" == "all" ]]; then
    tools=("gemini" "claude")
elif [[ -n "$TOOL" ]]; then
    tools=("$TOOL")
else
    read -ra tools <<< "$(detect_tools "$TARGET_PROJECT")"
fi

echo "[INFO] 目标项目: $TARGET_PROJECT"
echo "[INFO] 检测到的工具: ${tools[*]}"
echo "[INFO] 要安装的技能: ${SKILL_ARRAY[*]}"
echo ""

installed_count=0

for tool in "${tools[@]}"; do
    target_dir="$(get_target_dir "$tool" "$TARGET_PROJECT")"

    for skill in "${SKILL_ARRAY[@]}"; do
        source="$SKILLS_SOURCE_DIR/$skill"
        dest="$target_dir/$skill"

        if [[ -d "$dest" ]]; then
            echo "[SKIP] $skill -> $dest (已存在，跳过)"
            continue
        fi

        mkdir -p "$dest"
        cp -r "$source/"* "$dest/"

        file_count=$(find "$dest" -type f | wc -l)
        echo "[OK]   $skill -> $dest ($file_count 个文件)"
        installed_count=$((installed_count + 1))
    done
done

echo ""
if [[ $installed_count -gt 0 ]]; then
    echo "✅ 安装完成！共安装 $installed_count 个技能。"
    echo ""
    echo "下一步："
    echo "  1. 使用 blyy-init-docs 初始化项目文档（在 AI 工具中提及该技能名即可）"
    echo "  2. 后续代码变更时，blyy-doc-sync 会自动提醒更新文档"
else
    echo "⚠️  没有新技能被安装（可能全部已存在）。"
fi
