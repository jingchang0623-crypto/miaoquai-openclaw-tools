#!/bin/bash
# =================================================================
# OpenClaw Skill 一键部署测试工具
# 作者: 妙趣AI
# 功能: 快速部署、测试和验证 OpenClaw 自定义 Skills
# =================================================================

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/test-skills"
REPORT_FILE="${SCRIPT_DIR}/deploy-test-report.md"
LOG_FILE="${SCRIPT_DIR}/deploy-test.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

# 显示帮助
show_help() {
    cat << EOF
🤖 OpenClaw Skill 一键部署测试工具

用法: $0 [命令] [选项]

命令:
    test       测试指定 skill 目录
    validate   验证 skill 配置格式
    list       列出所有可测试的 skills
    report     生成测试报告
    batch      批量测试所有 skills
    clean      清理测试环境

选项:
    -p, --path <dir>     指定 skill 目录路径
    -v, --verbose        显示详细输出
    -h, --help          显示帮助信息

示例:
    $0 test -p ./my-skill
    $0 validate -p ./my-skill/SKILL.md
    $0 batch
    $0 report

EOF
}

# 创建测试目录
setup() {
    mkdir -p "$SKILLS_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
    log "测试环境初始化完成"
}

# 验证 skill 格式
validate_skill() {
    local skill_path="$1"
    
    if [[ ! -d "$skill_path" ]]; then
        error "Skill 目录不存在: $skill_path"
        return 1
    fi
    
    local skill_file="$skill_path/SKILL.md"
    if [[ ! -f "$skill_file" ]]; then
        error "找不到 SKILL.md 文件"
        return 1
    fi
    
    # 检查必需字段
    local name=$(grep -E "^# " "$skill_file" | head -1 | sed 's/^# //')
    local description=$(grep -E "^> " "$skill_file" | head -1 | sed 's/^> //')
    
    if [[ -z "$name" ]]; then
        error "Skill 缺少名称"
        return 1
    fi
    
    success "Skill 格式验证通过: $name"
    echo "  - 名称: $name"
    echo "  - 描述: ${description:-无描述}"
    
    return 0
}

# 测试单个 skill
test_skill() {
    local skill_path="$1"
    local skill_name=$(basename "$skill_path")
    
    log "开始测试 skill: $skill_name"
    
    # 1. 验证格式
    if ! validate_skill "$skill_path"; then
        error "Skill 格式验证失败: $skill_name"
        return 1
    fi
    
    # 2. 检查依赖文件
    local required_files=("SKILL.md")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$skill_path/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        warning "缺少文件: ${missing_files[*]}"
    else
        success "所有必需文件存在"
    fi
    
    # 3. 检查脚本可执行性
    local scripts=("$skill_path/"*.sh "$skill_path/"*.py 2>/dev/null)
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ "$script" == *.sh ]]; then
                if [[ -x "$script" ]]; then
                    success "脚本可执行: $(basename "$script")"
                else
                    warning "脚本不可执行: $(basename "$script")"
                fi
            fi
        fi
    done
    
    # 4. 验证 YAML/JSON 配置文件
    local config_files=("$skill_path/"*.yaml "$skill_path/"*.yml "$skill_path/"*.json 2>/dev/null)
    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            if [[ "$config" == *.json ]]; then
                if python3 -c "import json; json.load(open('$config'))" 2>/dev/null; then
                    success "JSON 格式正确: $(basename "$config")"
                else
                    error "JSON 格式错误: $(basename "$config")"
                fi
            else
                if python3 -c "import yaml; yaml.safe_load(open('$config'))" 2>/dev/null; then
                    success "YAML 格式正确: $(basename "$config")"
                else
                    error "YAML 格式错误: $(basename "$config")"
                fi
            fi
        fi
    done
    
    success "Skill 测试完成: $skill_name"
    return 0
}

# 列出所有 skills
list_skills() {
    log "可测试的 Skills:"
    
    # 扫描当前目录
    local count=0
    for dir in */; do
        if [[ -d "$dir" && -f "$dir/SKILL.md" ]]; then
            count=$((count + 1))
            echo "  $count. $dir"
        fi
    done
    
    # 扫描 generated-skills 目录
    if [[ -d "generated-skills" ]]; then
        for dir in generated-skills/*/; do
            if [[ -d "$dir" && -f "$dir/SKILL.md" ]]; then
                count=$((count + 1))
                echo "  $count. $dir"
            fi
        done
    fi
    
    if [[ $count -eq 0 ]]; then
        warning "未找到可测试的 Skills"
    else
        success "共找到 $count 个 Skills"
    fi
}

# 批量测试
batch_test() {
    log "开始批量测试..."
    
    local passed=0
    local failed=0
    
    # 测试当前目录的 skills
    for dir in */; do
        if [[ -d "$dir" && -f "$dir/SKILL.md" ]]; then
            if test_skill "$dir"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
            echo "---"
        fi
    done
    
    # 测试 generated-skills 目录
    if [[ -d "generated-skills" ]]; then
        for dir in generated-skills/*/; do
            if [[ -d "$dir" && -f "$dir/SKILL.md" ]]; then
                if test_skill "$dir"; then
                    passed=$((passed + 1))
                else
                    failed=$((failed + 1))
                fi
                echo "---"
            fi
        done
    fi
    
    log "批量测试完成: 通过 $passed, 失败 $failed"
}

# 生成测试报告
generate_report() {
    local report_date=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$REPORT_FILE" << EOF
# OpenClaw Skill 部署测试报告

生成时间: $report_date

## 测试概要

- 测试时间: $report_date
- 测试脚本: skill-deploy-test.sh

## 测试结果

$(if [[ -f "$LOG_FILE" ]]; then
    echo "### 测试日志"
    echo '```'
    tail -50 "$LOG_FILE"
    echo '```'
fi)

## 建议

1. 确保所有 Skills 都有完整的 SKILL.md 文件
2. 检查脚本的可执行权限
3. 验证配置文件格式
4. 测试完成后及时修复失败项

---
🤖 妙趣AI - OpenClaw 自动化运营工具
EOF
    
    success "测试报告已生成: $REPORT_FILE"
}

# 清理测试环境
clean() {
    log "清理测试环境..."
    rm -f "$LOG_FILE"
    rm -f "$REPORT_FILE"
    success "清理完成"
}

# 主函数
main() {
    setup
    
    local command="${1:-help}"
    local skill_path=""
    local verbose=false
    
    # 解析选项
    shift || true
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--path)
                skill_path="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
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
    
    case "$command" in
        test)
            if [[ -z "$skill_path" ]]; then
                error "请指定 skill 路径 (-p <path>)"
                exit 1
            fi
            test_skill "$skill_path"
            ;;
        validate)
            if [[ -z "$skill_path" ]]; then
                error "请指定 skill 文件路径"
                exit 1
            fi
            validate_skill "$(dirname "$skill_path")"
            ;;
        list)
            list_skills
            ;;
        report)
            generate_report
            ;;
        batch)
            batch_test
            generate_report
            ;;
        clean)
            clean
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
