#!/bin/bash
# Build icupkg (ICU 58.2) for arm64 macOS
# Places the binary at prebuilt/bin/mac/icupkg (replacing the broken symlink)
#
# icupkg is a host tool used during the build to list and strip the ICU data archive.
# Only the tools subset of ICU needs to be compiled — no need for the full static libs.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ICU_VERSION="58.2"
ICU_VERSION_MAJOR="58"
ICU_VERSION_ALT="58_2"

DOWNLOAD_URL="https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION_ALT//_/-}/icu4c-${ICU_VERSION_ALT}-src.tgz"
BUILD_BASE="/tmp/icu58_arm64_build"
ICU_TGZ="${BUILD_BASE}/icu4c-${ICU_VERSION_ALT}-src.tgz"
ICU_SRC="${BUILD_BASE}/icu"
ICU_BUILD="${BUILD_BASE}/icu_build"
ICU_INSTALL="${BUILD_BASE}/icu_install"

OUT_BIN="${REPO_ROOT}/prebuilt/bin/mac/icupkg"

echo "=== Building icupkg (ICU ${ICU_VERSION}) for arm64 macOS ==="

# ── 1. Download source ────────────────────────────────────────────────────────
mkdir -p "${BUILD_BASE}"

if [ ! -d "${ICU_SRC}" ]; then
    if [ ! -f "${ICU_TGZ}" ]; then
        echo "Downloading ICU ${ICU_VERSION} source..."
        curl -L -o "${ICU_TGZ}" "${DOWNLOAD_URL}"
    fi
    echo "Unpacking..."
    tar -xf "${ICU_TGZ}" -C "${BUILD_BASE}"
fi

# ── 2. Configure & build ──────────────────────────────────────────────────────
SDK="$(xcrun --sdk macosx --show-sdk-path)"
MACOS_MIN="11.0"

# ICU configure flags: static only, tools enabled, no samples/tests/extras
ICU_CONFIGURE_FLAGS=(
    "--disable-shared"
    "--enable-static"
    "--with-data-packaging=archive"
    "--disable-samples"
    "--disable-tests"
    "--prefix=${ICU_INSTALL}"
)

export CC="$(xcrun -find clang)"
export CXX="$(xcrun -find clang++)"
export CFLAGS="-arch arm64 -mmacosx-version-min=${MACOS_MIN} -isysroot ${SDK}"
export CXXFLAGS="${CFLAGS} -std=c++11 -stdlib=libc++"
export LDFLAGS="-arch arm64 -mmacosx-version-min=${MACOS_MIN} -isysroot ${SDK}"

rm -rf "${ICU_BUILD}" "${ICU_INSTALL}"
mkdir -p "${ICU_BUILD}"

echo "Configuring ICU..."
cd "${ICU_BUILD}"
"${ICU_SRC}/source/runConfigureICU" MacOSX "${ICU_CONFIGURE_FLAGS[@]}"

echo "Building ICU (this takes a few minutes)..."
make -j"$(sysctl -n hw.logicalcpu)" 2>&1 | tail -5

echo "Installing to ${ICU_INSTALL}..."
make install 2>&1 | tail -5

# ── 3. Place the binary ───────────────────────────────────────────────────────
BUILT_ICUPKG="${ICU_INSTALL}/bin/icupkg"

if [ ! -f "${BUILT_ICUPKG}" ]; then
    echo "ERROR: icupkg not found at ${BUILT_ICUPKG}"
    exit 1
fi

# Replace broken symlink with the real binary
rm -f "${OUT_BIN}"
mkdir -p "$(dirname "${OUT_BIN}")"
cp "${BUILT_ICUPKG}" "${OUT_BIN}"
chmod +x "${OUT_BIN}"

# Sign the binary (required on Apple Silicon)
codesign --force --sign - "${OUT_BIN}"

echo ""
echo "Done. icupkg installed to:"
echo "  ${OUT_BIN}"
echo ""
echo "Verify with:"
echo "  ${OUT_BIN} --help"
