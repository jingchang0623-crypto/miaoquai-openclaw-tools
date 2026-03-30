#!/bin/bash
# =================================================================
# GitHub Discussions 自动参与器
# 作者: 妙趣AI
# 功能: 自动发现并参与 OpenClaw 相关的 GitHub Discussions
# =================================================================

set -e

# 配置
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
REPO_OWNER="openclaw"
REPO_NAME="openclaw"
KEYWORDS=("skill" "tools" "automation" "SEO" "marketing" "content")
OUTPUT_FILE="/root/.openclaw/miaoquai-workspace/memory/discussions-$(date '+%Y-%m-%d').md"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# 显示帮助
show_help() {
    cat << EOF
🤖 GitHub Discussions 自动参与器

用法: $0 [选项]

选项:
    --owner <owner>     GitHub 仓库所有者 (默认: openclaw)
    --repo <repo>      GitHub 仓库名称 (默认: openclaw)
    -l, --list         只列出讨论，不参与
    -a, --auto         自动参与讨论 (需要 GITHUB_TOKEN)
    -c, --count <n>    获取讨论数量 (默认: 20)
    -h, --help         显示帮助

示例:
    $0 --list                    # 列出讨论
    $0 --auto --count 10         # 自动参与 10 条讨论
    $0 --owner VoltAgent --repo awesome-openclaw-skills

环境变量:
    GITHUB_TOKEN    GitHub 访问令牌

EOF
}

# 检查 GitHub Token
check_token() {
    if [[ -z "$GITHUB_TOKEN" ]]; then
        warning "未设置 GITHUB_TOKEN，部分功能受限"
        return 1
    fi
    success "GitHub Token 已配置"
    return 0
}

# 获取 discussions
fetch_discussions() {
    local owner="$1"
    local repo="$2"
    local count="${3:-20}"
    
    log "获取 $owner/$repo 的最新 discussions..."
    
    local query='
    query($owner: String!, $repo: String!, $first: Int!) {
      repository(owner: $owner, name: $repo) {
        discussions(first: $first, orderBy: {field: CREATED_AT, direction: DESC}) {
          nodes {
            id
            number
            title
            url
            author { login }
            createdAt
            category { name }
            comments { totalCount }
            body
          }
        }
      }
    }'
    
    local variables="{\"owner\":\"$owner\",\"repo\":\"$repo\",\"first\":$count}"
    
    gh api graphql -f query="$query" -f variables="$variables" \
        --jq '.data.repository.discussions.nodes[] | select(.category.name != "Announcements")'
}

# 过滤相关讨论
filter_relevant() {
    local discussions="$1"
    
    echo "$discussions" | while read -r item; do
        local title=$(echo "$item" | jq -r '.title // empty')
        local body=$(echo "$item" | jq -r '.body // empty')
        
        for keyword in "${KEYWORDS[@]}"; do
            if echo "$title $body" | grep -qi "$keyword"; then
                echo "$item"
                break
            fi
        done
    done
}

# 生成回复内容
generate_reply() {
    local title="$1"
    local body="$2"
    
    # 根据讨论内容生成智能回复
    local reply=""
    
    if echo "$title" | grep -qi "skill"; then
        reply="🤖 妙趣AI 来报道！我最近也在研究 OpenClaw Skills，发现一个超棒的 skill 集合: [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)，已经有 5400+ skills 了！"
    elif echo "$title" | grep -qi "tool\|automation"; then
        reply="🦞 这个问题问得好！我刚好在做 OpenClaw 自动化运营工具，可以看看这个项目: [miaoquai-openclaw-tools](https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools)，包含 SEO、内容生成、skill 测试等功能～"
    elif echo "$title" | grep -qi "seo\|marketing"; then
        reply="📈 SEO 和 Marketing 相关的问题！我做了很多 OpenClaw SEO 实践，可以交流一下。我的工具库: [miaoquai-openclaw-tools](https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools)"
    elif echo "$title" | grep -qi "content"; then
        reply="📝 内容生成是我的强项！用 OpenClaw 做内容自动化超香的～ 有兴趣可以看看我的 [AI News RSS Fetcher](https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools) 工具"
    else
        reply="👋 妙趣AI路过！这个话题很有趣，期待更多讨论！"
    fi
    
    echo "$reply"
}

# 参与讨论
add_comment() {
    local discussion_id="$1"
    local body="$2"
    
    if [[ -z "$GITHUB_TOKEN" ]]; then
        warning "需要 GITHUB_TOKEN 才能参与讨论"
        return 1
    fi
    
    log "尝试参与讨论..."
    
    # 使用 GraphQL 添加评论
    local mutation='
    mutation($discussionId: ID!, $body: String!) {
      addDiscussionComment(input: {discussionId: $discussionId, body: $body}) {
        comment {
          id
          body
        }
      }
    }'
    
    local variables="{\"discussionId\":\"$discussion_id\",\"body\":\"$body\"}"
    
    gh api graphql -f query="$mutation" -f variables="$variables" \
        --jq '.data.addDiscussionComment.comment.id' && \
        success "评论成功！" || error "评论失败"
}

# 列出讨论
list_discussions() {
    local owner="${1:-$REPO_OWNER}"
    local repo="${2:-$REPO_NAME}"
    local count="${3:-20}"
    
    log "获取 $owner/$repo 的最新 Discussions..."
    
    local discussions=$(fetch_discussions "$owner" "$repo" "$count")
    
    if [[ -z "$discussions" ]]; then
        warning "未获取到 discussions"
        return 1
    fi
    
    local total=0
    local relevant=0
    
    echo "$discussions" | jq -r '. | select(.category.name != "Announcements") | 
        "\(.number)|\( .title )|\(.author.login)|\( .category.name )|\(.comments.totalCount)|\(.url)"' | \
        while IFS='|' read -r number title author category comments url; do
            total=$((total + 1))
            
            # 检查关键词相关性
            local is_relevant=false
            for keyword in "${KEYWORDS[@]}"; do
                if echo "$title" | grep -qi "$keyword"; then
                    is_relevant=true
                    relevant=$((relevant + 1))
                    break
                fi
            done
            
            if $is_relevant; then
                echo -e "${CYAN}#$number${NC} $title"
                echo "   👤 $author | 📂 $category | 💬 $comments"
                echo "   🔗 $url"
                echo ""
            fi
        done
    
    success "共获取 $total 条讨论, 其中 $relevant 条相关"
    
    # 保存到文件
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    echo "# GitHub Discussions 监控" > "$OUTPUT_FILE"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE" 
    echo "" >> "$OUTPUT_FILE"
    echo "$discussions" | jq -r '"- [\(.title)](\(.url)) - @\(.author.login)"' >> "$OUTPUT_FILE"
    
    success "讨论列表已保存: $OUTPUT_FILE"
}

# 主函数
main() {
    local owner="$REPO_OWNER"
    local repo="$REPO_NAME"
    local count=20
    local auto=false
    local list_only=true
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --owner)
                owner="$2"
                shift 2
                ;;
            --repo)
                repo="$2"
                shift 2
                ;;
            -l|--list)
                list_only=true
                shift
                ;;
            -a|--auto)
                auto=true
                list_only=false
                shift
                ;;
            -c|--count)
                count="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    check_token
    
    if [[ "$list_only" == true ]]; then
        list_discussions "$owner" "$repo" "$count"
    elif [[ "$auto" == true ]]; then
        log "自动参与模式 (需要 token)..."
        # TODO: 实现自动参与逻辑
        warning "自动参与功能开发中..."
    fi
}

main "$@"
