/* Copyright (C) 2003-2015 LiveCode Ltd.

This file is part of LiveCode.

LiveCode is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License v3 as published by the Free
Software Foundation.

LiveCode is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with LiveCode.  If not see <http://www.gnu.org/licenses/>.  */

#include "prefix.h"

#include "globdefs.h"
#include "filedefs.h"
#include "objdefs.h"
#include "parsedef.h"

#include "exec.h"
#include "exec-interface.h"
#include "toolbar.h"

////////////////////////////////////////////////////////////////////////////////
// Display mode enum type

static MCExecEnumTypeElementInfo _kMCInterfaceToolbarDisplayModeElementInfo[] =
{
    { "default",      kMCToolbarDisplayModeDefault,      false },
    { "iconAndLabel", kMCToolbarDisplayModeIconAndLabel, false },
    { "iconOnly",     kMCToolbarDisplayModeIconOnly,     false },
    { "labelOnly",    kMCToolbarDisplayModeLabelOnly,    false },
};

static MCExecEnumTypeInfo _kMCInterfaceToolbarDisplayModeTypeInfo =
{
    "Interface.ToolbarDisplayMode",
    sizeof(_kMCInterfaceToolbarDisplayModeElementInfo) /
        sizeof(MCExecEnumTypeElementInfo),
    _kMCInterfaceToolbarDisplayModeElementInfo,
};

MCExecEnumTypeInfo *kMCInterfaceToolbarDisplayModeTypeInfo =
    &_kMCInterfaceToolbarDisplayModeTypeInfo;

////////////////////////////////////////////////////////////////////////////////
// Toolbar property accessors

void MCToolbar::GetDisplayMode(MCExecContext& ctxt, intenum_t& r_mode)
{
    r_mode = (intenum_t)m_display_mode;
}

void MCToolbar::SetDisplayMode(MCExecContext& ctxt, intenum_t p_mode)
{
    m_display_mode = (MCToolbarDisplayMode)p_mode;
    if (m_backend != nil)
        m_backend->SetDisplayMode(m_display_mode);
}

void MCToolbar::GetToolbarVisible(MCExecContext& ctxt, bool& r_visible)
{
    r_visible = m_toolbar_visible;
}

void MCToolbar::SetToolbarVisible(MCExecContext& ctxt, bool p_visible)
{
    m_toolbar_visible = p_visible;
    if (m_backend != nil)
        m_backend->SetVisible(p_visible);
}

void MCToolbar::GetItemNames(MCExecContext& ctxt, MCStringRef& r_names)
{
    MCAutoListRef t_list;
    /* UNCHECKED */ MCListCreateMutable('\n', &t_list);
    for (uindex_t i = 0; i < m_item_count; i++)
    {
        /* UNCHECKED */ MCListAppend(*t_list,
                                     MCNameGetString(m_items[i].GetName()));
    }
    /* UNCHECKED */ MCListCopyAsString(*t_list, r_names);
}

////////////////////////////////////////////////////////////////////////////////
// Per-item property accessors

void MCToolbar::GetItemLabel(MCExecContext& ctxt, MCNameRef p_item,
                             MCStringRef& r_label)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
    {
        r_label = MCValueRetain(kMCEmptyString);
        return;
    }
    r_label = MCValueRetain(t_item->GetLabel() ? t_item->GetLabel()
                                                : kMCEmptyString);
}

void MCToolbar::SetItemLabel(MCExecContext& ctxt, MCNameRef p_item,
                             MCStringRef p_label)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
        return;
    t_item->SetLabel(p_label);
    if (m_backend != nil)
        m_backend->UpdateItem(t_item);
}

void MCToolbar::GetItemTooltip(MCExecContext& ctxt, MCNameRef p_item,
                               MCStringRef& r_tooltip)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
    {
        r_tooltip = MCValueRetain(kMCEmptyString);
        return;
    }
    r_tooltip = MCValueRetain(t_item->GetTooltip() ? t_item->GetTooltip()
                                                   : kMCEmptyString);
}

void MCToolbar::SetItemTooltip(MCExecContext& ctxt, MCNameRef p_item,
                               MCStringRef p_tooltip)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
        return;
    t_item->SetTooltip(p_tooltip);
    if (m_backend != nil)
        m_backend->UpdateItem(t_item);
}

void MCToolbar::GetItemEnabled(MCExecContext& ctxt, MCNameRef p_item,
                               bool& r_enabled)
{
    MCToolbarItem *t_item = FindItem(p_item);
    r_enabled = (t_item != nil) ? t_item->GetEnabled() : false;
}

void MCToolbar::SetItemEnabled(MCExecContext& ctxt, MCNameRef p_item,
                               bool p_enabled)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
        return;
    t_item->SetEnabled(p_enabled);
    if (m_backend != nil)
        m_backend->UpdateItem(t_item);
}

void MCToolbar::GetItemIcon(MCExecContext& ctxt, MCNameRef p_item,
                            MCStringRef& r_icon)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
    {
        r_icon = MCValueRetain(kMCEmptyString);
        return;
    }
    r_icon = MCValueRetain(t_item->GetIcon() ? t_item->GetIcon()
                                             : kMCEmptyString);
}

void MCToolbar::SetItemIcon(MCExecContext& ctxt, MCNameRef p_item,
                            MCStringRef p_icon)
{
    MCToolbarItem *t_item = FindItem(p_item);
    if (t_item == nil)
        return;
    t_item->SetIcon(p_icon);
    if (m_backend != nil)
        m_backend->UpdateItem(t_item);
}
