#!/bin/bash
#===============================================
# yy_rustdesk_build - 发布 Android APK（release-apk-标签）
# 触发 GitHub Actions 编译 APK 并发布到 Release
#===============================================
set -e
TAG="release-apk-$(date +%Y%m%d%H%M%S)"
echo "=== yy_rustdesk APK 发布 ==="
echo "标签: $TAG"
echo ""
git tag "$TAG"
git push origin "$TAG"
echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build_public/actions"
