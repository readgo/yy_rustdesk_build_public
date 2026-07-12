# CI APK 自动发布方案

## 问题

GitHub Actions 构建 Android APK 后，`gh release create` 无法创建 Release，报错：
```
none of the git remotes configured for this repository point to a known GitHub host.
```

## 根因

1. **GITHUB_TOKEN 默认只读** — 仓库的 workflow permissions 默认可能设为只读，需显式声明写权限
2. **gh CLI 的 git remote 检查** — "Clone source" 步从 Gitee 克隆覆盖工作目录，git remote 变成 Gitee URL，gh CLI 找不到 github.com 拒绝操作
3. **GHA 默认 `set -eo pipefail`** — 任何命令失败立即终止步骤，导致 0 秒快速失败，日志不可见

## 最终方案

### 1. 声明权限

在 workflow 顶层添加：

```yaml
permissions:
  contents: write
```

### 2. 使用正确的 token 引用

```yaml
env:
  GH_TOKEN: ${{ github.token }}    # 不要用 secrets.GITHUB_TOKEN
```

### 3. gh --repo 使用 HOST/OWNER/REPO 格式

```bash
gh release create "$TAG" \
  "dist/"*.apk \
  --title "YYDesk v$VERSION" \
  --notes-file /tmp/release-notes.md \
  --generate-notes \
  --repo "github.com/${{ github.repository }}"   # 完整 HOST/OWNER/REPO，不是 --repo owner/repo
```

### 4. 禁用默认错误终止

```bash
set +e
set +o pipefail
gh release create ... 2>&1 || echo "gh 失败但继续"
```

## 调试过程

| 尝试 | 方案 | 失败原因 |
|------|------|---------|
| 1 | `gh --repo owner/repo` | gh 仍需 git remote 解析 host |
| 2 | curl 直调 API | JSON body 内换行符未转义 |
| 3 | 外部 Python 脚本 | 工作目录被 Clone source 覆盖（文件不在 Gitee 源码里） |
| 4 | actions/github-script | Node.js 版本兼容问题 |
| 5 | jq + curl | JSON 格式正确但缺写权限 |
| 6 | `gh --repo https://github.com/owner/repo` | URL 格式不对 |
| 7 | `gh --repo github.com/owner/repo` + `set +e` | 步骤能跑通但无写权限 |
| **8** | **+ `permissions: contents: write`** | **成功** |

## 参考

- [freq-lang/.github/workflows/engoo-daily.yml](https://github.com/jing1984/freq-lang/blob/main/.github/workflows/engoo-daily.yml) — 参考项目的成功配置
- GitHub Docs: [Automatic token authentication](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
