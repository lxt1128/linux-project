#!/bin/bash
# 统一异常处理模块 - 生产级版本

# 日志文件路径（自动创建logs目录）
LOG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." &> /dev/null && pwd )/logs"
LOG_FILE="$LOG_DIR/error.log"
mkdir -p "$LOG_DIR"

# 全局变量防止递归
ERROR_HANDLING_IN_PROGRESS=false

# 核心错误处理函数
handle_error() {
    # 防止递归调用
    if [ "$ERROR_HANDLING_IN_PROGRESS" = true ]; then
        return 1
    fi
    ERROR_HANDLING_IN_PROGRESS=true

    local exit_code=$?
    local failed_command="$BASH_COMMAND"
    local line_number="$LINENO"
    local script_name="$0"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local call_stack=""

    # 获取调用栈信息（可选）
    if [ -n "${FUNCNAME[*]:-}" ]; then
        call_stack="Call stack: ${FUNCNAME[*]}"
    fi

    # 写入错误日志 - 使用原子操作防止损坏
    local temp_log="$LOG_FILE.tmp"
    {
        echo "[$timestamp] ERROR in $script_name (line $line_number):" 
        echo "  Command: $failed_command"
        echo "  Exit code: $exit_code"
        echo "  Working Directory: $(pwd)"
        echo "  User: $(whoami)"
        echo "  Host: $(hostname)"
        echo "  Process ID: $$"
        if [ -n "$call_stack" ]; then
            echo "  $call_stack"
        fi
        echo "  ----------------------------------------"
    } > "$temp_log"
    
    # 原子性移动日志文件
    mv "$temp_log" "$LOG_FILE" 2>/dev/null || true

    # 给用户友好提示
    echo "❌ 脚本执行出错！"
    echo "  错误详情已记录到：$LOG_FILE"
    echo "  请查看日志排查问题"
    echo "  错误命令：$failed_command (第 $line_number 行)"

    # 重置标志
    ERROR_HANDLING_IN_PROGRESS=false
    
    exit $exit_code
}

# 捕获错误信号
trap 'handle_error' ERR

# 开启严格模式（推荐的安全选项）
set -o nounset  # 使用未定义变量时报错
set -o pipefail # 管道中任何命令失败，整个管道返回失败

# 可选：只在特定情况下启用 errexit
# if [ "${SAFE_MODE:-false}" = true ]; then
#     set -o errexit
# fi
