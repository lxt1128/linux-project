#!/bin/bash
# 全场景错题管理系统 通用工具函数库
# 刘瑞婷 2026-05-24

# 函数1：生成唯一错题ID（时间戳+随机数，保证全局唯一）
generate_id() {
    # 取当前时间戳（秒级）+ 3位随机数，共13位
    echo "$(date +%s)$(shuf -i 100-999 -n 1)"
}

# 函数2：统一日志记录函数
log() {
    local level=$1
    local message=$2
    local log_file="../../data/logs/system.log"
    
    # 自动创建日志文件（如果不存在）
    touch $log_file
    
    # 写入日志，格式：[时间] [级别] 消息
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> $log_file
}

# 函数3：校验科目是否合法（必须在全局配置的SUBJECTS列表中）
validate_subject() {
    local subject=$1
    # 加载全局配置
    source ../../config/global.conf
    
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
    local search_dir="../../data/subjects/$subject"

    # 如果该科目还没有任何错题，直接返回不重复
    if [ ! -d "$search_dir" ]; then
        return 1
    fi

    # 遍历该科目下所有的Markdown错题文件
    for file in $(find $search_dir -name "*.md" -type f); do
        # 提取文件中的题干部分
        # sed命令：找到"## 题干"和下一个"##"之间的内容
        local file_question=$(sed -n '/## 题干/,/##/p' $file | grep -v "## 题干" | grep -v "##" | tr -d '\n')

        # 比较题干是否相同（忽略前后空格）
	if [ "$(echo "$file_question" | xargs | tr '[:upper:]' '[:lower:]')" = "$(echo "$question" | xargs | tr '[:upper:]' '[:lower:]')" ]; then
            return 0  # 0表示存在重复
        fi
    done

    return 1  # 1表示无重复
}
