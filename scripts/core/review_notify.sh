#!/bin/bash
# review_notify.sh
# 每日随机抽取 1 道当天需要复习的错题
# 复习间隔遵循艾宾浩斯曲线：1 2 4 7 15 30 天

# 从 MD 文件中提取字段（和检索模块统一规则）
extract_field() {
    grep "^$2:" "$1" | head -1 | sed 's/^[^:]*: //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# 导入异常处理模块和配置
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXCEPTION_HANDLER_PATH="$SCRIPT_DIR/exception_handler.sh"
CONFIG_PATH="$SCRIPT_DIR/../../config/global.conf"

# 检查 exception_handler.sh 文件是否存在
if [ -f "$EXCEPTION_HANDLER_PATH" ]; then
    source "$EXCEPTION_HANDLER_PATH"
else
    echo "Error: exception_handler.sh not found at $EXCEPTION_HANDLER_PATH"
    exit 1
fi

# 加载配置
if [ -f "$CONFIG_PATH" ]; then
    source "$CONFIG_PATH"
else
    echo "Error: Config file not found at $CONFIG_PATH"
    exit 1
fi

# 定位仓库根目录（脚本位于 scripts/core/）
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# 内部固定路径
REVIEW_LOG="$REPO_ROOT/data/logs/review.log"
DATA_DIR="$REPO_ROOT/data"
SUBJECTS_DIR="$DATA_DIR/subjects"

# 若目录不存在则自动创建
mkdir -p "$(dirname "$REVIEW_LOG")"

# ===== 复习间隔常量 =====
INTERVALS=(1 2 4 7 15 30)

# 计算下一复习间隔天数
get_next_review() {
    local id="$1"
    local count=0

    # 检查日志文件是否存在
    if [ -f "$REVIEW_LOG" ]; then
        # 安全获取复习次数，确保结果是数字
        local temp_count
        temp_count=$(grep -c -- "$id" "$REVIEW_LOG" 2>/dev/null)

        # 验证结果是否为数字，如果不是则设为0
        if [[ "$temp_count" =~ ^[0-9]+$ ]]; then
            count=$temp_count
        else
            count=0
        fi
    fi

    # 检查INTERVALS数组是否存在且不为空
    if [ -z "${INTERVALS+x}" ] || [ ${#INTERVALS[@]} -eq 0 ]; then
        # 如果数组不存在或为空，使用默认间隔
        INTERVALS=(1 7 30 90 180 365)  # 1天, 1周, 1月, 3月, 6月, 1年
    fi

    # 计算数组长度和当前索引
    local total_intervals=${#INTERVALS[@]}
    local current_idx

    if (( count >= total_intervals )); then
        current_idx=$(( total_intervals - 1 ))
    else
        current_idx=$count
    fi

    # 确保索引在有效范围内
    if (( current_idx < 0 )); then
        current_idx=0
    elif (( current_idx >= total_intervals )); then
        current_idx=$(( total_intervals - 1 ))
    fi

    # 返回对应的间隔天数
    echo "${INTERVALS[$current_idx]}"
}

# 判断今天是否需要复习该题
needs_review() {
    local id=$1
    # 先判断有没有该id的记录，没有就直接返回需要复习
    if ! grep -q -- "$id" "$REVIEW_LOG"; then
        return 0
    fi
    local last_date
    last_date=$(grep "$id" "$REVIEW_LOG" | tail -1 | awk '{print $1}' | sed 's/\[//; s/\]//')

    # 确保 last_date 是有效的日期格式
    if ! date -d "$last_date" +%F > /dev/null 2>&1; then
        echo "Error: Invalid date '$last_date'"
        return 0
    fi

    local next_review_date
    local interval=$(get_next_review "$id")
    if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid interval '$interval'"
        return 0
    fi

    next_review_date=$(date -d "$last_date + $interval days" +%F)
    [[ $(date +%F) == "$next_review_date" ]] && return 0
    return 1
}

# 更新Markdown文件中的复习状态和次数
update_markdown_file() {
    local file="$1"
    local status="$2" 
    local count="$3"
    
    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist" >&2
        return 1
    fi
    
    # 更新复习状态
    sed -i.bak "s/^review_status:.*/review_status: $status/" "$file" && rm -f "$file.bak"
    # 更新复习次数  
    sed -i.bak "s/^review_count:.*/review_count: $count/" "$file" && rm -f "$file.bak"
}

# ===== 主流程 =====
# 收集所有错题
mapfile -t candidates < <(find "$DATA_DIR/subjects" -type f -name "*.md")

to_review=()
for f in "${candidates[@]}"; do
    id=$(extract_field "$f" "id")
    if needs_review "$id"; then
        to_review+=("$f")
    fi
done

# 没有需要复习的题目
if [ ${#to_review[@]} -eq 0 ]; then
    msg="[$(date '+%F %T')] No questions to review today"
    echo "$msg" | tee -a "$REVIEW_LOG"
    xmessage -center "No questions to review today"
    return 0
fi

# 随机挑选 1 道
choice=${to_review[$RANDOM % ${#to_review[@]}]}
echo "[$(date '+%F %T')] Review today: $(basename "$choice")" >> "$REVIEW_LOG"
subject_name=$(basename "$choice" .md)
xmessage -center "Review today: $subject_name"

# 复习打卡功能
read -p "Have you finished reviewing? (y/n): " completed
if [[ $completed == "y" ]]; then
    echo "[$(date '+%F %T')] Finished reviewing: $(basename "$choice")" >> "$REVIEW_LOG"
    xmessage -center "Finished reviewing: $subject_name"
    echo "✅ Checked"

    # 读取Markdown文件，更新复习状态和次数
    review_status=$(grep "review_status" "$choice" | awk '{print $2}' | tr -d '"')
    review_count=$(grep "review_count" "$choice" | awk '{print $2}' | tr -d '"')

    if [[ -z "$review_status" || -z "$review_count" ]]; then
        echo "Error: Unable to read review status or count from $choice"
    else
        # 验证review_count是数字，如果不是则设置为0
        if ! [[ "$review_count" =~ ^[0-9]+$ ]]; then
            review_count=0
        fi
        
        if [[ "$review_status" == "未复习" ]]; then
            new_status="已复习"
            review_count=$((review_count + 1))
        else
            new_status="已复习"
            review_count=$((review_count + 1))
        fi

        # 更新Markdown文件
        update_markdown_file "$choice" "$new_status" "$review_count"
    fi
else
    echo "[$(date '+%F %T')] Not finished reviewing: $subject_name" >> "$REVIEW_LOG"
    xmessage -center "Not finished reviewing: $subject_name"
fi
