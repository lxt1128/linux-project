#!/bin/bash
# 全场景错题管理系统 - 主启动脚本

set -e

# 设置项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 加载配置和工具
load_modules() {
    if [ -f "$PROJECT_ROOT/config/global.conf" ]; then
        source "$PROJECT_ROOT/config/global.conf"
        log_info "配置文件加载成功"
    else
        log_error "配置文件不存在"
        exit 1
    fi
    
    if [ -f "$PROJECT_ROOT/scripts/utils/common.sh" ]; then
        source "$PROJECT_ROOT/scripts/utils/common.sh"
        log_info "通用工具函数加载成功"
    fi
}

# 显示主菜单
show_menu() {
    clear
    echo "=================================="
    echo "    全场景错题管理系统 v1.0"
    echo "=================================="
    echo "当前时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=================================="
    echo "📝 录入管理："
    echo "  1. 📝 录入错题"
    echo "  2. 📥 批量导入错题"
    echo "  3. ✏️  编辑错题"
    echo ""
    echo "🔧 批量处理："
    echo "  4. 📋 批量修改标签"
    echo "  5. 📤 批量导出错题"
    echo "  6. 🗑️  批量删除错题"
    echo "  7. 🔄 批量重置状态"
    echo "  8. 📝 批量修改错误原因"
    echo "  9. 📊 批量统计分析"
    echo ""
    echo "📚 学习复习："
    echo "  10. 📚 复习错题"
    echo "  11. 📊 统计报告"
    echo ""
    echo "⚙️  系统设置："
    echo "  12. ⏰ 安装定时任务"
    echo "  13. ❓ 帮助信息"
    echo "  14. 🚪 退出系统"
    echo "=================================="
}

# 显示帮助
show_help() {
    clear
    echo "=================================="
    echo "           帮助信息"
    echo "=================================="
    echo "📚 系统功能说明："
    echo "  • 录入错题：添加新的错题记录"
    echo "  • 批量导入：从文件批量导入错题"
    echo "  • 编辑错题：修改现有错题内容"
    echo "  • 批量修改：批量修改标签、错误原因等"
    echo "  • 批量导出：导出指定范围的错题"
    echo "  • 批量删除：删除指定范围的错题"
    echo "  • 批量重置：重置复习状态"
    echo "  • 批量统计：查看学习统计分析"
    echo "  • 复习错题：查看待复习的错题"
    echo "  • 统计报告：查看学习统计数据"
    echo "  • 定时任务：设置自动提醒"
    echo ""
    echo "📁 数据存储："
    echo "  • 错题数据：$PROJECT_ROOT/data/subjects/"
    echo "  • 日志文件：$PROJECT_ROOT/data/logs/"
    echo ""
    echo "按任意键返回主菜单..."
    read -n 1 -s
}

# 显示子菜单
show_batch_menu() {
    clear
    echo "=================================="
    echo "       批量处理子菜单"
    echo "=================================="
    echo "1. 📋 批量修改标签"
    echo "2. 📤 批量导出错题"
    echo "3. 🗑️  批量删除错题"
    echo "4. 🔄 批量重置状态"
    echo "5. 📝 批量修改错误原因"
    echo "6. 📊 批量统计分析"
    echo "7. 🏠 返回主菜单"
    echo "=================================="
}

# 主循环
main_loop() {
    while true; do
        show_menu
        
        read -p "请选择操作 (1-14): " choice
        echo ""
        
        case $choice in
            1) 
                echo "🚀 启动录入模块..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/add_note.sh"
                ;;
            2) 
                echo "📥 启动批量导入模块..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/import_note.sh"
                ;;
            3) 
                read -p "请输入要编辑的错题ID: " id
                "$PROJECT_ROOT/scripts/core/edit_note.sh" "$id"
                ;;
            4) 
                echo "📋 启动批量修改标签..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/batch_process.sh"
                ;;
            5) 
                echo "📤 启动批量导出错题..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/batch_process.sh"
                ;;
            6) 
                echo "🗑️ 启动批量删除错题..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/batch_process.sh"
                ;;
            7) 
                echo "🔄 启动批量重置状态..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/batch_process.sh"
                ;;
            8) 
                echo "📝 启动批量修改错误原因..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/batch_process.sh"
                ;;
            9) 
                echo "📊 启动批量统计分析..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/batch_process.sh"
                ;;
            10) 
                echo "📚 启动复习模块..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/review_notify.sh"
                ;;
            11) 
                echo "📊 启动统计模块..."
                sleep 1
                "$PROJECT_ROOT/scripts/core/stat_report.sh"
                ;;
            12) 
                echo "⏰ 安装定时任务..."
                "$PROJECT_ROOT/scripts/utils/install_cron.sh"
                ;;
            13) 
                show_help
                ;;
            14) 
                echo "👋 感谢使用！再见！"
                exit 0
                ;;
            *) 
                echo "❌ 无效选择，请输入 1-14"
                sleep 2
                ;;
        esac
        
        echo ""
        echo "💡 按任意键返回主菜单，或 Ctrl+C 退出..."
        read -n 1 -s
    done
}

# 主函数
main() {
    echo "=================================="
    echo "    全场景错题管理系统 v2.0"
    echo "=================================="
    echo "启动时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 检查必要目录
    mkdir -p "$PROJECT_ROOT/data/logs" "$PROJECT_ROOT/data/revisions"
    
    # 创建ID计数器文件（如果不存在）
    if [ ! -f "$PROJECT_ROOT/data/id_counter.txt" ]; then
        echo 1 > "$PROJECT_ROOT/data/id_counter.txt"
        log_info "创建ID计数器文件"
    fi
    
    # 加载模块
    load_modules
    
    echo "✅ 系统已就绪！"
    echo "🎉 开始您的高效学习之旅吧！"
    echo ""
    echo "💡 按任意键进入主菜单..."
    read -n 1 -s
    
    # 启动主循环
    main_loop
}

# 运行主函数
main "$@"
