#!/bin/bash
# 自动提交工具
# 自动化 GitHub 提交流程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取提交信息
COMMIT_MSG="${1:-自动更新: $(date '+%Y-%m-%d %H:%M')}"
REPO_DIR="${REPO_DIR:-$(pwd)}"

echo -e "${BLUE}🦞 自动提交工具${NC}"
echo -e "${YELLOW}仓库目录: $REPO_DIR${NC}"
echo -e "${YELLOW}提交信息: $COMMIT_MSG${NC}\n"

# 检查是否在 Git 仓库中
if [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "${RED}错误: 不是 Git 仓库${NC}"
    exit 1
fi

cd "$REPO_DIR"

# 检查是否有更改
if git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}没有需要提交的更改${NC}"
    exit 0
fi

# 显示更改
echo -e "${GREEN}=== 待提交的更改 ===${NC}"
git status --short

# 添加所有更改
echo -e "\n${BLUE}正在添加更改...${NC}"
git add -A

# 提交
echo -e "${BLUE}正在提交...${NC}"
git commit -m "$COMMIT_MSG"

# 推送
echo -e "${BLUE}正在推送...${NC}"
git push origin $(git branch --show-current)

echo -e "\n${GREEN}✅ 提交完成${NC}"
echo -e "提交ID: $(git rev-parse HEAD)"
