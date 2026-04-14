#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# 🧠 OpenClaw Agent Memory Health Checker & Optimizer
# ─────────────────────────────────────────────────────────────────
# 检查 OpenClaw Agent 的记忆文件健康度，发现孤立记忆、
# 过期上下文、膨胀的 SOUL.md，并给出优化建议。
#
# 用途：OpenClaw / Claude Code / Codex 等 AI Agent 的
#       记忆文件（MEMORY.md, SOUL.md, USER.md）维护
#
# Version: 1.0.0 | 2026-04-15 | 妙趣AI (miaoquai.com)
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Config ───────────────────────────────────────────────────────
VERSION="1.0.0"
WORKSPACE="${1:-.}"
REPORT_DIR="${WORKSPACE}/memory-health-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/report-${TIMESTAMP}.md"
JSON_REPORT="${REPORT_DIR}/report-${TIMESTAMP}.json"

# Memory file patterns to scan
MEMORY_PATTERNS=("MEMORY.md" "SOUL.md" "USER.md" "AGENTS.md" "IDENTITY.md" "TOOLS.md")
MEMORY_DIRS=("memory" "memories" ".memory" ".memories")
DAILY_MEMORY_PATTERN='memory/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md'

# Health thresholds
WARN_SOUL_SIZE_KB=10        # SOUL.md > 10KB = bloated
WARN_MEMORY_SIZE_KB=50      # MEMORY.md > 50KB = heavy
WARN_DAILY_AGE_DAYS=14      # Daily memory > 14 days = stale
WARN_ORPHAN_THRESHOLD=30    # Days before daily memory is "orphaned"

# ── Helpers ──────────────────────────────────────────────────────
info()  { echo -e "${BLUE}ℹ️  ${RESET}$*"; }
ok()    { echo -e "${GREEN}✅ ${RESET}$*"; }
warn()  { echo -e "${YELLOW}⚠️  ${RESET}$*"; }
fail()  { echo -e "${RED}❌ ${RESET}$*"; }
sep()   { echo -e "${DIM}──────────────────────────────────────────────────────${RESET}"; }
header() { echo -e "\n${BOLD}${PURPLE}$1${RESET}"; echo -e "${DIM}$(printf '─%.0s' {1..58})${RESET}"; }

file_size_kb() { [ -f "$1" ] && echo $(($(wc -c < "$1") / 1024)) || echo "0"; }

days_since_modified() {
    local f="$1"
    [ -f "$f" ] || echo "9999"
    local modified=$(stat -c %Y "$f" 2>/dev/null || echo 0)
    echo $(( ($(date +%s) - modified) / 86400 ))
}

count_lines() { [ -f "$1" ] && wc -l < "$1" || echo "0"; }

# ── Discovery ────────────────────────────────────────────────────
discover_files() {
    local found=0
    local all_files=()

    info "扫描工作区: ${BOLD}${WORKSPACE}${RESET}"
    echo ""

    # Check core memory files
    header "📋 核心记忆文件"
    for pattern in "${MEMORY_PATTERNS[@]}"; do
        local matches=()
        while IFS= read -r -d '' f; do
            matches+=("$f")
        done < <(find "$WORKSPACE" -maxdepth 3 -name "$pattern" -type f -print0 2>/dev/null)

        if [ ${#matches[@]} -eq 0 ]; then
            warn "未找到: ${pattern}"
        else
            for f in "${matches[@]}"; do
                local rel="${f#$WORKSPACE/}"
                local size=$(file_size_kb "$f")
                local lines=$(count_lines "$f")
                local days=$(days_since_modified "$f")
                local status="${GREEN}健康${RESET}"
                [ "$days" -gt 7 ] && status="${YELLOW}${days}天未更新${RESET}"
                [ "$days" -gt 30 ] && status="${RED}${days}天未更新${RESET}"
                echo -e "  ${status}  ${CYAN}${rel}${RESET}  ${size}KB / ${lines}行 / ${days}天前修改"
                all_files+=("$f")
                ((found++))
            done
        fi
    done

    # Check daily memories
    header "📅 每日记忆文件"
    local daily_count=0
    local daily_files=()
    while IFS= read -r -d '' f; do
        daily_files+=("$f")
    done < <(find "$WORKSPACE" -path "*/memory/[0-9]*-[0-9]*-[0-9]*.md" -type f -print0 2>/dev/null)

    if [ ${#daily_files[@]} -eq 0 ]; then
        warn "未找到每日记忆文件 (memory/YYYY-MM-DD.md)"
    else
        for f in "${daily_files[@]}"; do
            local rel="${f#$WORKSPACE/}"
            local size=$(file_size_kb "$f")
            local days=$(days_since_modified "$f")
            local basename=$(basename "$f")
            local status="${GREEN}活跃${RESET}"
            [ "$days" -gt "$WARN_DAILY_AGE_DAYS" ] && status="${YELLOW}过期${RESET}"
            [ "$days" -gt "$WARN_ORPHAN_THRESHOLD" ] && status="${RED}孤立${RESET}"
            echo -e "  ${status}  ${CYAN}${rel}${RESET}  ${size}KB / ${days}天前"
            all_files+=("$f")
            ((daily_count++))
        done
    fi

    # Check memory directories
    header "📁 记忆目录"
    for dir in "${MEMORY_DIRS[@]}"; do
        if [ -d "${WORKSPACE}/${dir}" ]; then
            local count=$(find "${WORKSPACE}/${dir}" -type f | wc -l)
            echo -e "  ${GREEN}存在${RESET}  ${CYAN}${dir}/${RESET}  ${count} 个文件"
        fi
    done

    echo ""
    info "共发现 ${BOLD}${found}${RESET} 个记忆相关文件 (${daily_count} 个每日记忆)"

    # Export for other functions
    FOUND_FILES=("${all_files[@]}")
    DAILY_FILES=("${daily_files[@]}")
    echo "${#all_files[@]}" > /tmp/mhc_found_count
    echo "${#daily_files[@]}" > /tmp/mhc_daily_count
}

# ── Health Analysis ─────────────────────────────────────────────
analyze_health() {
    header "🔬 记忆健康分析"
    local issues=0
    local warnings=0
    local score=100

    echo ""

    # 1. SOUL.md bloat check
    info "检查 SOUL.md 膨胀度..."
    local soul_file=""
    for f in "${FOUND_FILES[@]}"; do
        [[ "$(basename "$f")" == "SOUL.md" ]] && soul_file="$f" && break
    done
    if [ -n "$soul_file" ]; then
        local soul_size=$(file_size_kb "$soul_file")
        if [ "$soul_size" -gt "$WARN_SOUL_SIZE_KB" ]; then
            fail "SOUL.md 过于臃肿: ${soul_size}KB (建议 < ${WARN_SOUL_SIZE_KB}KB)"
            ((issues++)); ((score -= 15))
            echo -e "    ${DIM}💡 提示: 将历史指令迁移到 AGENTS.md，SOUL.md 只保留核心人设${RESET}"
        elif [ "$soul_size" -gt $((WARN_SOUL_SIZE_KB / 2)) ]; then
            warn "SOUL.md 偏大: ${soul_size}KB (建议 < ${WARN_SOUL_SIZE_KB}KB)"
            ((warnings++)); ((score -= 5))
        else
            ok "SOUL.md 大小健康: ${soul_size}KB"
        fi
    else
        warn "未找到 SOUL.md - Agent 缺少核心人设定义"
        ((warnings++)); ((score -= 10))
    fi

    # 2. MEMORY.md weight check
    info "检查 MEMORY.md 重量..."
    local mem_file=""
    for f in "${FOUND_FILES[@]}"; do
        [[ "$(basename "$f")" == "MEMORY.md" ]] && mem_file="$f" && break
    done
    if [ -n "$mem_file" ]; then
        local mem_size=$(file_size_kb "$mem_file")
        local mem_lines=$(count_lines "$mem_file")
        if [ "$mem_size" -gt "$WARN_MEMORY_SIZE_KB" ]; then
            fail "MEMORY.md 超重: ${mem_size}KB / ${mem_lines}行 (建议 < ${WARN_MEMORY_SIZE_KB}KB)"
            ((issues++)); ((score -= 15))
            echo -e "    ${DIM}💡 提示: 归档过期记忆，保留最近30天的活跃内容${RESET}"
        elif [ "$mem_size" -gt $((WARN_MEMORY_SIZE_KB / 2)) ]; then
            warn "MEMORY.md 偏重: ${mem_size}KB / ${mem_lines}行"
            ((warnings++)); ((score -= 5))
        else
            ok "MEMORY.md 大小健康: ${mem_size}KB / ${mem_lines}行"
        fi
    fi

    # 3. Daily memory coverage check
    info "检查每日记忆连续性..."
    local daily_count=$(cat /tmp/mhc_daily_count 2>/dev/null || echo 0)
    if [ "$daily_count" -gt 0 ]; then
        # Find date range
        local dates=()
        for f in "${DAILY_FILES[@]}"; do
            dates+=($(basename "$f" .md))
        done
        IFS=$'\n' sorted=($(sort <<<"${dates[*]}")); unset IFS
        local first="${sorted[0]}"
        local last="${sorted[-1]}"

        # Count expected days
        local d1=$(date -d "$first" +%s 2>/dev/null || echo 0)
        local d2=$(date -d "$last" +%s 2>/dev/null || echo 0)
        local expected=$(( (d2 - d1) / 86400 + 1 ))
        local coverage=$((daily_count * 100 / expected))

        if [ "$coverage" -ge 80 ]; then
            ok "每日记忆覆盖率高: ${daily_count}/${expected} 天 (${coverage}%)"
        elif [ "$coverage" -ge 50 ]; then
            warn "每日记忆有间断: ${daily_count}/${expected} 天 (${coverage}%)"
            ((warnings++)); ((score -= 10))
        else
            fail "每日记忆严重断层: ${daily_count}/${expected} 天 (${coverage}%)"
            ((issues++)); ((score -= 20))
        fi

        # Check for stale daily memories
        local stale=0
        for f in "${DAILY_FILES[@]}"; do
            local days=$(days_since_modified "$f")
            [ "$days" -gt "$WARN_DAILY_AGE_DAYS" ] && ((stale++))
        done
        if [ "$stale" -gt 0 ]; then
            warn "${stale} 个每日记忆超过 ${WARN_DAILY_AGE_DAYS} 天未更新 (孤立风险)"
            ((warnings++))
        fi
    else
        warn "未找到每日记忆文件 - Agent 缺少运行日志"
        ((warnings++)); ((score -= 10))
    fi

    # 4. Cross-reference check (do files reference each other?)
    info "检查文件间交叉引用..."
    local has_agents=false
    local has_tools=false
    local has_identity=false
    for f in "${FOUND_FILES[@]}"; do
        case "$(basename "$f")" in
            AGENTS.md) has_agents=true ;;
            TOOLS.md) has_tools=true ;;
            IDENTITY.md) has_identity=true ;;
        esac
    done

    local ref_checks=0
    local ref_passes=0
    if [ -n "$soul_file" ] && [ -n "$mem_file" ]; then
        ((ref_checks++))
        if grep -qi "memory" "$soul_file" 2>/dev/null; then
            ok "SOUL.md 引用了记忆系统"
            ((ref_passes++))
        else
            warn "SOUL.md 未引用 MEMORY.md"
            ((warnings++)); ((score -= 3))
        fi
    fi
    if [ "$has_agents" ]; then
        ((ref_checks++))
        local agents_file=""
        for f in "${FOUND_FILES[@]}"; do
            [[ "$(basename "$f")" == "AGENTS.md" ]] && agents_file="$f" && break
        done
        if [ -n "$agents_file" ] && grep -qi "SOUL\|memory\|MEMORY" "$agents_file" 2>/dev/null; then
            ok "AGENTS.md 引用了核心文件"
            ((ref_passes++))
        else
            warn "AGENTS.md 可能缺少核心文件引用"
            ((warnings++)); ((score -= 3))
        fi
    fi

    # 5. Redundancy check (duplicate content)
    info "检查内容冗余度..."
    local total_size=0
    for f in "${FOUND_FILES[@]}"; do
        total_size=$((total_size + $(file_size_kb "$f")))
    done
    local avg_size=$((total_size / (${#FOUND_FILES[@]} + 1)))
    if [ "$total_size" -gt 200 ]; then
        warn "记忆文件总大小较大: ${total_size}KB (平均 ${avg_size}KB/文件)"
        echo -e "    ${DIM}💡 提示: 检查是否有重复内容，考虑合并或归档${RESET}"
        ((warnings++)); ((score -= 5))
    else
        ok "记忆文件总大小合理: ${total_size}KB"
    fi

    # 6. SECURITY: Check for sensitive data
    info "检查敏感信息安全..."
    local sensitive_found=false
    for f in "${FOUND_FILES[@]}"; do
        if grep -qiE '(api.key|secret|password|token).*=.*["\x27][A-Za-z0-9]{20,}' "$f" 2>/dev/null; then
            fail "发现可能的敏感信息: ${f#$WORKSPACE/}"
            ((issues++)); ((score -= 20))
            sensitive_found=true
        fi
    done
    [ "$sensitive_found" = false ] && ok "未发现硬编码的敏感信息"

    # Final score
    [ "$score" -lt 0 ] && score=0
    echo ""
    header "📊 健康评分"
    local grade="${GREEN}A+${RESET}"
    [ "$score" -lt 90 ] && grade="${GREEN}A${RESET}"
    [ "$score" -lt 80 ] && grade="${YELLOW}B+${RESET}"
    [ "$score" -lt 70 ] && grade="${YELLOW}B${RESET}"
    [ "$score" -lt 60 ] && grade="${RED}C${RESET}"
    [ "$score" -lt 40 ] && grade="${RED}D${RESET}"

    echo -e "  总分: ${BOLD}${score}/100${RESET}  等级: ${grade}"
    echo -e "  问题: ${RED}${issues}${RESET} 个  警告: ${YELLOW}${warnings}${RESET} 个"

    echo "${score}" > /tmp/mhc_score
    echo "${issues}" > /tmp/mhc_issues
    echo "${warnings}" > /tmp/mhc_warnings
}

# ── Optimization Suggestions ─────────────────────────────────────
suggest_optimizations() {
    header "🔧 优化建议"
    echo ""

    local score=$(cat /tmp/mhc_score 2>/dev/null || echo 100)

    if [ "$score" -ge 90 ]; then
        ok "记忆系统整体健康！以下是一些锦上添花的建议："
        echo ""
        echo -e "  ${CYAN}1.${RESET} 定期回顾 SOUL.md，确保人设与当前需求一致"
        echo -e "  ${CYAN}2.${RESET} 每周清理一次每日记忆，归档超过14天的记录"
        echo -e "  ${CYAN}3.${RESET} 在 AGENTS.md 中维护工作流清单，减少重复劳动"
    elif [ "$score" -ge 70 ]; then
        echo -e "  ${YELLOW}记忆系统需要一些关注：${RESET}"
        echo ""
        echo -e "  ${CYAN}1.${RESET} 📦 归档过期内容 — 将超过30天的记忆移到 archive/ 目录"
        echo -e "  ${CYAN}2.${RESET} ✂️ 精简 SOUL.md — 将操作指令迁移到 AGENTS.md"
        echo -e "  ${CYAN}3.${RESET} 🔗 加强交叉引用 — 确保核心文件互相引用"
        echo -e "  ${CYAN}4.${RESET} 📅 补全每日记忆 — 找出断层日期并补充"
    else
        echo -e "  ${RED}记忆系统需要紧急维护：${RESET}"
        echo ""
        echo -e "  ${CYAN}1.${RESET} 🚨 ${BOLD}立即清理敏感信息${RESET} — 检查 API Key / Token 是否泄露"
        echo -e "  ${CYAN}2.${RESET} 🗜️ ${BOLD}大幅精简核心文件${RESET} — SOUL.md 和 MEMORY.md 需要瘦身"
        echo -e "  ${CYAN}3.${RESET} 📊 ${BOLD}重建记忆结构${RESET} — 确保有 MEMORY.md / SOUL.md / USER.md"
        echo -e "  ${CYAN}4.${RESET} 🔄 ${BOLD}建立定期维护流程${RESET} — 使用 cron 定期执行健康检查"
        echo -e "  ${CYAN}5.${RESET} 🔒 ${BOLD}安全审查${RESET} — 确保无硬编码密钥"
    fi

    echo ""
    echo -e "  ${DIM}📖 更多 OpenClaw 技巧: https://miaoquai.com${RESET}"
}

# ── Archive Stale Memories ──────────────────────────────────────
archive_stale() {
    header "📦 归档过期记忆"
    echo ""

    local archive_dir="${WORKSPACE}/memory/archive"
    mkdir -p "$archive_dir"

    local archived=0
    for f in "${DAILY_FILES[@]}"; do
        local days=$(days_since_modified "$f")
        if [ "$days" -gt "$WARN_DAILY_AGE_DAYS" ]; then
            local rel="${f#$WORKSPACE/}"
            mv "$f" "$archive_dir/"
            ok "归档: ${rel} → memory/archive/"
            ((archived++))
        fi
    done

    if [ "$archived" -eq 0 ]; then
        info "没有需要归档的文件"
    else
        echo ""
        ok "归档完成: ${archived} 个文件 → memory/archive/"
    fi
}

# ── Generate Report ─────────────────────────────────────────────
generate_report() {
    header "📝 生成报告"
    mkdir -p "$REPORT_DIR"

    local score=$(cat /tmp/mhc_score 2>/dev/null || echo 0)
    local issues=$(cat /tmp/mhc_issues 2>/dev/null || echo 0)
    local warnings=$(cat /tmp/mhc_warnings 2>/dev/null || echo 0)
    local found=$(cat /tmp/mhc_found_count 2>/dev/null || echo 0)
    local daily=$(cat /tmp/mhc_daily_count 2>/dev/null || echo 0)

    cat > "$REPORT_FILE" <<EOF
# 🧠 OpenClaw Agent Memory Health Report

> Generated: $(date -Iseconds) | Version: ${VERSION}
> Workspace: ${WORKSPACE}

## 📊 Summary

| Metric | Value |
|--------|-------|
| Health Score | ${score}/100 |
| Issues | ${issues} |
| Warnings | ${warnings} |
| Memory Files Found | ${found} |
| Daily Memories | ${daily} |

## 📋 Files Scanned

EOF

    for f in "${FOUND_FILES[@]}"; do
        local rel="${f#$WORKSPACE/}"
        local size=$(file_size_kb "$f")
        local lines=$(count_lines "$f")
        local days=$(days_since_modified "$f")
        echo "- \`${rel}\` — ${size}KB, ${lines} lines, ${days}d ago" >> "$REPORT_FILE"
    done

    cat >> "$REPORT_FILE" <<EOF

## 🔧 Recommendations

1. Review and clean up memory files regularly
2. Archive daily memories older than ${WARN_DAILY_AGE_DAYS} days
3. Keep SOUL.md under ${WARN_SOUL_SIZE_KB}KB
4. Keep MEMORY.md under ${WARN_MEMORY_SIZE_KB}KB
5. Ensure cross-references between core files
6. Never hardcode API keys or tokens

---

*Report generated by [Agent Memory Health Checker](https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools) | [妙趣AI](https://miaoquai.com)*
EOF

    ok "Markdown 报告: ${REPORT_FILE}"

    # JSON report
    cat > "$JSON_REPORT" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "version": "${VERSION}",
  "workspace": "${WORKSPACE}",
  "score": ${score},
  "issues": ${issues},
  "warnings": ${warnings},
  "files_found": ${found},
  "daily_memories": ${daily},
  "files": [
$(for f in "${FOUND_FILES[@]}"; do
    local rel="${f#$WORKSPACE/}"
    local size=$(file_size_kb "$f")
    local lines=$(count_lines "$f")
    local days=$(days_since_modified "$f")
    echo "    {\"path\": \"${rel}\", \"size_kb\": ${size}, \"lines\": ${lines}, \"days_since_modified\": ${days}},"
done | sed '$ s/,$//')
  ]
}
EOF

    ok "JSON 报告: ${JSON_REPORT}"
    echo ""
    info "报告目录: ${REPORT_DIR}/"
}

# ── Watchdog (continuous monitoring) ────────────────────────────
watchdog() {
    local interval="${1:-3600}"  # Default: 1 hour
    header "🐕 记忆看门狗模式 (每 ${interval}s 检查)"
    info "按 Ctrl+C 停止"

    while true; do
        echo -e "\n${BOLD}$(date '+%Y-%m-%d %H:%M:%S')${RESET} 开始检查..."
        discover_files
        analyze_health
        local score=$(cat /tmp/mhc_score 2>/dev/null || echo 0)
        if [ "$score" -lt 60 ]; then
            fail "健康分数低于60！需要立即维护！"
        fi
        info "下次检查: ${interval} 秒后..."
        sleep "$interval"
    done
}

# ── Setup Cron ──────────────────────────────────────────────────
setup_cron() {
    header "⏰ 设置定时健康检查"

    local script_path="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local cron_cmd="0 6 * * * ${script_path} check ${WORKSPACE} >> /tmp/memory-health.log 2>&1"

    # Check if already exists
    if crontab -l 2>/dev/null | grep -q "memory-health-checker"; then
        warn "定时任务已存在，跳过添加"
    else
        (crontab -l 2>/dev/null; echo "$cron_cmd") | crontab -
        ok "已添加每日 06:00 记忆健康检查"
    fi

    echo ""
    info "当前定时任务:"
    crontab -l 2>/dev/null | grep "memory-health" || echo "  (无)"
}

# ── Usage ───────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
🧠 OpenClaw Agent Memory Health Checker v1.0.0

检查和优化 AI Agent 记忆系统的健康度。

用法: agent-memory-health-checker.sh <命令> [工作区路径]

命令:
  check <path>     全面健康检查（默认）
  archive          归档过期每日记忆
  report           生成 Markdown + JSON 报告
  watchdog [秒数]  持续监控模式（默认每小时）
  cron             设置每日定时检查
  version          显示版本

示例:
  ./agent-memory-health-checker.sh check ~/.openclaw/miaoquai-workspace
  ./agent-memory-health-checker.sh archive /path/to/workspace
  ./agent-memory-health-checker.sh watchdog 1800

妙趣AI出品 | https://miaoquai.com | https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools
EOF
}

# ── Main ────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  🧠 OpenClaw Agent Memory Health Checker v${VERSION}       ║"
    echo "║     妙趣AI | miaoquai.com                           ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    local cmd="${1:-check}"
    case "$cmd" in
        check)
            WORKSPACE="${2:-.}"
            WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd)" || { fail "无效路径: ${WORKSPACE}"; exit 1; }
            discover_files
            analyze_health
            suggest_optimizations
            echo ""
            sep()
            echo -e "${DIM}妙趣AI | 妙趣横生，AI工具导航: https://miaoquai.com${RESET}"
            ;;
        archive)
            WORKSPACE="${2:-.}"
            WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd)" || { fail "无效路径"; exit 1; }
            discover_files
            archive_stale
            ;;
        report)
            WORKSPACE="${2:-.}"
            WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd)" || { fail "无效路径"; exit 1; }
            discover_files
            analyze_health
            generate_report
            ;;
        watchdog)
            WORKSPACE="${3:-.}"
            WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd)" || { fail "无效路径"; exit 1; }
            watchdog "${2:-3600}"
            ;;
        cron)
            setup_cron
            ;;
        version)
            echo "agent-memory-health-checker.sh v${VERSION}"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
