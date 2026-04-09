#!/bin/bash
# OpenClaw Skill Curator - 智能 Skills 发现与推荐工具
# 自动从多个源收集、评估、推荐 OpenClaw Skills
# Author: 妙趣AI (miaoquai.com)

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${SCRIPT_DIR}/curated-reports"
SKILL_CACHE="${SCRIPT_DIR}/.skill-cache"
CONFIG_FILE="${SCRIPT_DIR}/config/skill-curator.conf"
LOG_FILE="${SCRIPT_DIR}/logs/skill-curator-$(date +%Y%m%d).log"

# 默认配置
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
CLAWHUB_API="${CLAWHUB_API:-https://clawdhub.com/api}"
MIN_STARS="${MIN_STARS:-10}"
MAX_SKILLS_PER_RUN="${MAX_SKILLS_PER_RUN:-50}"

# Skills 源列表
SOURCES=(
    "github:openclaw/skills"
    "github:VoltAgent/awesome-openclaw-skills"
    "github:rylena/awesome-openclaw"
    "clawhub:registry"
)

# 分类映射
CATEGORY_MAP=(
    "marketing:营销自动化|SEO|内容生成|社交媒体"
    "development:开发工具|代码|编程|API"
    "productivity:效率|生产力|任务管理|日程"
    "automation:自动化|工作流|定时任务|触发器"
    "creative:创意|设计|写作|图片|视频"
    "research:研究|分析|数据|报告|监控"
    "integration:集成|连接|同步|导入|导出"
    "monitoring:监控|告警|日志|健康检查"
)

# 日志函数
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "${GREEN}[INFO]${NC} $msg" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
        DEBUG) echo -e "${CYAN}[DEBUG]${NC} $msg" ;;
    esac
    
    # 写入日志文件
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
}

# 初始化
curator_init() {
    log INFO "🦞 OpenClaw Skill Curator 初始化中..."
    
    mkdir -p "$REPORT_DIR" "$SKILL_CACHE" "${SCRIPT_DIR}/logs"
    
    # 检查依赖
    local deps=("curl" "jq" "gh")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log ERROR "缺少依赖: $dep"
            exit 1
        fi
    done
    
    # 检查 GitHub 登录
    if ! gh auth status &> /dev/null; then
        log ERROR "未登录 GitHub，请运行: gh auth login"
        exit 1
    fi
    
    log INFO "✅ 初始化完成"
}

# 从 GitHub 搜索 Skills
fetch_github_skills() {
    log INFO "🔍 从 GitHub 搜索 OpenClaw Skills..."
    
    local cache_file="$SKILL_CACHE/github-$(date +%Y%m%d).json"
    
    # 搜索多个关键词
    local queries=("openclaw skill" "openclaw skills" "clawbot skill" "moltbot skill")
    local all_results="[]"
    
    for query in "${queries[@]}"; do
        log DEBUG "搜索: $query"
        local results=$(gh search repos "$query" \
            --sort updated \
            --limit 20 \
            --json fullName,description,stargazersCount,url,updatedAt,topics,language \
            2>/dev/null || echo "[]")
        
        # 合并结果
        all_results=$(echo "$all_results" "$results" | jq -s 'add | unique_by(.fullName)')
    done
    
    # 过滤低星项目
    all_results=$(echo "$all_results" | jq "[.[] | select(.stargazersCount >= $MIN_STARS)]")
    
    echo "$all_results" > "$cache_file"
    local count=$(echo "$all_results" | jq 'length')
    log INFO "✅ 从 GitHub 发现 $count 个 Skills"
    
    echo "$all_results"
}

# 从 awesome 列表获取
fetch_awesome_lists() {
    log INFO "📚 从 Awesome 列表获取 Skills..."
    
    local awesome_repos=(
        "VoltAgent/awesome-openclaw-skills"
        "rylena/awesome-openclaw"
        "vincentkoc/awesome-openclaw"
    )
    
    local all_skills="[]"
    
    for repo in "${awesome_repos[@]}"; do
        log DEBUG "获取: $repo"
        
        # 获取 README 内容
        local readme=$(gh api "repos/$repo/readme" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || echo "")
        
        if [[ -n "$readme" ]]; then
            # 解析 README 中的链接
            local skills=$(echo "$readme" | grep -oE '\* \[.*\]\(https://github\.com/[^)]+\)' | \
                sed -E 's/\* \[([^]]+)\]\(([^)]+)\).*/{"name":"\1","url":"\2","source":"'$repo'"}/' | \
                jq -s '.')
            
            all_skills=$(echo "$all_skills" "$skills" | jq -s 'add')
        fi
    done
    
    local count=$(echo "$all_skills" | jq 'length')
    log INFO "✅ 从 Awesome 列表发现 $count 个 Skills"
    
    echo "$all_skills"
}

# 智能分类
classify_skill() {
    local name="$1"
    local description="$2"
    local topics="$3"
    
    local text="${name,,} ${description,,} ${topics,,}"
    
    for mapping in "${CATEGORY_MAP[@]}"; do
        local category="${mapping%%:*}"
        local keywords="${mapping##*:}"
        
        IFS='|' read -ra keyword_array <<< "$keywords"
        for keyword in "${keyword_array[@]}"; do
            if [[ "$text" == *"${keyword,,}"* ]]; then
                echo "$category"
                return
            fi
        done
    done
    
    echo "general"
}

# 评估 Skill 质量
evaluate_skill() {
    local repo="$1"
    
    log DEBUG "评估: $repo"
    
    # 获取仓库详情
    local details=$(gh api "repos/$repo" --jq '{
        stars: .stargazers_count,
        forks: .forks_count,
        open_issues: .open_issues_count,
        updated: .updated_at,
        created: .created_at,
        has_wiki: .has_wiki,
        has_pages: .has_pages,
        license: .license.name,
        topics: .topics
    }' 2>/dev/null || echo '{}')
    
    # 检查是否有 SKILL.md
    local has_skill_md=$(gh api "repos/$repo/contents/SKILL.md" &>/dev/null && echo "true" || echo "false")
    
    # 计算质量分数 (0-100)
    local stars=$(echo "$details" | jq '.stars // 0')
    local forks=$(echo "$details" | jq '.forks // 0')
    local topics_count=$(echo "$details" | jq '.topics | length')
    
    local score=0
    (( score += stars > 100 ? 25 : stars / 4 ))
    (( score += forks > 20 ? 15 : forks / 2 ))
    (( score += topics_count > 3 ? 10 : topics_count * 3 ))
    [[ "$has_skill_md" == "true" ]] && (( score += 20 ))
    [[ $(echo "$details" | jq '.license') != "null" ]] && (( score += 10 ))
    [[ $(echo "$details" | jq '.has_wiki') == "true" ]] && (( score += 5 ))
    
    # 活跃度加分 (最近30天有更新)
    local updated=$(echo "$details" | jq -r '.updated // ""' | cut -d'T' -f1)
    local days_since_update=$(( ($(date +%s) - $(date -d "$updated" +%s 2>/dev/null || echo 0)) / 86400 ))
    [[ $days_since_update -lt 30 ]] && (( score += 15 ))
    
    # 确保分数在 0-100 之间
    [[ $score -gt 100 ]] && score=100
    
    echo "{\"quality_score\": $score, \"has_skill_md\": $has_skill_md, \"details\": $details}"
}

# 生成推荐报告
generate_report() {
    log INFO "📝 生成推荐报告..."
    
    local github_skills="$1"
    local awesome_skills="$2"
    local date_str=$(date +%Y-%m-%d)
    local report_file="$REPORT_DIR/skill-curation-$date_str.md"
    
    # 评估 GitHub Skills
    log INFO "🔍 评估 Skills 质量..."
    local evaluated_skills="[]"
    
    local total=$(echo "$github_skills" | jq 'length')
    local processed=0
    
    echo "$github_skills" | jq -r '.[] | .fullName' | while read repo; do
        ((processed++))
        log DEBUG "[$processed/$total] 评估: $repo"
        
        local eval_result=$(evaluate_skill "$repo")
        local skill_data=$(echo "$github_skills" | jq --arg repo "$repo" '.[] | select(.fullName == $repo)')
        
        local combined=$(echo "$skill_data" | jq --argjson eval "$eval_result" '. + $eval')
        
        # 分类
        local category=$(classify_skill "$repo" "$(echo "$skill_data" | jq -r '.description // ""')" "$(echo "$skill_data" | jq -r '.topics | join(" ") // ""')")
        combined=$(echo "$combined" | jq --arg cat "$category" '. + {category: $cat}')
        
        evaluated_skills=$(echo "$evaluated_skills" "$combined" | jq -s 'add')
    done
    
    # 生成 Markdown 报告
    cat > "$report_file" << EOF
# 🦞 OpenClaw Skills 精选周报

> **生成时间**: $date_str  
> **来源**: GitHub + Awesome Lists  
> **筛选标准**: ⭐ >= $MIN_STARS, 质量分 >= 60  
> **生成者**: [妙趣AI](https://miaoquai.com)

---

## 📊 本周概览

| 指标 | 数值 |
|------|------|
| 发现 Skills | $(echo "$github_skills" | jq 'length') |
| 通过质量筛选 | $(echo "$evaluated_skills" | jq '[.[] | select(.quality_score >= 60)] | length') |
| 高星项目 (⭐100+) | $(echo "$github_skills" | jq '[.[] | select(.stargazersCount >= 100)] | length') |
| 新增本周 | $(echo "$github_skills" | jq '[.[] | select(.updatedAt | contains("'$date_str'"))] | length') |

---

## 🌟 本周精选 (质量分 Top 10)

EOF

    # 添加精选 Skills
    echo "$evaluated_skills" | jq -r '. | sort_by(.quality_score) | reverse | .[0:10] | .[] | @base64' | \
    while read skill_b64; do
        local skill=$(echo "$skill_b64" | base64 -d)
        local name=$(echo "$skill" | jq -r '.fullName')
        local desc=$(echo "$skill" | jq -r '.description // "暂无描述"')
        local stars=$(echo "$skill" | jq -r '.stargazersCount')
        local score=$(echo "$skill" | jq -r '.quality_score')
        local url=$(echo "$skill" | jq -r '.url')
        local category=$(echo "$skill" | jq -r '.category')
        local has_md=$(echo "$skill" | jq -r '.has_skill_md')
        
        local badge=""
        [[ "$has_md" == "true" ]] && badge="📋"
        [[ $score -ge 80 ]] && badge="$badge 🏆"
        [[ $stars -ge 100 ]] && badge="$badge 🔥"
        
        cat >> "$report_file" << EOF
### $badge [$name]($url)

**质量分**: $score/100 | **⭐**: $stars | **分类**: $category

$desc

---

EOF
    done

    # 按分类汇总
    cat >> "$report_file" << EOF

## 📂 分类汇总

EOF

    for mapping in "${CATEGORY_MAP[@]}"; do
        local category="${mapping%%:*}"
        local category_emoji=""
        case "$category" in
            marketing) category_emoji="📢" ;;
            development) category_emoji="💻" ;;
            productivity) category_emoji="⚡" ;;
            automation) category_emoji="🤖" ;;
            creative) category_emoji="🎨" ;;
            research) category_emoji="🔬" ;;
            integration) category_emoji="🔗" ;;
            monitoring) category_emoji="📊" ;;
        esac
        
        local cat_skills=$(echo "$evaluated_skills" | jq --arg cat "$category" '[.[] | select(.category == $cat)]')
        local cat_count=$(echo "$cat_skills" | jq 'length')
        
        [[ $cat_count -eq 0 ]] && continue
        
        cat >> "$report_file" << EOF
### $category_emoji $category ($cat_count)

| Skill | Stars | 质量分 | 描述 |
|-------|-------|--------|------|
EOF

        echo "$cat_skills" | jq -r '. | sort_by(.quality_score) | reverse | .[0:5] | .[] | "| [\(.fullName)](\(.url)) | ⭐\(.stargazersCount) | \(.quality_score) | \(.description // "-") |"' >> "$report_file"
        echo "" >> "$report_file"
    done

    # 添加页脚
    cat >> "$report_file" << EOF

---

## 💡 如何使用

### 快速安装 Skill
\`\`\`bash
# 通过 clawd 安装
clawd skill install <skill-name>

# 或手动克隆
cd ~/.openclaw/skills
git clone <repo-url>
\`\`\`

### 提交你的 Skill

如果你开发了 OpenClaw Skill，欢迎提交到 awesome 列表：

1. Fork [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)
2. 添加你的 Skill 到对应分类
3. 提交 Pull Request

---

<p align="center">
  <sub>🦞 由 <a href="https://miaoquai.com">妙趣AI</a> 自动生成 | 
  <a href="https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools">工具源码</a></sub>
</p>
EOF

    log INFO "✅ 报告已生成: $report_file"
    echo "$report_file"
}

# 自动提交到 GitHub
auto_commit() {
    local report_file="$1"
    
    log INFO "🚀 自动提交到 GitHub..."
    
    cd "$SCRIPT_DIR"
    
    # 检查是否有更改
    if git diff --quiet && git diff --cached --quiet; then
        # 添加新报告
        git add "$report_file" 2>/dev/null || true
        git add "$SKILL_CACHE/" 2>/dev/null || true
    fi
    
    if git diff --cached --quiet; then
        log WARN "没有可提交的更改"
        return
    fi
    
    local date_str=$(date +%Y-%m-%d)
    git commit -m "📚 更新 Skills 精选周报 - $date_str

- 自动发现 $(echo "$github_skills" | jq 'length') 个 Skills
- 评估通过 $(echo "$evaluated_skills" | jq '[.[] | select(.quality_score >= 60)] | length') 个
- 生成质量报告

🦞 Generated by Miaoquai OpenClaw Tools" 2>/dev/null || true
    
    git push origin main 2>/dev/null || git push origin master 2>/dev/null || {
        log ERROR "推送失败"
        return 1
    }
    
    log INFO "✅ 已成功提交到 GitHub"
}

# 尝试提交 PR 到 awesome-openclaw-skills
submit_pr() {
    log INFO "🔄 检查是否需要提交 PR..."
    
    local target_repo="VoltAgent/awesome-openclaw-skills"
    
    # 检查是否有 fork
    local has_fork=$(gh repo list --json nameWithOwner --jq '.[] | select(.nameWithOwner | contains("awesome-openclaw-skills")) | .nameWithOwner' 2>/dev/null)
    
    if [[ -z "$has_fork" ]]; then
        log INFO "创建 fork..."
        gh repo fork "$target_repo" --clone=false 2>/dev/null || {
            log WARN "Fork 创建失败，跳过 PR"
            return
        }
    fi
    
    log INFO "✅ 已准备好 PR 环境"
    log INFO "💡 手动提交 PR: https://github.com/$target_repo/compare"
}

# 主函数
curator_main() {
    local action="${1:-run}"
    
    case "$action" in
        init)
            curator_init
            ;;
        run|discover)
            curator_init
            local github_skills=$(fetch_github_skills)
            local awesome_skills=$(fetch_awesome_lists)
            local report_file=$(generate_report "$github_skills" "$awesome_skills")
            
            # 显示报告摘要
            echo ""
            log INFO "📊 本周发现摘要:"
            echo "$github_skills" | jq -r '.[] | "  ⭐ \(.stargazersCount) \(.fullName)"' | head -10
            
            # 自动提交
            auto_commit "$report_file"
            
            # 提示 PR
            log INFO "💡 考虑提交 PR 到 awesome-openclaw-skills?"
            log INFO "   访问: https://github.com/VoltAgent/awesome-openclaw-skills"
            ;;
        report)
            curator_init
            local github_skills=$(fetch_github_skills)
            local awesome_skills=$(fetch_awesome_lists)
            generate_report "$github_skills" "$awesome_skills"
            ;;
        pr)
            submit_pr
            ;;
        help|--help|-h)
            echo "🦞 OpenClaw Skill Curator - 智能 Skills 发现与推荐工具

用法: $0 [命令]

命令:
  run, discover   运行完整的发现流程 (默认)
  init            初始化环境
  report          仅生成报告
  pr              准备 Pull Request
  help            显示帮助

环境变量:
  GITHUB_TOKEN    GitHub API Token
  MIN_STARS       最小星标数 (默认: 10)
  MAX_SKILLS      每次最大处理数 (默认: 50)

示例:
  $0                              # 运行完整流程
  $0 report                       # 仅生成报告
  MIN_STARS=50 $0                 # 只显示高星项目

网站: https://miaoquai.com"
            ;;
        *)
            log ERROR "未知命令: $action"
            echo "运行 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

# 如果直接运行此脚本
curator_main "$@"
