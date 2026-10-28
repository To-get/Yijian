#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p vendor Resources/engines docs
if [ ! -f vendor/fairy-stockfish-source.tar.gz ]; then
    curl -fL https://codeload.github.com/fairy-stockfish/Fairy-Stockfish/tar.gz/9f778da667f6e07dae1e85d3e2ea204fc6dee94d -o vendor/fairy-stockfish-source.tar.gz
fi
if [ ! -f vendor/gnugo-3.8.tar.gz ]; then
    curl -fL https://ftp.gnu.org/gnu/gnugo/gnugo-3.8.tar.gz -o vendor/gnugo-3.8.tar.gz
fi
shasum -a 256 -c scripts/engine-sources.sha256
if [ ! -d vendor/fairy-stockfish ]; then
    tar -xzf vendor/fairy-stockfish-source.tar.gz -C vendor
    mv vendor/Fairy-Stockfish-9f778da667f6e07dae1e85d3e2ea204fc6dee94d vendor/fairy-stockfish
fi
if [ ! -d vendor/gnugo-3.8 ]; then tar -xzf vendor/gnugo-3.8.tar.gz -C vendor; fi
python3 scripts/patch-fairy.py
python3 scripts/patch-gnugo.py
if [ "$(uname -m)" = arm64 ]; then fairy_arch=apple-silicon; else fairy_arch=x86-64; fi
make -C vendor/fairy-stockfish/src -j4 build ARCH="$fairy_arch" COMP=clang largeboards=yes nnue=no > docs/fairy-build.log 2>&1
(
    cd vendor/gnugo-3.8
    if [ ! -f config.status ]; then
        ./configure --disable-dependency-tracking --without-readline --without-curses CFLAGS='-O2 -fcommon -Wno-implicit-function-declaration -Wno-int-conversion' > ../../docs/gnugo-configure.log 2>&1
    fi
    make -j4 > ../../docs/gnugo-build.log 2>&1
)
cp vendor/fairy-stockfish/src/stockfish Resources/engines/fairy-stockfish
cp vendor/gnugo-3.8/interface/gnugo Resources/engines/gnugo
printf 'Two local engines are ready.\n'
