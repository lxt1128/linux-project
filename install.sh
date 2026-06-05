#!/bin/bash
# 全场景错题管理系统 - 安装脚本

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_dependencies() {
    log_info "检查系统依赖..."
    local deps=("bash" "grep" "find" "sed" "awk" "xmessage")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing[*]}"
        echo
        echo "安装命令示例:"
        echo "  Ubuntu/Debian: sudo apt update && sudo apt install -y ${missing[*]}"
        echo "  CentOS/RHEL: sudo yum install -y ${missing[*]}"
        echo "  macOS: brew install ${missing[*]}"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 验证项目结构完整性
verify_project_structure() {
    log_info "验证项目结构完整性..."
    
    local required_files=(
        "scripts/core/add_note.sh"
        "scripts/core/edit_note.sh"
        "scripts/core/review_notify.sh"
        "scripts/core/exception_handler.sh"
        "scripts/core/stat_report.sh"
        "scripts/utils/common.sh"
        "scripts/utils/install_cron.sh"
        "config/global.conf"
        "data/id_counter.txt"
        "start.sh"
    )
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        log_error "项目结构不完整，缺少文件:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
    
    log_success "项目结构验证通过"
}

# 设置项目路径
setup_paths() {
    PROJECT_ROOT="$(pwd)"  # 当前工作目录即项目根目录
    export PROJECT_ROOT
    
    log_info "当前项目根目录: $PROJECT_ROOT"
}

# 创建必要的子目录
create_subdirectories() {
    log_info "创建必要子目录..."
    
    local subdirs=(
        "data/subjects"
        "data/logs"
        "scripts/core"
        "scripts/utils"
        "config"
    )
    
    for subdir in "${subdirs[@]}"; do
        mkdir -p "$subdir"
        log_success "创建目录: $subdir"
    done
}

# 设置脚本权限
set_permissions() {
    log_info "设置脚本执行权限..."
    
    # 设置所有 .sh 文件可执行权限
    find . -name "*.sh" -type f -exec chmod +x {} \;
    
    log_success "权限设置完成"
}

# 初始化ID计数器
initialize_id_counter() {
    if [ ! -f "data/id_counter.txt" ]; then
        echo "1" > "data/id_counter.txt"
        log_success "初始化ID计数器: 1"
    else
        local current_id=$(cat "data/id_counter.txt")
        log_info "ID计数器已存在: $current_id"
    fi
}

# 初始化配置文件
initialize_config() {
    if [ ! -f "config/global.conf" ]; then
        cat > "config/global.conf" << 'EOF_CONFIG'
# 全局配置文件
DEFAULT_SUBJECT="数学"
MAX_REVISIONS=5
NOTIFICATION_ENABLED=true
BACKUP_ENABLED=true
REVIEW_INTERVAL_DAYS=1
CRON_SCHEDULE="0 9 * * *"  # 每天上午9点检查
EOF_CONFIG
        log_success "创建默认配置文件"
    else
        log_info "配置文件已存在"
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装完成状态..."
    
    # 检查启动脚本
    if [ -f "./start.sh" ] && [ -x "./start.sh" ]; then
        log_success "启动脚本可用: ./start.sh"
    else
        log_error "启动脚本不可用"
        exit 1
    fi
    
    # 检查核心脚本
    local core_scripts=(
        "scripts/core/add_note.sh"
        "scripts/core/edit_note.sh"
        "scripts/core/review_notify.sh"
        "scripts/core/exception_handler.sh"
        "scripts/core/stat_report.sh"
    )
    
    for script in "${core_scripts[@]}"; do
        if [ -f "./$script" ] && [ -x "./$script" ]; then
            log_success "核心脚本可用: ./$script"
        else
            log_error "核心脚本不可用: ./$script"
            exit 1
        fi
    done
    
    # 检查工具脚本
    local util_scripts=(
        "scripts/utils/common.sh"
        "scripts/utils/install_cron.sh"
    )
    
    for script in "${util_scripts[@]}"; do
        if [ -f "./$script" ] && [ -x "./$script" ]; then
            log_success "工具脚本可用: ./$script"
        else
            log_error "工具脚本不可用: ./$script"
            exit 1
        fi
    done
    
    # 检查数据目录
    if [ -d "./data/subjects" ] && [ -d "./data/logs" ]; then
        log_success "数据目录已准备就绪"
    else
        log_error "数据目录未创建"
        exit 1
    fi
}

# 显示使用说明
show_usage_instructions() {
    echo
    echo -e "${GREEN}🎉 安装完成！${NC}"
    echo "========================="
    echo
    echo -e "${BLUE}🚀 立即开始使用：${NC}"
    echo "   ./start.sh                          # 启动系统主界面"
    echo "   ./scripts/core/add_note.sh         # 直接录入错题"
    echo "   ./scripts/core/review_notify.sh    # 直接复习错题"
    echo "   ./scripts/utils/install_cron.sh    # 安装定时提醒"
    echo
    echo -e "${BLUE}📋 系统状态：${NC}"
    echo "   - 项目目录: $(pwd)"
    echo "   - 数据目录: $(pwd)/data/"
    echo "   - 配置文件: $(pwd)/config/global.conf"
    echo "   - 当前ID计数: $(cat "data/id_counter.txt")"
    echo
    echo -e "${BLUE}📖 项目信息：${NC}"
    echo "   安装时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    echo "========================="
    echo -e "${GREEN}✅ 安装成功！运行 ./start.sh 开始使用！${NC}"
}

# 主函数
main() {
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}   全场景错题管理系统 - 安装程序${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    check_dependencies
    verify_project_structure
    setup_paths
    create_subdirectories
    initialize_id_counter
    initialize_config
    set_permissions
    verify_installation
    show_usage_instructions
}

# 运行主函数
main "$@"
