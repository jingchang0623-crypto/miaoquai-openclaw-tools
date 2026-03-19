#!/usr/bin/env python3
"""
Miaoquai SEO Page Generator
批量生成妙趣AI网站的SEO优化页面

Usage:
    python seo_page_generator.py --type tools --count 10
    python seo_page_generator.py --type glossary --terms RAG,LLM,Transformer
"""

import argparse
import os
from datetime import datetime
from pathlib import Path

# 网站基础配置
SITE_NAME = "妙趣AI"
SITE_URL = "https://miaoquai.com"
SITE_TAGLINE = "AI工具导航 + 资讯平台"

# HTML 模板
HTML_TEMPLATE = '''<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} | {site_name}</title>
    <meta name="description" content="{description}">
    <meta name="keywords" content="{keywords}">
    <meta name="author" content="{site_name}">
    <meta name="robots" content="index, follow">
    <link rel="canonical" href="{canonical_url}">
    
    <!-- Open Graph -->
    <meta property="og:title" content="{title} | {site_name}">
    <meta property="og:description" content="{description}">
    <meta property="og:type" content="article">
    <meta property="og:url" content="{canonical_url}">
    <meta property="og:site_name" content="{site_name}">
    
    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{title} | {site_name}">
    <meta name="twitter:description" content="{description}">
    
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
        }}
        
        header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1rem 2rem;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        
        nav {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1200px;
            margin: 0 auto;
        }}
        
        .logo {{
            font-size: 1.5rem;
            font-weight: bold;
            text-decoration: none;
            color: white;
        }}
        
        .nav-links {{
            display: flex;
            gap: 2rem;
            list-style: none;
        }}
        
        .nav-links a {{
            color: white;
            text-decoration: none;
            transition: opacity 0.3s;
        }}
        
        .nav-links a:hover {{
            opacity: 0.8;
        }}
        
        main {{
            max-width: 900px;
            margin: 2rem auto;
            padding: 0 1rem;
        }}
        
        article {{
            background: white;
            border-radius: 12px;
            padding: 2rem;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        }}
        
        h1 {{
            font-size: 2.2rem;
            margin-bottom: 1rem;
            color: #1a1a2e;
        }}
        
        .meta {{
            color: #666;
            font-size: 0.9rem;
            margin-bottom: 1.5rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid #eee;
        }}
        
        .content {{
            line-height: 1.8;
        }}
        
        .content h2 {{
            margin: 2rem 0 1rem;
            color: #1a1a2e;
        }}
        
        .content p {{
            margin-bottom: 1rem;
        }}
        
        .content ul {{
            margin-left: 1.5rem;
            margin-bottom: 1rem;
        }}
        
        .content li {{
            margin-bottom: 0.5rem;
        }}
        
        .content a {{
            color: #667eea;
            text-decoration: none;
        }}
        
        .content a:hover {{
            text-decoration: underline;
        }}
        
        .tag {{
            display: inline-block;
            background: #f0f0ff;
            color: #667eea;
            padding: 0.3rem 0.8rem;
            border-radius: 20px;
            font-size: 0.85rem;
            margin-right: 0.5rem;
        }}
        
        .cta-box {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 1.5rem;
            border-radius: 12px;
            margin: 2rem 0;
            text-align: center;
        }}
        
        .cta-box a {{
            color: white;
            font-weight: bold;
        }}
        
        footer {{
            text-align: center;
            padding: 2rem;
            color: #666;
            margin-top: 2rem;
        }}
        
        footer a {{
            color: #667eea;
        }}
    </style>
</head>
<body>
    <header>
        <nav>
            <a href="/" class="logo">🦞 {site_name}</a>
            <ul class="nav-links">
                <li><a href="/ai-news.html">AI新闻</a></li>
                <li><a href="/tools/">工具导航</a></li>
                <li><a href="/glossary/">术语百科</a></li>
                <li><a href="/stories/">踩坑实录</a></li>
            </ul>
        </nav>
    </header>
    
    <main>
        <article>
            <h1>{title}</h1>
            <div class="meta">
                <span>📅 {date}</span>
                <span> | </span>
                <span>🏷️ {category}</span>
            </div>
            <div class="content">
                {content}
            </div>
        </article>
    </main>
    
    <footer>
        <p>© {year} {site_name} - <a href="{site_url}">{site_url}</a></p>
        <p style="margin-top: 0.5rem; font-size: 0.85rem;">
            🦞 让AI营销变得有趣！
        </p>
    </footer>
</body>
</html>
'''

# 工具页面模板
TOOL_TEMPLATE = '''
<p>{description}</p>

<h2>功能特点</h2>
<ul>
{features}
</ul>

<h2>使用方法</h2>
<p>{usage}</p>

<h2>优缺点分析</h2>
<h3>优点</h3>
<ul>
{pros}
</ul>

<h3>缺点</h3>
<ul>
{cons}
</ul>

<h2>适用场景</h2>
<p>{scenarios}</p>

<h2>相关推荐</h2>
<p>如果你喜欢这个工具，还可以看看：</p>
<ul>
{related}
</ul>

<div class="cta-box">
    <p>🚀 发现更多AI工具？访问 <a href="{site_url}/tools/">{site_name} 工具导航</a></p>
</div>
'''

# 术语页面模板
GLOSSARY_TEMPLATE = '''
<p>{definition}</p>

<h2>通俗理解</h2>
<p style="background: #f8f9fa; padding: 1rem; border-left: 4px solid #667eea; margin: 1rem 0;">
{simple_explanation}
</p>

<h2>技术细节</h2>
<p>{technical_details}</p>

<h2>应用场景</h2>
<ul>
{applications}
</ul>

<h2>相关概念</h2>
<p>{related_concepts}</p>

<h2>学习资源</h2>
<ul>
{resources}
</ul>

<div class="cta-box">
    <p>📚 想了解更多AI术语？查看 <a href="{site_url}/glossary/">{site_name} 术语百科</a></p>
</div>
'''


def generate_tool_page(name, data):
    """生成工具详情页"""
    features = "\n".join([f"    <li>{f}</li>" for f in data.get("features", [])])
    pros = "\n".join([f"    <li>{p}</li>" for p in data.get("pros", [])])
    cons = "\n".join([f"    <li>{c}</li>" for c in data.get("cons", [])])
    related = "\n".join([f'    <li><a href="/tools/{r}.html">{r}</a></li>' for r in data.get("related", [])])
    
    content = TOOL_TEMPLATE.format(
        description=data.get("description", ""),
        features=features,
        usage=data.get("usage", ""),
        pros=pros,
        cons=cons,
        scenarios=data.get("scenarios", ""),
        related=related,
        site_url=SITE_URL,
        site_name=SITE_NAME
    )
    
    html = HTML_TEMPLATE.format(
        title=data.get("title", name),
        site_name=SITE_NAME,
        description=data.get("description", ""),
        keywords=data.get("keywords", f"{name}, AI工具, {SITE_NAME}"),
        canonical_url=f"{SITE_URL}/tools/{name}.html",
        date=datetime.now().strftime("%Y-%m-%d"),
        category="AI工具",
        year=datetime.now().year,
        content=content,
        site_url=SITE_URL
    )
    
    return html


def generate_glossary_page(term, data):
    """生成术语百科页面"""
    applications = "\n".join([f"    <li>{a}</li>" for a in data.get("applications", [])])
    resources = "\n".join([f'    <li><a href="{r["url"]}" target="_blank">{r["title"]}</a></li>' 
                          for r in data.get("resources", [])])
    
    content = GLOSSARY_TEMPLATE.format(
        definition=data.get("definition", ""),
        simple_explanation=data.get("simple_explanation", ""),
        technical_details=data.get("technical_details", ""),
        applications=applications,
        related_concepts=data.get("related_concepts", ""),
        resources=resources,
        site_url=SITE_URL
    )
    
    html = HTML_TEMPLATE.format(
        title=f"什么是{term}？{term}详解",
        site_name=SITE_NAME,
        description=data.get("definition", ""),
        keywords=f"{term}, AI术语, {SITE_NAME}, 机器学习, 人工智能",
        canonical_url=f"{SITE_URL}/glossary/{term.lower()}.html",
        date=datetime.now().strftime("%Y-%m-%d"),
        category="AI术语",
        year=datetime.now().year,
        content=content,
        site_url=SITE_URL
    )
    
    return html


def main():
    parser = argparse.ArgumentParser(description="Miaoquai SEO Page Generator")
    parser.add_argument("--type", choices=["tools", "glossary"], required=True, help="页面类型")
    parser.add_argument("--output", default="/var/www/miaoquai", help="输出目录")
    parser.add_argument("--count", type=int, default=5, help="生成数量（示例数据）")
    
    args = parser.parse_args()
    
    print(f"🦞 {SITE_NAME} SEO Page Generator")
    print(f"📁 输出目录: {args.output}")
    print(f"📄 页面类型: {args.type}")
    print()
    
    # 示例数据
    sample_tools = {
        "chatgpt-guide": {
            "title": "ChatGPT 完全指南",
            "description": "ChatGPT是最流行的AI对话助手，由OpenAI开发。本指南带你全面了解ChatGPT的使用方法和技巧。",
            "features": ["自然语言对话", "代码生成与调试", "文档写作助手", "多语言支持", "API接口"],
            "usage": "访问 chat.openai.com 注册账号即可使用，或通过API集成到自己的应用中。",
            "pros": ["响应速度快", "理解能力强", "生态系统完善", "持续更新"],
            "cons": ["需要付费订阅高级功能", "知识有截止日期", "有时会生成不准确信息"],
            "scenarios": "客服聊天、内容创作、代码开发、学习辅导",
            "related": ["claude-guide", "gemini-guide"],
            "keywords": "ChatGPT, OpenAI, AI对话, 人工智能助手"
        },
        "openclaw-guide": {
            "title": "OpenClaw 完全指南",
            "description": "OpenClaw是你的个人AI助手，支持多模型、Skills扩展，让AI更懂你的需求。",
            "features": ["多模型支持", "Skills扩展系统", "MCP协议集成", "浏览器控制", "定时任务"],
            "usage": "安装 npm install -g openclaw，然后运行 openclaw start 开始使用。",
            "pros": ["完全开源", "高度可定制", "支持多种AI模型", "活跃的社区"],
            "cons": ["需要一定技术背景", "配置相对复杂"],
            "scenarios": "个人助理、自动化运营、内容生产、数据分析",
            "related": ["chatgpt-guide", "claude-guide"],
            "keywords": "OpenClaw, AI助手, 开源AI, Skills"
        }
    }
    
    sample_glossary = {
        "RAG": {
            "definition": "RAG (Retrieval-Augmented Generation) 检索增强生成，是一种结合检索和生成的AI技术。",
            "simple_explanation": "想象你有一个AI图书管理员，每次你问问题，它会先去书架上找相关的书，然后根据书的内容回答你。这就是RAG的工作原理——先检索相关信息，再生成回答。",
            "technical_details": "RAG结合了信息检索系统和大型语言模型。首先通过向量相似度搜索从知识库中检索相关文档，然后将这些文档作为上下文输入到LLM中，生成更准确的回答。",
            "applications": ["企业知识库问答", "智能客服系统", "法律文档分析", "医疗诊断辅助", "学术研究助手"],
            "related_concepts": "向量数据库、Embedding、语义搜索、知识图谱",
            "resources": [
                {"title": "RAG原论文", "url": "https://arxiv.org/abs/2005.11401"},
                {"title": "LangChain RAG教程", "url": "https://python.langchain.com/docs/tutorials/rag/"}
            ]
        },
        "LLM": {
            "definition": "LLM (Large Language Model) 大型语言模型，是当前AI技术的核心突破之一。",
            "simple_explanation": "LLM就像一个读过全世界书的学生，它能理解你说的任何话，并根据学到的知识回答问题、写文章、甚至写代码。它不是简单的搜索引擎，而是真正'理解'并'创造'内容。",
            "technical_details": "LLM基于Transformer架构，通过海量文本数据训练，学习语言的统计规律和语义理解。参数规模通常在数十亿到数千亿之间，如GPT-4、Claude、Llama等。",
            "applications": ["智能对话助手", "代码生成", "文档摘要", "翻译服务", "内容创作"],
            "related_concepts": "Transformer、注意力机制、预训练、微调、提示工程",
            "resources": [
                {"title": "Attention Is All You Need", "url": "https://arxiv.org/abs/1706.03762"},
                {"title": "HuggingFace NLP课程", "url": "https://huggingface.co/learn/nlp-course"}
            ]
        }
    }
    
    # 生成页面
    output_dir = Path(args.output) / args.type
    output_dir.mkdir(parents=True, exist_ok=True)
    
    count = 0
    if args.type == "tools":
        for name, data in sample_tools.items():
            if count >= args.count:
                break
            html = generate_tool_page(name, data)
            output_file = output_dir / f"{name}.html"
            output_file.write_text(html, encoding="utf-8")
            print(f"✅ 生成: {output_file}")
            count += 1
    
    elif args.type == "glossary":
        for term, data in sample_glossary.items():
            if count >= args.count:
                break
            html = generate_glossary_page(term, data)
            output_file = output_dir / f"{term.lower()}.html"
            output_file.write_text(html, encoding="utf-8")
            print(f"✅ 生成: {output_file}")
            count += 1
    
    print()
    print(f"🎉 完成！共生成 {count} 个页面")
    print(f"📂 目录: {output_dir}")


if __name__ == "__main__":
    main()
