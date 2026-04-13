#!/bin/bash
# MCP Server Quick Tester - 快速测试和诊断 MCP 服务器
# 妙趣AI出品 | https://miaoquai.com
# 版本: 1.0.0 | 2026-04-14

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 版本
VERSION="1.0.0"

# 默认配置
DEFAULT_TIMEOUT=30
DEFAULT_TRANSPORT="stdio"

# 使用说明
usage() {
    cat << EOF
🧪 MCP Server Quick Tester v${VERSION}
   妙趣AI出品 | https://miaoquai.com

用法:
    $(basename "$0") <command> [options]

命令:
    test <server_path>       测试本地 MCP 服务器
    test-remote <url>        测试远程 SSE 服务器
    validate <json_file>     验证 MCP 配置文件
    list-tools <server_path> 列出服务器所有工具
    call <server_path> <tool_name> [params] 调用指定工具
    discover                 发现常见 MCP 服务器
    inspect <server_path>    详细检查服务器配置
    report <server_path>     生成详细测试报告

选项:
    -t, --transport <type>   传输类型: stdio|sse (默认: stdio)
    -T, --timeout <seconds>  超时时间 (默认: 30)
    -e, --env <key=value>    环境变量 (可多次使用)
    -v, --verbose            详细输出
    -j, --json               JSON 格式输出
    -h, --help              显示帮助

示例:
    # 测试本地 MCP 服务器
    $(basename "$0") test ./my-mcp-server.js

    # 测试远程 SSE 服务器
    $(basename "$0") test-remote https://api.example.com/mcp

    # 验证配置文件
    $(basename "$0") validate ./mcp-config.json

    # 调用特定工具
    $(basename "$0") call ./server.js search --params '{"query":"AI"}'

    # 带环境变量测试
    $(basename "$0") test ./server.js -e API_KEY=xxx -e DEBUG=true

EOF
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_section() {
    echo -e "\n${CYAN}━━━ $1 ━━━${NC}"
}

# 检查依赖
check_dependencies() {
    local deps=("jq" "curl" "node")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少依赖: ${missing[*]}"
        log_info "请安装: sudo apt-get install jq curl nodejs"
        exit 1
    fi
}

# 解析命令行参数
parse_args() {
    TRANSPORT="$DEFAULT_TRANSPORT"
    TIMEOUT="$DEFAULT_TIMEOUT"
    ENV_VARS=()
    VERBOSE=false
    JSON_OUTPUT=false
    PARAMS=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--transport)
                TRANSPORT="$2"
                shift 2
                ;;
            -T|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -e|--env)
                ENV_VARS+=("$2")
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            --params)
                PARAMS="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                break
                ;;
        esac
    done
}

# 测试本地 MCP 服务器
test_local_server() {
    local server_path="$1"
    
    log_section "MCP 服务器测试"
    log_info "服务器路径: $server_path"
    log_info "传输类型: $TRANSPORT"
    log_info "超时时间: ${TIMEOUT}s"
    
    # 检查文件是否存在
    if [ ! -f "$server_path" ]; then
        log_error "服务器文件不存在: $server_path"
        return 1
    fi
    
    # 检查文件权限
    if [ ! -x "$server_path" ] && [[ ! "$server_path" =~ \.(js|ts|py)$ ]]; then
        log_warning "文件可能没有执行权限"
    fi
    
    # 设置环境变量
    for env_var in "${ENV_VARS[@]}"; do
        export "$env_var"
        if [ "$VERBOSE" = true ]; then
            log_info "设置环境变量: $env_var"
        fi
    done
    
    # 构建启动命令
    local cmd
    if [[ "$server_path" =~ \.js$ ]]; then
        cmd="node $server_path"
    elif [[ "$server_path" =~ \.ts$ ]]; then
        cmd="npx ts-node $server_path"
    elif [[ "$server_path" =~ \.py$ ]]; then
        cmd="python3 $server_path"
    else
        cmd="$server_path"
    fi
    
    log_info "启动命令: $cmd"
    
    # 发送初始化请求
    local init_request='{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {
                "name": "mcp-tester",
                "version": "1.0.0"
            }
        }
    }'
    
    log_info "发送初始化请求..."
    
    # 使用 timeout 运行测试
    local response
    if response=$(echo "$init_request" | timeout "$TIMEOUT" bash -c "$cmd" 2>&1 | head -20); then
        if echo "$response" | grep -q "jsonrpc"; then
            log_success "服务器响应正常 ✓"
            
            if [ "$VERBOSE" = true ]; then
                log_info "响应内容:"
                echo "$response" | jq '.' 2>/dev/null || echo "$response"
            fi
            
            # 检查协议版本
            if echo "$response" | grep -q "2024-11-05"; then
                log_success "协议版本兼容 ✓"
            else
                log_warning "协议版本可能不兼容"
            fi
            
            return 0
        else
            log_error "服务器响应格式不正确"
            if [ "$VERBOSE" = true ]; then
                echo "$response"
            fi
            return 1
        fi
    else
        log_error "服务器启动失败或超时"
        if [ -n "$response" ]; then
            log_info "错误输出:"
            echo "$response" | head -10
        fi
        return 1
    fi
}

# 测试远程 SSE 服务器
test_remote_server() {
    local url="$1"
    
    log_section "远程 MCP 服务器测试"
    log_info "服务器 URL: $url"
    
    # 测试连通性
    log_info "测试服务器连通性..."
    if curl -sf -o /dev/null --max-time "$TIMEOUT" "$url"; then
        log_success "服务器可访问 ✓"
    else
        log_error "无法访问服务器"
        return 1
    fi
    
    # 测试 SSE 端点
    log_info "测试 SSE 端点..."
    local sse_url="${url%/}/sse"
    if curl -sf -o /dev/null --max-time 5 "$sse_url"; then
        log_success "SSE 端点可用 ✓"
    else
        log_warning "SSE 端点可能不可用 (HTTP $?)"
    fi
    
    # 测试消息端点
    log_info "测试消息端点..."
    local message_url="${url%/}/message"
    local test_message='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mcp-tester","version":"1.0.0"}}}'
    
    local response
    if response=$(curl -sf -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$test_message" \
        --max-time "$TIMEOUT" \
        "$message_url" 2>&1); then
        log_success "消息端点响应正常 ✓"
        
        if [ "$VERBOSE" = true ]; then
            log_info "响应:"
            echo "$response" | jq '.' 2>/dev/null || echo "$response"
        fi
    else
        log_error "消息端点测试失败"
        return 1
    fi
}

# 验证 MCP 配置文件
validate_config() {
    local config_file="$1"
    
    log_section "配置文件验证"
    log_info "配置文件: $config_file"
    
    if [ ! -f "$config_file" ]; then
        log_error "文件不存在: $config_file"
        return 1
    fi
    
    # 检查 JSON 格式
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "JSON 格式错误"
        return 1
    fi
    
    log_success "JSON 格式正确 ✓"
    
    # 检查必要字段
    local required_fields=("mcpServers")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$config_file" > /dev/null 2>&1; then
            log_warning "缺少字段: $field"
        else
            log_success "字段存在: $field ✓"
        fi
    done
    
    # 统计服务器数量
    local server_count
    server_count=$(jq '.mcpServers | length' "$config_file")
    log_info "发现 $server_count 个 MCP 服务器配置"
    
    # 验证每个服务器配置
    local servers
    servers=$(jq -r '.mcpServers | keys[]' "$config_file")
    
    for server in $servers; do
        log_info "检查服务器: $server"
        local command
        command=$(jq -r ".mcpServers[\"$server\"].command" "$config_file")
        
        if [ -n "$command" ] && [ "$command" != "null" ]; then
            if command -v "$command" &> /dev/null; then
                log_success "  命令可用: $command ✓"
            else
                log_error "  命令不存在: $command"
            fi
        fi
    done
}

# 列出服务器工具
list_tools() {
    local server_path="$1"
    
    log_section "工具列表"
    log_info "正在获取工具列表..."
    
    local cmd
    if [[ "$server_path" =~ \.js$ ]]; then
        cmd="node $server_path"
    elif [[ "$server_path" =~ \.py$ ]]; then
        cmd="python3 $server_path"
    else
        cmd="$server_path"
    fi
    
    # 发送工具列表请求
    local tools_request='{
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/list"
    }'
    
    local response
    if response=$(echo "$tools_request" | timeout "$TIMEOUT" bash -c "$cmd" 2>&1 | head -50); then
        if echo "$response" | grep -q "tools"; then
            log_success "获取工具列表成功 ✓"
            
            # 解析工具列表
            local tools
            tools=$(echo "$response" | jq -r '.result.tools[]?.name' 2>/dev/null)
            
            if [ -n "$tools" ]; then
                echo -e "\n${CYAN}可用工具:${NC}"
                local count=0
                while IFS= read -r tool; do
                    ((count++))
                    echo "  $count. $tool"
                    
                    # 获取工具描述
                    local desc
                    desc=$(echo "$response" | jq -r ".result.tools[] | select(.name==\"$tool\") | .description" 2>/dev/null)
                    if [ -n "$desc" ] && [ "$desc" != "null" ]; then
                        echo "     $desc"
                    fi
                done <<< "$tools"
                
                log_info "共发现 $count 个工具"
            else
                log_warning "未找到工具"
            fi
        else
            log_error "无法获取工具列表"
        fi
    else
        log_error "请求失败"
    fi
}

# 调用工具
call_tool() {
    local server_path="$1"
    local tool_name="$2"
    
    log_section "调用工具"
    log_info "服务器: $server_path"
    log_info "工具: $tool_name"
    
    local cmd
    if [[ "$server_path" =~ \.js$ ]]; then
        cmd="node $server_path"
    elif [[ "$server_path" =~ \.py$ ]]; then
        cmd="python3 $server_path"
    else
        cmd="$server_path"
    fi
    
    # 构建调用请求
    local call_request
    if [ -n "$PARAMS" ]; then
        call_request="{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"$tool_name\",\"arguments\":$PARAMS}}"
    else
        call_request="{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"$tool_name\",\"arguments\":{}}}"
    fi
    
    log_info "发送调用请求..."
    
    local response
    if response=$(echo "$call_request" | timeout "$TIMEOUT" bash -c "$cmd" 2>&1 | head -100); then
        if echo "$response" | grep -q "jsonrpc"; then
            log_success "工具调用成功 ✓"
            
            echo -e "\n${CYAN}响应结果:${NC}"
            echo "$response" | jq '.' 2>/dev/null || echo "$response"
        else
            log_error "调用失败"
            echo "$response"
        fi
    else
        log_error "请求超时或失败"
    fi
}

# 发现常见 MCP 服务器
discover_servers() {
    log_section "MCP 服务器发现"
    log_info "搜索常见的 MCP 服务器实现...\n"
    
    local servers=(
        " filesystem|@modelcontextprotocol/server-filesystem|官方文件系统服务器"
        " github|@modelcontextprotocol/server-github|GitHub API 集成"
        " postgres|@modelcontextprotocol/server-postgres|PostgreSQL 数据库"
        " sqlite|@modelcontextprotocol/server-sqlite|SQLite 数据库"
        " puppeteer|@modelcontextprotocol/server-puppeteer|浏览器自动化"
        " brave-search|@modelcontextprotocol/server-brave-search|Brave 搜索"
    )
    
    echo -e "${CYAN}官方 MCP 服务器:${NC}"
    for server in "${servers[@]}"; do
        IFS='|' read -r name pkg desc <<< "$server"
        printf "  %-15s ${BLUE}%s${NC}\n    %s\n\n" "$name" "$pkg" "$desc"
    done
    
    echo -e "${CYAN}社区热门 MCP 服务器:${NC}"
    echo "  • ahujasid/blender-mcp    - Blender 3D 集成"
    echo "  • githehart/mcp-ollama    - Ollama 本地模型"
    echo "  • adhikary-parthiv/mcp-tavily - Tavily 搜索"
    echo "  • harshavardhan-b20/mcp-tmdb - TMDB 电影数据"
    
    log_info "使用 npm install -g <package> 安装官方服务器"
}

# 详细检查服务器
inspect_server() {
    local server_path="$1"
    
    log_section "服务器详细检查"
    log_info "检查: $server_path"
    
    # 文件信息
    if [ -f "$server_path" ]; then
        log_success "文件存在 ✓"
        log_info "文件大小: $(stat -f%z "$server_path" 2>/dev/null || stat -c%s "$server_path" 2>/dev/null | numfmt --to=iec)"
        log_info "修改时间: $(stat -f%Sm "$server_path" 2>/dev/null || stat -c%y "$server_path" 2>/dev/null)"
        
        # 检查 shebang
        if head -1 "$server_path" | grep -q "^#!"; then
            local shebang
            shebang=$(head -1 "$server_path")
            log_info "Shebang: $shebang"
        fi
    fi
    
    # 测试基本连接
    test_local_server "$server_path"
    
    # 列出工具
    list_tools "$server_path"
}

# 生成测试报告
generate_report() {
    local server_path="$1"
    local report_file="mcp-test-report-$(date +%Y%m%d-%H%M%S).md"
    
    log_section "生成测试报告"
    log_info "报告文件: $report_file"
    
    {
        echo "# MCP 服务器测试报告"
        echo ""
        echo "**测试时间**: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**服务器**: $server_path"
        echo "**测试工具**: MCP Quick Tester v${VERSION}"
        echo ""
        echo "## 基本信息"
        echo ""
        echo "| 属性 | 值 |"
        echo "|------|-----|"
        echo "| 文件名 | $(basename "$server_path") |"
        echo "| 路径 | $(dirname "$server_path") |"
        
        if [ -f "$server_path" ]; then
            echo "| 文件大小 | $(stat -f%z "$server_path" 2>/dev/null || stat -c%s "$server_path" 2>/dev/null | numfmt --to=iec) |"
            echo "| 权限 | $(ls -l "$server_path" | awk '{print $1}') |"
        fi
        echo ""
        echo "## 测试结果"
        echo ""
    } > "$report_file"
    
    # 运行测试并捕获输出
    if test_local_server "$server_path" >> "$report_file" 2>&1; then
        echo "" >> "$report_file"
        echo "✅ **整体状态**: 通过" >> "$report_file"
    else
        echo "" >> "$report_file"
        echo "❌ **整体状态**: 失败" >> "$report_file"
    fi
    
    log_success "报告生成完成: $report_file"
}

# 主函数
main() {
    check_dependencies
    
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    local command="$1"
    shift
    
    parse_args "$@"
    
    # 移除已解析的参数，保留位置参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--transport|-T|--timeout|-e|--env|-v|--verbose|-j|--json|--params)
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    case "$command" in
        test)
            if [ $# -eq 0 ]; then
                log_error "请指定服务器路径"
                usage
                exit 1
            fi
            test_local_server "$1"
            ;;
        test-remote)
            if [ $# -eq 0 ]; then
                log_error "请指定服务器 URL"
                usage
                exit 1
            fi
            test_remote_server "$1"
            ;;
        validate)
            if [ $# -eq 0 ]; then
                log_error "请指定配置文件"
                usage
                exit 1
            fi
            validate_config "$1"
            ;;
        list-tools)
            if [ $# -eq 0 ]; then
                log_error "请指定服务器路径"
                usage
                exit 1
            fi
            list_tools "$1"
            ;;
        call)
            if [ $# -lt 2 ]; then
                log_error "请指定服务器路径和工具名称"
                usage
                exit 1
            fi
            call_tool "$1" "$2"
            ;;
        discover)
            discover_servers
            ;;
        inspect)
            if [ $# -eq 0 ]; then
                log_error "请指定服务器路径"
                usage
                exit 1
            fi
            inspect_server "$1"
            ;;
        report)
            if [ $# -eq 0 ]; then
                log_error "请指定服务器路径"
                usage
                exit 1
            fi
            generate_report "$1"
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            log_error "未知命令: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
