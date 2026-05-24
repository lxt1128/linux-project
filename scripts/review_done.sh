#!/usr/bin/env bash
#review_done.sh 打卡完成复习
DATA_DIR="$(dirname "$0")/../data"
REVIEW_LOG="$DATD_DIR/logs/review.log"
id=$1
[[ -z $id ]] && { echo "用法: $0 <错题id>"; exit 1; }
echo "[$(data '+%F %T')] 已完成复习: $id" >> "$REVIEW_LOG"
echo "✅ 已打卡"
EOF

