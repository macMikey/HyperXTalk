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

//
// Windows ToolbarWindow32 backend for MCToolbar.
//

#ifdef _WINDOWS

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <commctrl.h>
#pragma comment(lib, "comctl32.lib")

#include "prefix.h"
#include "toolbar.h"

////////////////////////////////////////////////////////////////////////////////

// Maximum number of toolbar items (expand if needed)
#define W32_TOOLBAR_MAX_ITEMS 256

// WM_USER message sent from the toolbar subclass proc to route item clicks
#define WM_TOOLBAR_ITEM_CLICKED (WM_USER + 1)

// Per-item data stored alongside TBBUTTON
struct W32ToolbarItemData
{
    MCNewAutoNameRef  name;
    MCAutoStringRef label;
    MCAutoStringRef tooltip;
    MCAutoStringRef icon;
    bool            enabled;
};

class MCToolbarWin32Backend : public MCToolbarBackend
{
public:
    MCToolbarWin32Backend(MCToolbar *p_owner)
        : m_owner(p_owner), m_hwnd_toolbar(NULL), m_hwnd_parent(NULL),
          m_image_list(NULL), m_item_count(0), m_visible(true)
    {
        memset(m_buttons,   0, sizeof(m_buttons));
        memset(m_item_data, 0, sizeof(m_item_data));
    }

    ~MCToolbarWin32Backend() override {}

    void Create(void *p_window_handle) override
    {
        m_hwnd_parent = (HWND)p_window_handle;
        if (!m_hwnd_parent)
            return;

        // Ensure Common Controls are initialised
        INITCOMMONCONTROLSEX icex;
        icex.dwSize = sizeof(icex);
        icex.dwICC  = ICC_BAR_CLASSES;
        InitCommonControlsEx(&icex);

        m_hwnd_toolbar = CreateWindowEx(
            0,
            TOOLBARCLASSNAME,
            NULL,
            WS_CHILD | WS_VISIBLE |
            TBSTYLE_FLAT | TBSTYLE_TOOLTIPS | CCS_TOP,
            0, 0, 0, 0,
            m_hwnd_parent,
            (HMENU)1,
            GetModuleHandle(NULL),
            NULL);

        if (!m_hwnd_toolbar)
            return;

        // Required for TBBUTTON structs
        SendMessage(m_hwnd_toolbar, TB_BUTTONSTRUCTSIZE,
                    (WPARAM)sizeof(TBBUTTON), 0);

        // Standard 24x24 image list
        m_image_list = ImageList_Create(24, 24, ILC_COLOR32 | ILC_MASK, 8, 8);
        SendMessage(m_hwnd_toolbar, TB_SETIMAGELIST, 0,
                    (LPARAM)m_image_list);

        // Size the toolbar to fit within parent
        SendMessage(m_hwnd_toolbar, TB_AUTOSIZE, 0, 0);

        if (!m_visible)
            ShowWindow(m_hwnd_toolbar, SW_HIDE);
    }

    void Destroy() override
    {
        if (m_hwnd_toolbar)
        {
            DestroyWindow(m_hwnd_toolbar);
            m_hwnd_toolbar = NULL;
        }
        if (m_image_list)
        {
            ImageList_Destroy(m_image_list);
            m_image_list = NULL;
        }
        for (int i = 0; i < m_item_count; i++)
            m_item_data[i].~W32ToolbarItemData();
        m_item_count = 0;
    }

    void AddItem(const MCToolbarItem *p_item) override
    {
        if (!m_hwnd_toolbar || m_item_count >= W32_TOOLBAR_MAX_ITEMS)
            return;

        int t_idx = m_item_count;

        // Store item data
        new (&m_item_data[t_idx]) W32ToolbarItemData();
        /* UNCHECKED */ MCNameAssign(*(MCNameRef*)&m_item_data[t_idx].name,
                                     p_item->GetName());
        if (p_item->GetLabel())
            /* UNCHECKED */ MCValueAssign(*(MCStringRef*)&m_item_data[t_idx].label,
                                          p_item->GetLabel());
        if (p_item->GetTooltip())
            /* UNCHECKED */ MCValueAssign(*(MCStringRef*)&m_item_data[t_idx].tooltip,
                                          p_item->GetTooltip());
        m_item_data[t_idx].enabled = p_item->GetEnabled();

        // Build TBBUTTON
        TBBUTTON &btn = m_buttons[t_idx];
        memset(&btn, 0, sizeof(btn));

        MCToolbarItemStyle t_style = p_item->GetStyle();
        if (t_style == kMCToolbarItemStyleSeparator)
        {
            btn.fsStyle = TBSTYLE_SEP;
            btn.iBitmap = 8; // separator width
        }
        else
        {
            btn.idCommand = t_idx + 1; // command IDs are 1-based
            btn.fsStyle   = BTNS_BUTTON | BTNS_AUTOSIZE;
            btn.fsState   = p_item->GetEnabled() ? TBSTATE_ENABLED : 0;
            btn.iBitmap   = I_IMAGENONE;

            // Set label text — store as string ID via lParam
            if (p_item->GetLabel() && !MCStringIsEmpty(p_item->GetLabel()))
            {
                MCAutoStringRefAsWString t_wlabel;
                if (t_wlabel.Lock(p_item->GetLabel()))
                {
                    int t_str_idx = (int)SendMessage(m_hwnd_toolbar,
                                                     TB_ADDSTRING, 0,
                                                     (LPARAM)*t_wlabel);
                    btn.iString = t_str_idx;
                }
            }
        }

        SendMessage(m_hwnd_toolbar, TB_ADDBUTTONS, 1, (LPARAM)&btn);
        m_item_count++;

        SendMessage(m_hwnd_toolbar, TB_AUTOSIZE, 0, 0);
    }

    void RemoveItem(MCNameRef p_name) override
    {
        if (!m_hwnd_toolbar)
            return;

        for (int i = 0; i < m_item_count; i++)
        {
            if (MCNameIsEqualTo(*m_item_data[i].name, p_name,
                                kMCCompareCaseless))
            {
                SendMessage(m_hwnd_toolbar, TB_DELETEBUTTON, i, 0);
                m_item_data[i].~W32ToolbarItemData();

                // Shift remaining items
                for (int j = i; j < m_item_count - 1; j++)
                {
                    m_buttons[j]   = m_buttons[j + 1];
                    m_item_data[j] = m_item_data[j + 1];
                    // Re-sync command IDs
                    m_buttons[j].idCommand = j + 1;
                }
                m_item_count--;
                SendMessage(m_hwnd_toolbar, TB_AUTOSIZE, 0, 0);
                return;
            }
        }
    }

    void UpdateItem(const MCToolbarItem *p_item) override
    {
        if (!m_hwnd_toolbar)
            return;

        for (int i = 0; i < m_item_count; i++)
        {
            if (MCNameIsEqualTo(*m_item_data[i].name, p_item->GetName(),
                                kMCCompareCaseless))
            {
                // Update enabled state
                LPARAM t_state = p_item->GetEnabled() ? TBSTATE_ENABLED : 0;
                SendMessage(m_hwnd_toolbar, TB_SETSTATE,
                            (WPARAM)(i + 1), t_state);
                m_item_data[i].enabled = p_item->GetEnabled();
                return;
            }
        }
    }

    void ClearItems() override
    {
        if (!m_hwnd_toolbar)
            return;

        while (m_item_count > 0)
        {
            SendMessage(m_hwnd_toolbar, TB_DELETEBUTTON, 0, 0);
            m_item_data[--m_item_count].~W32ToolbarItemData();
        }
        SendMessage(m_hwnd_toolbar, TB_AUTOSIZE, 0, 0);
    }

    void SetDisplayMode(MCToolbarDisplayMode p_mode) override
    {
        if (!m_hwnd_toolbar)
            return;

        LONG t_style = GetWindowLong(m_hwnd_toolbar, GWL_STYLE);
        // Remove existing label/image flags
        t_style &= ~(TBSTYLE_LIST);

        switch (p_mode)
        {
            case kMCToolbarDisplayModeIconOnly:
                // No labels: strip TBSTYLE_LIST, items show icon only
                break;
            case kMCToolbarDisplayModeLabelOnly:
                // Show text only — remove images
                SendMessage(m_hwnd_toolbar, TB_SETIMAGELIST, 0, (LPARAM)NULL);
                t_style |= TBSTYLE_LIST;
                break;
            case kMCToolbarDisplayModeIconAndLabel:
            case kMCToolbarDisplayModeDefault:
            default:
                SendMessage(m_hwnd_toolbar, TB_SETIMAGELIST, 0,
                            (LPARAM)m_image_list);
                t_style |= TBSTYLE_LIST;
                break;
        }
        SetWindowLong(m_hwnd_toolbar, GWL_STYLE, t_style);
        SendMessage(m_hwnd_toolbar, TB_AUTOSIZE, 0, 0);
    }

    void SetVisible(bool p_visible) override
    {
        m_visible = p_visible;
        if (m_hwnd_toolbar)
            ShowWindow(m_hwnd_toolbar, p_visible ? SW_SHOW : SW_HIDE);
    }

    bool GetVisible() override
    {
        return m_visible;
    }

    // Called from the parent window's WndProc when WM_COMMAND is received
    void HandleCommand(WPARAM wParam)
    {
        int t_id = LOWORD(wParam) - 1; // back to 0-based
        if (t_id < 0 || t_id >= m_item_count)
            return;
        if (m_owner && *m_item_data[t_id].name)
            m_owner->itemClicked(*m_item_data[t_id].name);
    }

private:
    MCToolbar              *m_owner;
    HWND                    m_hwnd_toolbar;
    HWND                    m_hwnd_parent;
    HIMAGELIST              m_image_list;
    int                     m_item_count;
    bool                    m_visible;
    TBBUTTON                m_buttons[W32_TOOLBAR_MAX_ITEMS];
    W32ToolbarItemData      m_item_data[W32_TOOLBAR_MAX_ITEMS];
};

////////////////////////////////////////////////////////////////////////////////
// Factory

MCToolbarBackend *MCToolbarCreatePlatformBackend(MCToolbar *p_owner)
{
    return new MCToolbarWin32Backend(p_owner);
}

#endif // _WINDOWS
