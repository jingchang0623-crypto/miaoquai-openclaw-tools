#!/bin/bash
# OpenClaw Cron 任务管理器
# 用于管理和监控 OpenClaw 定时任务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8787}"
GATEWAY_TOKEN="${GATEWAY_TOKEN:-}"
LOG_DIR="/var/log/miaoquai/cron"
MEMORY_DIR="/root/.openclaw/miaoquai-workspace/memory"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 显示帮助
show_help() {
    echo -e "${CYAN}🦞 OpenClaw Cron 任务管理器${NC}"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  list              列出所有定时任务"
    echo "  status            检查 Cron 服务状态"
    echo "  add <name> <cron> <command>  添加新任务"
    echo "  remove <job_id>   删除任务"
    echo "  run <job_id>      立即执行任务"
    echo "  history <job_id>  查看任务执行历史"
    echo "  logs [job_id]     查看任务日志"
    echo "  health            健康检查所有任务"
    echo "  export            导出任务配置"
    echo ""
    echo "示例:"
    echo "  $0 list"
    echo "  $0 add daily-news '0 8 * * *' 'python generate_news.py'"
    echo "  $0 run abc123"
    echo "  $0 health"
    echo ""
}

# 检查 Gateway 状态
check_gateway() {
    echo -e "${BLUE}📡 检查 OpenClaw Gateway 状态...${NC}"
    
    if curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/health" | grep -q "200"; then
        echo -e "${GREEN}✅ Gateway 运行正常 ($GATEWAY_URL)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Gateway 未响应，尝试本地 crontab...${NC}"
        return 1
    fi
}

# 列出所有任务
list_jobs() {
    echo -e "${CYAN}📋 OpenClaw 定时任务列表${NC}"
    echo ""
    
    # 尝试从 Gateway 获取
    if check_gateway >/dev/null 2>&1 && [ -n "$GATEWAY_TOKEN" ]; then
        echo -e "${BLUE}从 Gateway 获取任务...${NC}"
        curl -s -H "Authorization: Bearer $GATEWAY_TOKEN" \
            "$GATEWAY_URL/api/cron/jobs" | jq -r '.jobs[] | 
            "\(.id) | \(.name // "unnamed") | \(.schedule.expr // .schedule.kind) | \(.enabled)"' 2>/dev/null || \
            echo -e "${YELLOW}无法从 Gateway 获取任务${NC}"
    fi
    
    # 同时显示本地 crontab
    echo ""
    echo -e "${PURPLE}📝 本地 Crontab 任务:${NC}"
    crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | while read -r line; do
        echo -e "  ${YELLOW}▸${NC} $line"
    done || echo -e "${YELLOW}  (无本地 crontab 任务)${NC}"
    
    # 显示系统 cron 任务
    echo ""
    echo -e "${PURPLE}⚙️  系统 Cron 任务 (/etc/cron.d):${NC}"
    if [ -d "/etc/cron.d" ]; then
        ls -la /etc/cron.d/ 2>/dev/null | grep -v "^total" | grep -v "^d" | awk '{print "  " $NF}'
    else
        echo -e "${YELLOW}  (无系统 cron 目录)${NC}"
    fi
}

# 任务健康检查
health_check() {
    echo -e "${CYAN}🏥 OpenClaw Cron 任务健康检查${NC}"
    echo ""
    
    local issues=0
    local checks_passed=0
    
    # 1. 检查 cron 服务
    echo -e "${BLUE}检查 cron 服务...${NC}"
    if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Cron 服务运行正常"
        ((checks_passed++))
    else
        echo -e "  ${RED}✗${NC} Cron 服务未运行"
        ((issues++))
    fi
    
    # 2. 检查 Gateway
    echo -e "${BLUE}检查 OpenClaw Gateway...${NC}"
    if check_gateway >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Gateway 连接正常"
        ((checks_passed++))
    else
        echo -e "  ${YELLOW}!${NC} Gateway 未响应 (可能正常，如果使用本地 crontab)"
        ((checks_passed++))
    fi
    
    # 3. 检查日志目录
    echo -e "${BLUE}检查日志目录...${NC}"
    if [ -d "$LOG_DIR" ]; then
        local log_count=$(ls -1 "$LOG_DIR"/*.log 2>/dev/null | wc -l)
        echo -e "  ${GREEN}✓${NC} 日志目录存在 ($log_count 个日志文件)"
        ((checks_passed++))
    else
        echo -e "  ${YELLOW}!${NC} 日志目录不存在，正在创建..."
        mkdir -p "$LOG_DIR"
        ((checks_passed++))
    fi
    
    # 4. 检查最近执行记录
    echo -e "${BLUE}检查最近执行记录...${NC}"
    if [ -d "$MEMORY_DIR" ]; then
        local latest_memory=$(ls -t "$MEMORY_DIR"/*.md 2>/dev/null | head -1)
        if [ -n "$latest_memory" ]; then
            local mem_date=$(basename "$latest_memory" .md)
            local today=$(date +%Y-%m-%d)
            if [ "$mem_date" = "$today" ]; then
                echo -e "  ${GREEN}✓${NC} 今日记忆文件已更新"
                ((checks_passed++))
            else
                echo -e "  ${YELLOW}!${NC} 最新记忆文件: $mem_date (非今日)"
                ((issues++))
            fi
        fi
    else
        echo -e "  ${YELLOW}!${NC} 记忆目录不存在"
        ((issues++))
    fi
    
    # 5. 检查是否有失败任务
    echo -e "${BLUE}检查任务执行状态...${NC}"
    local recent_errors=$(grep -r "失败\|ERROR\|failed" "$LOG_DIR"/*.log 2>/dev/null | \
        grep "$(date +%Y-%m-%d)" | wc -l)
    if [ "$recent_errors" -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} 今日无失败任务"
        ((checks_passed++))
    else
        echo -e "  ${RED}✗${NC} 今日有 $recent_errors 个失败任务"
        ((issues++))
    fi
    
    # 总结
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "检查通过: ${GREEN}$checks_passed${NC} 项"
    echo -e "发现问题: ${RED}$issues${NC} 项"
    
    if [ "$issues" -eq 0 ]; then
        echo -e "${GREEN}✅ 所有任务健康状态良好${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  发现问题，请检查${NC}"
        return 1
    fi
}

# 查看日志
view_logs() {
    local job_id="$1"
    local lines="${2:-50}"
    
    echo -e "${CYAN}📜 任务日志${NC}"
    echo ""
    
    if [ -n "$job_id" ]; then
        # 查找特定任务的日志
        local log_file="$LOG_DIR/${job_id}.log"
        if [ -f "$log_file" ]; then
            echo -e "${BLUE}日志文件: $log_file${NC}"
            tail -n "$lines" "$log_file"
        else
            echo -e "${YELLOW}未找到任务 $job_id 的日志文件${NC}"
            # 尝试在所有日志中搜索
            echo -e "${BLUE}在所有日志中搜索 $job_id...${NC}"
            grep -r "$job_id" "$LOG_DIR"/*.log 2>/dev/null | tail -n "$lines"
        fi
    else
        # 显示所有日志
        echo -e "${BLUE}最近 $lines 行日志:${NC}"
        for log in "$LOG_DIR"/*.log; do
            if [ -f "$log" ]; then
                echo -e "\n${PURPLE}=== $(basename "$log") ===${NC}"
                tail -n 10 "$log"
            fi
        done
    fi
}

# 查看执行历史
view_history() {
    local job_id="$1"
    
    echo -e "${CYAN}📊 任务执行历史: $job_id${NC}"
    echo ""
    
    # 从记忆文件中查找
    if [ -d "$MEMORY_DIR" ]; then
        echo -e "${BLUE}从记忆文件中查找...${NC}"
        grep -l "$job_id" "$MEMORY_DIR"/*.md 2>/dev/null | while read -r mem_file; do
            local date=$(basename "$mem_file" .md)
            echo -e "${YELLOW}📅 $date${NC}"
            grep -A 5 -B 2 "$job_id" "$mem_file" 2>/dev/null | head -20
            echo ""
        done
    fi
    
    # 从 Gateway 获取
    if check_gateway >/dev/null 2>&1 && [ -n "$GATEWAY_TOKEN" ]; then
        echo -e "${BLUE}从 Gateway 获取执行历史...${NC}"
        curl -s -H "Authorization: Bearer $GATEWAY_TOKEN" \
            "$GATEWAY_URL/api/cron/jobs/$job_id/runs" | jq '.' 2>/dev/null || \
            echo -e "${YELLOW}无法获取 Gateway 历史${NC}"
    fi
}

# 导出配置
export_config() {
    local output_file="${1:-cron-backup-$(date +%Y%m%d-%H%M%S).json}"
    
    echo -e "${CYAN}📤 导出 Cron 配置${NC}"
    
    local config='{"exported_at": "'$(date -Iseconds)'", "jobs": []}'
    
    # 从 Gateway 导出
    if check_gateway >/dev/null 2>&1 && [ -n "$GATEWAY_TOKEN" ]; then
        local gateway_jobs=$(curl -s -H "Authorization: Bearer $GATEWAY_TOKEN" \
            "$GATEWAY_URL/api/cron/jobs" | jq '.jobs' 2>/dev/null)
        if [ -n "$gateway_jobs" ] && [ "$gateway_jobs" != "null" ]; then
            config=$(echo "$config" | jq ".jobs += $gateway_jobs")
        fi
    fi
    
    # 从 crontab 导出
    local crontab_jobs=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | \
        jq -R -s 'split("\n") | map(select(length > 0) | {
            type: "crontab",
            line: .
        })')
    if [ -n "$crontab_jobs" ] && [ "$crontab_jobs" != "null" ]; then
        config=$(echo "$config" | jq ".jobs += $crontab_jobs")
    fi
    
    echo "$config" | jq '.' > "$output_file"
    echo -e "${GREEN}✅ 配置已导出到: $output_file${NC}"
    echo -e "${BLUE}包含 $(echo "$config" | jq '.jobs | length') 个任务${NC}"
}

# 立即执行任务
run_job() {
    local job_id="$1"
    
    if [ -z "$job_id" ]; then
        echo -e "${RED}错误: 请提供任务 ID${NC}"
        return 1
    fi
    
    echo -e "${CYAN}🚀 立即执行任务: $job_id${NC}"
    
    # 尝试通过 Gateway 触发
    if check_gateway >/dev/null 2>&1 && [ -n "$GATEWAY_TOKEN" ]; then
        echo -e "${BLUE}通过 Gateway 触发...${NC}"
        curl -s -X POST -H "Authorization: Bearer $GATEWAY_TOKEN" \
            "$GATEWAY_URL/api/cron/jobs/$job_id/run" | jq '.' 2>/dev/null || \
            echo -e "${YELLOW}Gateway 触发失败${NC}"
    else
        echo -e "${YELLOW}Gateway 不可用，请手动执行任务${NC}"
    fi
}

# 主函数
main() {
    local command="${1:-help}"
    
    case "$command" in
        list|ls)
            list_jobs
            ;;
        status)
            check_gateway
            ;;
        health)
            health_check
            ;;
        logs)
            view_logs "$2" "$3"
            ;;
        history)
            view_history "$2"
            ;;
        export)
            export_config "$2"
            ;;
        run)
            run_job "$2"
            ;;
        add|remove)
            echo -e "${YELLOW}提示: 请通过 OpenClaw Gateway 或 crontab -e 管理任务${NC}"
            echo -e "${BLUE}Gateway API: $GATEWAY_URL/api/cron/jobs${NC}"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}未知命令: $command${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
