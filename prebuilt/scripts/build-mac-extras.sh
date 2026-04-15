#!/bin/bash
#
# build-mac-extras.sh — populate the macOS prebuilt/ tree with the bits
# that BUILD1.md + the existing prebuilt/scripts scripts don't cover.
#
# Run this AFTER:
#   1. sh prebuilt/scripts/build-libffi-mac-arm64.sh
#   2. the seven xcodebuild thirdparty libs (libskia libsqlite libxml libzip
#      libcairo libxslt libiodbc) — note that libzip is currently broken via
#      xcodebuild; this script rebuilds it manually below.
#   3. sh prebuilt/scripts/build-libz-mac-arm64.sh  (or a prebuilt libz.a)
#   4. the copy step into prebuilt/lib/mac
#   5. sh prebuilt/scripts/build-icupkg-mac-arm64.sh
#
# Then this script:
#   - Builds libgif/libjpeg/libpng/libpcre via xcodebuild and installs them
#   - Compiles libzip 1.10.1 manually from the CMakeLists source list
#     (the generated libzip.xcodeproj file list is stale and can't build
#     cleanly against the modern libzip source; see the 'build-mac: prefer
#     libzip src/ over include/' commit for context)
#   - Copies the ICU static libs produced by build-icupkg-mac-arm64.sh
#     into prebuilt/lib/mac
#   - Supplies libcustomcrypto.a / libcustomssl.a from Homebrew openssl@3
#     (engine now targets the 3.x symbol names directly; no compat shim)
#   - Writes empty stub libpq.a and libmysql.a so the dbpostgresql /
#     dbmysql externals can link via -undefined dynamic_lookup
#
# Requirements: Xcode command line tools, Homebrew, and an installed
# openssl@3 (`brew install openssl@3`).
#
# All of this is a workaround for the broken fetch-mac step in the
# generated Xcode project. Once gyp is usable again or the prebuilt
# tarballs are re-hosted, this script can go away.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "${REPO_ROOT}"

PREBUILT_LIB="${REPO_ROOT}/prebuilt/lib/mac"
DEBUG_OUT="${REPO_ROOT}/_build/mac/Debug"

mkdir -p "${PREBUILT_LIB}"

# ── 1. Extra thirdparty libs via xcodebuild ──────────────────────────────────
echo "=== Building libgif libjpeg libpng libpcre ==="
for LIB in libgif libjpeg libpng libpcre; do
    xcodebuild \
        -project "${REPO_ROOT}/build-mac/livecode/thirdparty/${LIB}/${LIB}.xcodeproj" \
        -configuration Debug \
        -arch arm64 \
        SOLUTION_DIR="${REPO_ROOT}" \
        2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)|error:" || true
    if [ ! -f "${DEBUG_OUT}/${LIB}.a" ]; then
        echo "ERROR: ${LIB}.a missing after xcodebuild"
        exit 1
    fi
    cp "${DEBUG_OUT}/${LIB}.a" "${PREBUILT_LIB}/${LIB}.a"
done

# ── 2. libzip 1.10.1 manual build ────────────────────────────────────────────
# The libzip.xcodeproj file list predates libzip 1.x and references files
# (zip_source_file.c, zip_source_filep.c, zip_source_filename.c) that clash
# with the modern source tree. Compile the 1.10.1 CMakeLists list directly.
echo "=== Building libzip 1.10.1 manually ==="
LIBZIP_SRC="${REPO_ROOT}/thirdparty/libzip/src"
LIBZIP_BUILD="/tmp/hxt-libzip-build"
rm -rf "${LIBZIP_BUILD}"
mkdir -p "${LIBZIP_BUILD}"

# Patch config.h in place to disable bz2/lzma/zstd/openssl/crypto (we don't
# link them) and HAVE_FTS_H (we don't need fts). Restored at the end.
LIBZIP_CONFIG="${LIBZIP_SRC}/config.h"
LIBZIP_CONFIG_BACKUP="${LIBZIP_BUILD}/config.h.orig"
cp "${LIBZIP_CONFIG}" "${LIBZIP_CONFIG_BACKUP}"
trap 'cp "${LIBZIP_CONFIG_BACKUP}" "${LIBZIP_CONFIG}" 2>/dev/null || true' EXIT

sed -i '' \
    -e 's|^#define HAVE_CRYPTO$|/* #undef HAVE_CRYPTO */|' \
    -e 's|^#define HAVE_FICLONERANGE$|/* #undef HAVE_FICLONERANGE */|' \
    -e 's|^#define HAVE_LIBBZ2$|/* #undef HAVE_LIBBZ2 */|' \
    -e 's|^#define HAVE_LIBLZMA$|/* #undef HAVE_LIBLZMA */|' \
    -e 's|^#define HAVE_LIBZSTD$|/* #undef HAVE_LIBZSTD */|' \
    -e 's|^#define HAVE_OPENSSL$|/* #undef HAVE_OPENSSL */|' \
    -e 's|^#define HAVE_FTS_H$|/* #undef HAVE_FTS_H */|' \
    -e 's|^/\* #undef HAVE_UNISTD_H \*/$|#define HAVE_UNISTD_H|' \
    -e 's|^/\* #undef HAVE_STRCASECMP \*/$|#define HAVE_STRCASECMP|' \
    -e 's|^/\* #undef HAVE_STRINGS_H \*/$|#define HAVE_STRINGS_H|' \
    -e 's|^/\* #undef HAVE_STDBOOL_H \*/$|#define HAVE_STDBOOL_H|' \
    -e 's|^/\* #undef HAVE_DIRENT_H \*/$|#define HAVE_DIRENT_H|' \
    -e 's|^/\* #undef HAVE_FILENO \*/$|#define HAVE_FILENO|' \
    -e 's|^/\* #undef HAVE_FCHMOD \*/$|#define HAVE_FCHMOD|' \
    -e 's|^/\* #undef HAVE_LOCALTIME_R \*/$|#define HAVE_LOCALTIME_R|' \
    -e 's|^/\* #undef HAVE_MKSTEMP \*/$|#define HAVE_MKSTEMP|' \
    -e 's|^/\* #undef HAVE_STRDUP \*/$|#define HAVE_STRDUP|' \
    -e 's|^/\* #undef HAVE_STRTOLL \*/$|#define HAVE_STRTOLL|' \
    -e 's|^/\* #undef HAVE_STRTOULL \*/$|#define HAVE_STRTOULL|' \
    -e 's|^/\* #undef HAVE_STRUCT_TM_TM_ZONE \*/$|#define HAVE_STRUCT_TM_TM_ZONE|' \
    -e 's|^/\* #undef HAVE_ARC4RANDOM \*/$|#define HAVE_ARC4RANDOM|' \
    -e 's|^/\* #undef HAVE_GETPROGNAME \*/$|#define HAVE_GETPROGNAME|' \
    -e 's|^/\* #undef HAVE_NULLABLE \*/$|#define HAVE_NULLABLE|' \
    -e 's|^#define HAVE_MEMCPY_S$|/* #undef HAVE_MEMCPY_S */|' \
    -e 's|^#define HAVE_STRNCPY_S$|/* #undef HAVE_STRNCPY_S */|' \
    -e 's|^#define HAVE__SNPRINTF_S$|/* #undef HAVE__SNPRINTF_S */|' \
    -e 's|^#define HAVE__SNWPRINTF_S$|/* #undef HAVE__SNWPRINTF_S */|' \
    -e 's|^#define HAVE_LOCALTIME_S$|/* #undef HAVE_LOCALTIME_S */|' \
    -e 's|^#define HAVE_SNPRINTF_S$|/* #undef HAVE_SNPRINTF_S */|' \
    -e 's|^#define HAVE_STRERROR_S$|/* #undef HAVE_STRERROR_S */|' \
    -e 's|^#define HAVE_STRERRORLEN_S$|/* #undef HAVE_STRERRORLEN_S */|' \
    "${LIBZIP_CONFIG}"

LIBZIP_SOURCES=(
    zip_add.c zip_add_dir.c zip_add_entry.c zip_algorithm_deflate.c
    zip_buffer.c zip_close.c zip_delete.c zip_dir_add.c zip_dirent.c
    zip_discard.c zip_entry.c zip_error.c zip_error_clear.c zip_error_get.c
    zip_error_get_sys_type.c zip_error_strerror.c zip_error_to_str.c
    zip_extra_field.c zip_extra_field_api.c zip_fclose.c zip_fdopen.c
    zip_file_add.c zip_file_error_clear.c zip_file_error_get.c
    zip_file_get_comment.c zip_file_get_external_attributes.c
    zip_file_get_offset.c zip_file_rename.c zip_file_replace.c
    zip_file_set_comment.c zip_file_set_encryption.c
    zip_file_set_external_attributes.c zip_file_set_mtime.c
    zip_file_strerror.c zip_fopen.c zip_fopen_encrypted.c zip_fopen_index.c
    zip_fopen_index_encrypted.c zip_fread.c zip_fseek.c zip_ftell.c
    zip_get_archive_comment.c zip_get_archive_flag.c
    zip_get_encryption_implementation.c zip_get_file_comment.c
    zip_get_name.c zip_get_num_entries.c zip_get_num_files.c zip_hash.c
    zip_io_util.c zip_libzip_version.c zip_memdup.c zip_name_locate.c
    zip_new.c zip_open.c zip_pkware.c zip_progress.c zip_rename.c
    zip_replace.c zip_set_archive_comment.c zip_set_archive_flag.c
    zip_set_default_password.c zip_set_file_comment.c
    zip_set_file_compression.c zip_set_name.c zip_source_accept_empty.c
    zip_source_begin_write.c zip_source_begin_write_cloning.c
    zip_source_buffer.c zip_source_call.c zip_source_close.c
    zip_source_commit_write.c zip_source_compress.c zip_source_crc.c
    zip_source_error.c zip_source_file_common.c zip_source_file_stdio.c
    zip_source_free.c zip_source_function.c
    zip_source_get_file_attributes.c zip_source_is_deleted.c
    zip_source_layered.c zip_source_open.c zip_source_pass_to_lower_layer.c
    zip_source_pkware_decode.c zip_source_pkware_encode.c
    zip_source_read.c zip_source_remove.c zip_source_rollback_write.c
    zip_source_seek.c zip_source_seek_write.c zip_source_stat.c
    zip_source_supports.c zip_source_tell.c zip_source_tell_write.c
    zip_source_window.c zip_source_write.c zip_source_zip.c
    zip_source_zip_new.c zip_stat.c zip_stat_index.c zip_stat_init.c
    zip_strerror.c zip_string.c zip_unchange.c zip_unchange_all.c
    zip_unchange_archive.c zip_unchange_data.c zip_utf-8.c zip_err_str.c
    zip_source_file_stdio_named.c zip_random_unix.c
)

LIBZIP_CFLAGS=(
    -arch arm64 -O0 -g -w -fvisibility=hidden
    -I"${LIBZIP_SRC}" -I"${REPO_ROOT}/thirdparty/libz/include"
    -DCROSS_COMPILE_TARGET -DTARGET_PLATFORM_MACOS_X -D_MACOSX -D_DEBUG
    # macOS has native fseeko/ftello; prevent compat.h from redefining them
    # as macros, which corrupts the system stdio.h function declarations.
    -DHAVE_FSEEKO -DHAVE_FTELLO
)

LIBZIP_OBJS=()
pushd "${LIBZIP_SRC}" >/dev/null
for f in "${LIBZIP_SOURCES[@]}"; do
    o="${LIBZIP_BUILD}/${f%.c}.o"
    if ! clang "${LIBZIP_CFLAGS[@]}" -c "$f" -o "$o"; then
        echo "ERROR: libzip compile failed on $f"
        popd >/dev/null
        exit 1
    fi
    LIBZIP_OBJS+=("$o")
done
popd >/dev/null

ar rcs "${LIBZIP_BUILD}/libzip.a" "${LIBZIP_OBJS[@]}"
cp "${LIBZIP_BUILD}/libzip.a" "${PREBUILT_LIB}/libzip.a"
mkdir -p "${DEBUG_OUT}"
cp "${LIBZIP_BUILD}/libzip.a" "${DEBUG_OUT}/libzip.a"

# restore config.h now that libzip is built
cp "${LIBZIP_CONFIG_BACKUP}" "${LIBZIP_CONFIG}"
trap - EXIT

echo "libzip.a built with ${#LIBZIP_OBJS[@]} objects"

# ── 3. ICU static libs (from build-icupkg-mac-arm64.sh output) ───────────────
ICU_INSTALL="/tmp/icu58_arm64_build/icu_install"
echo "=== Installing ICU static libs from ${ICU_INSTALL} ==="
if [ ! -d "${ICU_INSTALL}/lib" ]; then
    echo "ERROR: ${ICU_INSTALL}/lib not found — run prebuilt/scripts/build-icupkg-mac-arm64.sh first"
    exit 1
fi
for f in libicudata.a libicui18n.a libicuio.a libicutu.a libicuuc.a; do
    cp "${ICU_INSTALL}/lib/$f" "${PREBUILT_LIB}/$f"
done

# ── 4. libcustomcrypto / libcustomssl from Homebrew openssl@3 + compat shim ──
echo "=== Supplying libcustomcrypto/libcustomssl from Homebrew openssl@3 ==="
OPENSSL_PREFIX="$(brew --prefix openssl@3 2>/dev/null || true)"
if [ -z "${OPENSSL_PREFIX}" ] || [ ! -f "${OPENSSL_PREFIX}/lib/libcrypto.a" ]; then
    echo "ERROR: Homebrew openssl@3 not installed. Run: brew install openssl@3"
    exit 1
fi
cp "${OPENSSL_PREFIX}/lib/libcrypto.a" "${PREBUILT_LIB}/libcustomcrypto.a"
cp "${OPENSSL_PREFIX}/lib/libssl.a"    "${PREBUILT_LIB}/libcustomssl.a"

# ── 5. Stub libpq.a and libmysql.a ───────────────────────────────────────────
# dbpostgresql.bundle and dbmysql.dylib link with -undefined dynamic_lookup
# so unresolved symbols are deferred to load time. The linker still insists
# on being able to find -lpq and -lmysql as files, so provide minimal
# archives with a single dummy object. Runtime will fail if you actually
# use these database drivers — install real libpq / libmysqlclient and
# replace these if you need that functionality.
echo "=== Creating stub libpq.a and libmysql.a ==="
STUB_C="${LIBZIP_BUILD}/db-driver-stub.c"
cat > "${STUB_C}" <<'EOF'
/* Stub archive marker for dbpostgresql / dbmysql link-time satisfaction.
 * These drivers actually resolve symbols at dlopen time; see
 * prebuilt/scripts/build-mac-extras.sh for context. */
int _hxt_db_driver_stub(void) { return 0; }
EOF
STUB_O="${LIBZIP_BUILD}/db-driver-stub.o"
clang -arch arm64 -c "${STUB_C}" -o "${STUB_O}"
ar rcs "${PREBUILT_LIB}/libpq.a"    "${STUB_O}"
ar rcs "${PREBUILT_LIB}/libmysql.a" "${STUB_O}"

echo ""
echo "=== Done. prebuilt/lib/mac now has: ==="
ls "${PREBUILT_LIB}/" | sort
