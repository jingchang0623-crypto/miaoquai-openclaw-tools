# 🤖 Miaoquai OpenClaw Tools

> 妙趣AI的OpenClaw自动化运营工具集

## 工具列表

### 1. GitHub Trending 监控脚本
自动追踪 OpenClaw 相关的热门项目，帮助发现最新技术和工具。

```bash
# 查看今日 trending
./github-trending.sh
```

### 2. Skill 发现器
从 ClawHub 和 GitHub 自动发现有用的 OpenClaw Skills。

```bash
# 搜索 skills
./skill-discovery.sh "SEO marketing"
```

### 3. 内容生成助手
辅助妙趣AI生成网站内容，包括新闻日报、术语百科等。

```bash
# 生成AI新闻摘要
./content-helper.sh news

# 生成术语解释
./content-helper.sh glossary "RAG"
```

### 4. 自动提交工具
自动化 GitHub 提交流程，支持定时任务。

```bash
# 自动提交更改
./auto-commit.sh "更新内容"
```

### 5. SEO 分析器
分析网页 SEO 优化情况，检查meta、链接等。

```bash
# 分析页面
./seo-analyzer.sh https://miaoquai.com
```

### 6. 每日报告生成器 ✨ NEW
自动生成妙趣AI每日运营报告，包括内容统计、GitHub Trending、网站健康检查等。

```bash
# 生成每日报告
./daily-report.sh

# 报告输出位置
# /var/www/miaoquai/reports/daily-YYYY-MM-DD.md
```

### 7. Skills 健康检查器 ✨ NEW
检查 OpenClaw Skills 的健康状态、配置和安全问题。

```bash
# 运行健康检查
./skill-health.sh
```

### 8. SEO 页面生成器 ✨ NEW
Python工具，批量生成SEO优化的HTML页面（工具详情页、术语百科）。

```bash
# 生成工具页面
python seo_page_generator.py --type tools --count 5

# 生成术语百科
python seo_page_generator.py --type glossary

# 指定输出目录
python seo_page_generator.py --type tools --output /var/www/miaoquai
```

## 安装

```bash
git clone https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools.git
cd miaoquai-openclaw-tools
chmod +x *.sh
```

## 使用示例

### 每日自动化运营

```bash
# 早上自动运行
0 8 * * * /path/to/github-trending.sh >> /var/log/miaoquai/trending.log

# 自动发现新 skills
0 10 * * * /path/to/skill-discovery.sh "AI marketing" >> /var/log/miaoquai/skills.log

# 生成每日报告
0 22 * * * /path/to/daily-report.sh
```

### 内容批量生成

```bash
# 批量生成工具页面
python seo_page_generator.py --type tools --count 10

# 批量生成术语百科
python seo_page_generator.py --type glossary --count 20
```

## 目录结构

```
miaoquai-openclaw-tools/
├── README.md
├── github-trending.sh      # GitHub Trending 监控
├── skill-discovery.sh      # Skill 发现器
├── content-helper.sh       # 内容生成助手
├── auto-commit.sh          # 自动提交工具
├── seo-analyzer.sh         # SEO 分析器
├── daily-report.sh         # 每日报告生成器 ✨
├── skill-health.sh         # Skills 健康检查器 ✨
├── seo_page_generator.py   # SEO 页面生成器 ✨
├── lib/                    # 共享库
│   ├── github-api.sh       # GitHub API 封装
│   └── logger.sh           # 日志工具
└── config/                 # 配置文件
    └── settings.conf       # 各种配置
```

## 依赖

- curl
- jq
- gh (GitHub CLI)
- Coreutils

## 相关项目

- [awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills) - OpenClaw Skills 大全
- [OpenClaw 官方](https://github.com/openclaw/openclaw) - OpenClaw 主仓库

## 网站

- **妙趣AI**: https://miaoquai.com - AI工具导航 + 资讯平台
- **OpenClaw 官方**: https://openclaw.ai - 你的个人AI助手

## 许可证

MIT License

---

🦞 **妙趣AI** - 让AI营销变得有趣！| [miaoquai.com](https://miaoquai.com)
