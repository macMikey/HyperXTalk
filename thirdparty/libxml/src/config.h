/* config.h — platform-agnostic build configuration for libxml2 2.15.3.
 * Supports both macOS/Clang (original target) and Windows/MSVC.
 * Do not run cmake or autoconf on top of this file.
 */

#ifdef _MSC_VER
/* ---- Windows / MSVC build -------------------------------------------- */

/* stdint.h available in VS 2010+ */
#define HAVE_STDINT_H 1

/* POSIX APIs not available on Windows */
/* #undef HAVE_DECL_GETENTROPY */
/* #undef HAVE_DECL_GLOB */
/* #undef HAVE_DECL_MMAP */

/* GCC/Clang attributes not supported in MSVC */
/* #undef HAVE_FUNC_ATTRIBUTE_DESTRUCTOR */

/* dlopen not available; Windows uses LoadLibrary */
/* #undef HAVE_DLOPEN */
/* #undef HAVE_SHLLOAD */

/* System config dir (unused on Windows) */
#define XML_SYSCONFDIR "C:/etc"

/* Do NOT define XML_THREAD_LOCAL for Windows static builds.
 * libxml2 comment (globals.c): "On Windows, we can't use TLS in static
 * builds. The RegisterWait callback would run after TLS was deallocated."
 * Leaving XML_THREAD_LOCAL undefined makes globals.c use the Win32 TLS
 * API path (TlsAlloc/TlsGetValue/TlsFree) instead. */
/* #undef XML_THREAD_LOCAL */

#else
/* ---- macOS / Linux / Clang / GCC build ------------------------------- */

/* Define to 1 if you have the declaration of 'getentropy' */
#define HAVE_DECL_GETENTROPY 1

/* Define to 1 if you have the declaration of 'glob' */
#define HAVE_DECL_GLOB 1

/* Define to 1 if you have the declaration of 'mmap' */
#define HAVE_DECL_MMAP 1

/* Define if __attribute__((destructor)) is accepted */
#define HAVE_FUNC_ATTRIBUTE_DESTRUCTOR 1

/* Have dlopen based dso */
#define HAVE_DLOPEN 1

/* Have shl_load based dso */
/* #undef HAVE_SHLLOAD */

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* System configuration directory (/etc) */
#define XML_SYSCONFDIR "/etc"

/* TLS specifier — _Thread_local is supported by clang on Apple platforms */
#define XML_THREAD_LOCAL _Thread_local

#endif /* _MSC_VER */
