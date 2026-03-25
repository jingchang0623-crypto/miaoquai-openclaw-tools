#!/bin/bash
#
# OpenClaw Skill - GitHub Trending Monitor
# 监控 GitHub Trending 上的 OpenClaw 相关项目并生成报告
#

set -e

REPORT_DIR="/var/www/miaoquai/reports"
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="${REPORT_DIR}/trending-${DATE}.md"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 搜索 OpenClaw 相关 trending 项目
search_openclaw_trending() {
    log_info "搜索 OpenClaw 相关 trending 项目..."
    
    # 最近7天创建的热门项目
    curl -s "https://api.github.com/search/repositories?q=openclaw+created:>$(date -d '7 days ago' +%Y-%m-%d)&sort=stars&order=desc&per_page=10" | \
        jq -r '.items[] | "|\(.full_name)|\(.stargazers_count)|\(.description)|"'
}

# 搜索 Skills 相关项目
search_skills_trending() {
    log_info "搜索 OpenClaw Skills 相关项目..."
    
    gh search repos "openclaw skills" --limit 5 --json name,url,description,stargazersCount | \
        jq -r '.[] | "|\(.name)|\(.stargazersCount)|\(.description)|"'
}

# 生成报告
generate_report() {
    mkdir -p "${REPORT_DIR}"
    
    cat > "${OUTPUT_FILE}" << EOF
---
title: GitHub Trending 监控报告
date: ${DATE}
category: OpenClaw
---

# 🦞 GitHub Trending 监控报告

**生成时间**: $(date "+%Y-%m-%d %H:%M:%S")

## 🔥 OpenClaw 热门项目

| 项目 | ⭐ Stars | 描述 |
|------|----------|------|
EOF

    # 添加搜索结果
    curl -s "https://api.github.com/search/repositories?q=openclaw+created:>2025-12-01&sort=stars&order=desc&per_page=10" | \
        jq -r '.items[] | "|[\(.full_name)](\(.html_url))|\(.stargazers_count)|\(.description // "无")|"' >> "${OUTPUT_FILE}"
    
    cat >> "${OUTPUT_FILE}" << EOF

## 🛠️ OpenClaw Skills 热门项目

| 项目 | ⭐ Stars | 描述 |
|------|----------|------|
EOF

    gh search repos "openclaw skills" --limit 5 --json name,url,description,stargazersCount | \
        jq -r '.[] | "|[\(.name)](\(.url))|\(.stargazersCount)|\(.description // "无")|"' >> "${OUTPUT_FILE}"
    
    cat >> "${OUTPUT_FILE}" << EOF

## 📊 趋势分析

- **推荐关注**: $(curl -s "https://api.github.com/repos/VoltAgent/awesome-openclaw-skills" | jq -r '.stargazers_count // 0') ⭐ awesome-openclaw-skills
- **轻量选择**: $(curl -s "https://api.github.com/repos/HKUDS/nanobot" | jq -r '.stargazers_count // 0') ⭐ nanobot
- **多Agent编排**: $(curl -s "https://api.github.com/repos/cft0808/edict" | jq -r '.stargazers_count // 0') ⭐ edict

---
*由妙趣AI自动生成 | [miaoquai.com](https://miaoquai.com)*
EOF

    log_info "报告已生成: ${OUTPUT_FILE}"
}

# 主程序
main() {
    log_info "开始 GitHub Trending 监控..."
    
    generate_report
    
    log_info "完成！"
}

main "$@"