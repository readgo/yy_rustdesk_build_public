#!/bin/bash
#===============================================
# yy_rustdesk_build - 发布 Windows 正式版（release-win-标签）
#===============================================
set -e
TAG="release-win-$(date +%Y%m%d%H%M%S)"
echo "=== yy_rustdesk Windows 正式发布 ==="
echo "标签: $TAG"
echo ""
git tag "$TAG"
git push origin "$TAG"
echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build/actions"
