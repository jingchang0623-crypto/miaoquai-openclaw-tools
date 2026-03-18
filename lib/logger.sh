#!/bin/bash
# 日志工具库

# 日志目录
LOG_DIR="${LOG_DIR:-/var/log/miaoquai}"
mkdir -p "$LOG_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    local message="$1"
    local log_file="${2:-$LOG_DIR/miaoquai.log}"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $message" | tee -a "$log_file"
}

log_success() {
    local message="$1"
    local log_file="${2:-$LOG_DIR/miaoquai.log}"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${GREEN}SUCCESS${NC}] $message" | tee -a "$log_file"
}

log_warning() {
    local message="$1"
    local log_file="${2:-$LOG_DIR/miaoquai.log}"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${YELLOW}WARNING${NC}] $message" | tee -a "$log_file"
}

log_error() {
    local message="$1"
    local log_file="${2:-$LOG_DIR/miaoquai.log}"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${RED}ERROR${NC}] $message" | tee -a "$log_file"
}

# 创建每日日志文件
get_daily_log() {
    echo "$LOG_DIR/miaoquai-$(date +%Y-%m-%d).log"
}
