# yy_control Windows 构建脚本 (PowerShell)
# 在 Windows 11/10 + MSVC 环境下运行
# 输出: dist/yy_control-windows-x86_64.zip

param(
  [Parameter(Mandatory=$true)][string]$ServerUrl,
  [Parameter(Mandatory=$true)][string]$Key
)

$ErrorActionPreference = "Stop"
Write-Host "=========================================="
Write-Host "yy_control Windows exe 构建"
Write-Host "=========================================="
Write-Host "Server: $ServerUrl"

# 1. 检查 Rust
$rustInstalled = Get-Command "cargo" -ErrorAction SilentlyContinue
if (-not $rustInstalled) {
  Write-Host "[1/6] 安装 Rust MSVC..."
  # https://rustup.rs
  Invoke-WebRequest -Uri "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" -OutFile "$env:TEMP\rustup-init.exe"
  & "$env:TEMP\rustup-init.exe" -y --default-host x86_64-pc-windows-msvc
  $env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
} else {
  Write-Host "[1/6] Rust 已安装"
}
rustup target add x86_64-pc-windows-msvc

# 2. 检查 Flutter
$flutterInstalled = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterInstalled) {
  Write-Host "[2/6] 安装 Flutter..."
  git clone --depth 1 --branch 3.24.5 https://github.com/flutter/flutter.git "$env:USERPROFILE\flutter"
  $env:Path = "$env:USERPROFILE\flutter\bin;$env:Path"
} else {
  Write-Host "[2/6] Flutter 已安装"
}
flutter --version

# 3. LLVM (bindgen 需要)
$llvmInstalled = Test-Path "C:\Program Files\LLVM\bin\clang.exe"
if (-not $llvmInstalled) {
  Write-Host "[3/6] 安装 LLVM..."
  # choco install llvm 或在 CI 中已预装
  winget install LLVM.LLVM -e --disable-interactivity 2>$null
}
$env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"

# 4. vcpkg 依赖
Write-Host "[4/6] 安装 vcpkg 依赖..."
if (-not (Test-Path "$env:VCPKG_ROOT")) {
  git clone https://github.com/microsoft/vcpkg "$env:USERPROFILE\vcpkg"
  & "$env:USERPROFILE\vcpkg\bootstrap-vcpkg.bat"
  $env:VCPKG_ROOT = "$env:USERPROFILE\vcpkg"
}
& "$env:VCPKG_ROOT\vcpkg" install --triplet x64-windows-static `
  libvpx libyuv aom opus libjpeg-turbo

# 5. 编译 Rust + Flutter
Write-Host "[5/6] 编译 Rust CDYLIB..."
$env:YY_SERVER_URL = $ServerUrl
$env:YY_KEY = $Key
$env:VCPKG_ROOT = $env:VCPKG_ROOT
$env:SODIUM_SHARED = "0"
$env:SODIUM_LIB_DIR = "$env:VCPKG_ROOT\installed\x64-windows-static\lib"

cargo build --lib --release --features flutter,yy_control,unix-file-copy-paste

Write-Host "[6/6] 编译 Flutter Windows..."
Set-Location flutter
flutter build windows --release
Set-Location ..

# 6. 打包
Write-Host "[6/6] 打包..."
$Bundle = "flutter\build\windows\x64\runner\Release"
$Output = "dist\yy_control-windows-x86_64"
New-Item -ItemType Directory -Force -Path $Output
Copy-Item "$Bundle\*" "$Output\" -Recurse -Force
Compress-Archive -Path "$Output\*" -DestinationPath "dist\yy_control-windows-x86_64.zip" -Force

Write-Host ""
Write-Host "=========================================="
Write-Host "✅ 构建完成!"
Write-Host "输出: dist\yy_control-windows-x86_64.zip"
Write-Host "解压后双击 yy_control.exe 即可运行"
Write-Host "=========================================="
