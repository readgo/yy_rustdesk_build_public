# yy_rustdesk_build

> GitHub Actions 自动构建 YY Control 远程桌面客户端

本仓库**不含源代码**，仅用于 CI/CD 持续集成。源码托管在私有 Git 服务器，由 Actions 拉取后编译。

## 构建产物

| 平台 | 产物 | 格式 |
|------|------|------|
| Linux x86_64 | `yy_control-x86_64.AppImage` | 单文件，双击直接运行 |
| Windows x86_64 | `yy_control-windows-x86_64.zip` | 解压后双击 `yy_control.exe` |

## 触发构建

### 方式一：打标签触发（推荐）

```bash
git tag release-<年月日时分秒>
git push origin release-<年月日时分秒>
```

示例：

```bash
git tag release-20260615000000
git push origin release-20260615000000
```

仅测试构建（标签前缀决定运行哪些 job）：

| 标签前缀 | 行为 |
|----------|------|
| `release-*` / `test-*`             | 同时构建 Linux + Windows |
| `release-linux-*` / `test-linux-*` | 仅 Linux |
| `release-win-*` / `test-win-*`     | 仅 Windows |

### 方式二：手动触发

GitHub 页面 → **Actions** → **Build yy_control** → **Run workflow**

### Android APK（多版本）

`publish-apk.sh` 打 `release-apk-*` 标签，一次构建**所有版本 APK**：

```bash
bash scripts/publish-apk.sh   # 打 release-apk-<时间戳> 标签
```

**构建逻辑**（build-apk.yml）：

- 标准 light 版（YYDesk）总是构建：`flutter/build_light.sh`
- 扫描私有源码仓库 `flutter/` 下所有 `build_light_*.sh`（排除 `build_light.sh`/`build_light_local.sh`），**每个脚本一个版本，依次执行**
- 每个版本的**全部参数硬编码在对应的私有仓库脚本里**（如 `build_light_yutomat.sh` 内含 server_url/key/MQTT 等），不在此 public 仓库配置任何版本参数
- 产物：`dist/YYDesk-<version>.apk` + `dist/<脚本名>-<version>.apk`，发布到同一 GitHub Release

**新增一个版本（2 步，不改 CI 代码）**：

1. 在私有源码仓库 `yy_rustdesk/flutter/` 复制 `build_light_yutomat.sh` 为 `build_light_<版本>.sh`，修改其中的参数（app 名/服务器/key/MQTT）
2. 提交并推送私有仓库，然后 `bash scripts/publish-apk.sh` 打标签触发

CI 自动扫描到新脚本并构建，无需改 build-apk.yml。

## GitHub Secrets（必须配置）

| Secret | 说明 |
|--------|------|
| `SOURCE_GIT_HOST`  | 源码 Git 服务器主机名（不含协议和路径） |
| `SOURCE_REPO`      | 源码仓库路径（`owner/name` 格式） |
| `SOURCE_BRANCH`    | 拉取的分支名 |
| `SOURCE_USERNAME`  | 拉取代码用的用户名 |
| `SOURCE_TOKEN`     | 拉取代码用的 Token |
| `YY_SERVER_URL`    | 产品后端服务器地址 |
| `YY_KEY`           | 产品密钥（base64） |

> 各 APK 版本的服务器/key/MQTT 参数在私有源码仓库的 `build_light_<版本>.sh` 中硬编码，不在此 public 仓库配置。

## 工作原理

```
打 release-* 标签 → GitHub Actions
    ├─ linux (ubuntu-24.04)
    │   ├─ git clone 源码
    │   ├─ apt install 依赖
    │   ├─ cargo build (flutter + yy_control features)
    │   ├─ flutter build linux --release
    │   ├─ appimagetool → yy_control-x86_64.AppImage
    │   └─ upload artifact
    │
    └─ windows (windows-2022)
        ├─ git clone 源码
        ├─ choco install llvm + vcpkg install
        ├─ cargo build (flutter + yy_control features)
        ├─ flutter build windows --release
        ├─ zip → yy_control-windows-x86_64.zip
        └─ upload artifact
```

## 本地构建

### Linux

```bash
# 需要 Ubuntu 22.04+，有 GTK 桌面环境
bash scripts/build-linux.sh
```

### Windows

```powershell
# 需要 Windows 10/11，有 MSVC 工具链
.\scripts\build-windows.ps1
```
