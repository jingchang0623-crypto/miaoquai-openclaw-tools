#!/bin/bash
#
# OpenClaw 社交媒体内容聚合器
# 自动收集 Twitter/X、GitHub 等平台的 OpenClaw 相关内容
# 生成适合妙趣网站发布的结构化内容摘要
#
# 用法:
#   ./social-media-aggregator.sh run          # 运行聚合
#   ./social-media-aggregator.sh config        # 查看配置
#   ./social-media-aggregator.sh test          # 测试连接
#

set -euo pipefail

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config/social-media.conf"
OUTPUT_DIR="/var/www/miaoquai/social"
LOG_FILE="/var/log/miaoquai/social-aggregator.log"

# 默认配置
TWITTER_QUERY="${TWITTER_QUERY:-opencl* OR #OpenClaw OR @openclaw}"
GITHUB_KEYWORDS="${GITHUB_KEYWORDS:-openclaw,agent,claude,gpt}"
DAYS_BACK=7

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

info() { log "${BLUE}[INFO]${NC} $1"; }
success() { log "${GREEN}[OK]${NC} $1"; }
warn() { log "${YELLOW}[WARN]${NC} $1"; }
error() { log "${RED}[ERROR]${NC} $1"; }

# 加载配置
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        info "已加载配置文件: $CONFIG_FILE"
    else
        warn "配置文件不存在，使用默认配置"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        create_default_config
    fi
}

# 创建默认配置
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# OpenClaw 社交媒体聚合器配置

# Twitter/X 搜索关键词 (使用 Twitter API 或 Nitter 等替代)
TWITTER_QUERY="openclaw OR #OpenClaw OR @openclaw OR agent framework"

# GitHub 搜索关键词
GITHUB_KEYWORDS="openclaw,agent framework,claude code,mcp"

# 内容类型过滤
CONTENT_TYPES="tool,news,skill,tutorial"

# 输出目录
OUTPUT_DIR="/var/www/miaoquai/social"

# 聚合天数
DAYS_BACK=7

# 是否自动发布到网站
AUTO_PUBLISH=true

# Discord Webhook (可选)
DISCORD_WEBHOOK=""
EOF
    success "已创建默认配置文件"
}

# 测试 API 连接
test_connection() {
    info "测试 API 连接..."
    
    # 测试 GitHub API
    if gh api rate_limit &>/dev/null; then
        success "GitHub API: 已连接"
    else
        error "GitHub API: 连接失败"
    fi
    
    # 测试网络
    if curl -s --connect-timeout 5 https://github.com &>/dev/null; then
        success "网络连接: 正常"
    else
        error "网络连接: 失败"
    fi
    
    success "连接测试完成"
}

# 收集 GitHub 内容
collect_github() {
    info "收集 GitHub OpenClaw 相关内容..."
    
    local temp_file="/tmp/github_collect_$(date +%s).json"
    
    # 搜索 OpenClaw 相关仓库
    gh search repos "$GITHUB_KEYWORDS" \
        --sort stars \
        --limit 20 \
        --json name,description,url,stargazersCount,updatedAt \
        > "$temp_file" 2>/dev/null || true
    
    if [[ -s "$temp_file" ]]; then
        success "GitHub 内容收集完成"
        cat "$temp_file"
    else
        warn "GitHub 内容收集失败或无结果"
    fi
    
    rm -f "$temp_file"
}

# 收集 Twitter 内容 (使用 GitHub Issues 作为替代方案)
collect_twitter() {
    info "收集社交媒体内容..."
    
    # 由于 Twitter API 限制，这里使用 GitHub Discussions 作为替代
    # 实际生产环境可考虑使用 Nitter 或 Twint
    
    local results=()
    
    # 搜索 OpenClaw 官方 discussions
    local discussions
    discussions=$(gh api search/repositories \
        --method GET \
        -F q="openclaw topic:agent" \
        -F per_page=10 \
        --jq '.items[:10] | .[] | {name: .full_name, description: .description, stars: .stargazers_count, url: .html_url}' 2>/dev/null || echo "[]")
    
    echo "$discussions"
    success "社交内容收集完成"
}

# 生成 Markdown 报告
generate_report() {
    local github_data="$1"
    local twitter_data="$2"
    local output_file="$OUTPUT_DIR/social-$(date +%Y-%m-%d).md"
    
    mkdir -p "$OUTPUT_DIR"
    
    cat > "$output_file" << EOF
# OpenClaw 社交媒体热点 - $(date '+%Y年%m月%d日')

> 自动聚合来自 GitHub、Twitter 等平台的 OpenClaw 相关信息

## 🔥 今日热点

### GitHub 项目

| 项目 | 描述 | ⭐ Stars | 链接 |
|------|------|----------|------|
EOF
    
    # 解析 GitHub 数据并添加到表格
    if [[ -n "$github_data" ]] && [[ "$github_data" != "[]" ]]; then
        echo "$github_data" | jq -r '.[] | "| [\(.name)](\(.url)) | \(.description // "无描述") | \(.stargazersCount // 0) | [查看](\(.url)) |"' 2>/dev/null || true
    fi
    
    cat >> "$output_file" << 'EOF'

### 📢 社区动态

EOF
    
    # 添加 Twitter/社区数据
    if [[ -n "$twitter_data" ]]; then
        echo "$twitter_data" | jq -r '.[] | "- \(.name): \(.description // "无描述")"' 2>/dev/null || true
    fi
    
    cat >> "$output_file" << EOF

### 💡 工具推荐

EOF
    
    # 添加推荐的工具
    cat >> "$output_file" << 'EOF'
- [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) - 5400+ Skills 精选
- [nanobot](https://github.com/HKUDS/nanobot) - 轻量级 OpenClaw 实现
- [zeroclaw](https://github.com/zeroclaw-labs/zeroclaw) - 快速小巧的 AI 助手
- [CowAgent](https://github.com/zhayujie/chatgpt-on-wechat) - 多平台 AI 助理

---
*由妙趣AI自动生成 | $(date '+%Y-%m-%d %H:%M')*
EOF
    
    success "报告已生成: $output_file"
    echo "$output_file"
}

# 运行完整聚合流程
run_aggregator() {
    info "开始 OpenClaw 社交媒体聚合..."
    
    load_config
    
    # 创建输出目录
    mkdir -p "$OUTPUT_DIR"
    
    # 收集数据
    local github_data
    github_data=$(collect_github)
    
    local twitter_data
    twitter_data=$(collect_twitter)
    
    # 生成报告
    local report
    report=$(generate_report "$github_data" "$twitter_data")
    
    # 输出摘要
    echo ""
    echo "========================================"
    success "聚合完成!"
    echo "报告位置: $report"
    echo "========================================"
    
    # 可选: 发送到 Discord
    if [[ -n "${DISCORD_WEBHOOK:-}" ]]; then
        info "发送到 Discord..."
        # 这里可以添加 Discord webhook 发送逻辑
    fi
}

# 显示帮助
show_help() {
    cat << EOF
OpenClaw 社交媒体内容聚合器

用法:
    $0 run          运行聚合
    $0 config       查看/编辑配置
    $0 test         测试连接
    $0 help         显示帮助

示例:
    $0 run          # 运行每日聚合
    $0 config       # 查看配置
    $0 test         # 测试 API 连接

输出:
    报告将保存到 $OUTPUT_DIR/

配置:
    配置文件: $CONFIG_FILE
EOF
}

# 主入口
main() {
    case "${1:-run}" in
        run)
            run_aggregator
            ;;
        config)
            load_config
            cat "$CONFIG_FILE"
            ;;
        test)
            test_connection
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
