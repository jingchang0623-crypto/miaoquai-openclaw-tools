#!/bin/bash
#
# trending-skill-generator.sh
# 根据 GitHub Trending 自动生成 OpenClaw Skills
# 
# 用法: ./trending-skill-generator.sh [--dry-run] [--category AI]
# 
# 输出: 生成的 Skills 保存在 ./generated-skills/
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/generated-skills"
GITHUB_API="https://api.github.com"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# 解析参数
DRY_RUN=false
CATEGORY=""
MAX_ITEMS=5

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --max)
            MAX_ITEMS="$2"
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 获取 GitHub Trending AI 项目
fetch_trending_projects() {
    log_info "正在获取 GitHub Trending AI 项目..."
    
    # 使用 gh CLI (已认证，有更高 rate limit)
    local result
    if command -v gh &> /dev/null; then
        result=$(gh api "search/repositories?q=AI+OR+machine+learning+OR+llm&sort=stars&order=desc&per_page=20" \
            -q '.items[:20] | .[] | "\(.full_name)|\(.description // "无描述")|\(.stargazers_count)|\(.html_url)"' 2>/dev/null) || true
    fi
    
    # Fallback to curl if gh fails
    if [ -z "$result" ]; then
        local query="AI+OR+machine+learning+OR+llm"
        result=$(curl -s \
            -H "Accept: application/vnd.github.v3+json" \
            "${GITHUB_API}/search/repositories?q=${query}&sort=stars&order=desc&per_page=20" | \
            jq -r '.items[:20] | .[] | "\(.full_name)|\(.description // "无描述")|\(.stargazers_count)|\(.html_url)"' 2>/dev/null) || true
    fi
    
    if [ -z "$result" ]; then
        log_error "无法获取 Trending 项目"
        exit 1
    fi
    
    echo "$result"
}

# 生成 Skill 模板
generate_skill() {
    local repo_name="$1"
    local description="$2"
    local stars="$3"
    local url="$4"
    local category="${5:-research}"
    
    # 将 repo name 转为 kebab-case 作为 skill 名称
    local skill_name=$(echo "$repo_name" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    
    cat > "${OUTPUT_DIR}/${skill_name}.md" << EOF
# ${repo_name}

> ${description}

## Skill 信息

- **名称**: ${skill_name}
- **类型**: OpenClaw Skill 模板
- **分类**: ${category}
- **数据来源**: GitHub Trending
- **原始项目**: ${repo_name}
- **Stars**: ${stars}
- **URL**: ${url}

## 描述

根据 GitHub Trending 自动生成的 Skill 模板，帮助 OpenClaw 用户快速了解和使用 ${repo_name} 项目。

## 使用场景

1. **项目调研**: 了解 ${repo_name} 的功能和用途
2. **技术选型**: 对比同类开源项目
3. **学习参考**: 研究优秀的开源实现
4. **集成开发**: 将项目功能集成到自己的工作流

## 前置要求

- OpenClaw 环境已配置
- 网络访问能力（访问 GitHub）

## 使用方法

\`\`\`markdown
请帮我分析 ${repo_name} 这个项目，介绍它的主要功能和使用方法。
\`\`\`

## 相关信息

- 🔗 [项目主页](${url})
- 📖 [Star 历史](${url}/stargazers)
- 🍴 [源码](${url})

---

*此 Skill 由 妙趣AI 自动生成 | miaoquai.com*
EOF

    log_info "✓ 已生成 Skill: ${skill_name}"
    echo "$skill_name"
}

# 生成 README
generate_readme() {
    cat > "${OUTPUT_DIR}/README.md" << EOF
# Generated OpenClaw Skills

> 根据 GitHub Trending 自动生成的 OpenClaw Skills

## 生成时间

$(date "+%Y-%m-%d %H:%M:%S")

## 生成的 Skills

| Skill 名称 | 描述 | Stars |
|------------|------|-------|
EOF

    for skill_file in "${OUTPUT_DIR}"/*.md; do
        if [[ "$(basename "$skill_file")" != "README.md" ]]; then
            local name=$(basename "$skill_file" .md)
            local desc=$(grep "^> " "$skill_file" | head -1 | sed 's/^> //')
            local stars=$(grep -E "^\- \*\*Stars\*\*:" "$skill_file" | awk '{print $3}')
            echo "| [${name}](./${name}.md) | ${desc:0:50}... | ${stars:-N/A} |" >> "${OUTPUT_DIR}/README.md"
        fi
    done

    echo "" >> "${OUTPUT_DIR}/README.md"
    echo "---" >> "${OUTPUT_DIR}/README.md"
    echo "*由 妙趣AI 自动生成 | [miaoquai.com](https://miaoquai.com)*" >> "${OUTPUT_DIR}/README.md"
}

# 主函数
main() {
    echo -e "${GREEN}🤖 Trending Skill Generator 启动${NC}" >&2
    echo -e "${GREEN}📅 执行时间: $(date)${NC}" >&2
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}⚠️ Dry Run 模式 - 不会生成实际文件${NC}" >&2
    fi
    
    # 获取 trending 项目
    local projects
    projects=$(fetch_trending_projects)
    
    if [ -z "$projects" ]; then
        log_error "无法获取 Trending 项目"
        exit 1
    fi
    
    local count=0
    local generated=()
    
    while IFS='|' read -r name desc stars url; do
        [ -z "$name" ] && continue
        
        # 过滤类别
        if [ -n "$CATEGORY" ]; then
            case "$name" in
                *"$CATEGORY"*) ;;
                *) continue ;;
            esac
        fi
        
        # 确定分类
        local category="research"
        case "$name" in
            *skill*) category="development" ;;
            *code*|*dev*|*tool*) category="development" ;;
            *seo*|*marketing*) category="marketing" ;;
            *ai*|*llm*|*model*) category="research" ;;
        esac
        
        if [ "$DRY_RUN" = false ]; then
            local skill
            skill=$(generate_skill "$name" "$desc" "$stars" "$url" "$category")
            generated+=("$skill")
        else
            echo -e "  → ${GREEN}$name${NC} (${stars} ⭐)" >&2
        fi
        
        ((count++)) || true
        [ $count -ge $MAX_ITEMS ] && break
        
    done <<< "$projects"
    
    if [ "$DRY_RUN" = false ]; then
        generate_readme
        log_info "✅ 完成! 生成了 $count 个 Skills"
        log_info "📁 输出目录: $OUTPUT_DIR"
    else
        log_info "✅ Dry Run 完成! 可以移除 --dry-run 来实际生成"
    fi
}

main
