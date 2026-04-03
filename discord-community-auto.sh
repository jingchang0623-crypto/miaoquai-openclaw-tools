#!/bin/bash
#
# Discord Community Automation Tool
# Discord 社区运营自动化脚本
#
# 功能：自动发送消息、热点追踪、社区互动
# 作者：妙趣AI (miaoquai.com)
# 版本：1.0.0
#

set -euo pipefail

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
LOG_DIR="${SCRIPT_DIR}/logs"
REPORTS_DIR="/var/www/miaoquai/discord"

# Discord 配置（从环境变量读取，安全考虑）
DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID:-1483699648890802201}"

# 颜色定义
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

# 初始化目录
init_dirs() {
    mkdir -p "$LOG_DIR" "$REPORTS_DIR" "${SCRIPT_DIR}/templates"
}

# 检查依赖
check_deps() {
    local deps=("curl" "jq" "date")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "缺少依赖: $dep"
            exit 1
        fi
    done
    
    if [[ -z "$DISCORD_BOT_TOKEN" ]]; then
        log_warn "未设置 DISCORD_BOT_TOKEN 环境变量"
        log_info "请设置: export DISCORD_BOT_TOKEN='your_token_here'"
    fi
}

# 发送 Discord 消息
send_message() {
    local content="$1"
    local channel_id="${2:-$DISCORD_CHANNEL_ID}"
    
    if [[ -z "$DISCORD_BOT_TOKEN" ]]; then
        log_error "Discord Bot Token 未设置，无法发送消息"
        return 1
    fi
    
    local response
    response=$(curl -s -X POST \
        "https://discord.com/api/v10/channels/${channel_id}/messages" \
        -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"${content//\"/\\\"}\"}" 2>&1)
    
    if echo "$response" | jq -e '.id' &>/dev/null; then
        log_success "消息发送成功"
        echo "$response" | jq -r '.id'
        return 0
    else
        log_error "消息发送失败: $response"
        return 1
    fi
}

# 获取今日 AI 热点话题
get_trending_topics() {
    log_info "正在获取今日 AI 热点..."
    
    # 模拟热点数据（实际使用时可接入 RSS 或搜索 API）
    cat << 'EOF'
🔥 今日 AI 热点

1️⃣ **OpenClaw 新动态**
   - GitHub trending 发现 560+ 优秀 Skills
   - 社区活跃度持续上升

2️⃣ **AI 工具推荐**
   - RSS 聚合自动化成为热门需求
   - Discord 社区运营工具需求增长

3️⃣ **技术趋势**
   - Agent 框架对比成为开发者关注焦点
   - AI 内容生成质量要求提升

来自: miaoquai.com | 妙趣AI
EOF
}

# 生成每日分享内容
generate_daily_share() {
    local date_str=$(date +"%Y-%m-%d")
    local weekday=$(date +"%A")
    
    cat << EOF
🌅 早安！${weekday}的 AI 早报来了 | ${date_str}

$(get_trending_topics)

💡 **今日工具推荐**
OpenClaw Agent Starter Kit - 一键创建标准化 Agent 项目
👉 快速搭建你的 AI Agent: https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools

📝 **每日一问**
你今天用 OpenClaw 解决了什么问题？
欢迎分享你的使用经验！

---
🤖 妙趣AI | 让AI营销变得有趣
🌐 https://miaoquai.com
EOF
}

# 生成踩坑实录分享
generate_troubleshoot_share() {
    cat << 'EOF'
🐛 妙趣踩坑实录 #OpenClaw

**"凌晨4点，我和这个bug对视了一个时辰"**

事情是这样的——昨天我在配置 Discord 自动化时，遇到了一个诡异的问题：

1. Token 明明正确，却返回 401
2. 日志里什么都没显示
3. 重启了 3 次，甚至怀疑人生

**最后发现：**
我把 Bot Token 复制成了 OAuth2 Token 🤦

**教训总结：**
✅ 区分 Bot Token 和 OAuth2 Token
✅ 先用 curl 测试 API 再写脚本
✅ 保持良好的睡眠比debug更重要

你有过类似的经历吗？

---
🤖 妙趣AI | 更多踩坑故事: https://miaoquai.com/stories
EOF
}

# 生成工具推荐
generate_tool_recommendation() {
    cat << 'EOF'
🛠️ OpenClaw 工具推荐

本周发现的神器：**RSS 聚合器**

功能亮点：
✨ 自动抓取多个 AI 源的最新文章
✨ AI 生成摘要，省时省力
✨ 一键发布到网站和邮件
✨ 支持定时任务

适用场景：
- 运营 AI 资讯网站
- 维护技术博客
- 团队内容共享

使用方法：
\`\`\`bash
./ai-news-rss-fetcher.sh
\`\`\`

源码地址：
https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools

---
🦞 由妙趣AI整理 | miaoquai.com
EOF
}

# 发布每日早报
post_daily_news() {
    log_info "正在生成每日早报..."
    local content=$(generate_daily_share)
    
    if send_message "$content"; then
        log_success "每日早报发布成功"
        save_report "daily" "$content"
    fi
}

# 发布踩坑实录
post_troubleshoot() {
    log_info "正在生成踩坑实录..."
    local content=$(generate_troubleshoot_share)
    
    if send_message "$content"; then
        log_success "踩坑实录发布成功"
        save_report "troubleshoot" "$content"
    fi
}

# 发布工具推荐
post_tool_rec() {
    log_info "正在生成工具推荐..."
    local content=$(generate_tool_recommendation)
    
    if send_message "$content"; then
        log_success "工具推荐发布成功"
        save_report "tool" "$content"
    fi
}

# 保存发布记录
save_report() {
    local type="$1"
    local content="$2"
    local date_str=$(date +"%Y-%m-%d")
    local time_str=$(date +"%H%M%S")
    local filename="discord-${type}-${date_str}-${time_str}.md"
    
    cat > "${REPORTS_DIR}/${filename}" << EOF
---
type: discord_${type}
date: ${date_str}
time: ${time_str}
channel: ${DISCORD_CHANNEL_ID}
---

${content}
EOF
    
    log_info "报告已保存: ${REPORTS_DIR}/${filename}"
}

# 查看发布历史
show_history() {
    log_info "Discord 发布历史:"
    
    if [[ ! -d "$REPORTS_DIR" ]] || [[ -z "$(ls -A "$REPORTS_DIR" 2>/dev/null)" ]]; then
        log_warn "暂无发布记录"
        return
    fi
    
    ls -lt "$REPORTS_DIR"/*.md 2>/dev/null | head -20 | while read -r line; do
        echo "$line"
    done
}

# 测试模式
test_mode() {
    log_info "测试模式 - 仅显示内容，不发送"
    echo ""
    echo "=== 每日早报预览 ==="
    generate_daily_share
    echo ""
    echo "=== 踩坑实录预览 ==="
    generate_troubleshoot_share
    echo ""
    echo "=== 工具推荐预览 ==="
    generate_tool_recommendation
}

# 帮助信息
show_help() {
    cat << 'EOF'
Discord 社区运营自动化工具

用法:
  ./discord-community-auto.sh [命令] [选项]

命令:
  daily         发布每日早报
  troubleshoot  发布踩坑实录
  tool          发布工具推荐
  test          测试模式（预览内容，不发送）
  history       查看发布历史
  help          显示帮助信息

环境变量:
  DISCORD_BOT_TOKEN    Discord Bot Token (必需)
  DISCORD_CHANNEL_ID   频道ID (默认: 1483699648890802201)

示例:
  # 设置 Token
  export DISCORD_BOT_TOKEN="your_bot_token_here"
  
  # 发布每日早报
  ./discord-community-auto.sh daily
  
  # 发布踩坑实录
  ./discord-community-auto.sh troubleshoot
  
  # 测试预览
  ./discord-community-auto.sh test

定时任务示例:
  # 每天早上9点发布早报
  0 9 * * * /path/to/discord-community-auto.sh daily
  
  # 每天下午4点发布踩坑故事
  0 16 * * * /path/to/discord-community-auto.sh troubleshoot

作者: 妙趣AI (miaoquai.com)
EOF
}

# 主函数
main() {
    init_dirs
    check_deps
    
    local command="${1:-help}"
    
    case "$command" in
        daily)
            post_daily_news
            ;;
        troubleshoot)
            post_troubleshoot
            ;;
        tool)
            post_tool_rec
            ;;
        test)
            test_mode
            ;;
        history)
            show_history
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
