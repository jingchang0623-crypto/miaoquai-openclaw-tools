#!/bin/bash
# OpenClaw Skills Health Checker
# 检查 OpenClaw Skills 的健康状态和配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 配置
OPENCLAW_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
SKILLS_DIR="$OPENCLAW_DIR/skills"

echo -e "${PURPLE}🦞 OpenClaw Skills Health Checker${NC}"
echo -e "${YELLOW}检查时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# 1. 检查 OpenClaw 安装
check_openclaw_install() {
    echo -e "${BLUE}=== 1. OpenClaw 安装检查 ===${NC}"
    
    if command -v openclaw &> /dev/null; then
        local version=$(openclaw --version 2>/dev/null || echo "未知")
        echo -e "  ${GREEN}✅ OpenClaw 已安装: $version${NC}"
    else
        echo -e "  ${RED}❌ OpenClaw 未安装${NC}"
        echo -e "  ${YELLOW}   安装: npm install -g openclaw${NC}"
    fi
    
    if [ -d "$OPENCLAW_DIR" ]; then
        echo -e "  ${GREEN}✅ OpenClaw 目录存在: $OPENCLAW_DIR${NC}"
    else
        echo -e "  ${YELLOW}⚠️ OpenClaw 目录不存在: $OPENCLAW_DIR${NC}"
    fi
    
    echo ""
}

# 2. 检查 Skills 目录
check_skills_dir() {
    echo -e "${BLUE}=== 2. Skills 目录检查 ===${NC}"
    
    if [ -d "$SKILLS_DIR" ]; then
        local skill_count=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l)
        local skill_dirs=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l)
        
        echo -e "  ${GREEN}✅ Skills 目录存在${NC}"
        echo -e "  📁 目录数量: $skill_dirs"
        echo -e "  📄 SKILL.md 数量: $skill_count"
        
        if [ $skill_count -gt 0 ]; then
            echo ""
            echo -e "  ${CYAN}已安装的 Skills:${NC}"
            find "$SKILLS_DIR" -name "SKILL.md" -exec dirname {} \; 2>/dev/null | while read dir; do
                local skill_name=$(basename "$dir")
                local desc=$(grep -m1 "^description:" "$dir/SKILL.md" 2>/dev/null | cut -d: -f2- | xargs || echo "无描述")
                echo -e "    - ${GREEN}$skill_name${NC}: $desc"
            done
        fi
    else
        echo -e "  ${YELLOW}⚠️ Skills 目录不存在: $SKILLS_DIR${NC}"
        echo -e "  ${YELLOW}   创建目录后安装 skills${NC}"
    fi
    
    echo ""
}

# 3. 检查配置文件
check_config() {
    echo -e "${BLUE}=== 3. 配置文件检查 ===${NC}"
    
    local config_file="$OPENCLAW_DIR/config.json"
    local gateway_config="$OPENCLAW_DIR/gateway.json"
    
    if [ -f "$config_file" ]; then
        echo -e "  ${GREEN}✅ config.json 存在${NC}"
        
        # 检查关键字段
        if jq -e '.model' "$config_file" &>/dev/null; then
            local model=$(jq -r '.model' "$config_file" 2>/dev/null)
            echo -e "     模型: $model"
        fi
    else
        echo -e "  ${YELLOW}⚠️ config.json 不存在${NC}"
    fi
    
    if [ -f "$gateway_config" ]; then
        echo -e "  ${GREEN}✅ gateway.json 存在${NC}"
    else
        echo -e "  ${YELLOW}⚠️ gateway.json 不存在${NC}"
    fi
    
    echo ""
}

# 4. 检查 SOUL.md 和 AGENTS.md
check_agent_files() {
    echo -e "${BLUE}=== 4. Agent 文件检查 ===${NC}"
    
    local soul_file="$OPENCLAW_DIR/SOUL.md"
    local agents_file="$OPENCLAW_DIR/AGENTS.md"
    local user_file="$OPENCLAW_DIR/USER.md"
    local tools_file="$OPENCLAW_DIR/TOOLS.md"
    
    for file in "$soul_file" "$agents_file" "$user_file" "$tools_file"; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local lines=$(wc -l < "$file")
            echo -e "  ${GREEN}✅ $filename 存在 ($lines 行)${NC}"
        else
            local filename=$(basename "$file")
            echo -e "  ${YELLOW}⚠️ $filename 不存在${NC}"
        fi
    done
    
    echo ""
}

# 5. 检查环境变量
check_env() {
    echo -e "${BLUE}=== 5. 环境变量检查 ===${NC}"
    
    local env_vars=("ANTHROPIC_API_KEY" "OPENAI_API_KEY" "BRAVE_API_KEY" "GITHUB_TOKEN")
    
    for var in "${env_vars[@]}"; do
        if [ -n "${!var}" ]; then
            echo -e "  ${GREEN}✅ $var 已设置${NC}"
        else
            echo -e "  ${YELLOW}⚠️ $var 未设置${NC}"
        fi
    done
    
    echo ""
}

# 6. 检查网络连接
check_network() {
    echo -e "${BLUE}=== 6. 网络连接检查 ===${NC}"
    
    local endpoints=(
        "https://api.openai.com:OpenAI API"
        "https://api.anthropic.com:Anthropic API"
        "https://api.github.com:GitHub API"
        "https://openclaw.ai:OpenClaw官网"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local url="${endpoint%%:*}"
        local name="${endpoint#*:}"
        
        if curl -s --connect-timeout 5 -o /dev/null "$url" 2>/dev/null; then
            echo -e "  ${GREEN}✅ $name 可访问${NC}"
        else
            echo -e "  ${RED}❌ $name 无法访问${NC}"
        fi
    done
    
    echo ""
}

# 7. Skills 安全检查
check_skill_security() {
    echo -e "${BLUE}=== 7. Skills 安全检查 ===${NC}"
    
    if [ -d "$SKILLS_DIR" ]; then
        local dangerous_patterns=(
            "rm -rf"
            "sudo"
            "chmod 777"
            "curl.*|.*sh"
            "eval.*\$("
        )
        
        local issues=0
        
        find "$SKILLS_DIR" -name "*.sh" -o -name "*.py" -o -name "*.js" 2>/dev/null | while read file; do
            for pattern in "${dangerous_patterns[@]}"; do
                if grep -q "$pattern" "$file" 2>/dev/null; then
                    echo -e "  ${YELLOW}⚠️ 可能存在危险操作: $file${NC}"
                    echo -e "     模式: $pattern"
                    ((issues++))
                fi
            done
        done
        
        if [ $issues -eq 0 ]; then
            echo -e "  ${GREEN}✅ 未发现明显安全问题${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠️ Skills 目录不存在，跳过安全检查${NC}"
    fi
    
    echo ""
}

# 8. 生成健康报告
generate_health_report() {
    local report_file="/tmp/openclaw-health-$(date +%Y%m%d-%H%M%S).md"
    
    {
        echo "# OpenClaw Skills 健康报告"
        echo ""
        echo "**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**OpenClaw 目录**: $OPENCLAW_DIR"
        echo ""
        echo "---"
        echo ""
        echo "运行 \`openclaw doctor\` 获取更详细的诊断信息。"
    } > "$report_file"
    
    echo -e "${GREEN}✅ 健康报告已生成: $report_file${NC}"
}

# 主函数
main() {
    check_openclaw_install
    check_skills_dir
    check_config
    check_agent_files
    check_env
    check_network
    check_skill_security
    
    echo -e "${PURPLE}========================================${NC}"
    generate_health_report
    
    echo ""
    echo -e "${GREEN}🎉 健康检查完成！${NC}"
    echo ""
    echo -e "${CYAN}推荐操作:${NC}"
    echo "  - 定期运行此脚本检查 Skills 状态"
    echo "  - 更新过期的 Skills: openclaw skills update"
    echo "  - 安装新 Skills: openclaw skills install <skill-name>"
}

main "$@"
