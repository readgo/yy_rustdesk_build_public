#!/bin/bash
#===============================================
# yy_rustdesk_build - 发布 Linux 正式版（release-linux-标签）
#===============================================
set -e

# 切到脚本所属仓库根目录（scripts 的上一级）。本脚本要打 tag 并推送，必须在
# yy_rustdesk_build_public 仓库里执行；否则标签会落到调用者所在仓库（例如在
# 根仓 yy_desk_work 里执行就推到 Gitee），GitHub Actions 收不到标签、不会触发
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

TAG="release-linux-$(date +%Y%m%d%H%M%S)"
echo "=== yy_rustdesk Linux 正式发布 ==="
echo "标签: $TAG"
echo ""
git tag "$TAG"
git push origin "$TAG"
echo ""
echo "✅ 已推送标签: $TAG"
echo "   查看进度: https://github.com/readgo/yy_rustdesk_build_public/actions"
