# 构建与测试

[返回项目首页](../README.md)

## 环境

- macOS；发布目标为 macOS 13 及以上。
- Apple Command Line Tools 或完整 Xcode，提供 Clang、make、Swift、iconutil 和 codesign。
- Swift 6.0 或更新版本（测试使用 Swift Testing）；实际验证版本为 Swift 6.4。
- Python 3、curl、tar、shasum。Python 仅用于构建期引擎适配，不是应用运行依赖。

没有 Swift Package 或 JavaScript 第三方包依赖。两个生产引擎的版本、补丁和许可见[第三方声明](../THIRD_PARTY_NOTICES.md)。

## 正式应用

在仓库根目录运行：

```sh
bash scripts/build.sh
```

脚本执行以下步骤：

1. 下载固定提交的 Fairy-Stockfish 与 GNU Go 3.8 源码归档。
2. 按 [engine-sources.sha256](../scripts/engine-sources.sha256) 校验，应用本地补丁并编译两个引擎。
3. 使用 Swift 的 release 配置编译应用。
4. 用 AppKit 路径绘制 16～1024 像素图标，并打包为 `.icns`。
5. 组装 `.app`，附带引擎源码、补丁、构建脚本及许可证，再进行本机临时签名。
6. 生成 ZIP 和 `SHA256SUMS.txt`。

Apple Silicon 构建产物：

```text
dist/
├── 弈间.app
├── 弈间-macOS-arm64.zip
└── SHA256SUMS.txt
```

在 Intel Mac 上，脚本会选择 x86-64 引擎构建并使用 `x86_64` 命名安装包；该流程尚未实机验证。

## 开发运行

```sh
bash scripts/build-engines.sh
swift run Yijian
```

在仓库根目录运行时，开发程序使用 `Resources/engines/` 中的引擎；正式 `.app` 使用自身 Resources 中的引擎。开发运行没有完整应用包，检查 Finder 图标时应使用 `dist/弈间.app`。

如需隔离开发棋谱，可在运行前指定数据目录：

```sh
YIJIAN_DATA_DIR=/tmp/yijian-dev-games swift run Yijian
```

## 测试

先编译引擎，再执行：

```sh
bash scripts/test.sh
```

[test.sh](../scripts/test.sh) 调用 `swift test --disable-xctest --scratch-path .build`，并在工具链附带 `TestingMacros` 插件时显式载入它，以兼容部分 Command Line Tools 的宏插件自动发现问题。它不下载测试依赖，也不更改系统工具链。当前测试范围和验证环境见[验收记录](verification.md)。

## 离线重建

`vendor/` 是被 Git 忽略的本地缓存。首次下载后保留其中的两个归档，即可重复构建而无需再次下载：

```text
vendor/fairy-stockfish-source.tar.gz
vendor/gnugo-3.8.tar.gz
```

已发布应用也在 `Contents/Resources/OpenSource/` 附带这些归档和重建脚本。校验值不匹配时构建会停止，请先核对来源。

## 图标

图标由 [make-icon.swift](../scripts/make-icon.swift) 原创绘制，包含象牙白国际象棋马、朱红中国象棋棋子、黑色围棋棋子与深绿棋盘背景。小尺寸自动减少细节。

修改图标后，在仓库根目录运行：

```sh
swift scripts/make-icon.swift .build/AppIcon.iconset
cp .build/AppIcon.iconset/icon_512x512@2x.png Resources/AppIcon.png
bash scripts/build.sh
```

`Resources/AppIcon.png` 用于仓库展示；安装包内的 `AppIcon.icns` 由构建脚本生成。`Info.plist` 声明图标文件，程序启动时也显式载入该图标。应用版本和构建号分别位于 `CFBundleShortVersionString` 与 `CFBundleVersion`。

## 签名

默认脚本使用 `codesign --sign -` 进行本机临时签名。它确认包内签名完整性，不代表 Apple Developer ID 签名或公证。对外发布如需 Developer ID 和公证，应在生成最终 ZIP 前完成相应签名与公证流程，再重新计算校验值。
