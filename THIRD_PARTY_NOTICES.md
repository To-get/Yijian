# 第三方组件声明

弈间通过独立本地进程使用以下两个引擎，没有外部模型、云服务或运行时网络请求。项目自身源码、文档与原创图标采用 GPL-3.0-or-later，见 [LICENSE](LICENSE)；第三方组件保留其原有版权及许可证。

## Fairy-Stockfish

- 上游：[Fairy-Stockfish](https://github.com/fairy-stockfish/Fairy-Stockfish)。
- 固定提交：`9f778da667f6e07dae1e85d3e2ea204fc6dee94d`
- 许可：GNU GPL version 3 or later（SPDX：`GPL-3.0-or-later`），完整文本见 [Fairy-Stockfish-GPL-3.txt](licenses/Fairy-Stockfish-GPL-3.txt)，对应上游 `Copying.txt`。
- 源码归档：[固定提交下载](https://codeload.github.com/fairy-stockfish/Fairy-Stockfish/tar.gz/9f778da667f6e07dae1e85d3e2ea204fc6dee94d)，本地缓存名为 `fairy-stockfish-source.tar.gz`；校验值见 [engine-sources.sha256](scripts/engine-sources.sha256)。
- 本地修改：[patch-fairy.py](scripts/patch-fairy.py) 给 `src/uci.cpp` 添加 `yijian` 管道命令，暴露上游局面、合法走法、记谱、终局判断。没有重写搜索算法或规则。
- Apple Silicon 构建：`make -j4 build ARCH=apple-silicon COMP=clang largeboards=yes nnue=no`。使用传统评估，不包含 NNUE 权重。

## GNU Go

- 上游：[GNU Go](https://www.gnu.org/software/gnugo/)。
- 版本：3.8，[官方源码归档](https://ftp.gnu.org/gnu/gnugo/gnugo-3.8.tar.gz)。
- 许可：GNU GPL version 3 or later（SPDX：`GPL-3.0-or-later`），完整文本见 [GNU-Go-GPL-3.txt](licenses/GNU-Go-GPL-3.txt)，对应上游 `COPYING`。
- 源码归档：`gnugo-3.8.tar.gz`；校验值见 [engine-sources.sha256](scripts/engine-sources.sha256)。
- 本地修改：[patch-gnugo.py](scripts/patch-gnugo.py) 为 `utils/gg_utils.c` 的 `gg_sort` 添加 `nel < 2` 提前返回，修复空数组时 `nel - 1` 形成无效指针在现代 Clang 优化下导致的搜索崩溃。仍保留 `-O2` 优化与完整搜索。
- 为现代 Clang 使用 `-fcommon -Wno-implicit-function-declaration -Wno-int-conversion` 兼容编译选项。
- 配置：`./configure --disable-dependency-tracking --without-readline --without-curses CFLAGS='-O2 -fcommon -Wno-implicit-function-declaration -Wno-int-conversion'`，然后 `make -j4`。
- 对弈规则：`--chinese-rules --positional-superko`，白贴 7.5，使用 GTP 通信。

## 源码与分发

Git 仓库保留固定下载地址、SHA-256 清单、适配脚本与许可证；`vendor/` 作为本地缓存不提交。正式应用的 `Contents/Resources/OpenSource/` 则直接附带两个引擎的对应源码归档，以及重建所需的补丁、脚本、校验清单和完整许可证。上游源码中的版权声明保持不变。

在仓库根目录运行 `bash scripts/build-engines.sh` 可取得并重建相同版本。完整应用构建见[构建说明](docs/BUILDING.md)。

## 从应用内附带源码重建引擎

将 `Contents/Resources/OpenSource/` 中的两个源码归档复制到一个新目录的 `vendor/`，将 `patch-fairy.py`、`patch-gnugo.py`、`build-engines.sh`、`engine-sources.sha256` 复制到 `scripts/`，在此新目录运行：

```sh
bash scripts/build-engines.sh
```

需要 macOS 的 Apple Command Line Tools（Clang / make）及 Python 3。脚本先校验源码归档，再在本地编译。源码已附带时不需要联网。

修改和重新分发引擎时，请同时保留对应的源码、补丁、重建说明和原有版权声明。
