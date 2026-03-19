#!/bin/bash
# Miaoquai Daily Report Generator
# 自动生成妙趣AI每日运营报告

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
REPORT_DIR="${REPORT_DIR:-/var/www/miaoquai/reports}"
SITE_URL="${SITE_URL:-https://miaoquai.com}"
DATE=$(date '+%Y-%m-%d')
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$REPORT_DIR"

# 生成报告
generate_report() {
    local report_file="$REPORT_DIR/daily-$DATE.md"
    
    echo "# 🦞 妙趣AI 每日运营报告" > "$report_file"
    echo "" >> "$report_file"
    echo "**生成时间**: $DATETIME" >> "$report_file"
    echo "**报告日期**: $DATE" >> "$report_file"
    echo "" >> "$report_file"
    
    # 1. 网站内容统计
    echo "## 📊 网站内容统计" >> "$report_file"
    echo "" >> "$report_file"
    
    local news_count=$(find /var/www/miaoquai/news -name "*.html" 2>/dev/null | wc -l || echo 0)
    local tools_count=$(find /var/www/miaoquai/tools -name "*.html" 2>/dev/null | wc -l || echo 0)
    local glossary_count=$(find /var/www/miaoquai/glossary -name "*.html" 2>/dev/null | wc -l || echo 0)
    local stories_count=$(find /var/www/miaoquai/stories -name "*.html" 2>/dev/null | wc -l || echo 0)
    local total_pages=$(find /var/www/miaoquai -name "*.html" 2>/dev/null | wc -l || echo 0)
    
    echo "| 类型 | 数量 |" >> "$report_file"
    echo "|------|------|" >> "$report_file"
    echo "| 新闻日报 | $news_count |" >> "$report_file"
    echo "| 工具页面 | $tools_count |" >> "$report_file"
    echo "| 术语百科 | $glossary_count |" >> "$report_file"
    echo "| 踩坑实录 | $stories_count |" >> "$report_file"
    echo "| **总计** | **$total_pages** |" >> "$report_file"
    echo "" >> "$report_file"
    
    # 2. GitHub Trending
    echo "## 🔥 GitHub Trending (OpenClaw相关)" >> "$report_file"
    echo "" >> "$report_file"
    
    gh search repos "openclaw" --sort stars --limit 5 --json fullName,description,stargazersCount,url 2>/dev/null | \
        jq -r '.[] | "- [\(.fullName)](\(.url)) ⭐\(.stargazersCount) - \(.description // "无描述")"' >> "$report_file" 2>/dev/null || \
        echo "- 暂无数据" >> "$report_file"
    
    echo "" >> "$report_file"
    
    # 3. AI Agent Trending
    echo "## 🤖 AI Agent 热门项目" >> "$report_file"
    echo "" >> "$report_file"
    
    curl -s "https://api.github.com/search/repositories?q=ai-agent+OR+llm+agent&sort=stars&order=desc&per_page=5" \
        -H "Accept: application/vnd.github.v3+json" 2>/dev/null | \
        jq -r '.items[] | "- [\(.full_name)](\(.html_url)) ⭐\(.stargazers_count) - \(.description // "无描述")"' >> "$report_file" 2>/dev/null || \
        echo "- 暂无数据" >> "$report_file"
    
    echo "" >> "$report_file"
    
    # 4. OpenClaw Skills 发现
    echo "## 🛠️ 最新 OpenClaw Skills" >> "$report_file"
    echo "" >> "$report_file"
    
    gh search repos "openclaw-skill OR openclaw skill" --sort updated --limit 5 --json fullName,description,updatedAt,url 2>/dev/null | \
        jq -r '.[] | "- [\(.fullName)](\(.url)) - \(.description // "无描述")"' >> "$report_file" 2>/dev/null || \
        echo "- 暂无数据" >> "$report_file"
    
    echo "" >> "$report_file"
    
    # 5. 网站健康检查
    echo "## 🏥 网站健康检查" >> "$report_file"
    echo "" >> "$report_file"
    
    local http_status=$(curl -s -o /dev/null -w "%{http_code}" "$SITE_URL" 2>/dev/null || echo "000")
    local response_time=$(curl -s -o /dev/null -w "%{time_total}" "$SITE_URL" 2>/dev/null || echo "0")
    
    if [ "$http_status" = "200" ]; then
        echo "- ✅ 网站状态: 正常 (HTTP $http_status)" >> "$report_file"
    else
        echo "- ❌ 网站状态: 异常 (HTTP $http_status)" >> "$report_file"
    fi
    
    echo "- ⏱️ 响应时间: ${response_time}s" >> "$report_file"
    echo "" >> "$report_file"
    
    # 6. 今日待办
    echo "## 📝 今日任务提醒" >> "$report_file"
    echo "" >> "$report_file"
    echo "- [ ] 生成AI新闻日报" >> "$report_file"
    echo "- [ ] 更新术语百科" >> "$report_file"
    echo "- [ ] 创作踩坑实录" >> "$report_file"
    echo "- [ ] GitHub Discussions 互动" >> "$report_file"
    echo "- [ ] Discord 社区分享" >> "$report_file"
    echo "" >> "$report_file"
    
    # 7. 相关链接
    echo "## 🔗 相关链接" >> "$report_file"
    echo "" >> "$report_file"
    echo "- [妙趣AI官网](https://miaoquai.com)" >> "$report_file"
    echo "- [OpenClaw官网](https://openclaw.ai)" >> "$report_file"
    echo "- [GitHub仓库](https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools)" >> "$report_file"
    echo "" >> "$report_file"
    
    echo "---" >> "$report_file"
    echo "" >> "$report_file"
    echo "_🦞 报告由妙趣AI自动生成_ | [miaoquai.com](https://miaoquai.com)" >> "$report_file"
    
    echo "$report_file"
}

# 主函数
main() {
    echo -e "${CYAN}🦞 妙趣AI 每日报告生成器${NC}"
    echo -e "${YELLOW}生成日期: $DATE${NC}"
    echo ""
    
    # 检查依赖
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}错误: 需要安装 gh (GitHub CLI)${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}错误: 需要安装 jq${NC}"
        exit 1
    fi
    
    # 生成报告
    local report_file=$(generate_report)
    
    if [ -f "$report_file" ]; then
        echo -e "${GREEN}✅ 报告已生成: $report_file${NC}"
        echo ""
        echo -e "${BLUE}报告预览:${NC}"
        echo "----------------------------------------"
        head -50 "$report_file"
        echo "----------------------------------------"
        echo ""
        echo -e "${PURPLE}完整报告: $report_file${NC}"
    else
        echo -e "${RED}❌ 报告生成失败${NC}"
        exit 1
    fi
}

main "$@"
