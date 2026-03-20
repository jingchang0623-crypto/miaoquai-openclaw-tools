#!/bin/bash
# ============================================================================
# OpenClaw Skills 模板生成器
# 快速创建符合规范的OpenClaw Skills
# ============================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 使用说明
usage() {
    cat << EOF
${CYAN}🦞 OpenClaw Skills 模板生成器${NC}

用法:
  $0 <skill-name> [options]

参数:
  skill-name          Skills名称（kebab-case格式）

选项:
  --category <cat>    Skills分类（marketing/development/productivity/automation）
  --description <desc> Skills描述
  --output <dir>      输出目录（默认：当前目录）

示例:
  $0 seo-optimizer --category marketing --description "SEO优化分析工具"
  $0 blog-writer --category productivity

EOF
    exit 1
}

# 参数解析
SKILL_NAME=""
CATEGORY="productivity"
DESCRIPTION=""
OUTPUT_DIR="."

while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --description)
            DESCRIPTION="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [[ -z "$SKILL_NAME" ]]; then
                SKILL_NAME="$1"
            fi
            shift
            ;;
    esac
done

# 验证参数
if [[ -z "$SKILL_NAME" ]]; then
    echo -e "${RED}错误: 请提供Skills名称${NC}"
    usage
fi

# 验证名称格式（kebab-case）
if [[ ! "$SKILL_NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
    echo -e "${RED}错误: Skills名称必须使用kebab-case格式（小写字母、数字、连字符）${NC}"
    echo -e "示例: seo-optimizer, blog-writer, api-tester"
    exit 1
fi

# 验证分类
VALID_CATEGORIES=("marketing" "development" "productivity" "automation" "creative" "research")
if [[ ! " ${VALID_CATEGORIES[*]} " =~ " ${CATEGORY} " ]]; then
    echo -e "${RED}错误: 无效的分类 '${CATEGORY}'${NC}"
    echo -e "有效分类: ${VALID_CATEGORIES[*]}"
    exit 1
fi

echo -e "${CYAN}🦞 OpenClaw Skills 模板生成器${NC}"
echo "========================================"
echo ""
echo -e "${GREEN}Skills名称:${NC} $SKILL_NAME"
echo -e "${GREEN}分类:${NC} $CATEGORY"
echo -e "${GREEN}输出目录:${NC} $OUTPUT_DIR"
echo ""

# 创建输出目录
SKILL_DIR="${OUTPUT_DIR}/${SKILL_NAME}"
mkdir -p "${SKILL_DIR}"

# 生成SKILL.md
SKILL_TITLE=$(echo "$SKILL_NAME" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

cat > "${SKILL_DIR}/SKILL.md" << EOF
# ${SKILL_TITLE}

${DESCRIPTION:-当用户需要与${SKILL_TITLE}相关的帮助时，激活此技能。}

## 触发条件

- 用户提到 "${SKILL_NAME}"
- 用户需要进行${SKILL_TITLE}相关操作
- 用户表达对${CATEGORY}任务的需求

## 能力范围

此Skill可以：

1. **核心功能** - [待补充]
2. **辅助功能** - [待补充]
3. **限制说明** - [待补充]

## 使用指南

### 基础用法

\`\`\`
# 示例1: 基础使用
请帮我${SKILL_TITLE}...

# 示例2: 高级使用
使用${SKILL_NAME}来...
\`\`\`

### 最佳实践

1. [待补充最佳实践1]
2. [待补充最佳实践2]

### 注意事项

- [待补充注意事项1]
- [待补充注意事项2]

## 输出格式

此Skill的标准输出格式：

\`\`\`markdown
## ${SKILL_TITLE} 结果

**状态**: ✅ 成功 / ❌ 失败

**详情**:
- [输出项1]
- [输出项2]

**建议**:
- [下一步行动建议]
\`\`\`

## 技术细节

### 依赖工具

- 工具1: 用途说明
- 工具2: 用途说明

### 配置要求

\`\`\`bash
# 环境变量配置（如需要）
export SKILL_CONFIG="..."
\`\`\`

## 示例场景

### 场景1: [待补充]

用户需求: ...
处理过程: ...
输出结果: ...

### 场景2: [待补充]

用户需求: ...
处理过程: ...
输出结果: ...

## 相关Skills

- [related-skill-1](../related-skill-1/SKILL.md) - 相关说明
- [related-skill-2](../related-skill-2/SKILL.md) - 相关说明

---

*此Skill由妙趣AI Skills模板生成器创建*
*网站: https://miaoquai.com*
EOF

# 生成config.json（可选配置文件）
cat > "${SKILL_DIR}/config.json" << EOF
{
  "name": "${SKILL_NAME}",
  "title": "${SKILL_TITLE}",
  "version": "1.0.0",
  "category": "${CATEGORY}",
  "description": "${DESCRIPTION:-${SKILL_TITLE}技能}",
  "author": "miaoquai-ai",
  "repository": "https://github.com/jingchang0623-crypto/miaoquai-openclaw-tools",
  "website": "https://miaoquai.com",
  "tags": ["${CATEGORY}", "openclaw", "skill"],
  "dependencies": [],
  "minOpenClawVersion": "2026.1.0"
}
EOF

# 生成README.md
cat > "${SKILL_DIR}/README.md" << EOF
# ${SKILL_TITLE}

> ${DESCRIPTION:-${SKILL_TITLE}技能}

## 快速开始

1. 将此目录复制到OpenClaw的skills目录
2. 根据需要编辑 \`SKILL.md\`
3. 配置 \`config.json\` 中的参数
4. 重启OpenClaw或重新加载Skills

## 示例使用

\`\`\`
请帮我使用${SKILL_NAME}...
\`\`\`

## 配置

编辑 \`config.json\` 来自定义此Skill的行为。

## 相关链接

- [妙趣AI](https://miaoquai.com) - AI工具导航与资讯
- [OpenClaw文档](https://docs.openclaw.ai) - 官方文档

---

🦞 由妙趣AI创建 | [miaoquai.com](https://miaoquai.com)
EOF

# 生成示例脚本（如果需要）
cat > "${SKILL_DIR}/example.sh" << 'EOF'
#!/bin/bash
# 示例脚本 - 根据实际需求修改

set -euo pipefail

echo "执行Skills相关操作..."

# 在这里添加实际的脚本逻辑

echo "完成！"
EOF

chmod +x "${SKILL_DIR}/example.sh"

# 创建测试文件
mkdir -p "${SKILL_DIR}/tests"
cat > "${SKILL_DIR}/tests/test_skill.sh" << 'EOF'
#!/bin/bash
# Skills测试脚本

set -euo pipefail

echo "运行Skills测试..."

# 测试1: 验证SKILL.md存在
test -f "../SKILL.md" && echo "✅ SKILL.md 存在" || echo "❌ SKILL.md 不存在"

# 测试2: 验证config.json格式
if command -v jq &> /dev/null; then
    jq . ../config.json > /dev/null && echo "✅ config.json 格式正确" || echo "❌ config.json 格式错误"
fi

# 在这里添加更多测试

echo "测试完成！"
EOF

chmod +x "${SKILL_DIR}/tests/test_skill.sh"

echo -e "${GREEN}✅ Skills模板已生成！${NC}"
echo ""
echo -e "${CYAN}📁 生成的文件:${NC}"
find "${SKILL_DIR}" -type f -printf "  - %p\n"
echo ""
echo -e "${YELLOW}📝 下一步:${NC}"
echo "  1. 编辑 ${SKILL_DIR}/SKILL.md 完善技能定义"
echo "  2. 根据需要修改 ${SKILL_DIR}/config.json"
echo "  3. 实现具体的脚本逻辑（如需要）"
echo "  4. 运行测试: ${SKILL_DIR}/tests/test_skill.sh"
echo ""
echo -e "${PURPLE}💡 提示:${NC}"
echo "  - 参考 Superpowers 项目学习高级Skills写法"
echo "  - 查看 OpenClaw 文档了解Skills规范"
echo "  - 发布到 ClawHub 与社区分享你的Skills"

# 输出Skills目录路径
echo ""
echo "${SKILL_DIR}"
