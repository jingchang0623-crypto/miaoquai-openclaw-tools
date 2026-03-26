#!/bin/bash
#===============================================================================
# AI News RSS Fetcher - AI新闻RSS聚合器
# 
# 功能：自动抓取各大AI源的RSS新闻，生成内容摘要和报告
# 输出：/var/www/miaoquai/rss/ai-news-YYYY-MM-DD.md
#
# 使用方法：
#   ./ai-news-rss-fetcher.sh          # 抓取所有源
#   ./ai-news-rss-fetcher.sh openai  # 只抓取 OpenAI
#   ./ai-news-rss-fetcher.sh list    # 列出所有可用源
#===============================================================================

set -euo pipefail

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-/var/www/miaoquai/rss}"
CONFIG_FILE="${SCRIPT_DIR}/config/rss-sources.conf"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 默认 RSS 源
declare -A RSS_SOURCES=(
    ["openai"]="https://openai.com/blog/rss.xml"
    ["anthropic"]="https://www.anthropic.com/rss.xml"
    ["huggingface"]="https://huggingface.co/blog/feed.xml"
    ["thegradient"]="https://thegradient.pub/rss/"
    ["mit_techreview"]="https://www.technologyreview.com/feed/"
    ["techcrunch_ai"]="https://techcrunch.com/category/artificial-intelligence/feed/"
    ["wired_ai"]="https://www.wired.com/feed/tag/ai/latest/rss"
)

# 显示帮助
show_help() {
    cat << EOF
AI News RSS Fetcher - AI新闻RSS聚合器

使用方法:
    $(basename $0) [选项] [源...]

选项:
    list              列出所有可用RSS源
    fetch <源>        抓取指定源的新闻
    all               抓取所有源的新闻 (默认)
    --help            显示帮助信息

示例:
    $(basename $0)              # 抓取所有源
    $(basename $0) openai anthropic  # 只抓取 OpenAI 和 Anthropic
    $(basename $0) list        # 列出所有源

源列表:
EOF
    for source in "${!RSS_SOURCES[@]}"; do
        echo "    - $source"
    done
}

# 列出所有源
list_sources() {
    echo "可用 RSS 源:"
    echo "============="
    for source in "${!RSS_SOURCES[@]}"; do
        echo -e "  ${GREEN}$source${NC}"
        echo "    URL: ${RSS_SOURCES[$source]}"
    done
}

# 解析 RSS
parse_rss() {
    local url="$1"
    local source="$2"
    
    log_info "正在抓取 $source..."
    
    # 使用 curl 获取 RSS
    local response
    response=$(curl -s -L --max-time 30 "$url" 2>/dev/null) || {
        log_error "无法抓取 $source: $url"
        return 1
    }
    
    # 解析 XML (简单处理)
    echo "$response" | grep -oE '<item><title>[^<]+</title><link>[^<]+</link></item>' 2>/dev/null | \
    sed 's/<item>//g' | sed 's/<\/item>//g' | \
    while read -r item; do
        local title=$(echo "$item" | grep -oE '<title>[^<]+</title>' | sed 's/<title>//g' | sed 's/<\/title>//g')
        local link=$(echo "$item" | grep -oE '<link>[^<]+</link>' | sed 's/<link>//g' | sed 's/<\/link>//g')
        if [[ -n "$title" && -n "$link" ]]; then
            echo "- [$title]($link)"
        fi
    done
    
    log_success "$source 抓取完成"
}

# 生成报告
generate_report() {
    local date=$(date +%Y-%m-%d)
    local output_file="${OUTPUT_DIR}/ai-news-${date}.md"
    
    mkdir -p "$OUTPUT_DIR"
    
    cat > "$output_file" << EOF
# AI 新闻日报 - ${date}

> 妙趣AI自动聚合 | 数据来源：RSS

---

## 📰 今日热门

EOF

    # 抓取每个源
    for source in "${!RSS_SOURCES[@]}"; do
        echo "### $(echo $source | tr '_' ' ' | tr '[:lower:]' '[:upper:]')" >> "$output_file"
        echo "" >> "$output_file"
        
        local news=$(parse_rss "${RSS_SOURCES[$source]}" "$source")
        if [[ -n "$news" ]]; then
            echo "$news" >> "$output_file"
        else
            echo "暂无更新" >> "$output_file"
        fi
        echo "" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

---

📡 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')

🔗 更多AI资讯: [miaoquai.com](https://miaoquai.com)
EOF

    log_success "报告已生成: $output_file"
    echo "$output_file"
}

# 主函数
main() {
    local sources=()
    
    # 解析参数
    if [[ $# -eq 0 ]]; then
        sources=("${!RSS_SOURCES[@]}")
    else
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            list)
                list_sources
                exit 0
                ;;
            all)
                sources=("${!RSS_SOURCES[@]}")
                ;;
            *)
                for arg in "$@"; do
                    if [[ "${RSS_SOURCES[$arg]:-}" ]]; then
                        sources+=("$arg")
                    else
                        log_warn "未知源: $arg"
                    fi
                done
                ;;
        esac
    fi
    
    # 如果没有指定有效源，退出
    if [[ ${#sources[@]} -eq 0 ]]; then
        log_error "没有有效的RSS源"
        show_help
        exit 1
    fi
    
    log_info "开始抓取 ${#sources[@]} 个RSS源..."
    
    # 生成报告
    generate_report
    
    log_success "完成！"
}

# 运行
main "$@"
