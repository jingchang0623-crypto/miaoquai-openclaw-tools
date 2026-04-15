#!/bin/bash
# =============================================================================
# OpenClaw PR Opportunity Finder
# 自动发现 OpenClaw 相关项目的 PR 机会
# Author: 妙趣AI (miaoquai.com)
# Version: 1.0.0
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REPO_CACHE="${HOME}/.cache/openclaw-pr-finder"
REPORT_FILE="pr-opportunities-$(date +%Y%m%d).md"
INTERACTIVE=false
SHOW_ALL=false

# OpenClaw 相关核心仓库列表
CORE_REPOS=(
    "openclaw/openclaw"
    "openclaw/skills"
    "openclaw/clawhub"
    "VoltAgent/awesome-openclaw-skills"
    "hesamsheikh/awesome-openclaw-usecases"
    "openclaw/docs"
    "Gen-Verse/OpenClaw-RL"
    "clawdbot-ai/awesome-openclaw-skills-zh"
    "xianyu110/awesome-openclaw-tutorial"
)

# 帮助信息
show_help() {
    cat << EOF
🦞 OpenClaw PR Opportunity Finder

用法: $0 [选项]

选项:
    -i, --interactive    交互式模式，逐个浏览机会
    -a, --all           显示所有问题，不仅限于 good first issue
    -h, --help          显示帮助信息

示例:
    $0                  # 快速扫描并生成报告
    $0 -i               # 交互式浏览
    $0 -a               # 显示所有开放问题

报告将保存在: ./reports/pr-opportunities-YYYYMMDD.md
EOF
}

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 初始化缓存目录
init_cache() {
    mkdir -p "$REPO_CACHE"
    mkdir -p "reports"
}

# 获取仓库开放 issues
fetch_repo_issues() {
    local repo=$1
    local per_page=$2
    local cache_file="$REPO_CACHE/${repo//\//_}.json"
    
    # 检查缓存（15分钟内有效）
    if [[ -f "$cache_file" ]] && [[ $(find "$cache_file" -mmin -15 2>/dev/null) ]]; then
        cat "$cache_file"
        return 0
    fi
    
    # 从 GitHub API 获取
    local response
    response=$(curl -s "https://api.github.com/repos/$repo/issues?state=open&per_page=$per_page" 2>/dev/null || echo "[]")
    
    # 保存缓存
    echo "$response" > "$cache_file"
    echo "$response"
}

# 检查是否为好的 PR 机会
is_good_opportunity() {
    local json=$1
    local labels=$(echo "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(','.join([l['name'] for l in d.get('labels',[])]))" 2>/dev/null || echo "")
    
    # 检查是否是 good first issue / help wanted / enhancement
    if [[ "$labels" == *"good first issue"* ]] || \
       [[ "$labels" == *"help wanted"* ]] || \
       [[ "$labels" == *"enhancement"* ]] || \
       [[ "$labels" == *"documentation"* ]] || \
       [[ "$labels" == *"docs"* ]]; then
        return 0
    fi
    
    # 检查是否是 PR 相关标签
    if [[ "$labels" == *"skill"* ]] || \
       [[ "$labels" == *"add skill"* ]] || \
       [[ "$labels" == *"add use case"* ]]; then
        return 0
    fi
    
    return 1
}

# 解析 issue 信息
parse_issue() {
    local json=$1
    python3 << PYEOF 2>/dev/null
import json
import sys

try:
    d = json.loads('''$json''')
    if not isinstance(d, dict):
        sys.exit(1)
    
    # 跳过 PR
    if d.get('pull_request'):
        sys.exit(1)
    
    number = d.get('number', 0)
    title = d.get('title', '')
    url = d.get('html_url', '')
    body = d.get('body', '') or ''
    state = d.get('state', '')
    created = d.get('created_at', '')[:10]
    comments = d.get('comments', 0)
    
    labels = [l['name'] for l in d.get('labels', [])]
    label_str = ', '.join(labels[:5])
    
    user = d.get('user', {}).get('login', 'unknown')
    
    print(f"{number}|{title}|{url}|{label_str}|{created}|{comments}|{user}|{body[:200]}")
except:
    sys.exit(1)
PYEOF
}

# 生成报告头部
generate_report_header() {
    local date_str=$(date '+%Y年%m月%d日 %H:%M')
    cat << EOF
# 🦞 OpenClaw PR 机会报告

**生成时间**: $date_str  
**报告来源**: [妙趣AI](https://miaoquai.com) 自动化运营工具  
**工具版本**: 1.0.0

---

## 📊 扫描概况

本报告扫描了以下核心仓库的最新开放 issues：

EOF
    for repo in "${CORE_REPOS[@]}"; do
        echo "- [$repo](https://github.com/$repo)"
    done
    
    echo -e "\n---\n"
}

# 扫描单个仓库
scan_repo() {
    local repo=$1
    log_info "扫描仓库: $repo"
    
    local issues_json
    issues_json=$(fetch_repo_issues "$repo" 5)
    
    # 检查是否为错误响应
    if echo "$issues_json" | grep -q '"message"'; then
        log_warn "无法访问 $repo: $(echo "$issues_json" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
        return 1
    fi
    
    local count=0
    local output=""
    
    # 处理每个 issue
    while IFS= read -r issue_json; do
        [[ -z "$issue_json" ]] && continue
        [[ "$issue_json" == "[" ]] && continue
        [[ "$issue_json" == "]" ]] && continue
        
        # 检查是否是好的机会
        if [[ "$SHOW_ALL" == false ]]; then
            if ! is_good_opportunity "$issue_json"; then
                continue
            fi
        fi
        
        local parsed
        parsed=$(parse_issue "$issue_json")
        [[ -z "$parsed" ]] && continue
        
        IFS='|' read -r number title url labels created comments user <<< "$parsed"
        [[ -z "$number" ]] && continue
        
        output+="\n### #$number: $title\n"
        output+="**仓库**: [$repo](https://github.com/$repo)  \n"
        output+="**标签**: ${labels:-无}  \n"
        output+="**创建**: $created | **评论**: $comments | **作者**: @$user  \n"
        output+="**链接**: [$url]($url)\n"
        output+="\n**推荐理由**: "
        
        # 添加推荐理由
        if [[ "$labels" == *"good first issue"* ]]; then
            output+="🏷️ 标记为 **good first issue**，适合新手贡献"
        elif [[ "$labels" == *"documentation"* ]] || [[ "$labels" == *"docs"* ]]; then
            output+="📚 文档改进，适合熟悉项目后贡献"
        elif [[ "$labels" == *"skill"* ]] || [[ "$labels" == *"add skill"* ]]; then
            output+="🛠️ 添加新 Skill，可展示你对 OpenClaw 的理解"
        elif [[ "$labels" == *"enhancement"* ]]; then
            output+="✨ 功能增强，有技术含量"
        else
            output+="🔍 开放问题，等待社区贡献"
        fi
        output+="\n"
        
        ((count++))
    done < <(echo "$issues_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join([json.dumps(i) for i in d]))" 2>/dev/null)
    
    if [[ $count -gt 0 ]]; then
        log_success "在 $repo 发现 $count 个机会"
        echo -e "\n## 📁 $repo" >> "$REPORT_FILE"
        echo -e "$output" >> "$REPORT_FILE"
        return 0
    else
        log_warn "$repo 暂无合适机会"
        return 1
    fi
}

# 主扫描函数
run_scan() {
    log_info "开始扫描 OpenClaw 生态的 PR 机会..."
    log_info "模式: $([[ $SHOW_ALL == true ]] && echo '显示所有 issues' || echo '仅显示好机会')"
    echo
    
    # 生成报告头部
    generate_report_header > "$REPORT_FILE"
    
    local found=0
    for repo in "${CORE_REPOS[@]}"; do
        if scan_repo "$repo"; then
            ((found++))
        fi
        sleep 0.5  # 避免 API 限流
    done
    
    # 添加报告底部
    cat << EOF >> "$REPORT_FILE"

---

## 🎯 下一步行动

1. **选择合适的 Issue**: 根据自己的技能和兴趣选择
2. **阅读贡献指南**: 查看仓库的 CONTRIBUTING.md
3. **留言认领**: 在 issue 下留言表示愿意贡献
4. **开始编码**: 创建分支，提交 PR
5. **参与社区**: 加入 OpenClaw 社区交流

## 🔗 相关资源

- 🌐 [妙趣AI - AI工具导航与资讯](https://miaoquai.com)
- 📖 [OpenClaw 文档](https://docs.openclaw.org)
- 💬 [OpenClaw Discord](https://discord.gg/openclaw)
- 🦞 [OpenClaw GitHub](https://github.com/openclaw)

---

*本报告由 [妙趣AI](https://miaoquai.com) 自动生成 | OpenClaw 生态贡献者工具*
EOF
    
    echo
    log_success "扫描完成！"
    log_info "报告已保存: $REPORT_FILE"
    log_info "发现 $found 个仓库有贡献机会"
    
    if [[ $found -eq 0 ]]; then
        log_warn "今天没有找到合适的机会，明天再来看看吧~"
    fi
}

# 交互式模式
interactive_mode() {
    log_info "进入交互式模式..."
    
    local all_issues=()
    
    # 收集所有问题
    for repo in "${CORE_REPOS[@]}"; do
        local issues_json
        issues_json=$(fetch_repo_issues "$repo" 3)
        
        while IFS= read -r issue_json; do
            [[ -z "$issue_json" ]] && continue
            local parsed
            parsed=$(parse_issue "$issue_json")
            [[ -z "$parsed" ]] && continue
            
            IFS='|' read -r number title url labels created comments user <<< "$parsed"
            all_issues+=("$repo|#$number|$title|$url|$labels")
        done < <(echo "$issues_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join([json.dumps(i) for i in d]))" 2>/dev/null)
        
        sleep 0.3
    done
    
    local total=${#all_issues[@]}
    log_info "共发现 $total 个开放 issue"
    echo
    
    local idx=0
    for issue in "${all_issues[@]}"; do
        ((idx++))
        IFS='|' read -r repo number title url labels <<< "$issue"
        
        echo -e "${GREEN}[$idx/$total]${NC} $repo $number"
        echo "    📌 $title"
        echo "    🏷️ 标签: ${labels:-无}"
        echo "    🔗 $url"
        echo
        
        read -p "按 Enter 继续，输入 'o' 在浏览器打开，'q' 退出: " choice
        case $choice in
            o|O)
                if command -v xdg-open &> /dev/null; then
                    xdg-open "$url" &
                elif command -v open &> /dev/null; then
                    open "$url"
                else
                    log_warn "无法自动打开浏览器，请手动访问: $url"
                fi
                ;;
            q|Q)
                log_info "退出交互模式"
                break
                ;;
        esac
        echo
    done
}

# 清理缓存
cleanup() {
    rm -rf "$REPO_CACHE"
    log_info "缓存已清理"
}

# 主函数
main() {
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -a|--all)
                SHOW_ALL=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查依赖
    if ! command -v curl &> /dev/null; then
        log_error "需要安装 curl"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        log_error "需要安装 python3"
        exit 1
    fi
    
    # 初始化
    init_cache
    
    # 根据模式运行
    if [[ "$INTERACTIVE" == true ]]; then
        interactive_mode
    else
        run_scan
        
        # 显示报告预览
        if [[ -f "$REPORT_FILE" ]]; then
            echo
            echo "=== 报告预览 (前50行) ==="
            head -50 "$REPORT_FILE"
            echo
            echo "=== 完整报告: $REPORT_FILE ==="
        fi
    fi
    
    # 可选：清理缓存
    # cleanup
}

# 运行
main "$@"
