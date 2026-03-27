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

### 9. Cron 任务管理器 ✨ NEW
管理和监控 OpenClaw 定时任务的完整工具。

```bash
# 列出所有任务
./cron-manager.sh list

# 健康检查
./cron-manager.sh health

# 查看日志
./cron-manager.sh logs [job_id]

# 查看执行历史
./cron-manager.sh history <job_id>

# 导出配置
./cron-manager.sh export backup.json

# 立即执行任务
./cron-manager.sh run <job_id>
```

### 9. OpenClaw 生态系统监控器 ✨ NEW
监控与OpenClaw相关的开源项目和Skills生态，发现新机会。

```bash
# 运行生态监控
./ecosystem-monitor.sh

# 输出Markdown报告
# ./ecosystem-reports/ecosystem-report-YYYY-MM-DD_HHMMSS.md
```

**监控项目包括**:
- volcengine/OpenViking - OpenClaw专用上下文数据库
- obra/superpowers - Agentic Skills框架
- langchain-ai/open-swe - 异步编码Agent
- shareAI-lab/learn-claude-code - Claude Code学习资源

### 10. Skills 模板生成器 ✨ NEW
快速创建符合规范的OpenClaw Skills模板。

```bash
# 生成SEO优化Skills
./skill-template-generator.sh seo-optimizer \
  --category marketing \
  --description "SEO优化分析工具"

# 生成博客写作Skills
./skill-template-generator.sh blog-writer \
  --category productivity
```

**支持分类**: marketing, development, productivity, automation, creative, research

### 11. Skills 效果分析器 ✨ NEW
分析 Skills 使用效果，提供优化建议和评分。

```bash
# 完整分析（生成 Markdown 报告）
./skill-performance-analyzer.sh

# 快速统计
./skill-performance-analyzer.sh -t quick

# 分析 trending 项目
./skill-performance-analyzer.sh -t trending

# JSON 格式输出
./skill-performance-analyzer.sh -o json

# 报告输出位置
# ./skill-reports/skill-analysis-YYYY-MM-DD_HHMMSS.md
```

**分析维度**:
- SKILL.md 完整度
- README 文档质量
- 工具清单配置
- 代码行数统计
- 综合评分 (0-100)

### 12. Agent 框架对比器 ✨ NEW (2026-03-25)
比较 OpenClaw 与 DeerFlow、ruflo、Claude Code 等 AI Agent 框架的功能差异。

```bash
# 输出完整对比表格
./agent-framework-comparator.sh -t

# 对比 DeerFlow
./agent-framework-comparator.sh -c deer-flow

# 对比 ruflo
./agent-framework-comparator.sh -c ruflo

# 智能推荐
./agent-framework-comparator.sh -r
```

**今日 Trending 发现** 🔥:
- 🦌 **bytedance/deer-flow** - SuperAgent harness (42,987 ⭐, +4,319 today)
- 🌊 **ruvnet/ruflo** - Claude 多Agent编排平台 (24,982 ⭐)
- 📰 **mvanhorn/last30days-skill** - AI研究技能 (5,443 ⭐)
- 🔷 **hesreallyhim/awesome-claude-code** - Claude Code 技能列表

### 14. GitHub Trending 监控器 ✨ NEW
实时监控 GitHub Trending 上的 OpenClaw 相关项目，生成每日趋势报告。

```bash
# 运行监控
./trending-monitor.sh

# 报告输出位置
# /var/www/miaoquai/reports/trending-YYYY-MM-DD.md
```

### 15. Skills 使用追踪器 ✨ NEW
追踪本地 OpenClaw Skills 的使用情况，生成使用统计和效果分析报告。

```bash
# 记录技能使用
./skill-usage-tracker.sh track <skill_name> [success|fail]

# 生成使用报告
./skill-usage-tracker.sh report

# 显示统计
./skill-usage-tracker.sh stats

# 报告输出位置
# /var/www/miaoquai/reports/skill-usage-YYYY-MM-DD.md
```

### 16. AI News RSS 聚合器 ✨ NEW (2026-03-27)
自动抓取各大AI源的RSS新闻，生成内容摘要和报告。

```bash
# 抓取所有源 (默认)
./ai-news-rss-fetcher.sh

# 抓取指定源
./ai-news-rss-fetcher.sh openai anthropic

# 列出所有可用源
./ai-news-rss-fetcher.sh list

# 报告输出位置
# /var/www/miaoquai/rss/ai-news-YYYY-MM-DD.md
```

**支持的源**:
- OpenAI Blog
- Anthropic Blog
- Hugging Face Blog
- The Gradient
- MIT Tech Review
- TechCrunch AI
- Wired AI

### 17. 社交媒体内容聚合器 ✨ NEW (2026-03-28)
自动收集 Twitter/X、GitHub 等平台的 OpenClaw 相关内容，生成适合妙趣网站发布的结构化摘要。

```bash
# 运行聚合
./social-media-aggregator.sh run

# 查看配置
./social-media-aggregator.sh config

# 测试连接
./social-media-aggregator.sh test

# 报告输出位置
# /var/www/miaoquai/social/social-YYYY-MM-DD.md
```

**功能特性**:
- GitHub 项目热点追踪
- 社区动态收集
- 自动化 Markdown 报告生成
- 可选 Discord/Webhook 推送

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
├── ecosystem-monitor.sh    # 生态系统监控器 ✨ NEW
├── skill-template-generator.sh  # Skills模板生成器 ✨ NEW
├── cron-manager.sh         # Cron 任务管理器 ✨ NEW
├── agent-framework-comparator.sh  # Agent框架对比器 ✨ NEW
├── trending-monitor.sh            # GitHub Trending 监控器 ✨ NEW
├── skill-usage-tracker.sh        # Skills 使用追踪器 ✨ NEW
├── ai-news-rss-fetcher.sh        # AI News RSS 聚合器 ✨ NEW
├── social-media-aggregator.sh     # 社交媒体内容聚合器 ✨ NEW
├── lib/                    # 共享库
│   ├── github-api.sh       # GitHub API 封装
│   └── logger.sh           # 日志工具
├── config/                 # 配置文件
│   └── settings.conf       # 各种配置
├── ecosystem-reports/      # 生态监控报告输出
└── skill-reports/         # Skills 分析报告
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
