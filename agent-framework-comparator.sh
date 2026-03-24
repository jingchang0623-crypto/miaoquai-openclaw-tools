#!/bin/bash
# =============================================================================
# Agent Framework Comparator
# =============================================================================
# 比较 OpenClaw 与其他 AI Agent 框架的差异，帮助选择最适合的方案
#
# 对比框架:
# - OpenClaw (开源)
# - DeerFlow (bytedance, 开源)
# - ruflo (ruvnet, 开源)
# - Claude Code (Anthropic, 开源)
#
# 用法:
#   ./agent-framework-comparator.sh [选项]
#   选项:
#     -c, --compare <framework>    对比指定框架
#     -t, --table                  输出对比表格
#     -r, --recommend              基于需求推荐框架
#     -v, --version                显示版本
#     -h, --help                   显示帮助
#
# 示例:
#   ./agent-framework-comparator.sh -t              # 输出对比表格
#   ./agent-framework-comparator.sh -c deer-flow    # 对比 DeerFlow
#   ./agent-framework-comparator.sh -r              # 获取推荐
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 版本
VERSION="1.0.0"
DATE="2026-03-25"

# 框架数据
declare -A FRAMEWORKS=(
    ["openclaw"]="https://github.com/openclaw/openclaw|OpenClaw|开源|✅|✅|✅|✅|✅|✅|✅|✅|✅|高|⭐⭐⭐⭐⭐"
    ["deer-flow"]="https://github.com/bytedance/deer-flow|DeerFlow|开源|✅|✅|✅|✅|✅|❌|✅|❌|❌|中|⭐⭐⭐⭐"
    ["ruflo"]="https://github.com/ruvnet/ruflo|ruflo|开源|✅|✅|❌|✅|✅|✅|❌|❌|❌|高|⭐⭐⭐⭐"
    ["claude-code"]="https://github.com/anthropics/claude-code|Claude Code|开源|✅|✅|✅|✅|✅|❌|✅|✅|✅|高|⭐⭐⭐⭐⭐"
)

# 功能对比数据
declare -A FEATURES=(
    ["openclaw_skills"]="✅ 内置 Skills 系统"
    ["openclaw_subagent"]="✅ 支持子 Agent"
    ["openclaw_sandbox"]="✅ 沙箱执行环境"
    ["openclaw_memory"]="✅ 长期记忆"
    ["openclaw_mcp"]="✅ MCP 协议支持"
    ["openclaw_console"]="✅ 可视化管理后台"
    ["openclaw_cron"]="✅ 定时任务"
    ["openclaw_chat"]="✅ 多种聊天渠道"
    ["deer-flow_skills"]="✅ Skills 扩展"
    ["deer-flow_subagent"]="✅ 子 Agent 编排"
    ["deer-flow_sandbox"]="✅ Docker 沙箱"
    ["deer-flow_memory"]="✅ 记忆系统"
    ["deer-flow_mcp"]="❌ 无 MCP"
    ["deer-flow_console"]="✅ Web UI"
    ["deer-flow_cron"]="❌ 无定时任务"
    ["deer-flow_chat"]="✅ IM 集成"
    ["ruflo_skills"]="✅ Plugin 系统"
    ["ruflo_subagent"]="✅ Swarm 编排"
    ["ruflo_sandbox"]="❌ 无沙箱"
    ["ruflo_memory"]="✅ RAG 集成"
    ["ruflo_mcp"]="✅ MCP 支持"
    ["ruflo_console"]="❌ 无后台"
    ["ruflo_cron"]="❌ 无定时任务"
    ["ruflo_chat"]="✅ 聊天界面"
    ["claude-code_skills"]="✅ Hooks/Skills"
    ["claude-code_subagent"]="✅ 子 Agent"
    ["claude-code_sandbox"]="✅ 代码执行"
    ["claude-code_memory"]="✅ Memory API"
    ["claude-code_mcp"]="✅ MCP 支持"
    ["claude-code_console"]="❌ 无后台"
    ["claude-code_cron"]="❌ 无定时任务"
    ["claude-code_chat"]="✅ Claude CLI"
)

# 打印标题
print_header() {
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  🤖 AI Agent Framework Comparator v${VERSION}${NC}"
    echo -e "${BOLD}${BLUE}  📅 ${DATE} | 妙趣AI${NC}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# 打印帮助
print_help() {
    print_header
    echo -e "${BOLD}用法:${NC} $0 [选项]"
    echo ""
    echo -e "${BOLD}选项:${NC}"
    echo -e "  ${GREEN}-c, --compare <framework>${NC}    对比指定框架"
    echo -e "  ${GREEN}-t, --table${NC}                  输出完整对比表格"
    echo -e "  ${GREEN}-r, --recommend${NC}              基于需求推荐框架"
    echo -e "  ${GREEN}-v, --version${NC}                显示版本"
    echo -e "  ${GREEN}-h, --help${NC}                   显示帮助"
    echo ""
    echo -e "${BOLD}示例:${NC}"
    echo "  $0 -t                    # 输出对比表格"
    echo "  $0 -c deer-flow          # 对比 DeerFlow"
    echo "  $0 -r                    # 获取推荐"
    echo ""
    echo -e "${BOLD}支持的框架:${NC} openclaw, deer-flow, ruflo, claude-code"
}

# 打印对比表格
print_table() {
    print_header
    
    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│                        核心功能对比矩阵                                  │${NC}"
    echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BOLD}${CYAN}│ 功能                │ OpenClaw  │ DeerFlow  │  ruflo   │Claude Code│${NC}"
    echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│ Skills/插件系统      │     ✅     │     ✅     │    ✅    │    ✅     │${NC}"
    echo -e "${CYAN}│ 子 Agent 编排        │     ✅     │     ✅     │    ✅    │    ✅     │${NC}"
    echo -e "${CYAN}│ 沙箱执行环境        │     ✅     │     ✅     │    ❌    │    ✅     │${NC}"
    echo -e "${CYAN}│ 长期记忆            │     ✅     │     ✅     │    ✅    │    ✅     │${NC}"
    echo -e "${CYAN}│ MCP 协议支持        │     ✅     │     ❌     │    ✅    │    ✅     │${NC}"
    echo -e "${CYAN}│ 可视化管理后台      │     ✅     │     ✅     │    ❌    │    ❌     │${NC}"
    echo -e "${CYAN}│ 定时任务            │     ✅     │     ❌     │    ❌    │    ❌     │${NC}"
    echo -e "${CYAN}│ 多种聊天渠道        │     ✅     │     ✅     │    ✅    │    ✅     │${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│ 部署复杂度          │    低     │    中     │   中     │    低     │${NC}"
    echo -e "${CYAN}│ 社区活跃度          │   ⭐⭐⭐⭐⭐  │  ⭐⭐⭐⭐   │  ⭐⭐⭐⭐  │  ⭐⭐⭐⭐⭐  │${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}推荐场景:${NC}"
    echo ""
    echo -e "${YELLOW}🎯 选择 OpenClaw 如果:${NC}"
    echo "   • 需要完整的 Skills 生态系统（5000+ skills）"
    echo "   • 需要定时任务和自动化工作流"
    echo "   • 需要可视化管理后台"
    echo "   • 需要飞书、Discord 等多渠道集成"
    echo "   • 中国地区用户，需要中文支持"
    echo ""
    echo -e "${YELLOW}🎯 选择 DeerFlow 如果:${NC}"
    echo "   • 需要强大的深度研究能力"
    echo "   • 使用 Docker 进行沙箱隔离"
    echo "   • 需要企业级部署"
    echo ""
    echo -e "${YELLOW}🎯 选择 ruflo 如果:${NC}"
    echo "   • 专门使用 Claude 作为后端"
    echo "   • 需要多 Agent Swarm 编排"
    echo ""
    echo -e "${YELLOW}🎯 选择 Claude Code 如果:${NC}"
    echo "   • 主要进行本地代码开发"
    echo "   • 需要与 Anthropic 模型深度集成"
    echo "   • 熟悉 CLI 操作"
    echo ""
}

# 对比指定框架
compare_framework() {
    local framework=$1
    
    print_header
    
    case $framework in
        openclaw)
            echo -e "${GREEN}🤖 OpenClaw${NC}"
            echo ""
            echo -e "${BOLD}官网:${NC} https://openclaw.ai"
            echo -e "${BOLD}开源:${NC} https://github.com/openclaw/openclaw"
            echo ""
            echo -e "${BOLD}${GREEN}核心优势:${NC}"
            echo "  ✅ 内置 5000+ Skills 生态系统"
            echo "  ✅ 完整的定时任务系统 (cron)"
            echo "  ✅ 可视化管理后台 (OpenClaw Console)"
            echo "  ✅ MCP 协议支持"
            echo "  ✅ 飞书、Discord、Telegram 多渠道集成"
            echo "  ✅ 中国本地化支持"
            echo "  ✅ 子 Agent 和沙箱执行"
            echo ""
            echo -e "${YELLOW}📊 GitHub Trending:${NC} 今日热度中"
            ;;
        deer-flow)
            echo -e "${GREEN}🦌 DeerFlow${NC}"
            echo ""
            echo -e "${BOLD}官网:${NC} https://deerflow.tech"
            echo -e "${BOLD}开源:${NC} https://github.com/bytedance/deer-flow"
            echo "  ⭐ 42,987 stars | 今天 +4,319 stars 🔥"
            echo ""
            echo -e "${BOLD}${GREEN}核心优势:${NC}"
            echo "  ✅ 字节跳动背书，企业级质量"
            echo "  ✅ Docker 沙箱隔离"
            echo "  ✅ 强大的深度研究能力"
            echo "  ✅ Web UI 界面"
            echo "  ✅ IM 渠道集成"
            echo ""
            echo -e "${RED}不足:${NC}"
            echo "  ❌ 无 MCP 协议支持"
            echo "  ❌ 无定时任务系统"
            echo "  ❌ 中文文档较少"
            ;;
        ruflo)
            echo -e "${GREEN}🌊 ruflo${NC}"
            echo ""
            echo -e "${BOLD}官网:${NC} https://ruflo.ai"
            echo -e "${BOLD}开源:${NC} https://github.com/ruvnet/ruflo"
            echo "  ⭐ 24,982 stars"
            echo ""
            echo -e "${BOLD}${GREEN}核心优势:${NC}"
            echo "  ✅ Claude 深度集成"
            echo "  ✅ Swarm 多 Agent 编排"
            echo "  ✅ RAG 知识库支持"
            echo "  ✅ MCP 协议支持"
            echo ""
            echo -e "${RED}不足:${NC}"
            echo "  ❌ 无沙箱执行环境"
            echo "  ❌ 无可视化管理后台"
            echo "  ❌ 无定时任务"
            ;;
        claude-code)
            echo -e "${GREEN}🔷 Claude Code${NC}"
            echo ""
            echo -e "${BOLD}官网:${NC} https://claude.ai/claude-code"
            echo -e "${BOLD}开源:${NC} https://github.com/anthropics/claude-code"
            echo ""
            echo -e "${BOLD}${GREEN}核心优势:${NC}"
            echo "  ✅ Anthropic 官方支持"
            echo "  ✅ MCP 协议先驱"
            echo "  ✅ 本地代码执行"
            echo "  ✅ Memory API"
            echo "  ✅ Hooks 和 Skills 系统"
            echo ""
            echo -e "${RED}不足:${NC}"
            echo "  ❌ 无可视化管理后台"
            echo "  ❌ 无定时任务系统"
            echo "  ❌ 渠道集成有限"
            ;;
        *)
            echo -e "${RED}错误: 未知框架 '$framework'${NC}"
            echo "支持的框架: openclaw, deer-flow, ruflo, claude-code"
            exit 1
            ;;
    esac
    
    echo ""
}

# 推荐框架
recommend_framework() {
    print_header
    
    echo -e "${BOLD}${CYAN}📋 框架推荐向导${NC}"
    echo ""
    echo "回答几个问题，帮你选择最适合的框架："
    echo ""
    
    read -p "1. 你需要定时任务自动化吗? (y/n): " need_cron
    read -p "2. 你需要可视化后台管理吗? (y/n): " need_console
    read -p "3. 你在中国地区吗? (y/n): " in_china
    read -p "4. 你需要 MCP 协议支持吗? (y/n): " need_mcp
    echo ""
    
    echo -e "${BOLD}🎯 推荐结果:${NC}"
    
    if [[ "$need_cron" == "y" || "$need_console" == "y" ]]; then
        echo -e "${GREEN}👉 推荐使用 OpenClaw${NC}"
        echo "   理由: OpenClaw 是唯一同时支持定时任务和可视化后台的开源框架"
    elif [[ "$in_china" == "y" ]]; then
        echo -e "${GREEN}👉 推荐使用 OpenClaw${NC}"
        echo "   理由: OpenClaw 有完整的中文支持和本地化渠道集成"
    elif [[ "$need_mcp" == "n" ]]; then
        echo -e "${GREEN}👉 推荐使用 DeerFlow${NC}"
        echo "   理由: DeerFlow 今日 GitHub Trending 第一，深度研究能力强"
    else
        echo -e "${GREEN}👉 推荐使用 OpenClaw${NC}"
        echo "   理由: 综合功能最完整，Skills 生态系统丰富"
    fi
    
    echo ""
    echo -e "${CYAN}查看完整对比: $0 -t${NC}"
}

# 主函数
main() {
    local compare_framework=""
    local show_table=false
    local show_recommend=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--compare)
                compare_framework="$2"
                shift 2
                ;;
            -t|--table)
                show_table=true
                shift
                ;;
            -r|--recommend)
                show_recommend=true
                shift
                ;;
            -v|--version)
                echo "v${VERSION} (${DATE})"
                exit 0
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo -e "${RED}错误: 未知参数 '$1'${NC}"
                echo "使用 -h 查看帮助"
                exit 1
                ;;
        esac
    done
    
    # 执行操作
    if [[ "$show_table" == "true" ]]; then
        print_table
    elif [[ "$show_recommend" == "true" ]]; then
        recommend_framework
    elif [[ -n "$compare_framework" ]]; then
        compare_framework "$compare_framework"
    else
        print_help
    fi
}

# 运行
main "$@"