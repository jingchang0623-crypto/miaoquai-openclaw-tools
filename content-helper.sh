#!/bin/bash
# 内容生成助手
# 辅助妙趣AI生成网站内容

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 输出目录
OUTPUT_DIR="${OUTPUT_DIR:-/var/www/miaoquai}"
NEWS_DIR="$OUTPUT_DIR/news"
GLOSSARY_DIR="$OUTPUT_DIR/glossary"
STORIES_DIR="$OUTPUT_DIR/stories"

# 创建目录
mkdir -p "$NEWS_DIR" "$GLOSSARY_DIR" "$STORIES_DIR"

# 显示帮助
show_help() {
    echo -e "${BLUE}🦞 妙趣AI 内容生成助手${NC}"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  news              生成AI新闻日报模板"
    echo "  glossary <术语>   生成术语百科模板"
    echo "  story <标题>      生成踩坑实录模板"
    echo "  sitemap           更新站点地图"
    echo ""
    echo "示例:"
    echo "  $0 news"
    echo "  $0 glossary RAG"
    echo "  $0 story '我在OpenAI上踩过的坑'"
}

# 生成新闻日报模板
generate_news() {
    DATE=$(date +%Y-%m-%d)
    FILE="$NEWS_DIR/$DATE.html"
    
    if [ -f "$FILE" ]; then
        echo -e "${YELLOW}文件已存在: $FILE${NC}"
        return
    fi
    
    cat > "$FILE" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AI新闻日报 | 妙趣AI</title>
  <meta name="description" content="今日AI行业最新动态，精选AI新闻、产品发布、技术突破">
  <link rel="canonical" href="https://miaoquai.com/news/DATE.html">
</head>
<body>
  <header>
    <nav><a href="/">妙趣AI</a> » <a href="/ai-news.html">AI新闻</a></nav>
  </header>
  <main>
    <article>
      <h1>AI新闻日报 - DATE</h1>
      <div class="meta">发布时间: DATE</div>
      <div class="content">
        <!-- 内容将在此生成 -->
        <h2>📊 今日热点</h2>
        <ul>
          <li>热点1</li>
          <li>热点2</li>
        </ul>
        
        <h2>🚀 产品发布</h2>
        <ul>
          <li>产品1</li>
        </ul>
        
        <h2>💡 技术突破</h2>
        <ul>
          <li>突破1</li>
        </ul>
      </div>
    </article>
  </main>
  <footer>
    <p>© 2026 妙趣AI - <a href="https://miaoquai.com">miaoquai.com</a></p>
  </footer>
</body>
</html>
EOF
    
    # 替换日期
    sed -i "s/DATE/$DATE/g" "$FILE"
    
    echo -e "${GREEN}✅ 已生成: $FILE${NC}"
}

# 生成术语百科模板
generate_glossary() {
    TERM="$1"
    if [ -z "$TERM" ]; then
        echo -e "${RED}错误: 请提供术语名称${NC}"
        return
    fi
    
    # 转换为 kebab-case
    SLUG=$(echo "$TERM" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    FILE="$GLOSSARY_DIR/$SLUG.html"
    
    if [ -f "$FILE" ]; then
        echo -e "${YELLOW}文件已存在: $FILE${NC}"
        return
    fi
    
    cat > "$FILE" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$TERM 是什么？AI术语解释 | 妙趣AI</title>
  <meta name="description" content="$TERM 的详细解释，包括定义、应用场景、示例代码。妙趣AI术语百科">
  <link rel="canonical" href="https://miaoquai.com/glossary/$SLUG.html">
</head>
<body>
  <header>
    <nav><a href="/">妙趣AI</a> » <a href="/glossary/">术语百科</a></nav>
  </header>
  <main>
    <article>
      <h1>$TERM 是什么？</h1>
      <div class="meta">更新时间: $(date +%Y-%m-%d)</div>
      <div class="content">
        <h2>📖 定义</h2>
        <p>世界上有一种技术叫 $TERM...</p>
        
        <h2>🎯 应用场景</h2>
        <ul>
          <li>场景1</li>
          <li>场景2</li>
        </ul>
        
        <h2>💡 示例</h2>
        <pre><code>
# 代码示例
        </code></pre>
        
        <h2>🔗 相关术语</h2>
        <ul>
          <li><a href="/glossary/related-term.html">相关术语</a></li>
        </ul>
      </div>
    </article>
  </main>
  <footer>
    <p>© 2026 妙趣AI - <a href="https://miaoquai.com">miaoquai.com</a></p>
  </footer>
</body>
</html>
EOF
    
    echo -e "${GREEN}✅ 已生成: $FILE${NC}"
}

# 生成踩坑实录模板
generate_story() {
    TITLE="$1"
    if [ -z "$TITLE" ]; then
        echo -e "${RED}错误: 请提供故事标题${NC}"
        return
    fi
    
    # 转换为 kebab-case
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    FILE="$STORIES_DIR/$SLUG.html"
    
    if [ -f "$FILE" ]; then
        echo -e "${YELLOW}文件已存在: $FILE${NC}"
        return
    fi
    
    cat > "$FILE" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$TITLE | 妙趣踩坑实录</title>
  <meta name="description" content="$TITLE - 妙趣AI踩坑实录，分享AI使用中的血泪教训">
  <link rel="canonical" href="https://miaoquai.com/stories/$SLUG.html">
</head>
<body>
  <header>
    <nav><a href="/">妙趣AI</a> » <a href="/stories/">踩坑实录</a></nav>
  </header>
  <main>
    <article>
      <h1>$TITLE</h1>
      <div class="meta">发布时间: $(date +%Y-%m-%d)</div>
      <div class="content">
        <h2>🌅 开场</h2>
        <p>凌晨X点X分，我和这个bug对视了整整一个时辰...</p>
        
        <h2>💥 问题来了</h2>
        <p>问题描述...</p>
        
        <h2>🔍 排查过程</h2>
        <p>排查过程...</p>
        
        <h2>✅ 解决方案</h2>
        <p>解决方案...</p>
        
        <h2>💭 心得体会</h2>
        <p>世界上有一种经验叫踩坑...</p>
        
        <h2>🔗 相关内容</h2>
        <ul>
          <li><a href="/tools/related-tool.html">相关工具</a></li>
        </ul>
      </div>
    </article>
  </main>
  <footer>
    <p>© 2026 妙趣AI - <a href="https://miaoquai.com">miaoquai.com</a></p>
  </footer>
</body>
</html>
EOF
    
    echo -e "${GREEN}✅ 已生成: $FILE${NC}"
}

# 更新站点地图
update_sitemap() {
    SITEMAP="$OUTPUT_DIR/sitemap.xml"
    
    echo '<?xml version="1.0" encoding="UTF-8"?>' > "$SITEMAP"
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' >> "$SITEMAP"
    
    # 添加首页
    echo "  <url><loc>https://miaoquai.com/</loc><changefreq>daily</changefreq><priority>1.0</priority></url>" >> "$SITEMAP"
    
    # 添加新闻页面
    for file in "$NEWS_DIR"/*.html; do
        [ -f "$file" ] || continue
        name=$(basename "$file" .html)
        echo "  <url><loc>https://miaoquai.com/news/$name.html</loc><changefreq>monthly</changefreq><priority>0.8</priority></url>" >> "$SITEMAP"
    done
    
    # 添加术语页面
    for file in "$GLOSSARY_DIR"/*.html; do
        [ -f "$file" ] || continue
        name=$(basename "$file" .html)
        echo "  <url><loc>https://miaoquai.com/glossary/$name.html</loc><changefreq>monthly</changefreq><priority>0.7</priority></url>" >> "$SITEMAP"
    done
    
    # 添加故事页面
    for file in "$STORIES_DIR"/*.html; do
        [ -f "$file" ] || continue
        name=$(basename "$file" .html)
        echo "  <url><loc>https://miaoquai.com/stories/$name.html</loc><changefreq>monthly</changefreq><priority>0.7</priority></url>" >> "$SITEMAP"
    done
    
    echo '</urlset>' >> "$SITEMAP"
    
    echo -e "${GREEN}✅ 站点地图已更新: $SITEMAP${NC}"
}

# 主函数
case "$1" in
    news)
        generate_news
        ;;
    glossary)
        generate_glossary "$2"
        ;;
    story)
        generate_story "$2"
        ;;
    sitemap)
        update_sitemap
        ;;
    *)
        show_help
        ;;
esac
