#!/bin/bash
#===============================================
# yy_rustdesk_build - 发布测试构建（test-当前时间）
# 触发 GitHub Actions 编译测试版
#===============================================
set -e

# 切到脚本所属仓库根目录（scripts 的上一级）。本脚本要打 tag 并推送，必须在
# yy_rustdesk_build_public 仓库里执行；否则标签会落到调用者所在仓库（例如在
# 根仓 yy_desk_work 里执行就推到 Gitee），GitHub Actions 收不到标签、不会触发
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

REPO_URL="https://github.com/readgo/yy_rustdesk_build_public.git"
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
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build_public/actions"
