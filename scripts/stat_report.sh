#!/bin/bash
set +u

# 导入异常处理模块
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCEPTION_HANDLER_PATH="$SCRIPT_DIR/exception_handler.sh"

if [ -f "$EXCEPTION_HANDLER_PATH" ]; then
    source "$EXCEPTION_HANDLER_PATH"
else
    echo "警告: exception_handler.sh 未找到，跳过异常处理"
fi

# 自动获取仓库根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="${REPO_ROOT}/data/subjects"

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 显示帮助
show_help() {
    echo "错题统计分析工具"
    echo "用法: ./stat_report.sh [选项]"
    echo "选项:"
    echo "  --subject   仅查看科目统计"
    echo "  --tag       仅查看知识点频率"
    echo "  --weak      仅查看薄弱点分析"
    echo "  -h, --help  显示帮助"
}

# 1. 科目统计（带条形图）
stats_subject() {
    echo -e "${GREEN}📊 各科目错题数量统计${NC}"
    echo "========================================="
    
    tmp_file=$(mktemp)
    find "$DATA_DIR" -name "*.md" 2>/dev/null | sed 's|.*/data/subjects/||' | cut -d'/' -f1 | sort | uniq -c > "$tmp_file"
    
    if [ ! -s "$tmp_file" ]; then
        echo "暂无数据"
        rm -f "$tmp_file"
        return
    fi
    
    max=$(awk '{print $1}' "$tmp_file" | sort -rn | head -1)
    
    while read cnt subject; do
        if [ $max -le 20 ]; then
            bar_len=$cnt
        else
            bar_len=$(( cnt * 20 / max ))
        fi
        [ $bar_len -eq 0 ] && bar_len=1
        bar=$(printf "%${bar_len}s" | tr ' ' '█')
        printf "%-8s %3d  %s\n" "$subject" "$cnt" "$bar"
    done < "$tmp_file"
    
    total=$(awk '{sum+=$1} END {print sum}' "$tmp_file")
    echo "-----------------------------------------"
    echo -e "📝 总计: ${YELLOW}${total}${NC} 道错题"
    rm -f "$tmp_file"
}

# 2. 知识点频率统计
stats_tag() {
    echo -e "${GREEN}🏷️ 知识点错误频率统计 (Top 5)${NC}"
    echo "========================================="
    
    tmp_file=$(mktemp)
    find "$DATA_DIR" -name "*.md" 2>/dev/null -exec grep "^tags: " {} \; | sed 's/^tags: //' | tr ',' '\n' | sed 's/^ //' | sort | uniq -c | sort -rn | head -5 > "$tmp_file"
    
    if [ ! -s "$tmp_file" ]; then
        echo "暂无数据"
        rm -f "$tmp_file"
        return
    fi
    
    rank=1
    while read cnt tag; do
        echo "$rank. $tag (错 $cnt 次)"
        rank=$((rank + 1))
    done < "$tmp_file"
    rm -f "$tmp_file"
}

# 3. 薄弱点分析
stats_weak() {
    echo -e "${RED}⚠️ 薄弱知识点分析${NC}"
    echo "========================================="
    
    top_tag=$(find "$DATA_DIR" -name "*.md" 2>/dev/null -exec grep "^tags: " {} \; | sed 's/^tags: //' | tr ',' '\n' | sed 's/^ //' | sort | uniq -c | sort -rn | head -1)
    
    if [ -z "$top_tag" ]; then
        echo "暂无数据"
        return
    fi
    
    cnt=$(echo "$top_tag" | awk '{print $1}')
    tag=$(echo "$top_tag" | awk '{print $2}')
    
    total=$(find "$DATA_DIR" -name "*.md" 2>/dev/null | wc -l)
    if [ $total -eq 0 ]; then
        echo "暂无数据"
        return
    fi
    
    percent=$(( cnt * 100 / total ))
    echo -e "🔥 最薄弱知识点: ${RED}${tag}${NC}"
    echo "   错误次数: $cnt 次 (占比 ${percent}%)"
    echo -e "   建议: 优先复习 ${YELLOW}${tag}${NC} 相关知识"
}

case ${1:-""} in
    --subject)
        stats_subject
        ;;
    --tag)
        stats_tag
        ;;
    --weak)
        stats_weak
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "未知选项，使用 -h 查看帮助"
        ;;
esac
