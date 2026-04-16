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

3. **Homebrew** — required for `libffi`.  
   Install: https://docs.brew.sh/Installation  
   If already installed, update it:
   ```bash
   brew upgrade
   ```

4. **Python 3** — verify it is available:
   ```bash
   python3 --version   # should return Python 3.x
   ```

---

## Build Steps

Open Terminal and run the following commands in order.  
All commands assume you are in the repo root — start every session with:

```bash
cd ~/Developer/HyperXTalk
```

---

### 1. Build libffi

```bash
sh prebuilt/scripts/build-libffi-mac-arm64.sh
```

---

### 2. Build third-party libraries

```bash
REPO=~/Developer/HyperXTalk
for LIB in libskia libsqlite libxml libzip libcairo libxslt libiodbc; do
  echo "=== Building $LIB ==="
  xcodebuild \
    -project "$REPO/build-mac/livecode/thirdparty/$LIB/$LIB.xcodeproj" \
    -configuration Debug \
    -arch arm64 \
    SOLUTION_DIR="$REPO" 2>&1 | grep -E "BUILD (SUCCEEDED|FAILED)|error:"
done
```

---

### 3. Build libz

```bash
sh prebuilt/scripts/build-libz-mac-arm64.sh
```

---

### 4. Copy libraries into place

```bash
REPO=~/Developer/HyperXTalk
cp "$REPO/_build/mac/Debug/libcairo.a"  "$REPO/prebuilt/lib/mac/libcairo.a"
cp "$REPO/_build/mac/Debug/libxslt.a"   "$REPO/prebuilt/lib/mac/libxslt.a"
cp "$REPO/_build/mac/Debug/libiodbc.a"  "$REPO/prebuilt/lib/mac/libiodbc.a"
for F in "$REPO"/_build/mac/Debug/libskia*.a; do
  cp "$F" "$REPO/prebuilt/lib/mac/$(basename "$F")"
done
cp "$REPO/_build/mac/Debug/libxml.a"    "$REPO/prebuilt/lib/mac/libxml.a"
cp "$REPO/_build/mac/Debug/libzip.a"    "$REPO/prebuilt/lib/mac/libzip.a"
```

---

### 5. Build ICU for arm64 macOS (icupkg host tool + five static libs)

```bash
sh prebuilt/scripts/build-icu-mac-arm64.sh
```

Produces `prebuilt/bin/mac/icupkg` and `prebuilt/lib/mac/libicu*.a` in one
pass. Source is fetched to `prebuilt/build/icu-58-mac-arm64/` (gitignored).

---

### 6. Populate the remaining prebuilts

libgif, libjpeg, libpng, libpcre, libcustomcrypto/ssl, and the stub
libpq/libmysql archives.

```bash
brew install openssl@3     # if not already installed
sh prebuilt/scripts/build-mac-extras.sh
```

This script works around several things the upstream fetch-mac step
was supposed to handle but no longer does (broken prebuilt URL). See
the comment at the top of `build-mac-extras.sh` for details.

---

### 7. Bake in database client libraries

Required for functional DB drivers. The default prebuilts from step 6 are
720-byte stub archives — enough for the linker to succeed, but the driver
bundles end up with unresolved `PQconnectdb` / `mysql_init` symbols.

- `dbmysql` has a `dlsym(RTLD_DEFAULT, "mysql_init")` guard and returns a
  clean error if you skip this step
  (`revdb/src/mysql_connection.cpp:37-50`).
- `dbpostgresql` has no such guard — calling any PostgreSQL function on a
  build that skipped this step crashes the engine.

The first two scripts replace the stubs in `prebuilt/lib/mac/` with real
static libraries from Homebrew, so step 8's `make compile-mac` links the
bundles against them. The `rebuild-db*.sh` calls only matter when re-baking
after an existing build; on a fresh tree, step 8 alone is enough.

```bash
brew install libpq mysql-client
sh prebuilt/scripts/build-libpq-mac-arm64.sh
sh prebuilt/scripts/build-libmysql-mac-arm64.sh
sh rebuild-dbpostgresql.sh
sh rebuild-dbmysql.sh
```

---

### 8. Build the engine

```bash
make compile-mac
```

> ⚠️ The build will end with a code signing error on the very last line.  
> This is expected — look for `** BUILD SUCCEEDED **` just above it.  
> The signing step that follows will handle this correctly.

---

### 9. Code sign mac-bin

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

