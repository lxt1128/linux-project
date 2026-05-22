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

