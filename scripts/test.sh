#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift_tool=$(xcrun --find swift)
testing_plugin="$(dirname "$swift_tool")/../lib/swift/host/plugins/testing/libTestingMacros.dylib"
test_options=(--disable-xctest --scratch-path .build)
# Some Command Line Tools builds omit this bundled plugin from auto-discovery.
if [ -f "$testing_plugin" ]; then
    test_options+=(-Xswiftc -load-plugin-library -Xswiftc "$testing_plugin")
fi
"$swift_tool" test "${test_options[@]}" "$@"
