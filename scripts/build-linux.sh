#!/usr/bin/env bash
# yy_rustdesk Linux AppImage 本地构建脚本
# 用于 GitHub Actions 或在 Ubuntu 22.04+ 上本地构建
# 输出: yy_control-x86_64.AppImage

set -e

# ===== Config =====
: "${YY_SERVER_URL:?YY_SERVER_URL env var is required}"
: "${YY_KEY:?YY_KEY env var is required}"

echo "=========================================="
echo "yy_control Linux AppImage 构建"
echo "=========================================="
echo "Server: $YY_SERVER_URL"

# 1. 系统依赖
echo "[1/7] 安装系统依赖..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  libgtk-3-dev libxdo-dev libva-dev libxcb-randr0-dev \
  libvpx-dev libyuv-dev libopus-dev libaom-dev libjpeg-turbo8-dev \
  libpulse-dev libgstreamer-plugins-base1.0-dev \
  libxfixes-dev libxtst-dev libxkbcommon-dev \
  libpam0g-dev curl wget file imagemagick

# 2. Rust
if ! command -v cargo &>/dev/null; then
  echo "[2/7] 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "[2/7] Rust 已安装"
fi

# 3. Flutter
if ! command -v flutter &>/dev/null; then
  echo "[3/7] 安装 Flutter 3.24.5..."
  git clone --depth 1 --branch 3.24.5 \
    https://github.com/flutter/flutter.git "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
  flutter config --enable-linux-desktop
else
  echo "[3/7] Flutter 已安装"
fi
flutter --version 2>&1 | head -1

# 4. 编译 Rust CDYLIB
echo "[4/7] 编译 Rust CDYLIB..."
export YY_SERVER_URL
export YY_KEY
export PKG_CONFIG_ALLOW_CROSS=1
cargo build --lib --release --features flutter,yy_control,unix-file-copy-paste 2>&1 | tail -3

# 5. 编译 Flutter Linux
echo "[5/7] 编译 Flutter Linux..."
export LIBRARY_PATH="/usr/lib/gcc/x86_64-linux-gnu/12"
cd flutter
flutter build linux --release 2>&1 | tail -3
cd ..

# 6. 下载 appimagetool
echo "[6/7] 准备 appimagetool..."
if [ ! -f /tmp/appimagetool ]; then
  curl -sL \
    https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage \
    -o /tmp/appimagetool
  chmod +x /tmp/appimagetool
fi

# 7. 打包 AppImage
echo "[7/7] 打包 AppImage..."
APPDIR=$(mktemp -d)
BUNDLE="flutter/build/linux/x64/release/bundle"
mkdir -p "$APPDIR/usr/lib/yy_control"
cp -r "$BUNDLE"/* "$APPDIR/usr/lib/yy_control/"

# Bundle system libs
mkdir -p "$APPDIR/usr/lib/x86_64-linux-gnu"
for lib in \
  libgtk-3.so.0 libgdk-3.so.0 libglib-2.0.so.0 libgobject-2.0.so.0 \
  libgio-2.0.so.0 libpangocairo-1.0.so.0 libpango-1.0.so.0 \
  libcairo.so.2 libcairo-gobject.so.2 libgdk_pixbuf-2.0.so.0 \
  libatk-1.0.so.0 libatk-bridge-2.0.so.0 libatspi.so.0 \
  libharfbuzz.so.0 libfreetype.so.6 libfontconfig.so.1 \
  libX11.so.6 libXfixes.so.3 libxcb.so.1 libxcb-shm.so.0 \
  libxcb-randr.so.0 libxcb-xfixes.so.0 libxcb-shape.so.0 \
  libXdamage.so.1 libXcomposite.so.1 libXrender.so.1 \
  libXext.so.6 libXcursor.so.1 libXi.so.6 libXtst.so.6 \
  libXrandr.so.2 libXinerama.so.1 libxkbcommon.so.0 \
  libdl.so.2 libpthread.so.0 libstdc++.so.6 libm.so.6 libc.so.6 \
  librt.so.1 libpcre2-8.so.0 libffi.so.8 libpixman-1.so.0 \
  libepoxy.so.0 libfribidi.so.0 libpng16.so.16 libexpat.so.1 \
  libuuid.so.1 libbz2.so.1.0 libEGL.so.1 libGL.so.1 \
  libdrm.so.2 libgbm.so.1 libgcc_s.so.1 \
  libwayland-client.so.0 libwayland-cursor.so.0 \
  libwayland-egl.so.1 libwayland-server.so.0 \
  libgstreamer-1.0.so.0 libgstvideo-1.0.so.0 libgstbase-1.0.so.0 \
  libgstpbutils-1.0.so.0 libgstaudio-1.0.so.0 libgsttag-1.0.so.0 \
  libgmodule-2.0.so.0 libgstapp-1.0.so.0 libgstriff-1.0.so.0 \
  liborc-0.4.so.0 libpulse.so.0 libpulse-simple.so.0; do
  cp -L "/lib/x86_64-linux-gnu/$lib" "$APPDIR/usr/lib/x86_64-linux-gnu/" 2>/dev/null || true
  cp -L "/usr/lib/x86_64-linux-gnu/$lib" "$APPDIR/usr/lib/x86_64-linux-gnu/" 2>/dev/null || true
done

# AppRun
cat > "$APPDIR/AppRun" << 'EOSCRIPT'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib/yy_control/lib:$HERE/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
exec "$HERE/usr/lib/yy_control/rustdesk" "$@"
EOSCRIPT
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/yy_control.desktop" << 'EODESK'
[Desktop Entry]
Name=YY Control
Comment=Remote Desktop Client
Exec=yy_control
Icon=yy_control
Type=Application
Categories=Network;
Terminal=false
EODESK

convert -size 256x256 xc:transparent -fill "#4A90D9" \
  -draw "circle 128,128 128,20" "$APPDIR/yy_control.png" 2>/dev/null || true

mkdir -p dist
APPIMAGE_EXTRACT_AND_RUN=1 /tmp/appimagetool \
  "$APPDIR" "dist/yy_control-x86_64.AppImage"

rm -rf "$APPDIR"

echo ""
echo "=========================================="
echo "✅ 构建完成!"
echo "输出: dist/yy_control-x86_64.AppImage"
ls -lh dist/yy_control-x86_64.AppImage
echo "运行: ./dist/yy_control-x86_64.AppImage"
echo "=========================================="
