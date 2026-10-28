# GitHub 推送与发布清单

[返回项目首页](../README.md)

源码进入 Git 仓库，编译好的应用通过 GitHub Releases 分发。GitHub 会根据发布标签提供源码 ZIP／tar.gz；它们和可直接运行的应用安装包用途不同。参见 [GitHub Releases 文档](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)。

## 应推送到 Git 仓库

```text
.gitattributes
.gitignore
Package.swift
README.md
LICENSE
CHANGELOG.md
CONTRIBUTING.md
THIRD_PARTY_NOTICES.md
Sources/
Tests/
Resources/Info.plist
Resources/AppIcon.png
scripts/
licenses/
docs/USER_GUIDE.md
docs/BUILDING.md
docs/RELEASING.md
docs/verification.md
docs/releases/
```

这些文件足以阅读、构建、测试和复现项目。原创图标 PNG 和绘制脚本都应保留。引擎源代码采用固定下载地址和 SHA-256 校验，不需要把整个上游构建目录提交进 Git。

## 不应推送到 Git 仓库

| 内容 | 原因及去向 |
|---|---|
| `.build/`、`.swiftpm/` | 本机编译缓存 |
| `dist/` | 应用及 ZIP 通过 Releases 上传 |
| `vendor/` | 下载和解压的第三方源码、本机编译产物；构建脚本可重新取得 |
| `Resources/engines/` | 已编译的引擎二进制，由脚本生成 |
| `docs/*.log`、`docs/local/`、`docs/pre-update-games.json` | 原始构建日志及本地验收数据 |
| `*.yijian` | 个人棋谱，除非日后专门制作可公开的测试样例 |
| `.DS_Store`、`__pycache__/`、`*.pyc` | 系统和脚本缓存 |

以上已配置在 [.gitignore](../.gitignore) 中。`.gitignore` 不会移除已经被 Git 跟踪的文件；提交前仍应检查暂存区。

## 首次推送

先在 GitHub 新建一个空仓库。以下命令在项目根目录执行；把远程地址替换为你自己仓库页面提供的真实地址。

```sh
git init -b main
git add .gitattributes .gitignore Package.swift README.md LICENSE CHANGELOG.md CONTRIBUTING.md THIRD_PARTY_NOTICES.md
git add Sources Tests scripts licenses Resources/Info.plist Resources/AppIcon.png
git add docs/USER_GUIDE.md docs/BUILDING.md docs/RELEASING.md docs/verification.md docs/releases
git diff --cached --stat
git status --short
```

确认暂存内容后：

```sh
git commit -m "Prepare Yijian 1.0.1 for release"
git remote add origin https://github.com/YOUR_ACCOUNT/YOUR_REPOSITORY.git
git push -u origin main
```

这里的 `YOUR_ACCOUNT/YOUR_REPOSITORY` 是必须替换的占位符。已有 Git 仓库或 origin 时，无需再次初始化或添加远程地址。

## 发布应用

1. 运行构建与测试：

   ```sh
   bash scripts/build.sh
   bash scripts/test.sh
   codesign --verify --deep --strict dist/弈间.app
   ```

2. 运行 `dist/弈间.app`，检查图标、三棋切换、AI 落子、教程和棋谱保存；版本与变更写入 [CHANGELOG.md](../CHANGELOG.md)。
3. 将源码及文档提交后，为该提交创建标签：

   ```sh
   git tag -a v1.0.1 -m "Yijian 1.0.1"
   git push origin v1.0.1
   ```

4. 在 GitHub 的 Releases 中以 `v1.0.1` 创建发布，正文使用 [v1.0.1 发布说明](releases/v1.0.1.md)。
5. 上传以下两个文件作为 Release assets：

   ```text
   dist/弈间-macOS-arm64.zip
   dist/SHA256SUMS.txt
   ```

ZIP 已包含完整 `.app`、两个引擎的对应源码、补丁、重建脚本与许可证。无需把 `.app` 目录逐个上传到 Git。

当前包使用本机临时签名，发布说明应明确未进行 Developer ID 签名和公证。以后完成正式签名或公证后，应重新打 ZIP 并计算校验值。

## 下载校验

将 ZIP 和 `SHA256SUMS.txt` 放在同一目录，在该目录运行：

```sh
shasum -a 256 -c SHA256SUMS.txt
```

校验文件由构建脚本生成，对应当次实际 ZIP。不要沿用旧安装包的校验值。
