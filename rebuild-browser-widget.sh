#!/bin/bash
# Rebuild just the browser widget (browser.lcb → module.lcm) and deploy it.
# Run this from the HyperXTalk repo root on your Mac.

set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
BUILD="$REPO/_build/mac/Debug"
LC_COMPILE="$BUILD/lc-compile"
LCI_PATH="$BUILD/modules/lci"
EXT_DIR="$BUILD/packaged_extensions/com.livecode.widget.browser"
SRC="$REPO/extensions/widgets/browser/browser.lcb"
BUNDLE_EXT="$REPO/mac-bin/HyperXTalk.app/Contents/Tools/Extensions/com.livecode.widget.browser"

echo "=== Rebuilding browser widget ==="
echo "  Source:  $SRC"
echo "  Output:  $EXT_DIR/module.lcm"

"$LC_COMPILE" \
    --modulepath "$EXT_DIR" \
    --modulepath "$LCI_PATH" \
    --manifest "$EXT_DIR/manifest.xml" \
    --output "$EXT_DIR/module.lcm" \
    "$SRC"

echo "  Compiled successfully."

# Deploy to app bundle
if [ -d "$BUNDLE_EXT" ]; then
    cp "$EXT_DIR/module.lcm" "$BUNDLE_EXT/module.lcm"
    echo "  Deployed to app bundle."
else
    echo "  WARNING: Bundle path not found: $BUNDLE_EXT"
fi

echo "=== Done. ==="
