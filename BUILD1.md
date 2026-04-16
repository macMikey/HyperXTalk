# HyperXTalk — macOS ARM64 Build Instructions

## Prerequisites

1. **Clone location** — the repo must live at `~/Developer/HyperXTalk`.
   Create the folder if needed:
   ```bash
   mkdir -p ~/Developer
   git clone https://github.com/emily-elizabeth/HyperXTalk ~/Developer/HyperXTalk
   ```
   > ⚠️ Do **not** clone into `~/Documents/` or any folder synced by iCloud Drive.
   > iCloud tags app bundles with extended attributes that break code signing.

2. **Xcode** — ensure you have the latest version installed and have accepted the license:
   ```bash
   sudo xcodebuild -license accept
   ```

3. **Homebrew** — install from https://docs.brew.sh/Installation, then install
   the formulae the prebuild scripts need:
   ```bash
   brew install openssl@3 libpq mysql-client
   ```

4. **Python 3** — verify it is available:
   ```bash
   python3 --version   # should return Python 3.x
   ```

---

## Build

From the repo root:

```bash
cd ~/Developer/HyperXTalk
make prebuilt-mac    # builds libffi, libskia & friends, libz, ICU, openssl
                     #   extras, libpq, libmysql — about 10 min on an M1
make compile-mac
```

> ⚠️ `make compile-mac` ends with a code signing error on the very last line.
> This is expected — look for `** BUILD SUCCEEDED **` just above it.
> The signing step that follows handles it correctly.

### What `make prebuilt-mac` does

In order:

1. `prebuilt/scripts/build-libffi-mac-arm64.sh` — vendored libffi → `prebuilt/lib/mac/libffi.a`.
2. `prebuilt/scripts/build-thirdparty-mac-arm64.sh` — xcodebuild over the seven
   vendored libs (libskia, libsqlite, libxml, libzip, libcairo, libxslt,
   libiodbc) and copies the resulting `.a` files into `prebuilt/lib/mac/`.
3. `prebuilt/scripts/build-libz-mac-arm64.sh` — zlib.
4. `prebuilt/scripts/build-icu-mac-arm64.sh` — ICU 58.2 (icupkg host tool + five
   `libicu*.a` static libs in one pass).
5. `prebuilt/scripts/build-mac-extras.sh` — libgif, libjpeg, libpng, libpcre,
   and `libcustomcrypto`/`libcustomssl` (copied from Homebrew openssl@3).
6. `prebuilt/scripts/build-libpq-mac-arm64.sh` — real static libpq from Homebrew.
7. `prebuilt/scripts/build-libmysql-mac-arm64.sh` — real static libmysqlclient.

Step 6+7 replace the stub `libpq.a` / `libmysql.a` archives so that the
`dbpostgresql` / `dbmysql` driver bundles link against functional
client libraries. Without them, `dbpostgresql` silently crashes the engine
when used (no runtime guard); `dbmysql` has a `dlsym` guard and reports a
clean error (`revdb/src/mysql_connection.cpp:37-50`).

Re-running is idempotent — each script checks existing state and skips
network work when it can.

### Re-baking DB drivers after an existing build

If you already have a built tree and want to replace the stub-linked
driver bundles, use the rebuild scripts:

```bash
sh rebuild-dbpostgresql.sh
sh rebuild-dbmysql.sh
```

On a fresh tree, `make compile-mac` alone is enough — the drivers link
against the real libraries from `make prebuilt-mac` directly.

---

### Code sign `mac-bin`

```bash
REPO=~/Developer/HyperXTalk
MACBIN="$REPO/mac-bin"
find "$MACBIN" -not -name "*.dSYM" | while read F; do
    if [[ -f "$F" ]] && file "$F" | grep -qE "Mach-O|bundle"; then
        codesign --force --sign - "$F" 2>/dev/null && echo "Signed: $(basename $F)"
    fi
done
find "$MACBIN" -name "*.app" -exec codesign --force --options runtime \
  --entitlements "$REPO/HyperXTalk.entitlements" --sign - {} \;
echo "Done signing."
```
