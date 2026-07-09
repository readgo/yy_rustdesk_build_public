#!/bin/bash
#===============================================
# yy_rustdesk APK 发行脚本
# 1. 调用 build_light.sh 编译 APK
# 2. 重命名为 YYDesk-版本号.apk
# 3. 发布到 GitHub Release
#
# 依赖: gh (GitHub CLI), 已登录 (gh auth status)
#===============================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# yy_rustdesk 仓库根目录（scripts/../..）
YYDESK_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=========================================="
echo "  YYDesk APK 发行"
echo "=========================================="
echo "构建目录: $YYDESK_DIR"
echo ""

# ===== 1. 提取版本号 =====
echo "[1/5] 提取版本号..."
cd "$YYDESK_DIR"
YY_VERSION=$(grep -oP '^version\s*=\s*"\K[^"]+' Cargo.toml 2>/dev/null || echo "")
if [ -z "$YY_VERSION" ]; then
  echo "  ERROR: 无法从 Cargo.toml 读取版本号"
  exit 1
fi
echo "  版本号: $YY_VERSION"

# ===== 2. 编译 APK =====
echo "[2/5] 编译 APK..."
cd "$YYDESK_DIR"
bash flutter/build_light.sh

# ===== 3. 重命名 APK =====
echo "[3/5] 重命名 APK..."
OUTPUT_DIR="flutter/build/app/outputs/flutter-apk"
cd "$YYDESK_DIR"

# build_light.sh 输出的文件名: app-${YY_VENDOR}-${YY_MODE}-${MODE}.apk
# 默认值来自 build_light.sh: YY_VENDOR=yy, YY_MODE=light, MODE=release
SOURCE_APK=""
for candidate in "$OUTPUT_DIR"/app-*.apk; do
  if [ -f "$candidate" ]; then
    SOURCE_APK="$candidate"
    break
  fi
done

if [ -z "$SOURCE_APK" ]; then
  echo "  ERROR: 未在 $OUTPUT_DIR 中找到构建产物"
  exit 1
fi

RELEASE_APK="$OUTPUT_DIR/YYDesk-${YY_VERSION}.apk"
cp "$SOURCE_APK" "$RELEASE_APK"
echo "  源文件: $(basename "$SOURCE_APK")"
echo "  发行包: $(basename "$RELEASE_APK")"

# ===== 4. 发布到 GitHub Release =====
echo "[4/5] 发布到 GitHub Release..."
cd "$YYDESK_DIR/yy_rustdesk_build_public"

RELEASE_TAG="v${YY_VERSION}"

# 检查 tag 是否已存在
if git rev-parse "$RELEASE_TAG" >/dev/null 2>&1; then
  echo "  标签 $RELEASE_TAG 已存在，更新 Release..."
  gh release upload "$RELEASE_TAG" "$YYDESK_DIR/$RELEASE_APK" --clobber
else
  echo "  创建 Release: $RELEASE_TAG"
  gh release create "$RELEASE_TAG" \
    "$YYDESK_DIR/$RELEASE_APK" \
    --title "YYDesk v${YY_VERSION}" \
    --notes "YYDesk v${YY_VERSION} Android APK

### 安装
下载 APK 后，在 Android 设备上安装即可。
首次安装需在系统设置中允许「未知来源应用」。
" \
    --generate-notes
  git push origin "$RELEASE_TAG"
fi

# ===== 5. 清理临时文件 =====
echo "[5/5] 清理..."
rm -f "$RELEASE_APK"

echo ""
echo "=========================================="
echo "  ✅ 发布完成!"
echo "  APK: 已上传至 Release $RELEASE_TAG"
echo "  地址: https://github.com/readgo/yy_rustdesk_build_public/releases/tag/$RELEASE_TAG"
echo "=========================================="
