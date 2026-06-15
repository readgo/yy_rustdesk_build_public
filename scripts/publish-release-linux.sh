#!/bin/bash
#===============================================
# yy_rustdesk_build - 发布 Linux 正式版（release-linux-标签）
#===============================================
set -e
TAG="release-linux-$(date +%Y%m%d%H%M%S)"
echo "=== yy_rustdesk Linux 正式发布 ==="
echo "标签: $TAG"
echo ""
git tag "$TAG"
git push origin "$TAG"
echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build_public/actions"
