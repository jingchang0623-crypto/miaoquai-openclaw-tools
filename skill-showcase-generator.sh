#!/usr/bin/env bash
# skill-showcase-generator.sh
# 快速生成 OpenClaw Skill 展示页面的工具
# Usage: ./skill-showcase-generator.sh [skill-name] [skill-description]
#
# 妙彩风格：这事儿我给你办了，但别让我太无聊

set -euo pipefail

# === 颜色配置 ===
readonly COLOR_RESET="\033[0m"
readonly COLOR_CYAN="\033[1;36m"
readonly COLOR_GREEN="\033[1;32m"
readonly COLOR_YELLOW="\033[1;33m"
readonly COLOR_RED="\033[1;31m"
readonly COLOR_MAGENTA="\033[1;35m"

# === 默认配置 ===
SKILLS_DIR="./skills"
OUTPUT_DIR="./skill-showcase"
TEMPLATE_FILE=""

# === 图标映射 ===
declare -A SKILL_ICONS=(
    ["web"]="🌐"
    ["search"]="🔍"
    ["ai"]="🤖"
    ["dev"]="💻"
    ["file"]="📁"
    ["api"]="🔌"
    ["automation"]="⚡"
    ["data"]="📊"
    ["default"]="🦞"
)

# === 帮助信息 ===
show_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║     🦞 OpenClaw Skill Showcase Generator 🦞              ║
╚══════════════════════════════════════════════════════════╝

「世界上有一种技能，叫做OpenClaw Skill...
 它能让你的AI学会新招，就像给龙虾装上了机械臂」

用法: skill-showcase-generator [选项] <skill-name> [描述]

选项:
  -h, --help          显示帮助
  -d, --description   技能描述
  -a, --author        作者名
  -c, --category      分类 (web|ai|dev|automation|api|data)
  -o, --output        输出目录
  --template          使用自定义模板

示例:
  skill-showcase-generator news-aggregator "AI新闻聚合器"
  skill-showcase-generator -c web "web-fetch-skill"
  
分类列表:
  web        - 网页操作相关
  ai         - AI/ML相关
  dev        - 开发工具
  automation - 自动化任务
  api        - API集成
  data       - 数据处理

EOF
}

# === 打印函数 ===
info() { echo -e "${COLOR_CYAN}ℹ️  $*${COLOR_RESET}"; }
success() { echo -e "${COLOR_GREEN}✅ $*${COLOR_RESET}"; }
warn() { echo -e "${COLOR_YELLOW}⚠️  $*${COLOR_RESET}"; }
error() { echo -e "${COLOR_RED}❌ $*${COLOR_RESET}"; }
miao() { echo -e "${COLOR_MAGENTA}🦞 $*${COLOR_RESET}"; }

# === 获取图标 ===
get_icon() {
    local category="${1:-default}"
    echo "${SKILL_ICONS[$category]:-${SKILL_ICONS[default]}}"
}

# === 生成技能卡片HTML ===
generate_skill_card() {
    local name="$1"
    local description="$2"
    local category="${3:-default}"
    local author="${4:-Anonymous}"
    local icon
    icon=$(get_icon "$category")
    
    cat << EOF
<div class="skill-card" data-category="$category">
  <div class="skill-icon">$icon</div>
  <h3 class="skill-name">$name</h3>
  <p class="skill-description">$description</p>
  <div class="skill-meta">
    <span class="skill-category">#$category</span>
    <span class="skill-author">by $author</span>
  </div>
</div>
EOF
}

# === 生成完整展示页面 ===
generate_showcase_page() {
    local skill_name="$1"
    local description="$2"
    local category="${3:-default}"
    local author="${4:-Anonymous}"
    local output_file="$OUTPUT_DIR/$skill_name/index.html"
    local icon
    icon=$(get_icon "$category")
    
    mkdir -p "$(dirname "$output_file")"
    
    cat > "$output_file" << EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$skill_name - OpenClaw Skill | 妙趣AI</title>
    <meta name="description" content="$description - OpenClaw Skill Showcase">
    <style>
        :root {
            --primary: #FF6B6B;
            --secondary: #4ECDC4;
            --dark: #2C3E50;
            --light: #F7F7F7;
            --accent: #FFE66D;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, var(--dark) 0%, #1a1a2e 100%);
            color: var(--light);
            min-height: 100vh;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
        }
        header {
            text-align: center;
            padding: 60px 0;
        }
        .logo {
            font-size: 4rem;
            margin-bottom: 20px;
            animation: float 3s ease-in-out infinite;
        }
        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }
        h1 {
            font-size: 2.5rem;
            background: linear-gradient(45deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 15px;
        }
        .tagline {
            color: #888;
            font-size: 1.1rem;
        }
        .skill-showcase {
            background: rgba(255,255,255,0.05);
            border-radius: 20px;
            padding: 40px;
            margin: 40px 0;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .skill-header {
            display: flex;
            align-items: center;
            gap: 20px;
            margin-bottom: 30px;
        }
        .skill-icon-large {
            font-size: 5rem;
            filter: drop-shadow(0 0 20px rgba(78, 205, 196, 0.5));
        }
        .skill-info h2 {
            font-size: 2rem;
            margin-bottom: 10px;
        }
        .skill-info .category {
            display: inline-block;
            background: var(--secondary);
            color: var(--dark);
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            font-weight: bold;
        }
        .description {
            font-size: 1.1rem;
            line-height: 1.8;
            color: #ccc;
            margin: 30px 0;
            padding: 20px;
            background: rgba(0,0,0,0.2);
            border-radius: 10px;
            border-left: 4px solid var(--primary);
        }
        .installation {
            margin: 30px 0;
        }
        .installation h3 {
            color: var(--accent);
            margin-bottom: 15px;
        }
        .code-block {
            background: #1a1a2e;
            border-radius: 10px;
            padding: 20px;
            overflow-x: auto;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .code-block code {
            color: var(--secondary);
            font-family: 'Fira Code', monospace;
            font-size: 0.95rem;
        }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .feature {
            background: rgba(255,255,255,0.05);
            padding: 20px;
            border-radius: 10px;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .feature h4 {
            color: var(--accent);
            margin-bottom: 10px;
        }
        footer {
            text-align: center;
            padding: 40px 0;
            border-top: 1px solid rgba(255,255,255,0.1);
            margin-top: 40px;
        }
        footer a {
            color: var(--secondary);
            text-decoration: none;
        }
        .author-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: rgba(255,255,255,0.1);
            padding: 8px 16px;
            border-radius: 20px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="logo">🦞</div>
            <h1>OpenClaw Skill</h1>
            <p class="tagline">让AI成为你的超能力</p>
        </header>
        
        <div class="skill-showcase">
            <div class="skill-header">
                <div class="skill-icon-large">$icon</div>
                <div class="skill-info">
                    <h2>$skill_name</h2>
                    <span class="category">$category</span>
                </div>
            </div>
            
            <div class="description">
                <p>$description</p>
                <p style="margin-top: 15px; font-style: italic; color: #888;">
                    「世界上有一种技能，叫做OpenClaw Skill。
                    它能让你的AI学会新招，就像给龙虾装上了机械臂。」
                </p>
            </div>
            
            <div class="installation">
                <h3>🚀 快速开始</h3>
                <div class="code-block">
                    <code># 安装技能<br>
openclaw skill add $skill_name<br><br>
# 使用技能<br>
openclaw run $skill_name</code>
                </div>
            </div>
            
            <div class="features">
                <div class="feature">
                    <h4>⚡ 快速部署</h4>
                    <p>一键安装，立即使用</p>
                </div>
                <div class="feature">
                    <h4>🎯 专业定制</h4>
                    <p>针对特定场景优化</p>
                </div>
                <div class="feature">
                    <h4>🔒 安全可靠</h4>
                    <p>经过社区验证</p>
                </div>
            </div>
            
            <div class="author-badge">
                <span>👤</span>
                <span>Created by $author</span>
            </div>
        </div>
        
        <footer>
            <p>由 <a href="https://miaoquai.com" target="_blank">妙趣AI</a> 生成 | 
               <a href="https://github.com/openclaw/openclaw" target="_blank">OpenClaw 官方</a></p>
            <p style="margin-top: 10px; font-size: 0.9rem; color: #666;">
                🦞 让AI成为你的超能力
            </p>
        </footer>
    </div>
</body>
</html>
EOF
    
    echo "$output_file"
}

# === 主函数 ===
main() {
    local skill_name=""
    local description=""
    local category="default"
    local author="MiaoquAI"
    
    # 参数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -a|--author)
                author="$2"
                shift 2
                ;;
            -c|--category)
                category="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --template)
                TEMPLATE_FILE="$2"
                shift 2
                ;;
            -*)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$skill_name" ]]; then
                    skill_name="$1"
                elif [[ -z "$description" ]]; then
                    description="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 验证必要参数
    if [[ -z "$skill_name" ]]; then
        error "请提供技能名称"
        show_help
        exit 1
    fi
    
    if [[ -z "$description" ]]; then
        description="OpenClaw 技能: $skill_name"
    fi
    
    # 创建展示页面
    miao "正在生成技能展示页面..."
    info "技能名称: $skill_name"
    info "分类: $category"
    info "作者: $author"
    
    local output_file
    output_file=$(generate_showcase_page "$skill_name" "$description" "$category" "$author")
    
    success "技能展示页面已生成: $output_file"
    miao "这事儿我给你办了！"
    
    # 显示预览
    echo ""
    info "预览链接: file://$output_file"
    info "打开浏览器查看效果:"
    echo -e "${COLOR_CYAN}   python3 -m http.server 8000 &${COLOR_RESET}"
    echo -e "${COLOR_CYAN}   open http://localhost:8000/$(basename "$OUTPUT_DIR")/${skill_name}/${COLOR_RESET}"
    
    return 0
}

# 执行主函数
main "$@"
