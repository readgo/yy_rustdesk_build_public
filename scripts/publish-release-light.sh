#!/bin/bash
#===============================================
# yy_rustdesk_build_public - 发布 PC light 正式版
# 触发 build-light-pc.yml（tags: release-light-*）
#===============================================
set -e

TAG="release-light-$(date +%Y%m%d%H%M%S)"

echo "=== yy_rustdesk PC light 正式发布 ==="
echo "标签: $TAG"
echo ""

git tag "$TAG"
git push origin "$TAG"

echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build_public/actions"
