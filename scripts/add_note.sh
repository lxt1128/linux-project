#!/bin/bash
# 全场景错题管理系统 错题录入模块
# 刘瑞婷 2026-05-24

# 自动定位项目根目录
PROJECT_ROOT=$(cd "$(dirname "$0")/../../" && pwd)
export PROJECT_ROOT

# 导入异常处理模块
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
EXCEPTION_HANDLER_PATH="$SCRIPT_DIR/exception_handler.sh"

# 检查异常处理模块是否存在
if [ -f "$EXCEPTION_HANDLER_PATH" ]; then
    source "$EXCEPTION_HANDLER_PATH"
else
    echo "Error: exception_handler.sh not found at $EXCEPTION_HANDLER_PATH"
    exit 1
fi


# 加载通用工具函数
source "$PROJECT_ROOT/scripts/utils/common.sh"

echo "====================================="
echo "        错题录入系统"
echo "====================================="
echo ""

# 步骤1：选择科目
echo "请选择科目（输入对应序号）："
source ../../config/global.conf
for i in "${!SUBJECTS[@]}"; do
    echo "$((i+1)). ${SUBJECTS[$i]}"
done
echo ""

# 读取用户输入的科目序号
read -p "请输入序号: " subject_idx
# 计算数组索引（用户输入从1开始，数组从0开始）
subject=${SUBJECTS[$((subject_idx-1))]}

# 校验科目是否合法
if ! validate_subject "$subject"; then
    log "ERROR" "用户输入了无效的科目序号: $subject_idx"
    echo "❌ 错误：无效的科目序号！"
    exit 1
fi

log "INFO" "用户选择了科目: $subject"

# 步骤2：输入错题详细信息
echo ""
read -p "请输入错题题干: " question
# 非空校验
if [ -z "$question" ]; then
    log "ERROR" "用户输入了空的题干"
    echo "❌ 错误：题干不能为空！"
    exit 1
fi

read -p "请输入正确答案: " answer
# 非空校验
if [ -z "$answer" ]; then
    log "ERROR" "用户输入了空的答案"
    echo "❌ 错误：答案不能为空！"
    exit 1
fi

read -p "请输入解析过程: " analysis
read -p "请输入错误标签（多个用逗号分隔，如: 概念不清,计算错误）: " tags

# 步骤2.5：重复录入检测
if check_duplicate "$subject" "$question"; then
    echo ""
    read -p "⚠️ 检测到相似错题，是否继续录入？(y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log "INFO" "用户取消了重复错题的录入"
        echo "已取消录入"
        exit 0
    fi
    log "INFO" "用户确认继续录入重复错题"
fi

# 步骤3：生成唯一ID和存储路径
# 顺序自增ID：1、2、3、4...
ID_FILE="../../data/id_counter.txt"
# 如果文件不存在，初始化为1
if [ ! -f "$ID_FILE" ]; then
  echo 1 > "$ID_FILE"
fi
# 读取当前ID
id=$(cat "$ID_FILE")
# 自增+1，保存回去
next_id=$((id + 1))
echo $next_id > "$ID_FILE"
timestamp=$(date +%Y%m%d_%H%M%S)
# 按科目/年/月/日分层存储
date_dir=$(date +%Y/%m/%d)
save_dir="../../data/subjects/$subject/$date_dir"
# 自动创建存储目录（如果不存在）
mkdir -p $save_dir
file_path="$save_dir/${id}_${timestamp}.md"

# 步骤4：写入Markdown格式的错题文件
cat > $file_path << EOF
---
id: $id
subject: $subject
tags: $tags
create_time: $(date '+%Y-%m-%d %H:%M:%S')
update_time: $(date '+%Y-%m-%d %H:%M:%S')
review_status: 未复习
review_count: 0
---

## 题干
$question

## 正确答案
$answer

## 解析
$analysis

## 错误原因
EOF

# 步骤5：记录日志并提示成功
log "INFO" "成功录入错题，ID: $id，存储路径: $file_path"
echo ""
echo "✅ 错题录入成功！"
echo "📌 错题ID: $id"
echo "📂 存储位置: $file_path"
