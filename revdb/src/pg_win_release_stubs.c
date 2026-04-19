/*
 * pg_win_release_stubs.c
 *
 * Stubs for Debug-CRT symbols referenced by prebuilt Debug-mode static
 * libraries (libpq.lib) when they are linked into a Release build.
 *
 * Compiled only for Release|x64 via the ClCompile condition in
 * dbpostgresql.vcxproj.
 */

#include <ctype.h>

/*
 * _chvalidator
 *
 * MSVC Debug CRT character-type validator.  In Release builds the
 * character-classification macros (isalpha, isdigit, …) expand to direct
 * _pctype table lookups and this function is never emitted by the compiler.
 * A prebuilt Debug-mode libpq.lib references it as an external symbol, so
 * we provide a correct implementation using the Release CRT's _pctype table.
 */
int __cdecl _chvalidator(int c, int maskval)
{
    return _pctype[c] & maskval;
}
