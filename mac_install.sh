#!/bin/bash

clear
echo "============================================="
echo "    Claude Code + DeepSeek V4 Pro 一键安装    "
echo "           【国内镜像版 · 全自动】           "
echo "============================================="

# 1. 安装 Homebrew 国内镜像
echo ""
echo "🔽 安装 Homebrew 国内镜像..."
/bin/bash -c "$(curl -fsSL https://gitee.com/ineedhouse/homebrew-install/raw/master/install.sh)"

# 将 brew 加入当前 shell（Apple Silicon / Intel）
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 2. 自动安装依赖 git + node（缺失时再装，避免无谓升级）
echo ""
echo "🔽 检查并安装 git & node..."
if ! command -v git &>/dev/null; then
  brew install git
else
  echo "   git 已存在，跳过"
fi
if ! command -v node &>/dev/null; then
  brew install node
else
  echo "   node 已存在，跳过"
fi

# 3. 国内镜像安装 Claude Code CLI
echo ""
echo "🔽 安装 Claude Code CLI（国内镜像）..."
curl -fsSL https://gitee.com/ineedhouse/cdn/raw/master/claude.ai/install.sh | sh

# 4. 输入 API Key
echo ""
read -p "请输入你的 DeepSeek API Key（sk-开头）: " API_KEY

if [[ -z "$API_KEY" || "$API_KEY" != sk-* ]]; then
  echo "❌ 无效 API Key"
  exit 1
fi

# 5. 写入配置
CONFIG="
# Claude Code -> DeepSeek V4 Pro[1m]
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
export ANTHROPIC_AUTH_TOKEN=$API_KEY
export ANTHROPIC_MODEL=deepseek-v4-pro[1m]
export API_TIMEOUT_MS=600000
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
"

echo "$CONFIG" >> ~/.zshrc
source ~/.zshrc

echo ""
echo "✅ 安装完成！"
echo "🤖 模型：deepseek-v4-pro[1m]"
echo "📌 直接输入：claude  即可使用！"