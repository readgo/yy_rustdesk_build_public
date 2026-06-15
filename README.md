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
