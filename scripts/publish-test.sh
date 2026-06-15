#!/bin/bash
#===============================================
# yy_rustdesk_build - 发布测试构建（test-当前时间）
# 触发 GitHub Actions 编译测试版
#===============================================
set -e

REPO_URL="https://github.com/readgo/yy_rustdesk_build.git"
TAG="test-$(date +%Y%m%d%H%M%S)"

# 如果带参数 linux/win，则发指定平台
if [ "$1" = "linux" ]; then
  TAG="test-linux-$(date +%Y%m%d%H%M%S)"
  echo "仅构建 Linux"
elif [ "$1" = "win" ]; then
  TAG="test-win-$(date +%Y%m%d%H%M%S)"
  echo "仅构建 Windows"
fi

echo "=== yy_rustdesk 测试构建 ==="
echo "标签: $TAG"
echo ""

git tag "$TAG"
git push origin "$TAG"

echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build/actions"
