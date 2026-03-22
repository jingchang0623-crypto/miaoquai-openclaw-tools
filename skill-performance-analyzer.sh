#!/bin/bash
#
# OpenClaw Skill Performance Analyzer
# 妙趣AI - Skills 效果分析器
# 分析 Skills 使用效果，提供优化建议
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
REPORTS_DIR="$SCRIPT_DIR/skill-reports"
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 创建报告目录
mkdir -p "$REPORTS_DIR"

# 默认配置
ANALYSIS_TYPE="full"  # full | quick | trending
OUTPUT_FORMAT="markdown"  # markdown | json
SKILLS_DIR="$HOME/.openclaw/skills"
OPENCLAW_DIR="$HOME/.openclaw"

show_usage() {
    cat << EOF
OpenClaw Skill Performance Analyzer
妙趣AI - Skills 效果分析器

用法: $0 [选项]

选项:
    -t, --type <类型>      分析类型: full, quick, trending (默认: full)
    -o, --output <格式>    输出格式: markdown, json (默认: markdown)
    -s, --skills <目录>    Skills 目录 (默认: ~/.openclaw/skills)
    -v, --verbose          显示详细输出
    -h, --help             显示帮助

示例:
    $0                      # 完整分析
    $0 -t quick             # 快速分析
    $0 -t trending         # 分析 trending skills
    $0 -o json             # JSON 格式输出

EOF
}

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            ANALYSIS_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -s|--skills)
            SKILLS_DIR="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 分析 Skills 目录结构
analyze_skills_structure() {
    log_info "分析 Skills 目录结构..."

    local skills_count=0
    local categories=()

    if [[ -d "$SKILLS_DIR" ]]; then
        for dir in "$SKILLS_DIR"/*/; do
            if [[ -d "$dir" ]]; then
                ((skills_count++))
                local category=$(basename "$dir")
                categories+=("$category")
            fi
        done
    fi

    echo "{\"skills_count\": $skills_count, \"categories\": [$(IFS=,; echo "${categories[*]}")], \"location\": \"$SKILLS_DIR\"}"
}

# 分析单个 Skill
analyze_skill() {
    local skill_path="$1"
    local skill_name=$(basename "$skill_path")

    # 检查必要文件
    local has_skill_md=0
    local has_readme=0
    local description=""
    local tools_count=0
    local lines_count=0

    [[ -f "$skill_path/SKILL.md" ]] && has_skill_md=1
    [[ -f "$skill_path/README.md" ]] && has_readme=1

    # 提取描述
    if [[ -f "$skill_path/SKILL.md" ]]; then
        description=$(head -5 "$skill_path/SKILL.md" | grep -E "^#|description" | head -1 | sed 's/# //' | tr -d '"')
        lines_count=$(wc -l < "$skill_path/SKILL.md")
    fi

    # 统计工具
    if [[ -f "$skill_path/tools.md" ]]; then
        tools_count=$(grep -c "^-\s" "$skill_path/tools.md" 2>/dev/null || echo 0)
    fi

    # 评分
    local score=0
    [[ $has_skill_md -eq 1 ]] && ((score+=30))
    [[ $has_readme -eq 1 ]] && ((score+=20))
    [[ ${#description} -gt 10 ]] && ((score+=20))
    [[ $tools_count -gt 0 ]] && ((score+=15))
    [[ $lines_count -gt 20 ]] && ((score+=15))

    echo "{\"name\": \"$skill_name\", \"score\": $score, \"has_skill_md\": $has_skill_md, \"has_readme\": $has_readme, \"description\": \"$description\", \"tools_count\": $tools_count, \"lines_count\": $lines_count}"
}

# 分析所有 Skills
analyze_all_skills() {
    log_info "分析所有 Skills..."

    local results=()

    if [[ -d "$SKILLS_DIR" ]]; then
        for dir in "$SKILLS_DIR"/*/; do
            if [[ -d "$dir" ]]; then
                local result=$(analyze_skill "$dir")
                results+=("$result")
            fi
        done
    fi

    echo "[${results[*]}]" | jq -s '.' 2>/dev/null || echo "[]"
}

# 分析 trending 相关项目
analyze_trending() {
    log_info "分析 GitHub Trending 相关项目..."

    # 手动维护的相关项目列表
    local trending_projects=(
        "volcengine/OpenViking:OpenClaw专用上下文数据库"
        "obra/superpowers:Agentic Skills框架"
        "affaan-m/everything-claude-code:Agent性能优化"
        "shareAI-lab/learn-claude-code:Claude Code学习"
        "langchain-ai/deepagents:Agent Harness"
    )

    echo "# 📈 OpenClaw 生态系统 trending 分析"

    for project in "${trending_projects[@]}"; do
        IFS=':' read -r repo desc <<< "$project"
        echo "## $repo"
        echo "- 描述: $desc"
        echo "- 仓库: https://github.com/$repo"
        echo ""
    done
}

# 生成完整报告
generate_full_report() {
    local output_file="$REPORTS_DIR/skill-analysis-$TIMESTAMP.md"

    log_info "生成完整分析报告..."

    {
        echo "# 🤖 OpenClaw Skills 效果分析报告"
        echo ""
        echo "**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**分析类型**: $ANALYSIS_TYPE"
        echo "**Skills目录**: $SKILLS_DIR"
        echo ""
        echo "---"
        echo ""

        # 1. Skills 统计
        echo "## 📊 Skills 统计"
        echo ""
        local structure=$(analyze_skills_structure)
        echo "$structure" | jq -r '"
**统计信息**:
- Skills 总数: \(.skills_count)
- 目录位置: \(.location)
- 分类: \(.categories | join(", "))
"
        echo ""

        # 2. 各项 Skill 评分
        echo "## ⭐ Skills 评分"
        echo ""
        local skills_data=$(analyze_all_skills)
        echo "$skills_data" | jq -r '.[] | "- **\(.name)**: 得分 \(.score)/100 \(if .score >= 70 then "✅" elif .score >= 50 then "⚠️" else "❌" end)\n  - 描述: \(.description)\n  - 工具数: \(.tools_count)\n  - 代码行: \(.lines_count)\n"' 2>/dev/null || echo "_无法解析 Skills 数据_"
        echo ""

        # 3. 优化建议
        echo "## 💡 优化建议"
        echo ""
        echo "### 立即可执行"
        echo ""
        echo "1. **完善 SKILL.md** - 确保每个 Skill 都有完整的 SKILL.md 文件"
        echo "2. **添加使用示例** - 在 README.md 中添加实际使用案例"
        echo "3. **定义工具清单** - 创建 tools.md 列出所有支持的工具"
        echo ""
        echo "### 长期优化"
        echo ""
        echo "1. **监控 trending** - 关注 volcengine/OpenViking 等新兴项目"
        echo "2. **性能优化** - 参考 affaan-m/everything-claude-code 的优化方案"
        echo "3. **技能组合** - 探索 obra/superpowers 的组合方法"
        echo ""

        # 4. Trending 项目
        echo "## 🔥 Trending 项目"
        echo ""
        analyze_trending
        echo ""

        # 5. 相关链接
        echo "## 🔗 相关链接"
        echo ""
        echo "- [妙趣AI](https://miaoquai.com)"
        echo "- [OpenClaw 官方](https://openclaw.ai)"
        echo "- [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)"
        echo ""
        echo "---"
        echo "*🤖 妙趣AI - 让AI营销变得有趣！*"
    } > "$output_file"

    log_success "报告已生成: $output_file"
    echo "$output_file"
}

# 快速分析
quick_analysis() {
    log_info "执行快速分析..."

    local skills_count=0
    [[ -d "$SKILLS_DIR" ]] && skills_count=$(find "$SKILLS_DIR" -maxdepth 1 -type d | wc -l)
    ((skills_count--))

    echo "📊 Quick Stats:"
    echo "- Skills 数量: $skills_count"
    echo "- Skills 目录: $SKILLS_DIR"
    echo "- 分析时间: $(date '+%Y-%m-%d %H:%M:%S')"
}

# 主程序
main() {
    log_info "🤖 OpenClaw Skill Performance Analyzer"
    log_info "分析类型: $ANALYSIS_TYPE"
    log_info "输出格式: $OUTPUT_FORMAT"
    echo ""

    case $ANALYSIS_TYPE in
        full)
            if [[ "$OUTPUT_FORMAT" == "json" ]]; then
                analyze_all_skills | jq '.'
            else
                generate_full_report
            fi
            ;;
        quick)
            quick_analysis
            ;;
        trending)
            analyze_trending
            ;;
        *)
            log_error "未知分析类型: $ANALYSIS_TYPE"
            exit 1
            ;;
    esac
}

main
