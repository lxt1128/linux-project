#!/bin/bash
# 全场景错题管理系统 批量处理模块

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
echo "        批量处理系统"
echo "====================================="
echo ""

# 显示操作菜单
echo "请选择批量处理操作："
echo "1. 批量修改标签"
echo "2. 批量导出错题"
echo "3. 批量删除错题"
echo "4. 批量重置复习状态"
echo "5. 批量修改错误原因"
echo "6. 批量统计分析"
echo ""

read -p "请输入操作序号 (1-6): " operation_type

case $operation_type in
    1) operation_desc="批量修改标签" ;;
    2) operation_desc="批量导出错题" ;;
    3) operation_desc="批量删除错题" ;;
    4) operation_desc="批量重置复习状态" ;;
    5) operation_desc="批量修改错误原因" ;;
    6) operation_desc="批量统计分析" ;;
    *) 
        log "ERROR" "用户输入了无效的操作序号: $operation_type"
        echo "❌ 错误：无效的操作序号！"
        exit 1
        ;;
esac

log "INFO" "用户选择了操作: $operation_desc"

# 获取目标科目
echo ""
echo "请选择操作范围："
echo "1. 所有科目"
source "$PROJECT_ROOT/config/global.conf"
for i in "${!SUBJECTS[@]}"; do
    echo "$((i+2)). ${SUBJECTS[$i]}"
done
echo ""

read -p "请输入科目序号: " subject_idx

if [ "$subject_idx" -eq 1 ]; then
    target_subject="all"
    log "INFO" "用户选择了所有科目"
else
    target_subject=${SUBJECTS[$((subject_idx-2))]}
    if ! validate_subject "$target_subject"; then
        log "ERROR" "用户输入了无效的科目序号: $subject_idx"
        echo "❌ 错误：无效的科目序号！"
        exit 1
    fi
    log "INFO" "用户选择了科目: $target_subject"
fi

# 搜索符合条件的错题文件
find_questions_by_subject() {
    local subject="$1"
    if [ "$subject" = "all" ]; then
        find "$PROJECT_ROOT/data/subjects" -name "*.md" 2>/dev/null | sort
    else
        find "$PROJECT_ROOT/data/subjects/$subject" -name "*.md" 2>/dev/null | sort
    fi
}

# 步骤1：批量修改标签
batch_modify_tags() {
    local subject="$1"
    
    echo ""
    read -p "请输入要修改的原标签: " old_tag
    if [ -z "$old_tag" ]; then
        log "ERROR" "用户输入了空的原标签"
        echo "❌ 错误：原标签不能为空！"
        exit 1
    fi
    
    read -p "请输入新标签: " new_tag
    if [ -z "$new_tag" ]; then
        log "ERROR" "用户输入了空的新标签"
        echo "❌ 错误：新标签不能为空！"
        exit 1
    fi
    
    local files
    files=$(find_questions_by_subject "$subject")
    
    if [ -z "$files" ]; then
        log "WARNING" "在科目 $subject 中未找到错题文件"
        echo "⚠️  在指定科目中未找到错题文件"
        return 1
    fi
    
    local modified_count=0
    local failed_count=0
    
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            # 检查是否包含目标标签
            if grep -q "tags:.*$old_tag" "$file"; then
                # 替换标签
                local temp_file=$(mktemp)
                sed "s/\(tags:.*\)$old_tag\(.*\)/\1$new_tag\2/" "$file" > "$temp_file"
                
                # 如果替换失败，尝试简单替换
                if ! grep -q "tags:.*$new_tag" "$temp_file"; then
                    sed "s/tags: $old_tag/tags: $new_tag/" "$file" > "$temp_file"
                fi
                
                mv "$temp_file" "$file"
                ((modified_count++))
                
                # 记录修改日志
                local id=$(grep -oP 'id: \K\d+' "$file" | head -1)
                log "INFO" "修改错题ID $id 的标签: $old_tag -> $new_tag"
            else
                rm -f "$temp_file"  # 删除临时文件
            fi
        fi
    done <<< "$files"
    
    echo ""
    echo "📊 修改统计："
    echo "  成功修改: $modified_count 题"
    echo "  修改失败: $failed_count 题"
    log "INFO" "批量修改标签完成，修改了 $modified_count 题"
}

# 步骤2：批量导出错题
batch_export_questions() {
    local subject="$1"
    
    echo ""
    read -p "请输入起始ID (回车表示不限制): " start_id
    read -p "请输入结束ID (回车表示不限制): " end_id
    read -p "请输入导出文件名 (默认: export_$(date +%Y%m%d_%H%M%S).md): " export_file
    export_file=${export_file:-"export_$(date +%Y%m%d_%H%M%S).md"}
    
    local files
    files=$(find_questions_by_subject "$subject")
    
    if [ -z "$files" ]; then
        log "WARNING" "在科目 $subject 中未找到错题文件"
        echo "⚠️  在指定科目中未找到错题文件"
        return 1
    fi
    
    # 创建导出文件头部
    echo "# 批量导出错题集" > "$export_file"
    echo "# 导出时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$export_file"
    echo "# 导出科目: $subject" >> "$export_file"
    if [ -n "$start_id" ] && [ -n "$end_id" ]; then
        echo "# ID范围: $start_id - $end_id" >> "$export_file"
    fi
    echo "" >> "$export_file"
    
    local exported_count=0
    local skipped_count=0
    
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            local file_id=$(grep -oP 'id: \K\d+' "$file" | head -1)
            
            # 检查ID范围
            local should_export=true
            if [ -n "$start_id" ] && [ -n "$end_id" ]; then
                if [ "$file_id" -lt "$start_id" ] || [ "$file_id" -gt "$end_id" ]; then
                    should_export=false
                fi
            fi
            
            if [ "$should_export" = true ]; then
                # 添加分隔符和内容
                echo "---" >> "$export_file"
                echo "# 错题ID: $file_id" >> "$export_file"
                echo "" >> "$export_file"
                cat "$file" >> "$export_file"
                echo "" >> "$export_file"
                ((exported_count++))
                
                log "INFO" "导出错题ID: $file_id"
            else
                ((skipped_count++))
            fi
        fi
    done <<< "$files"
    
    echo ""
    echo "📊 导出统计："
    echo "  成功导出: $exported_count 题"
    echo "  已跳过: $skipped_count 题"
    echo "  保存位置: $export_file"
    log "INFO" "批量导出完成，导出 $exported_count 题到 $export_file"
}

# 步骤3：批量删除错题
batch_delete_questions() {
    local subject="$1"
    
    echo ""
    read -p "请输入起始ID (回车表示不限制): " start_id
    read -p "请输入结束ID (回车表示不限制): " end_id
    
    local files
    files=$(find_questions_by_subject "$subject")
    
    if [ -z "$files" ]; then
        log "WARNING" "在科目 $subject 中未找到错题文件"
        echo "⚠️  在指定科目中未找到错题文件"
        return 1
    fi
    
    local to_delete=()
    
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            local file_id=$(grep -oP 'id: \K\d+' "$file" | head -1)
            
            # 检查ID范围
            local should_delete=true
            if [ -n "$start_id" ] && [ -n "$end_id" ]; then
                if [ "$file_id" -lt "$start_id" ] || [ "$file_id" -gt "$end_id" ]; then
                    should_delete=false
                fi
            fi
            
            if [ "$should_delete" = true ]; then
                to_delete+=("$file")
            fi
        fi
    done <<< "$files"
    
    if [ ${#to_delete[@]} -eq 0 ]; then
        echo "⚠️  没有找到符合条件的错题"
        return 0
    fi
    
    echo ""
    echo "将要删除以下 ${#to_delete[@]} 个文件："
    for file in "${to_delete[@]}"; do
        local file_id=$(grep -oP 'id: \K\d+' "$file" | head -1)
        local subject_name=$(echo "$file" | sed "s|$PROJECT_ROOT/data/subjects/||" | cut -d'/' -f1)
        echo "  - ID: $file_id, 科目: $subject_name, 路径: $file"
    done
    
    echo ""
    read -p "⚠️  确认删除以上错题？此操作不可撤销！(y/n): " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        log "INFO" "用户取消了批量删除操作"
        echo "已取消删除"
        return 0
    fi
    
    local deleted_count=0
    for file in "${to_delete[@]}"; do
        if rm "$file"; then
            local file_id=$(grep -oP 'id: \K\d+' "$file" | head -1)
            ((deleted_count++))
            log "INFO" "删除错题ID: $file_id"
        fi
    done
    
    echo ""
    echo "📊 删除统计："
    echo "  成功删除: $deleted_count 题"
    log "INFO" "批量删除完成，删除了 $deleted_count 题"
}

# 步骤4：批量重置复习状态
batch_reset_review_status() {
    local subject="$1"
    
    local files
    files=$(find_questions_by_subject "$subject")
    
    if [ -z "$files" ]; then
        log "WARNING" "在科目 $subject 中未找到错题文件"
        echo "⚠️  在指定科目中未找到错题文件"
        return 1
    fi
    
    local reset_count=0
    
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            # 重置复习状态
            sed -i 's/review_status:.*/review_status: 未复习/' "$file"
            sed -i 's/review_count:.*/review_count: 0/' "$file"
            sed -i "s/update_time:.*/update_time: $(date '+%Y-%m-%d %H:%M:%S')/" "$file"
            
            ((reset_count++))
            
            local id=$(grep -oP 'id: \K\d+' "$file" | head -1)
            log "INFO" "重置错题ID $id 的复习状态"
        fi
    done <<< "$files"
    
    echo ""
    echo "📊 重置统计："
    echo "  成功重置: $reset_count 题"
    log "INFO" "批量重置复习状态完成，重置了 $reset_count 题"
}

# 步骤5：批量修改错误原因
batch_modify_reason() {
    local subject="$1"
    
    echo ""
    read -p "请输入要修改的原错误原因: " old_reason
    if [ -z "$old_reason" ]; then
        log "ERROR" "用户输入了空的原错误原因"
        echo "❌ 错误：原错误原因不能为空！"
        exit 1
    fi
    
    read -p "请输入新错误原因: " new_reason
    if [ -z "$new_reason" ]; then
        log "ERROR" "用户输入了空的新错误原因"
        echo "❌ 错误：新错误原因不能为空！"
        exit 1
    fi
    
    local files
    files=$(find_questions_by_subject "$subject")
    
    if [ -z "$files" ]; then
        log "WARNING" "在科目 $subject 中未找到错题文件"
        echo "⚠️  在指定科目中未找到错题文件"
        return 1
    fi
    
    local modified_count=0
    local failed_count=0
    
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            # 检查是否包含目标错误原因
            if grep -q "## 错误原因\s*$old_reason" "$file" || grep -A1 "## 错误原因" "$file" | grep -q "^$old_reason$"; then
                # 替换错误原因
                local temp_file=$(mktemp)
                sed "/## 错误原因/{n;s/^$old_reason$/$new_reason/;}" "$file" > "$temp_file"
                
                mv "$temp_file" "$file"
                ((modified_count++))
                
                # 记录修改日志
                local id=$(grep -oP 'id: \K\d+' "$file" | head -1)
                log "INFO" "修改错题ID $id 的错误原因: $old_reason -> $new_reason"
            else
                rm -f "$temp_file"  # 删除临时文件
            fi
        fi
    done <<< "$files"
    
    echo ""
    echo "📊 修改统计："
    echo "  成功修改: $modified_count 题"
    echo "  修改失败: $failed_count 题"
    log "INFO" "批量修改错误原因完成，修改了 $modified_count 题"
}

# 步骤6：批量统计分析
batch_statistics_analysis() {
    local subject="$1"
    
    local files
    files=$(find_questions_by_subject "$subject")
    
    if [ -z "$files" ]; then
        log "WARNING" "在科目 $subject 中未找到错题文件"
        echo "⚠️  在指定科目中未找到错题文件"
        return 1
    fi
    
    local total_count=0
    local subjects=()
    local tags_all=()
    local review_stats=()
    local date_stats=()
    local reasons_all=()
    
    while IFS= read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            # 统计总数
            ((total_count++))
            
            # 提取科目
            local file_subject=$(grep -oP 'subject: \K.*' "$file" | head -1)
            subjects+=("$file_subject")
            
            # 提取标签
            local tags_line=$(grep -oP 'tags: \K.*' "$file" | head -1)
            if [ -n "$tags_line" ]; then
                IFS=',' read -ra tag_array <<< "$tags_line"
                for tag in "${tag_array[@]}"; do
                    tag=$(echo "$tag" | xargs)  # 去除前后空格
                    if [ -n "$tag" ]; then
                        tags_all+=("$tag")
                    fi
                done
            fi
            
            # 提取复习状态
            local review_status=$(grep -oP 'review_status: \K.*' "$file" | head -1)
            review_stats+=("$review_status")
            
            # 提取创建日期
            local create_date=$(grep -oP 'create_time: \K[0-9]{4}-[0-9]{2}-[0-9]{2}' "$file" | head -1)
            date_stats+=("$create_date")
            
            # 提取错误原因
            local reason=$(awk '/## 错误原因/{getline; print}' "$file" | xargs)
            if [ -n "$reason" ]; then
                reasons_all+=("$reason")
            fi
        fi
    done <<< "$files"
    
    echo ""
    echo "📊 批量统计分析报告"
    echo "==================="
    echo "总错题数量: $total_count"
    echo ""
    
    # 按科目统计
    echo "各科目分布："
    printf '%s\n' "${subjects[@]}" | sort | uniq -c | while read -r count subj; do
        echo "  $subj: $count 题 ($(echo "scale=2; $count * 100 / $total_count" | bc)%)"
    done
    echo ""
    
    # 按标签统计
    echo "知识点标签分布（前10）："
    printf '%s\n' "${tags_all[@]}" | sort | uniq -c | sort -nr | head -10 | while read -r count tag; do
        echo "  $tag: $count 次"
    done
    echo ""
    
    # 按错误原因统计
    echo "错误原因分布（前10）："
    printf '%s\n' "${reasons_all[@]}" | sort | uniq -c | sort -nr | head -10 | while read -r count reason; do
        echo "  $reason: $count 次"
    done
    echo ""
    
    # 按复习状态统计
    echo "复习状态分布："
    printf '%s\n' "${review_stats[@]}" | sort | uniq -c | while read -r count status; do
        echo "  $status: $count 题"
    done
    echo ""
    
    # 按日期统计
    echo "按日期分布（最近7天）："
    printf '%s\n' "${date_stats[@]}" | sort | uniq -c | tail -7 | while read -r count date; do
        echo "  $date: $count 题"
    done
    
    log "INFO" "批量统计分析完成，统计了 $total_count 题"
}

# 执行相应的操作
echo ""
case $operation_type in
    1) batch_modify_tags "$target_subject" ;;
    2) batch_export_questions "$target_subject" ;;
    3) batch_delete_questions "$target_subject" ;;
    4) batch_reset_review_status "$target_subject" ;;
    5) batch_modify_reason "$target_subject" ;;
    6) batch_statistics_analysis "$target_subject" ;;
esac

echo ""
echo "✅ 批量处理完成！"
