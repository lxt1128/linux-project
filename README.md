# linux-project 错题本自动化工具
用纯 Bash 脚本把错题按学科分类保存，支持关键字查询与定时复习提醒。

## 功能
1. 按学科分类保存错题
2. 关键词模糊搜索
3. crontab定时复习提醒

## 目录结构
linux-project
├── scripts/ # 可执行脚本
│ ├── add_note.sh # 新增错题
│ ├── query_note.sh # 查询错题
│ └── review_notify.sh
├── tests/ # 单元测试（bats）
├── data/
│ ├── subjects/ # 学科题库文件
│ └── logs/ # 运行日志
└── docs/ # 项目截图、设计文档


## 快速开始
```bash
# 克隆后首次运行
./scripts/add_note.sh 数学 "洛必达法则" "忘记洛必达法则使用条件"
./scripts/query_note.sh 数学 洛必达
依赖
Bash ≥ 4.0
可选：bats（测试框架） sudo apt install bats
测试
bats tests/test_add_note.bats
日志位置
data/logs/review.log 记录每次复习时间戳。

