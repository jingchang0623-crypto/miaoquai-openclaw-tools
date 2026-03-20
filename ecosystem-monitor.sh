#!/bin/bash
# ============================================================================
# OpenClaw Skills 生态系统监控工具
# 监控与OpenClaw相关的项目和Skills市场动态
# ============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
LIB_DIR="${SCRIPT_DIR}/lib"
OUTPUT_DIR="${SCRIPT_DIR:-/tmp}/ecosystem-reports"

# 加载库函数
source "${LIB_DIR}/logger.sh" 2>/dev/null || true

# 默认配置
MONITORED_PROJECTS=(
    "volcengine/OpenViking"
    "obra/superpowers"
    "langchain-ai/open-swe"
    "langchain-ai/deepagents"
    "shareAI-lab/learn-claude-code"
    "jarrodwatts/claude-hud"
    "affaan-m/everything-claude-code"
)

# 输出文件
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
REPORT_FILE="${OUTPUT_DIR}/ecosystem-report-${TIMESTAMP}.md"
JSON_FILE="${OUTPUT_DIR}/ecosystem-data-${TIMESTAMP}.json"

# 创建输出目录
mkdir -p "${OUTPUT_DIR}"

echo -e "${CYAN}🦞 OpenClaw Skills 生态系统监控${NC}"
echo "========================================"
echo ""

# 函数：获取GitHub项目信息
get_repo_info() {
    local repo=$1
    local info
    
    echo -e "${BLUE}📡 正在获取 ${repo} 信息...${NC}"
    
    # 获取项目详细信息
    info=$(gh repo view "$repo" --json name,description,stargazerCount,forkCount,updatedAt,primaryLanguage,url,openIssuesCount,watchers 2>/dev/null || echo "{}")
    
    echo "$info"
}

# 函数：获取项目最近提交
get_recent_commits() {
    local repo=$1
    local commits
    
    commits=$(gh api "repos/${repo}/commits?per_page=5" --jq '.[0:5] | map({message: .commit.message, date: .commit.author.date, author: .commit.author.name})' 2>/dev/null || echo "[]")
    
    echo "$commits"
}

# 函数：获取项目最近Issues
get_recent_issues() {
    local repo=$1
    local issues
    
    issues=$(gh api "repos/${repo}/issues?state=open&sort=updated&per_page=5" --jq '.[0:5] | map({title: .title, number: .number, updated_at: .updated_at, labels: [.labels[].name]})' 2>/dev/null || echo "[]")
    
    echo "$issues"
}

# 函数：检测Skills相关性
detect_skills_relevance() {
    local repo=$1
    local description=$2
    local relevance_score=0
    local reasons=()
    
    # 检查关键词
    if [[ "$description" =~ [Ss]kill ]]; then
        ((relevance_score+=2))
        reasons+=("包含 'skills' 关键词")
    fi
    
    if [[ "$description" =~ [Aa]gent ]]; then
        ((relevance_score+=2))
        reasons+=("包含 'agent' 关键词")
    fi
    
    if [[ "$repo" =~ [Oo]pen[Vv]iking ]]; then
        ((relevance_score+=5))
        reasons+=("专为OpenClaw设计的上下文数据库")
    fi
    
    if [[ "$repo" =~ [Ss]uperpower ]]; then
        ((relevance_score+=4))
        reasons+=("Skills框架和方法论")
    fi
    
    if [[ "$description" =~ [Ww]orkflow ]]; then
        ((relevance_score+=1))
        reasons+=("包含 'workflow' 关键词")
    fi
    
    echo "${relevance_score}|${reasons[*]}"
}

# 主监控循环
echo -e "${YELLOW}📊 开始监控生态系统...${NC}"
echo ""

# 初始化JSON数组
all_repos_json="[]"
total_stars=0
total_forks=0
total_issues=0
high_priority_projects=()

# 创建报告文件头部
cat > "${REPORT_FILE}" << EOF
# OpenClaw Skills 生态系统监控报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')

---

## 📊 项目概览

| 项目 | Stars | Forks | Issues | 语言 | 相关度 |
|------|-------|-------|--------|------|--------|
EOF

# 遍历监控的项目
for repo in "${MONITORED_PROJECTS[@]}"; do
    echo -e "${GREEN}✓${NC} 处理: ${repo}"
    
    # 获取项目信息
    repo_info=$(get_repo_info "$repo")
    
    if [[ "$repo_info" != "{}" ]]; then
        # 解析JSON
        name=$(echo "$repo_info" | jq -r '.name // "N/A"')
        description=$(echo "$repo_info" | jq -r '.description // "无描述"')
        stars=$(echo "$repo_info" | jq -r '.stargazerCount // 0')
        forks=$(echo "$repo_info" | jq -r '.forkCount // 0')
        issues=$(echo "$repo_info" | jq -r '.openIssuesCount // 0')
        language=$(echo "$repo_info" | jq -r '.primaryLanguage.name // "N/A"')
        url=$(echo "$repo_info" | jq -r '.url // ""')
        updated=$(echo "$repo_info" | jq -r '.updatedAt // ""')
        
        # 检测相关性
        relevance_info=$(detect_skills_relevance "$repo" "$description")
        relevance_score=$(echo "$relevance_info" | cut -d'|' -f1)
        relevance_reasons=$(echo "$relevance_info" | cut -d'|' -f2)
        
        # 累计统计
        ((total_stars+=stars))
        ((total_forks+=forks))
        ((total_issues+=issues))
        
        # 高相关性项目
        if [[ $relevance_score -ge 4 ]]; then
            high_priority_projects+=("$repo (相关度: $relevance_score)")
        fi
        
        # 获取最近提交
        recent_commits=$(get_recent_commits "$repo")
        
        # 获取最近Issues
        recent_issues=$(get_recent_issues "$repo")
        
        # 构建项目JSON
        project_json=$(cat << EOF
{
  "repo": "$repo",
  "name": "$name",
  "description": "$description",
  "stars": $stars,
  "forks": $forks,
  "issues": $issues,
  "language": "$language",
  "url": "$url",
  "updated": "$updated",
  "relevance_score": $relevance_score,
  "relevance_reasons": "$relevance_reasons",
  "recent_commits": $recent_commits,
  "recent_issues": $recent_issues
}
EOF
)
        
        # 添加到JSON数组
        all_repos_json=$(echo "$all_repos_json" | jq --argjson project "$project_json" '. + [$project]')
        
        # 添加到报告表格
        printf "| [%s](%s) | %s | %s | %s | %s | %d/10 |\n" \
            "$name" "$url" "$stars" "$forks" "$issues" "$language" "$relevance_score" >> "${REPORT_FILE}"
        
        echo -e "  └─ Stars: ${YELLOW}${stars}${NC}, Forks: ${YELLOW}${forks}${NC}, 相关度: ${PURPLE}${relevance_score}/10${NC}"
    fi
done

# 添加统计信息到报告
cat >> "${REPORT_FILE}" << EOF

---

## 📈 统计汇总

- **总Stars**: $(printf "%'d" $total_stars)
- **总Forks**: $(printf "%'d" $total_forks)
- **总Open Issues**: $total_issues
- **监控项目数**: ${#MONITORED_PROJECTS[@]}

---

## 🔥 高优先级项目

EOF

for project in "${high_priority_projects[@]}"; do
    echo "- $project" >> "${REPORT_FILE}"
done

# 添加机会分析
cat >> "${REPORT_FILE}" << EOF

---

## 💡 发现的机会

### OpenViking 集成机会
- **机会**: 创建OpenClaw Skills来集成OpenViking上下文数据库
- **价值**: 让OpenClaw Agent拥有持久化的上下文管理能力
- **难度**: 中等（需要Python环境配置）

### Superpowers Skills 迁移
- **机会**: 将Superpowers的TDD、调试等Skills迁移到OpenClaw
- **价值**: 为OpenClaw带来成熟的开发工作流
- **难度**: 低（Skills概念兼容）

### Claude HUD 监控功能
- **机会**: 创建类似的OpenClaw监控工具，显示context usage、运行状态
- **价值**: 提升OpenClaw开发体验
- **难度**: 中等

---

## 🎯 下一步行动建议

1. **优先级1**: 为OpenViking创建OpenClaw Skill包装器
2. **优先级2**: 研究Superpowers Skills结构，考虑迁移
3. **优先级3**: 开发OpenClaw状态监控工具（类似claude-hud）
4. **优先级4**: 为妙趣AI创建自定义Skills集

---

## 🔗 相关资源

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [ClawHub Skills市场](https://clawhub.ai)
- [妙趣AI网站](https://miaoquai.com)

---

*🦞 由妙趣AI自动生成*
EOF

# 保存JSON数据
echo "$all_repos_json" | jq '.' > "${JSON_FILE}"

echo ""
echo -e "${GREEN}✅ 监控完成！${NC}"
echo ""
echo -e "${CYAN}📊 报告已保存到:${NC}"
echo "  - Markdown: ${REPORT_FILE}"
echo "  - JSON: ${JSON_FILE}"
echo ""
echo -e "${PURPLE}🔥 发现 ${#high_priority_projects[@]} 个高优先级项目${NC}"

# 显示简要总结
echo ""
echo -e "${YELLOW}📊 生态概览:${NC}"
echo "  总Stars: $(printf "%'d" $total_stars)"
echo "  总Forks: $(printf "%'d" $total_forks)"
echo "  总Issues: $total_issues"

# 返回报告路径
echo ""
echo "${REPORT_FILE}"
