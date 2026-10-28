#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-engines.sh
swift build -c release --scratch-path .build
binary_dir=$(swift build -c release --scratch-path .build --show-bin-path)
app_dir="dist/弈间.app"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources/engines" "$app_dir/Contents/Resources/OpenSource" .build/AppIcon.iconset
cp "$binary_dir/Yijian" "$app_dir/Contents/MacOS/Yijian"
cp Resources/Info.plist "$app_dir/Contents/Info.plist"
cp Resources/engines/fairy-stockfish Resources/engines/gnugo "$app_dir/Contents/Resources/engines/"
swift scripts/make-icon.swift .build/AppIcon.iconset
iconutil -c icns .build/AppIcon.iconset -o "$app_dir/Contents/Resources/AppIcon.icns"
cp vendor/fairy-stockfish-source.tar.gz vendor/gnugo-3.8.tar.gz scripts/patch-fairy.py scripts/patch-gnugo.py scripts/build-engines.sh scripts/engine-sources.sha256 THIRD_PARTY_NOTICES.md "$app_dir/Contents/Resources/OpenSource/"
cp vendor/fairy-stockfish/Copying.txt "$app_dir/Contents/Resources/OpenSource/Fairy-Stockfish-GPL-3.txt"
cp vendor/gnugo-3.8/COPYING "$app_dir/Contents/Resources/OpenSource/GNU-Go-GPL-3.txt"
cp LICENSE "$app_dir/Contents/Resources/OpenSource/Yijian-GPL-3.txt"
codesign --force --sign - "$app_dir/Contents/Resources/engines/fairy-stockfish"
codesign --force --sign - "$app_dir/Contents/Resources/engines/gnugo"
codesign --force --deep --sign - "$app_dir"
codesign --verify --deep --strict "$app_dir"
touch "$app_dir"
ditto -c -k --sequesterRsrc --keepParent "$app_dir" "dist/弈间-macOS-$(uname -m).zip"
(cd dist && shasum -a 256 "弈间-macOS-$(uname -m).zip" > SHA256SUMS.txt)
printf '\nApplication ready: %s\n' "$app_dir"
