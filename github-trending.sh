#!/bin/bash
# GitHub Trending 监控脚本
# 自动追踪 OpenClaw 相关的热门项目

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志文件
LOG_DIR="${LOG_DIR:-/var/log/miaoquai}"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/trending-$(date +%Y-%m-%d).log"

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "${BLUE}🦞 GitHub Trending 监控启动${NC}"
log "${YELLOW}追踪关键词: openclaw, ai-agent, skills${NC}"

# 搜索 OpenClaw 相关项目
search_openclaw() {
    log "\n${GREEN}=== OpenClaw 核心项目 ===${NC}"
    gh search repos "openclaw" --sort stars --limit 5 --json fullName,description,stargazersCount,url 2>/dev/null | \
        jq -r '.[] | "⭐ \(.stargazersCount) - \(.fullName): \(.description)"' | \
        while read line; do log "$line"; done

    log "\n${GREEN}=== OpenClaw Skills 项目 ===${NC}"
    gh search repos "openclaw skill" --sort stars --limit 5 --json fullName,description,stargazersCount,url 2>/dev/null | \
        jq -r '.[] | "⭐ \(.stargazersCount) - \(.fullName): \(.description)"' | \
        while read line; do log "$line"; done

    log "\n${GREEN}=== AI Agent 相关项目 ===${NC}"
    gh search repos "ai-agent" --sort stars --limit 5 --json fullName,description,stargazersCount,url 2>/dev/null | \
        jq -r '.[] | "⭐ \(.stargazersCount) - \(.fullName): \(.description)"' | \
        while read line; do log "$line"; done
}

# 检查是否安装了必要的工具
check_dependencies() {
    if ! command -v gh &> /dev/null; then
        log "${RED}错误: gh (GitHub CLI) 未安装${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log "${RED}错误: jq 未安装${NC}"
        exit 1
    fi
}

# 主函数
main() {
    check_dependencies
    
    # 检查 GitHub 登录状态
    if ! gh auth status &> /dev/null; then
        log "${RED}错误: 未登录 GitHub${NC}"
        log "请运行: gh auth login"
        exit 1
    fi
    
    search_openclaw
    
    log "\n${GREEN}✅ 监控完成${NC}"
    log "日志文件: $LOG_FILE"
}

main "$@"
