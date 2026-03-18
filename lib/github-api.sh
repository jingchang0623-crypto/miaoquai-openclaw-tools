#!/bin/bash
# GitHub API 封装库

# 搜索仓库
github_search_repos() {
    local query="$1"
    local sort="${2:-stars}"
    local limit="${3:-10}"
    
    gh search repos "$query" --sort "$sort" --limit "$limit" \
        --json fullName,description,stargazersCount,url,updatedAt 2>/dev/null
}

# 获取仓库信息
github_get_repo() {
    local repo="$1"
    gh repo view "$repo" --json name,description,stargazersCount,url 2>/dev/null
}

# 创建仓库
github_create_repo() {
    local name="$1"
    local description="${2:-}"
    
    gh repo create "$name" --public --description "$description" 2>/dev/null
}

# 列出用户仓库
github_list_user_repos() {
    local user="${1:-$(gh api user --jq '.login')}"
    local limit="${2:-30}"
    
    gh repo list "$user" --limit "$limit" 2>/dev/null
}

# 检查登录状态
github_check_auth() {
    gh auth status &>/dev/null
}

# 获取当前用户
github_get_current_user() {
    gh api user --jq '.login' 2>/dev/null
}
