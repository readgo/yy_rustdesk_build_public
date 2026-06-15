#!/bin/bash
#===============================================
# yy_rustdesk_build - 仅构建 Linux（test-linux-标签）
#===============================================
set -e
TAG="test-linux-$(date +%Y%m%d%H%M%S)"
echo "=== yy_rustdesk Linux 测试构建 ==="
echo "标签: $TAG"
echo ""
git tag "$TAG"
git push origin "$TAG"
echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build/actions"
