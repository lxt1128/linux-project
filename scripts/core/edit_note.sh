#!/bin/bash
# 全场景错题管理系统 错题编辑模块
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

# 检查参数是否正确
if [ $# -ne 1 ]; then
    echo "用法: ./edit_note.sh <错题ID>"
    echo "示例: ./edit_note.sh 1779605817579"
    exit 1
fi

id=$1
echo "正在查找ID为 $id 的错题..."

# 全局搜索该ID的错题文件
file_path=$(find ../../data/subjects -name "*${id}_*.md" -type f | head -n 1)

if [ -z "$file_path" ]; then
    log "ERROR" "未找到ID为 $id 的错题"
    echo "❌ 错误：未找到ID为 $id 的错题"
    exit 1
fi

echo "✅ 找到错题: $file_path"
echo ""

# 步骤1：备份原文件（版本控制）
revision_dir="../../data/revisions/$id"
mkdir -p $revision_dir
revision_file="$revision_dir/$(date +%Y%m%d_%H%M%S).bak"
cp $file_path $revision_file
log "INFO" "备份错题 $id 到 $revision_file"
echo "📌 已自动备份当前版本到: $revision_file"
echo ""

# 步骤2：显示当前错题信息
echo "=== 当前错题信息 ==="
# 提取并显示元数据
grep -E "^(id|subject|tags|create_time|update_time):" $file_path
echo ""

# 步骤3：选择要修改的字段
echo "请选择要修改的字段（输入对应序号）："
echo "1. 题干"
echo "2. 正确答案"
echo "3. 解析"
echo "4. 错误标签"
echo "5. 查看历史版本"
echo "6. 取消修改"
echo ""

read -p "请输入序号: " field_idx

case $field_idx in
    1)
        read -p "请输入新的题干: " new_content
        # 使用sed替换题干部分
        sed -i "/## 题干/,/## 正确答案/c\## 题干\n$new_content\n\n## 正确答案" $file_path
        log "INFO" "修改了错题 $id 的题干"
        ;;
    2)
        read -p "请输入新的正确答案: " new_content
        sed -i "/## 正确答案/,/## 解析/c\## 正确答案\n$new_content\n\n## 解析" $file_path
        log "INFO" "修改了错题 $id 的答案"
        ;;
    3)
        read -p "请输入新的解析: " new_content
        sed -i "/## 解析/,/## 错误原因/c\## 解析\n$new_content\n\n## 错误原因" $file_path
        log "INFO" "修改了错题 $id 的解析"
        ;;
    4)
        read -p "请输入新的错误标签: " new_content
        # 修改元数据中的tags字段
        sed -i "s/tags: .*/tags: $new_content/" $file_path
        log "INFO" "修改了错题 $id 的标签"
        ;;
    5)
        echo ""
        echo "=== 历史版本列表 ==="
        ls -1 $revision_dir | sort -r
        echo ""
        read -p "输入要回退的版本文件名（或按回车取消）: " version
        if [ -n "$version" ] && [ -f "$revision_dir/$version" ]; then
            cp "$revision_dir/$version" $file_path
            log "INFO" "错题 $id 已回退到版本 $version"
            echo "✅ 版本回退成功！"
        else
            echo "已取消回退"
        fi
        exit 0
        ;;
    6)
        echo "已取消修改"
        exit 0
        ;;
    *)
        log "ERROR" "用户输入了无效的字段序号: $field_idx"
        echo "❌ 错误：无效的序号！"
        exit 1
        ;;
esac

# 步骤4：更新update_time字段
sed -i "s/update_time: .*/update_time: $(date '+%Y-%m-%d %H:%M:%S')/" $file_path

# 步骤5：提示成功
echo ""
echo "✅ 错题修改成功！"
echo "📌 原版本已备份，可通过选项5回退"
