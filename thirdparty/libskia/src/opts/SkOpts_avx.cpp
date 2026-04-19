#if defined(__x86_64__) || defined(__i386__)
/*
 * Copyright 2016 Google Inc.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include "SkSafe_math.h"   // Keep this first.
#include "SkOpts.h"

#define SK_OPTS_NS avx

#if defined(_INC_MATH) && !defined(INC_MATH_IS_SAFE_NOW)
    #error We have included ucrt\math.h without protecting it against ODR violation.
#endif

namespace SkOpts {
    void Init_avx() { }
}
#endif /* __x86_64__ || __i386__ */

#if defined(_M_X64) || defined(_M_IX86)
/* MSVC x86/x64: GCC-only guard above means Init_avx() was never defined on MSVC.
 * Provide a no-op stub so the linker resolves the symbol; portable Skia
 * defaults (installed by Init_none/SkOpts_none.cpp) remain in effect. */
namespace SkOpts { void Init_avx() {} }
#endif
