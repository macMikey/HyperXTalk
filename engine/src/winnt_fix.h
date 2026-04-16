/* winnt_fix.h
 *
 * Force-include this header to ensure Windows SDK 10.0.26100.0's winnt.h
 * is fully processed BEFORE any LiveCode header (parsedef.h) defines
 * 'constant' as a typedef.
 *
 * Root cause: w32prefix.h sets WIN32_LEAN_AND_MEAN before <windows.h>,
 * which causes the compiler to skip the winnt.h section at line ~24176 on
 * the first pass. A later SDK header then needs that section, but by that
 * point parsedef.h has already defined 'constant' as a struct typedef,
 * causing C2059 "syntax error: 'constant'".
 *
 * Fix: include <winsock2.h> here (force-included before the source file),
 * which pulls in <windows.h> → <winnt.h> in full while no user typedefs
 * are yet in scope. The subsequent prefix.h → w32prefix.h → <windows.h>
 * becomes a no-op via the _WINDOWS_ include guard.
 */

#ifndef _WINSOCK2API_
#include <winsock2.h>
#endif
