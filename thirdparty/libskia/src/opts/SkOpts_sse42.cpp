#if defined(__x86_64__) || defined(__i386__)
/*
 * Copyright 2016 Google Inc.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file.
 */

#include "SkOpts.h"

#define SK_OPTS_NS sse42
#include "SkChecksum_opts.h"

namespace SkOpts {
    void Init_sse42() {
        hash_fn = sse42::hash_fn;
    }
}
#endif /* __x86_64__ || __i386__ */

#if defined(_M_X64) || defined(_M_IX86)
/* MSVC x86/x64: GCC-only guard above means Init_sse42() was never defined on MSVC.
 * Provide a no-op stub so the linker resolves the symbol; portable Skia
 * defaults (installed by Init_none/SkOpts_none.cpp) remain in effect. */
namespace SkOpts { void Init_sse42() {} }
#endif
