#!/bin/bash
# 全场景错题管理系统 错题批量导入模块

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
echo "        错题批量导入系统"
echo "====================================="
echo ""

# 步骤1：获取导入文件路径
echo "请选择导入格式："
echo "1. 单行格式 (标题|题干|答案|解析|错误原因|科目|标签)"
echo "2. Markdown格式 (.md文件)"
echo "3. TXT格式 (标题:内容,题干:内容,答案:内容,解析:内容,错误原因:内容,科目:内容,标签:内容)"
echo ""

read -p "请输入格式序号 (1-3): " format_type

case $format_type in
    1) format_desc="单行格式" ;;
    2) format_desc="Markdown格式" ;;
    3) format_desc="TXT格式" ;;
    *) 
        log "ERROR" "用户输入了无效的格式序号: $format_type"
        echo "❌ 错误：无效的格式序号！"
        exit 1
        ;;
esac

log "INFO" "用户选择了导入格式: $format_desc"

# 步骤2：输入文件路径
echo ""
read -p "请输入要导入的文件路径: " file_path

# 检查文件是否存在
if [ ! -f "$file_path" ]; then
    log "ERROR" "导入文件不存在: $file_path"
    echo "❌ 错误：文件不存在！"
    exit 1
fi

# 检查文件大小
file_size=$(stat -c%s "$file_path")
if [ $file_size -gt 52428800 ]; then  # 50MB限制
    log "ERROR" "导入文件过大: $file_path (${file_size} bytes)"
    echo "❌ 错误：文件过大（超过50MB），请分割文件后再导入！"
    exit 1
fi

log "INFO" "用户选择了导入文件: $file_path (大小: ${file_size} bytes)"

# 步骤3：解析不同格式的文件
parse_and_import() {
    local file_path="$1"
    local format_type="$2"
    local imported_count=0
    local failed_count=0
    
    case $format_type in
        1)  # 单行格式：标题|题干|答案|解析|错误原因|科目|标签
            while IFS= read -r line; do
                # 跳过空行和注释行
                if [ -z "$line" ] || [[ $line =~ ^[[:space:]]*# ]]; then
                    continue
                fi
                
                # 分割字段
                IFS='|' read -r title question answer analysis reason subject tags <<< "$line"
                
                # 非空校验
                if [ -z "$title" ] || [ -z "$question" ] || [ -z "$answer" ]; then
                    log "WARNING" "跳过无效行: $line"
                    ((failed_count++))
                    continue
                fi
                
                # 设置默认值
                subject=${subject:-"数学"}
                tags=${tags:-"通用"}
                analysis=${analysis:-""}
                reason=${reason:-""}
                
                # 创建错题
                create_question "$title" "$question" "$answer" "$analysis" "$reason" "$subject" "$tags"
                if [ $? -eq 0 ]; then
                    ((imported_count++))
                else
                    ((failed_count++))
                fi
            done < "$file_path"
            ;;
        2)  # Markdown格式
            # 读取整个文件内容
            local content
            content=$(cat "$file_path")
            
            # 使用正则表达式提取信息
            local title question answer analysis reason subject tags
            title=$(echo "$content" | grep -oP '^#[[:space:]]+\K.*' | head -1)
            question=$(echo "$content" | grep -oP '^##[[:space:]]+题干[:：]\K.*' | head -1)
            answer=$(echo "$content" | grep -oP '^##[[:space:]]+答案[:：]\K.*' | head -1)
            analysis=$(echo "$content" | grep -oP '^##[[:space:]]+解析[:：]\K.*' | head -1)
            reason=$(echo "$content" | grep -oP '^##[[:space:]]+错误原因[:：]\K.*' | head -1)
            subject=$(echo "$content" | grep -oP '^###[[:space:]]+科目[:：]\K.*' | head -1)
            tags=$(echo "$content" | grep -oP '^###[[:space:]]+标签[:：]\K.*' | head -1)
            
            # 设置默认值
            title=${title:-"未命名题目"}
            analysis=${analysis:-""}
            reason=${reason:-""}
            subject=${subject:-"数学"}
            tags=${tags:-"通用"}
            
            if [ -n "$question" ] && [ -n "$answer" ]; then
                create_question "$title" "$question" "$answer" "$analysis" "$reason" "$subject" "$tags"
                if [ $? -eq 0 ]; then
                    ((imported_count++))
                else
                    ((failed_count++))
                fi
            else
                log "ERROR" "Markdown格式解析失败: $file_path"
                ((failed_count++))
            fi
            ;;
        3)  # TXT格式
            # 读取整个文件内容
            local content
            content=$(cat "$file_path")
            
            # 提取信息
            local title question answer analysis reason subject tags
            title=$(echo "$content" | grep -oP '^标题[:：]\K.*' | head -1)
            question=$(echo "$content" | grep -oP '^题干[:：]\K.*' | head -1)
            answer=$(echo "$content" | grep -oP '^答案[:：]\K.*' | head -1)
            analysis=$(echo "$content" | grep -oP '^解析[:：]\K.*' | head -1)
            reason=$(echo "$content" | grep -oP '^错误原因[:：]\K.*' | head -1)
            subject=$(echo "$content" | grep -oP '^科目[:：]\K.*' | head -1)
            tags=$(echo "$content" | grep -oP '^标签[:：]\K.*' | head -1)
            
            # 设置默认值
            title=${title:-"未命名题目"}
            analysis=${analysis:-""}
            reason=${reason:-""}
            subject=${subject:-"数学"}
            tags=${tags:-"通用"}
            
            if [ -n "$question" ] && [ -n "$answer" ]; then
                create_question "$title" "$question" "$answer" "$analysis" "$reason" "$subject" "$tags"
                if [ $? -eq 0 ]; then
                    ((imported_count++))
                else
                    ((failed_count++))
                fi
            else
                log "ERROR" "TXT格式解析失败: $file_path"
                ((failed_count++))
            fi
            ;;
    esac
    
    echo ""
    echo "📊 导入统计："
    echo "  成功导入: $imported_count 题"
    echo "  导入失败: $failed_count 题"
    
    if [ $failed_count -gt 0 ]; then
        log "WARNING" "批量导入完成，但有 $failed_count 项失败"
    else
        log "INFO" "批量导入完成，共导入 $imported_count 题"
    fi
}

# 创建单个错题的函数
create_question() {
    local title="$1"
    local question="$2" 
    local answer="$3"
    local analysis="$4"
    local reason="$5"
    local subject="$6"
    local tags="$7"
    
    # 验证必填字段
    if [ -z "$question" ] || [ -z "$answer" ]; then
        return 1
    fi
    
    # 校验科目
    if ! validate_subject "$subject"; then
        subject="数学"  # 默认科目
    fi
    
    # 步骤4：生成唯一ID和存储路径
    ID_FILE="$PROJECT_ROOT/data/id_counter.txt"
    if [ ! -f "$ID_FILE" ]; then
        echo 1 > "$ID_FILE"
    fi
    id=$(cat "$ID_FILE")
    next_id=$((id + 1))
    echo $next_id > "$ID_FILE"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    date_dir=$(date +%Y/%m/%d)
    save_dir="$PROJECT_ROOT/data/subjects/$subject/$date_dir"
    mkdir -p $save_dir
    file_path="$save_dir/${id}_${timestamp}.md"
    
    # 步骤5：写入Markdown格式的错题文件
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



## 题目标题
$title

## 题干
$question

## 正确答案
$answer

## 解析
$analysis

## 错误原因
$reason

EOF

    log "INFO" "成功导入错题，ID: $id，存储路径: $file_path"
    return 0
}

# 步骤4：开始导入
echo ""
echo "开始导入文件: $file_path"
echo "导入格式: $format_desc"
echo "预计导入数量: $(wc -l < "$file_path") 行"
echo ""

read -p "确认开始导入？(y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log "INFO" "用户取消了批量导入操作"
    echo "已取消导入"
    exit 0
fi

log "INFO" "开始批量导入错题，文件: $file_path，格式: $format_desc"

# 执行导入
parse_and_import "$file_path" "$format_type"

echo ""
echo "✅ 批量导入完成！"
