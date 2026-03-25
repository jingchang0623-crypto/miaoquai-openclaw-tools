#!/bin/bash
#
# OpenClaw Skill - Skill Usage Tracker
# 追踪本地 OpenClaw Skills 的使用情况和效果分析
#

set -e

TRACK_FILE="${HOME}/.openclaw/skills/usage.json"
REPORT_DIR="/var/www/miaoquai/reports"

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[Tracker]${NC} $1"; }

# 初始化使用追踪
init_tracker() {
    mkdir -p "$(dirname "$TRACK_FILE")"
    if [ ! -f "$TRACK_FILE" ]; then
        echo '{"skills":{},"last_updated":"'"$(date -Iseconds)"'"}' > "$TRACK_FILE"
    fi
}

# 记录技能使用
track_usage() {
    local skill_name="$1"
    local status="${2:-success}"
    
    if [ -z "$skill_name" ]; then
        echo "用法: track_usage.sh <skill_name> [success|fail]"
        exit 1
    fi
    
    init_tracker
    
    # 使用 jq 更新 JSON
    local timestamp=$(date -Iseconds)
    local temp=$(mktemp)
    
    jq --arg skill "$skill_name" \
       --arg status "$status" \
       --arg time "$timestamp" \
       '.skills[$skill] = (.skills[$skill] // {"uses":0,"success":0,"fail":0,"last_used":""}) | 
        .skills[$skill].uses += 1 |
        if $status == "success" then .skills[$skill].success += 1 else .skills[$skill].fail += 1 end |
        .skills[$skill].last_used = $time |
        .last_updated = $time' "$TRACK_FILE" > "$temp"
    
    mv "$temp" "$TRACK_FILE"
    log "已记录: $skill_name (状态: $status)"
}

# 生成使用报告
generate_report() {
    local date=$(date +%Y-%m-%d)
    local output="${REPORT_DIR}/skill-usage-${date}.md"
    
    mkdir -p "$REPORT_DIR"
    
    init_tracker
    
    cat > "$output" << EOF
---
title: OpenClaw Skills 使用报告
date: ${date}
---

# 📊 OpenClaw Skills 使用报告

**生成时间**: $(date "+%Y-%m-%d %H:%M:%S")

## 使用统计

| Skill | 使用次数 | 成功 | 失败 | 成功率 | 最后使用 |
|-------|----------|------|------|--------|----------|
EOF

    # 解析 JSON 并生成表格
    jq -r '.skills | to_entries[] | 
        "\(if (.value.uses > 0) then 
            "| \(.key) | \(.value.uses) | \(.value.success) | \(.value.fail) | \((.value.success * 100 / .value.uses))% | \(.value.last_used[0:19]) |"
         else empty end)' "$TRACK_FILE" >> "$output"

    # 添加汇总
    local total=$(jq '.skills | length' "$TRACK_FILE")
    local total_uses=$(jq '[.skills[].uses] | add' "$TRACK_FILE")
    local total_success=$(jq '[.skills[].success] | add' "$TRACK_FILE")
    
    cat >> "$output" << EOF

## 📈 汇总

- **活跃 Skills**: ${total:-0}
- **总使用次数**: ${total_uses:-0}
- **总成功次数**: ${total_success:-0}
- **综合成功率**: $(echo "$total_success $total_uses" | awk '{if($2>0) printf "%.1f", $1*100/$2; else print "0"}')%

---
*由妙趣AI自动生成 | [miaoquai.com](https://miaoquai.com)*
EOF

    log "报告已生成: $output"
    echo "$output"
}

# 展示统计
show_stats() {
    init_tracker
    
    echo -e "${CYAN}========== Skills 使用统计 ==========${NC}"
    jq -r '.skills | to_entries[] | 
        "\(.key):\n  使用: \(.value.uses)\n  成功: \(.value.success)\n  失败: \(.value.fail)\n  最后: \(.value.last_used[0:19] // "从未")"' "$TRACK_FILE"
}

# 主程序
case "${1:-}" in
    track)
        track_usage "$2" "$3"
        ;;
    report)
        generate_report
        ;;
    stats)
        show_stats
        ;;
    *)
        echo "OpenClaw Skill Usage Tracker"
        echo ""
        echo "用法:"
        echo "  $0 track <skill_name> [success|fail]  - 记录使用"
        echo "  $0 report                              - 生成报告"
        echo "  $0 stats                               - 显示统计"
        ;;
esac