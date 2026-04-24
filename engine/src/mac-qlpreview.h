/* Copyright (C) 2024 HyperXTalk contributors.

This file is part of HyperXTalk.

HyperXTalk is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation. */

#ifndef MAC_QLPREVIEW_H
#define MAC_QLPREVIEW_H

#include "foundation.h"

class MCStack;

// Write a PNG snapshot of p_stack's first card as the extended attribute
// "com.hyperxtalk.qlpreview" on the file at p_path.
// Called from MCDispatch::dosavestack() on macOS after the file is written.
// Safe to call when the stack has no window (no-op in that case).
void MCStackWriteQLPreview(MCStack *p_stack, MCStringRef p_path);

#endif // MAC_QLPREVIEW_H
