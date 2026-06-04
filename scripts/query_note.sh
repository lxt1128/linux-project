#!/bin/bash
# 导入异常处理模块
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCEPTION_HANDLER_PATH="$SCRIPT_DIR/exception_handler.sh"

if [ -f "$EXCEPTION_HANDLER_PATH" ]; then
    source "$EXCEPTION_HANDLER_PATH"
else
    echo "警告: exception_handler.sh 未找到，跳过异常处理"
fi
# ============================================
# 错题检索模块
# 用法：./query_note.sh -s 数学
# ============================================

# 仓库根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="${REPO_ROOT}/data/subjects"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助
show_help() {
    echo "错题检索工具"
    echo ""
    echo "用法: ./query_note.sh [选项] [参数]"
    echo ""
    echo "选项:"
    echo "  -s, --subject   按科目搜索"
    echo "  -t, --tag       按标签搜索"
    echo "  -d, --date      按日期搜索 (格式: 2026-05-24)"
    echo "  -k, --keyword   按关键词搜索 (在题干中搜索)"
    echo "  -l, --list      列出所有科目"
    echo "  -h, --help      显示帮助"
    echo ""
    echo "示例:"
    echo "  ./query_note.sh -s 数学"
    echo "  ./query_note.sh -t 基础概念"
    echo "  ./query_note.sh -d 2026-05-24"
    echo "  ./query_note.sh -k 加法"
    echo "  ./query_note.sh -l"
}

# 从 MD 文件中提取字段（去掉可能的多余空格）
extract_field() {
    grep "^$2:" "$1" | head -1 | sed 's/^[^:]*: //' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# 提取题干（第一行 # 开头的内容）
extract_question() {
    grep "^# " "$1" | head -1 | sed 's/^# //'
}

# 获取科目名（从文件路径中提取，路径格式：data/subjects/数学/xxx/xxx.md）
get_subject_from_path() {
    local file_path=$1
    # 找到 data/subjects/ 后面的第一级目录名
    echo "$file_path" | sed 's|.*/data/subjects/||' | cut -d'/' -f1
}

# 列出所有科目
list_subjects() {
    echo "📚 所有科目列表"
    echo "========================================="
    for subject_dir in "$DATA_DIR"/*; do
        if [ -d "$subject_dir" ]; then
            subject=$(basename "$subject_dir")
            count=$(find "$subject_dir" -name "*.md" 2>/dev/null | wc -l)
            echo "  $subject ($count 道错题)"
        fi
    done
}

# 按科目搜索
search_by_subject() {
    local subject=$1
    local subject_dir="$DATA_DIR/$subject"
    
    if [ ! -d "$subject_dir" ]; then
        echo "❌ 没有找到科目: $subject"
        echo "使用 -l 查看所有科目"
        return
    fi
    
    echo "🔍 搜索科目: $subject"
    echo "========================================="
    
    find "$subject_dir" -name "*.md" | while read -r file; do
        local id=$(extract_field "$file" "id")
        local tags=$(extract_field "$file" "tags")
        local create_time=$(extract_field "$file" "create_time")
        local status=$(extract_field "$file" "review_status")
        local question=$(extract_question "$file")
        
        echo "📝 [ID: $id] $question"
        echo "   标签: $tags | 时间: $create_time | 状态: $status"
        echo "-----------------------------------------"
    done
}

# 按标签搜索
search_by_tag() {
    local tag=$1
    echo "🔍 搜索标签: $tag"
    echo "========================================="
    
    find "$DATA_DIR" -name "*.md" | while read -r file; do
        local tags=$(extract_field "$file" "tags")
        if echo "$tags" | grep -q "$tag"; then
            local id=$(extract_field "$file" "id")
            local subject=$(get_subject_from_path "$file")
            local question=$(extract_question "$file")
            local create_time=$(extract_field "$file" "create_time")
            
            echo "📝 [ID: $id] $question"
            echo "   科目: $subject | 时间: $create_time"
            echo "-----------------------------------------"
        fi
    done
}

# 按日期搜索
search_by_date() {
    local date=$1
    echo "🔍 搜索日期: $date"
    echo "========================================="
    
    find "$DATA_DIR" -name "*.md" | while read -r file; do
        local create_time=$(extract_field "$file" "create_time")
        if echo "$create_time" | grep -q "$date"; then
            local id=$(extract_field "$file" "id")
            local subject=$(get_subject_from_path "$file")
            local tags=$(extract_field "$file" "tags")
            local question=$(extract_question "$file")
            
            echo "📝 [ID: $id] $question"
            echo "   科目: $subject | 标签: $tags"
            echo "-----------------------------------------"
        fi
    done
}

# 按关键词搜索
search_by_keyword() {
    local keyword=$1
    echo "🔍 搜索关键词: $keyword"
    echo "========================================="
    
    find "$DATA_DIR" -name "*.md" | while read -r file; do
        if grep -q "$keyword" "$file"; then
            local id=$(extract_field "$file" "id")
            local subject=$(get_subject_from_path "$file")
            local question=$(extract_question "$file")
            
            echo "📝 [ID: $id] $question"
            echo "   科目: $subject"
            echo "-----------------------------------------"
        fi
    done
}

# 主程序
case $1 in
    -s|--subject)
        search_by_subject "$2"
        ;;
    -t|--tag)
        search_by_tag "$2"
        ;;
    -d|--date)
        search_by_date "$2"
        ;;
    -k|--keyword)
        search_by_keyword "$2"
        ;;
    -l|--list)
        list_subjects
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "❌ 未知选项: $1"
        echo "使用 -h 查看帮助"
        ;;
esac
