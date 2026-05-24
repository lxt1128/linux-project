#!/usr/bin/env bash
#exception_handler.sh
set -euo pipefail

LOG_DIR="$(dirname "$0")/../data/logs"
ERR_LOG="$LOG_DIR/error.log"
mkdir -p "$LOG_DIR"

log_error() {
    echo "[$(date '+%F %T')] ERROR: $*" >> "$ERR_LOG"
}

handle() {
    case "$1" in
        "file_not_found")
            log_error "文件不存在: $2"
            ;;
        "permission_denied")
            log_error "权限不足: $2"
            ;;
        "invalid_param")
            log_error "参数错误: $2"
            ;;
        *)
            log_error "未知异常: $*"
            ;;
    esac
}

# 如果直接运行脚本，则打印帮助
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "用法: source exception_handler.sh; handle <type> <msg>"
fi
EOF
