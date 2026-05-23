#!/usr/bin/env bash
# review_notify.sh  2026-05-22
# 依据艾宾浩斯遗忘曲线抽取今日待复习错题
set -euo pipefail

DATA_DIR="$(dirname "$0")/../data"
REVIEW_LOG="$DATA_DIR/logs/review.log"

# 如果目录不存在则创建
mkdir -p "$DATA_DIR/logs"

# 简易版本：随机抽 1 题
note=$(find "$DATA_DIR/subjects" -type f -name "*.txt" | shuf -n1)
if [[ -z $note ]]; then
    echo "暂无错题可复习" | tee -a "$REVIEW_LOG"
    exit 0
fi

echo "[$(date '+%F %T')] 今日复习: $(basename "$note")" >> "$REVIEW_LOG"
cat "$note"
EOF

# 复习间隔（天）
INTERVALS=(1 2 4 7 15 30)

# 读取复习记录，计算下一次复习时间
get_next_review() {
    local id=$1
    local count=$(grep -c "$id" "$REVIEW_LOG" || echo 0)
    local idx=$(( count < ${#INTERVALS[@]} ? count : ${#INTERVALS[@]} - 1 ))
    echo ${INTERVALS[$idx]}
}

# 判断今天是否需要复习某题
needs_review() {
    local id=$1
    local last_date=$(grep "$id" "$REVIEW_LOG" | tail -1 | awk '{print $1}')
    if [[ -z $last_date ]]; then
        return 0    # 从未复习过
    fi
    local next=$(date -d "$last_date +$(get_next_review "$id") days" +%F)
    [[ $(date +%F) == "$next" ]]
}

# 过滤待复习题目
mapfile -t candidates < <(find "$DATA_DIR/subjects" -type f -name "*.txt")
to_review=()
for f in "${candidates[@]}"; do
    id=$(basename "$f" .txt)
    needs_review "$id" && to_review+=("$f")
done

if ((${#to_review[@]} == 0)); then
    echo "今日无待复习错题" | tee -a "$REVIEW_LOG"
    exit 0
fi

choice=${to_review[$RANDOM % ${#to_review[@]} ]}
echo "[$(date '+%F %T')] 今日复习: $(basename "$choice")" >> "$REVIEW_LOG"
cat "$choice"
