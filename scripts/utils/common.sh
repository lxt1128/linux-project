#!/bin/bash
# 全场景错题管理系统 通用工具函数库

# 设置项目根目录（如果未设置）
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    export PROJECT_ROOT
fi

# 函数1：生成唯一错题ID（使用递增计数器，更实用）
generate_id() {
    local counter_file="$PROJECT_ROOT/data/id_counter.txt"
    
    # 确保计数器文件存在
    if [ ! -f "$counter_file" ]; then
        echo 1 > "$counter_file"
    fi
    
    # 读取当前ID，然后递增
    local current_id=$(cat "$counter_file")
    local next_id=$((current_id + 1))
    echo "$next_id" > "$counter_file"
    
    echo "$current_id"
}

# 函数2：统一日志记录函数
log() {
    local level=$1
    local message=$2
    local log_file="$PROJECT_ROOT/data/logs/system.log"
    
    # 确保日志目录存在
    mkdir -p "$(dirname "$log_file")"
    
    # 自动创建日志文件（如果不存在）
    touch "$log_file"
    
    # 写入日志，格式：[时间] [级别] 消息
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$log_file"
}

# 函数3：校验科目是否合法
validate_subject() {
    local subject=$1
    
    # 加载全局配置
    if [ -f "$PROJECT_ROOT/config/global.conf" ]; then
        source "$PROJECT_ROOT/config/global.conf"
    else
        # 如果配置文件不存在，使用默认科目
        SUBJECTS=("数学" "语文" "英语" "物理" "化学" "生物" "历史" "地理" "政治")
    fi
    
    # 遍历科目列表进行匹配
    for s in "${SUBJECTS[@]}"; do
        if [ "$s" = "$subject" ]; then
            return 0  # 0表示成功，科目合法
        fi
    done
    return 1  # 1表示失败，科目不合法
}

# 函数4：检测错题是否重复（基于题干相似度）
check_duplicate() {
    local subject=$1
    local question=$2
    local search_dir="$PROJECT_ROOT/data/subjects/$subject"

    # 如果该科目还没有任何错题，直接返回不重复
    if [ ! -d "$search_dir" ]; then
        return 1
    fi

    # 遍历该科目下所有的MD错题文件
    for file in $(find "$search_dir" -name "*.md" -type f); do
        # 提取文件中的题干部分
        # 查找"## 题干"行，然后提取直到下一个"##"行之前的内容
        local file_question=$(awk '
        /^## 题干/ { flag=1; next }
        /^##/ && flag { flag=0; next }
        flag { print }
        ' "$file" | tr -d '\n' | xargs)

        # 比较题干是否相同（忽略大小写和前后空格）
        if [ "$(echo "$file_question" | tr '[:upper:]' '[:lower:]')" = "$(echo "$question" | tr '[:upper:]' '[:lower:]')" ]; then
            return 0  # 0表示存在重复
        fi
    done

    return 1  # 1表示无重复
}

# 函数5：从 MD 文件中提取字段
extract_field() {
    local file=$1
    local field=$2
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    grep "^$field:" "$file" | head -1 | sed 's/^[^:]*: //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# 函数6：获取时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 函数7：创建错题文件名（安全化处理）
sanitize_filename() {
    local name=$1
    # 替换非法字符，保留字母数字中文下划线
    echo "$name" | sed 's/[^a-zA-Z0-9_\u4e00-\u9fa5]/_/g'
}

# 函数8：检查文件是否存在
file_exists() {
    local file=$1
    [ -f "$file" ]
}

# 函数9：检查目录是否存在
dir_exists() {
    local dir=$1
    [ -d "$dir" ]
}

# 函数10：创建目录（如果不存在）
ensure_dir() {
    local dir=$1
    mkdir -p "$dir"
}

# 函数11：获取所有科目列表
get_all_subjects() {
    local subjects_dir="$PROJECT_ROOT/data/subjects"
    if [ -d "$subjects_dir" ]; then
        find "$subjects_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    fi
}

# 函数12：获取某科目下的所有错题ID
get_subject_notes() {
    local subject=$1
    local subject_dir="$PROJECT_ROOT/data/subjects/$subject"
    
    if [ -d "$subject_dir" ]; then
        find "$subject_dir" -name "*.md" -exec basename {} .md \; | sort -n
    fi
}

# 函数13：验证错题ID是否有效
validate_note_id() {
    local subject=$1
    local id=$2
    local note_file="$PROJECT_ROOT/data/subjects/$subject/${id}.md"
    
    [ -f "$note_file" ]
}

# 函数14：发送桌面通知
send_notification() {
    local title=$1
    local message=$2
    
    # 检查是否有图形界面
    if [ -n "$DISPLAY" ]; then
        if command -v notify-send &> /dev/null; then
            notify-send "$title" "$message" --urgency=normal --expire-time=5000
        elif command -v xmessage &> /dev/null; then
            xmessage -center "$title: $message" &
        fi
    fi
}

# 函数15：获取用户输入（带默认值）
get_user_input() {
    local prompt=$1
    local default=$2
    local input
    
    if [ -n "$default" ]; then
        read -p "$prompt (默认: $default): " input
        input=${input:-$default}
    else
        read -p "$prompt: " input
    fi
    
    echo "$input"
}

# 函数16：确认操作
confirm_action() {
    local message=$1
    local response
    
    read -p "$message (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 函数17：显示进度条
show_progress() {
    local current=$1
    local total=$2
    local width=30
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r["
    for ((i=0; i<filled; i++)); do
        printf "="
    done
    for ((i=filled; i<width; i++)); do
        printf " "
    done
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# 函数18：计算字符串长度（支持中文）
str_length() {
    local str="$1"
    # 使用 wc -m 并减去换行符
    echo "${#str}"
}

# 函数19：截取字符串（支持中文）
str_substring() {
    local str="$1"
    local start=$2
    local length=$3
    
    echo "${str:$start:$length}"
}

# 函数20：格式化数字（如：1 -> 001）
format_number() {
    local num=$1
    local width=${2:-3}
    
    printf "%0${width}d" "$num"
}

# 函数21：备份文件
backup_file() {
    local file=$1
    local backup_dir="$PROJECT_ROOT/data/backups"
    
    if [ -f "$file" ]; then
        ensure_dir "$backup_dir"
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        local backup_name="${file}.bak_${timestamp}"
        cp "$file" "$backup_name"
        log INFO "已备份文件: $file -> $backup_name"
    fi
}

# 函数22：恢复文件
restore_file() {
    local file=$1
    local backup_dir="$PROJECT_ROOT/data/backups"
    local latest_backup=$(ls -t "$backup_dir/$(basename "$file").bak_"* 2>/dev/null | head -n 1)
    
    if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        cp "$latest_backup" "$file"
        log INFO "已恢复文件: $latest_backup -> $file"
        return 0
    else
        log ERROR "未找到备份文件: $file"
        return 1
    fi
}

# 函数23：清理临时文件
cleanup_temp() {
    local temp_dir="$PROJECT_ROOT/data/temp"
    if [ -d "$temp_dir" ]; then
        find "$temp_dir" -type f -mtime +7 -delete  # 删除7天前的临时文件
        log INFO "已清理临时文件"
    fi
}

# 函数24：检查磁盘空间
check_disk_space() {
    local path=${1:-"$PROJECT_ROOT"}
    local available=$(df "$path" | tail -1 | awk '{print $4}')
    local min_space_mb=100  # 最小可用空间 100MB
    
    if [ "$available" -lt "$min_space_mb" ]; then
        log ERROR "磁盘空间不足: 可用 ${available}KB"
        return 1
    fi
    return 0
}

# 函数25：获取系统信息
get_system_info() {
    echo "系统: $(uname -s)"
    echo "架构: $(uname -m)"
    echo "Shell: $SHELL"
    echo "Bash版本: $BASH_VERSION"
    echo "项目根目录: $PROJECT_ROOT"
}

# 函数26：颜色输出
color_echo() {
    local color=$1
    local message=$2
    
    case $color in
        red)     echo -e "\033[31m$message\033[0m" ;;
        green)   echo -e "\033[32m$message\033[0m" ;;
        yellow)  echo -e "\033[33m$message\033[0m" ;;
        blue)    echo -e "\033[34m$message\033[0m" ;;
        purple)  echo -e "\033[35m$message\033[0m" ;;
        cyan)    echo -e "\033[36m$message\033[0m" ;;
        white)   echo -e "\033[37m$message\033[0m" ;;
        *)       echo "$message" ;;
    esac
}

# 函数27：等待用户按键
wait_for_keypress() {
    echo "按任意键继续..."
    read -n 1 -s
}

# 函数28：清屏
clear_screen() {
    clear
}

# 函数29：检查网络连接
check_network() {
    ping -c 1 -W 1 google.com >/dev/null 2>&1 || ping -c 1 -W 1 baidu.com >/dev/null 2>&1
    return $?
}

# 函数30：获取配置值
get_config_value() {
    local key=$1
    local config_file="$PROJECT_ROOT/config/global.conf"
    
    if [ -f "$config_file" ]; then
        grep "^$key=" "$config_file" | cut -d'=' -f2 | sed 's/"//g'
    else
        # 返回默认值
        case $key in
            DEFAULT_SUBJECT) echo "数学" ;;
            MAX_REVISIONS) echo "5" ;;
            NOTIFICATION_ENABLED) echo "true" ;;
            BACKUP_ENABLED) echo "true" ;;
            REVIEW_INTERVAL_DAYS) echo "1" ;;
            CRON_SCHEDULE) echo "0 9 * * *" ;;
            *) echo "" ;;
        esac
    fi
}

# 初始化日志目录
ensure_dir "$PROJECT_ROOT/data/logs"
ensure_dir "$PROJECT_ROOT/data/subjects"
ensure_dir "$PROJECT_ROOT/data/backups"
ensure_dir "$PROJECT_ROOT/data/temp"

# 确保ID计数器文件存在
if [ ! -f "$PROJECT_ROOT/data/id_counter.txt" ]; then
    echo 1 > "$PROJECT_ROOT/data/id_counter.txt"
fi

log INFO "通用工具函数库加载完成"
