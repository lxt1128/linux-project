#!/usr/bin/env bash
# 自动配置crontab定时复习任务安装脚本
# 支持：检查重复任务、自动添加、异常处理、广播通知

# 获取项目根目录绝对路径（兼容软链接调用）
REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REVIEW_SCRIPT="$REPO_ROOT/scripts/core/review_notify.sh"
CRON_LINE="0 8 * * * /bin/bash $REVIEW_SCRIPT | tee | wall"

# 1. 先检查review_notify.sh是否存在
if [ ! -x "$REVIEW_SCRIPT" ]; then
    echo "❌ 错误：找不到可执行的复习脚本 $REVIEW_SCRIPT"
    exit 1
fi

# 2. 检查是否已经存在该任务，避免重复添加
if crontab -l 2>/dev/null | grep -Fq "$REPO_ROOT/scripts/core/review_notify.sh"; then
    echo "ℹ️ 每日复习提醒已经配置过，无需重复安装"
    exit 0
fi

# 3. 添加新的定时任务到当前用户crontab
# 保留原有crontab内容，追加新任务
if (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -; then
    echo "✅ 安装成功！每日 08:00 会自动给所有登录用户推送复习提醒"
    echo "ℹ️ 提醒：如果使用WSL/普通用户环境，建议用sudo执行本脚本保证wall命令正常运行"
    echo "ℹ️ 提醒内容会通过wall命令广播，xmessage弹窗同时保留，双渠道提醒更可靠"
else
    echo "❌ 安装失败：crontab配置错误，请检查权限"
    exit 1
fiin
