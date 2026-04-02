#!/usr/bin/env python3
"""
OpenClaw Skill Template Generator 🦞
=====================================
Generate ready-to-use skill templates for OpenClaw

Usage:
    python skill-generator.py --type web-fetch --name my-tool
    python skill-generator.py --type seo-analyzer --name seo-helper
    python skill-generator.py --type content-writer --name blog-writer
"""

import argparse
import os
import json
from datetime import datetime

SKILL_TEMPLATES = {
    "web-fetch": {
        "name": "Web Fetch Skill",
        "description": "Fetch and extract content from URLs",
        "category": "tools",
        "skill_md": """# {name}

_{description}_

## 触发条件

当用户提到以下内容时触发：
- {keywords}

## 功能

1. 访问目标URL并提取内容
2. 解析HTML/Markdown
3. 返回结构化数据

## 使用示例

```
请帮我抓取 https://example.com 的内容
```
""",
        "py_code": '''import requests
from bs4 import BeautifulSoup

class WebFetcher:
    def __init__(self):
        self.session = requests.Session()
    
    def fetch(self, url: str) -> dict:
        """Fetch URL content"""
        response = self.session.get(url, timeout=30)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        return {
            "title": soup.title.string if soup.title else "",
            "content": soup.get_text()[:1000],
            "url": url
        }

# Entry point
def main(url: str):
    fetcher = WebFetcher()
    return fetcher.fetch(url)
'''
    },
    "seo-analyzer": {
        "name": "SEO Analyzer Skill", 
        "description": "Analyze webpage SEO performance",
        "category": "marketing",
        "skill_md": """# {name}

_{description}_

## 触发条件

当用户提到以下内容时触发：
- SEO分析
- 网站优化
- 搜索引擎优化

## 功能

1. 分析页面标题和meta描述
2. 检查关键词密度
3. 评估页面结构
4. 生成优化建议

## 使用示例

```
分析这个页面的SEO: https://example.com
```
""",
        "py_code": '''import re
from urllib.parse import urlparse

class SEOAnalyzer:
    def __init__(self):
        self.issues = []
    
    def analyze(self, html: str, url: str) -> dict:
        """Analyze SEO performance"""
        # Check title
        title_match = re.search(r'<title>([^<]+)</title>', html, re.I)
        title = title_match.group(1) if title_match else None
        
        # Check meta description
        desc_match = re.search(r'<meta[^>]*name=["\']description["\'][^>]*content=["\']([^"\']+)["\']', html, re.I)
        description = desc_match.group(1) if desc_match else None
        
        # Check h1 tags
        h1_count = len(re.findall(r'<h1[^>]*>', html, re.I))
        
        score = 0
        if title: score += 30
        if description: score += 30
        if h1_count == 1: score += 20
        if len(description or "") > 50: score += 20
        
        return {
            "score": score,
            "title": title,
            "description": description,
            "h1_count": h1_count,
            "issues": self.issues,
            "url": url
        }
'''
    },
    "content-writer": {
        "name": "Content Writer Skill",
        "description": "Generate marketing content",
        "category": "marketing",
        "skill_md": """# {name}

_{description}_

## 触发条件

当用户提到以下内容时触发：
- 写文章
- 内容创作
- 营销文案

## 功能

1. 根据主题生成文章大纲
2. 撰写吸引人的标题
3. 创作SEO友好的内容
4. 生成社交媒体文案

## 使用示例

```
帮我写一篇关于AI工具的文章
```
""",
        "py_code": '''import random
from datetime import datetime

class ContentWriter:
    def __init__(self):
        self.templates = {
            "howto": "如何{topic}的5个技巧",
            "review": "{topic}深度测评：优点与不足",
            "news": "{topic}最新动态与行业分析",
            "guide": "{topic}完整使用指南"
        }
    
    def generate_outline(self, topic: str, style: str = "howto") -> dict:
        """Generate article outline"""
        template = self.templates.get(style, self.templates["howto"])
        title = template.format(topic=topic)
        
        outline = [
            f"# {title}",
            f"\n## 引言\\n\\n为什么{topic}值得你关注？",
            "\n## 核心要点",
            "\n## 详细分析",
            "\n## 实战技巧",
            "\n## 总结"
        ]
        
        return {
            "title": title,
            "topic": topic,
            "style": style,
            "outline": "\\n".join(outline),
            "created_at": datetime.now().isoformat()
        }
'''
    },
    "rss-aggregator": {
        "name": "RSS Aggregator Skill",
        "description": "Aggregate and filter RSS feeds",
        "category": "tools",
        "skill_md": """# {name}

_{description}_

## 触发条件

当用户提到以下内容时触发：
- RSS订阅
- 资讯聚合
- 订阅源

## 功能

1. 订阅多个RSS源
2. 过滤关键词
3. 定时获取更新
4. 生成每日简报

## 使用示例

```
帮我订阅AI相关的RSS源
```
""",
        "py_code": '''import feedparser
from datetime import datetime, timedelta
import hashlib

class RSSAggregator:
    def __init__(self):
        self.feeds = {}
        self.entries = []
    
    def add_feed(self, name: str, url: str):
        """Add RSS feed"""
        self.feeds[name] = url
    
    def fetch_all(self, hours: int = 24) -> list:
        """Fetch all feeds"""
        cutoff = datetime.now() - timedelta(hours=hours)
        self.entries = []
        
        for name, url in self.feeds.items():
            try:
                feed = feedparser.parse(url)
                for entry in feed.entries:
                    if hasattr(entry, 'published_parsed'):
                        pub_date = datetime(*entry.published_parsed[:6])
                        if pub_date >= cutoff:
                            self.entries.append({
                                "source": name,
                                "title": entry.title,
                                "link": entry.link,
                                "date": pub_date.isoformat(),
                                "id": hashlib.md5(entry.link.encode()).hexdigest()
                            })
            except Exception as e:
                print(f"Error fetching {name}: {e}")
        
        self.entries.sort(key=lambda x: x["date"], reverse=True)
        return self.entries
    
    def filter_by_keyword(self, keyword: str) -> list:
        """Filter entries by keyword"""
        return [e for e in self.entries if keyword.lower() in e["title"].lower()]
'''
    },
    "image-generator": {
        "name": "Image Generator Skill",
        "description": "Generate images via AI",
        "category": "creative",
        "skill_md": """# {name}

_{description}_

## 触发条件

当用户提到以下内容时触发：
- 生成图片
- AI绘图
- 创作图片

## 功能

1. 文字转图片
2. 风格选择
3. 批量生成
4. 保存和分享

## 使用示例

```
生成一张赛博朋克风格的城市图片
```
""",
        "py_code": '''import json
import base64
from datetime import datetime

class ImageGenerator:
    STYLES = {
        "cyberpunk": "Neon lights, futuristic city, dark background",
        "anime": "Japanese anime style, vibrant colors",
        "realistic": "Photorealistic, detailed, natural lighting",
        "minimalist": "Simple shapes, clean lines, solid colors",
        "watercolor": "Soft edges, flowing colors, artistic"
    }
    
    def __init__(self, api_key: str = None):
        self.api_key = api_key
    
    def generate(self, prompt: str, style: str = "realistic", **kwargs) -> dict:
        """Generate image from prompt"""
        full_prompt = f"{prompt}, {self.STYLES.get(style, '')}"
        
        # Placeholder - integrate with DALL-E/Stable Diffusion
        return {
            "prompt": full_prompt,
            "style": style,
            "width": kwargs.get("width", 1024),
            "height": kwargs.get("height", 1024),
            "created_at": datetime.now().isoformat(),
            "status": "ready"
        }
    
    def list_styles(self) -> list:
        """List available styles"""
        return list(self.STYLES.keys())
'''
    }
}

def generate_skill(name: str, skill_type: str, output_dir: str = ".") -> bool:
    """Generate a skill from template"""
    if skill_type not in SKILL_TEMPLATES:
        print(f"Error: Unknown skill type '{skill_type}'")
        print(f"Available types: {', '.join(SKILL_TEMPLATES.keys())}")
        return False
    
    template = SKILL_TEMPLATES[skill_type]
    skill_name = name.replace(" ", "-").lower()
    
    # Create directory
    skill_dir = os.path.join(output_dir, skill_name)
    os.makedirs(skill_dir, exist_ok=True)
    
    # Generate SKILL.md
    skill_md_content = template["skill_md"].format(
        name=skill_name.replace("-", " ").title(),
        description=template["description"],
        keywords=", ".join([skill_type, name])
    )
    
    with open(os.path.join(skill_dir, "SKILL.md"), "w") as f:
        f.write(skill_md_content)
    
    # Generate Python module
    py_file = skill_name.replace("-", "_") + ".py"
    with open(os.path.join(skill_dir, py_file), "w") as f:
        f.write(template["py_code"])
    
    # Generate config.json
    config = {
        "name": skill_name,
        "display_name": name.replace("-", " ").title(),
        "description": template["description"],
        "category": template["category"],
        "version": "1.0.0",
        "created_at": datetime.now().isoformat()
    }
    
    with open(os.path.join(skill_dir, "config.json"), "w") as f:
        json.dump(config, f, indent=2)
    
    print(f"✅ Generated skill: {skill_name}")
    print(f"   Location: {skill_dir}/")
    return True

def list_skill_types():
    """List all available skill types"""
    print("\n📦 Available Skill Types:")
    print("-" * 40)
    for key, value in SKILL_TEMPLATES.items():
        print(f"  • {key:20} - {value['name']}")
    print()

def main():
    parser = argparse.ArgumentParser(
        description="🦞 OpenClaw Skill Template Generator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python skill-generator.py --type web-fetch --name my-fetcher
  python skill-generator.py --type seo-analyzer --name site-checker  
  python skill-generator.py --type content-writer --name blog-helper
  python skill-generator.py --list
        """
    )
    
    parser.add_argument("--type", "-t", help="Skill type to generate")
    parser.add_argument("--name", "-n", help="Skill name")
    parser.add_argument("--output", "-o", default=".", help="Output directory")
    parser.add_argument("--list", "-l", action="store_true", help="List available skill types")
    
    args = parser.parse_args()
    
    if args.list:
        list_skill_types()
    elif args.type and args.name:
        generate_skill(args.name, args.type, args.output)
    else:
        parser.print_help()
        list_skill_types()

if __name__ == "__main__":
    main()
