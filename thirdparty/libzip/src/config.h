#ifndef HAD_CONFIG_H
#define HAD_CONFIG_H
#ifndef _HAD_ZIPCONF_H
#include "zipconf.h"
#endif

/*
 * Portable config.h for HyperXTalk's vendored libzip.
 * Branches on target platform — mac/linux use the POSIX feature set;
 * Windows keeps the MSVC defines. No optional compression backends
 * (bz2/lzma/zstd) and no crypto — the engine does not link against them.
 */

#define PACKAGE "libzip"
#define VERSION "1.11.4"

#define ENABLE_FDOPEN

#if defined(_WIN32) || defined(_WIN64)

/* ── Windows / MSVC ────────────────────────────────────────────────────── */
/* HAVE_CRYPTO tells zip_random_win32.c to include zip_crypto.h, which pulls
   in zip_crypto_win.h and defines HAVE_SECURE_RANDOM, suppressing the
   duplicate CryptGenRandom fallback that would otherwise collide with the
   BCryptGenRandom implementation in zip_crypto_win.c (LNK2005). */
#define HAVE_CRYPTO
#define HAVE_WINDOWS_CRYPTO
#define HAVE__CLOSE
#define HAVE__DUP
#define HAVE__FDOPEN
#define HAVE__FILENO
#define HAVE__SETMODE
#define HAVE__SNPRINTF_S
#define HAVE__SNWPRINTF_S
#define HAVE__STRDUP
#define HAVE__STRICMP
#define HAVE__STRTOI64
#define HAVE__STRTOUI64
#define HAVE__UNLINK
#define HAVE_LOCALTIME_S
#define HAVE_MEMCPY_S
#define HAVE_SETMODE
#define HAVE_SNPRINTF
#define HAVE__SNPRINTF
/* HAVE_SNPRINTF_S / HAVE_STRERRORLEN_S intentionally omitted:
   MSVC 14.x CRT does not export these as linkable symbols without
   __STDC_WANT_LIB_EXT1__ globally defined; zip_error_strerror.c
   uses snprintf + a fixed 256-byte buffer instead. */
#define HAVE_STRERROR_S
#define HAVE_STRICMP
#define HAVE_STRNCPY_S
#define SIZEOF_OFF_T 4
#define SIZEOF_SIZE_T 8

#elif defined(__APPLE__) || defined(__linux__) || defined(__unix__)

/* ── macOS / Linux / POSIX ─────────────────────────────────────────────── */
#define HAVE_UNISTD_H
#define HAVE_STDBOOL_H
#define HAVE_STRINGS_H
#define HAVE_DIRENT_H
#define HAVE_STRCASECMP
#define HAVE_STRDUP
#define HAVE_FILENO
#define HAVE_FCHMOD
#define HAVE_FSEEKO
#define HAVE_FTELLO
#define HAVE_MKSTEMP
#define HAVE_LOCALTIME_R
#define HAVE_SNPRINTF
#define HAVE_STRTOLL
#define HAVE_STRTOULL
#define HAVE_STRUCT_TM_TM_ZONE
#define HAVE_NULLABLE
#define SIZEOF_OFF_T 8
#define SIZEOF_SIZE_T 8

#if defined(__APPLE__)
#define HAVE_ARC4RANDOM
#define HAVE_GETPROGNAME
#endif

/* glibc gained arc4random in 2.36 (Aug 2022). Older glibc falls back to
 * libzip's internal PRNG path. */
#if defined(__linux__) && defined(__GLIBC__) && \
    (__GLIBC__ > 2 || (__GLIBC__ == 2 && __GLIBC_MINOR__ >= 36))
#define HAVE_ARC4RANDOM
#endif

#else
#error "libzip config.h: unsupported platform"
#endif

#endif /* HAD_CONFIG_H */
