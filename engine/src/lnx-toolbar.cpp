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
// Linux GTK toolbar backend for MCToolbar.
// Uses GtkToolbar (GTK 3). On GTK 4 this class is a no-op stub —
// a GtkBox+GtkButton implementation can replace it later.
//

#ifdef TARGET_PLATFORM_LINUX

#include <gtk/gtk.h>

#include "prefix.h"
#include "toolbar.h"

////////////////////////////////////////////////////////////////////////////////

struct LnxToolbarItemData
{
    MCNewAutoNameRef   name;
    GtkToolItem    *widget;   // nil for separator/space items
};

class MCToolbarLinuxBackend : public MCToolbarBackend
{
public:
    MCToolbarLinuxBackend(MCToolbar *p_owner)
        : m_owner(p_owner), m_toolbar(NULL), m_parent(NULL),
          m_item_count(0), m_visible(true),
          m_display_mode(kMCToolbarDisplayModeDefault)
    {
    }

    ~MCToolbarLinuxBackend() override {}

    void Create(void *p_window_handle) override
    {
#if GTK_MAJOR_VERSION < 4
        m_parent = (GtkWidget *)p_window_handle;
        if (!m_parent)
            return;

        m_toolbar = gtk_toolbar_new();
        if (!m_toolbar)
            return;

        _applyDisplayMode();

        // Pack the toolbar at the top of the parent window's vbox.
        // The engine's Linux window is a GtkWindow with a GtkVBox as the
        // top-level container.
        GtkWidget *t_child = gtk_bin_get_child(GTK_BIN(m_parent));
        if (t_child && GTK_IS_BOX(t_child))
        {
            gtk_box_pack_start(GTK_BOX(t_child), m_toolbar,
                               FALSE, FALSE, 0);
            gtk_box_reorder_child(GTK_BOX(t_child), m_toolbar, 0);
        }
        else
        {
            // Fallback: add directly to window
            gtk_container_add(GTK_CONTAINER(m_parent), m_toolbar);
        }

        if (m_visible)
            gtk_widget_show(m_toolbar);
        else
            gtk_widget_hide(m_toolbar);
#endif
    }

    void Destroy() override
    {
#if GTK_MAJOR_VERSION < 4
        if (m_toolbar)
        {
            gtk_widget_destroy(m_toolbar);
            m_toolbar = NULL;
        }
        for (int i = 0; i < m_item_count; i++)
            m_items[i].~LnxToolbarItemData();
        m_item_count = 0;
#endif
    }

    void AddItem(const MCToolbarItem *p_item) override
    {
#if GTK_MAJOR_VERSION < 4
        if (!m_toolbar || m_item_count >= 256)
            return;

        int t_idx = m_item_count;
        new (&m_items[t_idx]) LnxToolbarItemData();
        /* UNCHECKED */ MCNameAssign(*(MCNameRef*)&m_items[t_idx].name,
                                     p_item->GetName());

        GtkToolItem *t_item = NULL;
        MCToolbarItemStyle t_style = p_item->GetStyle();

        if (t_style == kMCToolbarItemStyleSeparator)
        {
            t_item = gtk_separator_tool_item_new();
        }
        else if (t_style == kMCToolbarItemStyleSpace ||
                 t_style == kMCToolbarItemStyleFlexSpace)
        {
            t_item = gtk_separator_tool_item_new();
            gtk_separator_tool_item_set_draw(
                GTK_SEPARATOR_TOOL_ITEM(t_item), FALSE);
            if (t_style == kMCToolbarItemStyleFlexSpace)
                gtk_tool_item_set_expand(t_item, TRUE);
        }
        else
        {
            GtkToolButton *t_button = NULL;

            // Label
            const char *t_label_cstr = "";
            MCAutoStringRefAsCString t_label_c;
            if (p_item->GetLabel() && !MCStringIsEmpty(p_item->GetLabel()))
                if (t_label_c.Lock(p_item->GetLabel()))
                    t_label_cstr = *t_label_c;

            t_button = GTK_TOOL_BUTTON(
                gtk_tool_button_new(NULL, t_label_cstr));

            // Icon — try as a theme icon name
            if (p_item->GetIcon() && !MCStringIsEmpty(p_item->GetIcon()))
            {
                MCAutoStringRefAsCString t_icon_c;
                if (t_icon_c.Lock(p_item->GetIcon()))
                {
                    GtkWidget *t_icon = gtk_image_new_from_icon_name(
                        *t_icon_c, GTK_ICON_SIZE_LARGE_TOOLBAR);
                    if (t_icon)
                        gtk_tool_button_set_icon_widget(t_button, t_icon);
                }
            }

            t_item = GTK_TOOL_ITEM(t_button);

            if (!p_item->GetEnabled())
                gtk_widget_set_sensitive(GTK_WIDGET(t_item), FALSE);

            // Tooltip
            if (p_item->GetTooltip() && !MCStringIsEmpty(p_item->GetTooltip()))
            {
                MCAutoStringRefAsCString t_tip_c;
                if (t_tip_c.Lock(p_item->GetTooltip()))
                    gtk_tool_item_set_tooltip_text(t_item, *t_tip_c);
            }

            // Click signal — pass index as user data
            g_signal_connect(t_button, "clicked",
                             G_CALLBACK(_onItemClicked),
                             GINT_TO_POINTER(t_idx));
            // Store backend pointer in item data
            g_object_set_data(G_OBJECT(t_button), "backend",
                              (gpointer)this);
        }

        m_items[t_idx].widget = t_item;
        gtk_toolbar_insert(GTK_TOOLBAR(m_toolbar), t_item, -1);
        gtk_widget_show(GTK_WIDGET(t_item));
        m_item_count++;
#endif
    }

    void RemoveItem(MCNameRef p_name) override
    {
#if GTK_MAJOR_VERSION < 4
        if (!m_toolbar)
            return;

        for (int i = 0; i < m_item_count; i++)
        {
            if (MCNameIsEqualTo(*m_items[i].name, p_name,
                                kMCCompareCaseless))
            {
                if (m_items[i].widget)
                {
                    gtk_container_remove(GTK_CONTAINER(m_toolbar),
                                        GTK_WIDGET(m_items[i].widget));
                }
                m_items[i].~LnxToolbarItemData();

                for (int j = i; j < m_item_count - 1; j++)
                    m_items[j] = m_items[j + 1];
                m_item_count--;
                return;
            }
        }
#endif
    }

    void UpdateItem(const MCToolbarItem *p_item) override
    {
#if GTK_MAJOR_VERSION < 4
        for (int i = 0; i < m_item_count; i++)
        {
            if (MCNameIsEqualTo(*m_items[i].name, p_item->GetName(),
                                kMCCompareCaseless))
            {
                GtkToolItem *t_widget = m_items[i].widget;
                if (!t_widget)
                    return;

                gtk_widget_set_sensitive(GTK_WIDGET(t_widget),
                                        p_item->GetEnabled() ? TRUE : FALSE);

                if (GTK_IS_TOOL_BUTTON(t_widget))
                {
                    GtkToolButton *t_btn = GTK_TOOL_BUTTON(t_widget);

                    if (p_item->GetLabel())
                    {
                        MCAutoStringRefAsCString t_lbl;
                        if (t_lbl.Lock(p_item->GetLabel()))
                            gtk_tool_button_set_label(t_btn, *t_lbl);
                    }
                    if (p_item->GetTooltip())
                    {
                        MCAutoStringRefAsCString t_tip;
                        if (t_tip.Lock(p_item->GetTooltip()))
                            gtk_tool_item_set_tooltip_text(t_widget, *t_tip);
                    }
                }
                return;
            }
        }
#endif
    }

    void ClearItems() override
    {
#if GTK_MAJOR_VERSION < 4
        if (!m_toolbar)
            return;

        for (int i = 0; i < m_item_count; i++)
        {
            if (m_items[i].widget)
            {
                gtk_container_remove(GTK_CONTAINER(m_toolbar),
                                    GTK_WIDGET(m_items[i].widget));
            }
            m_items[i].~LnxToolbarItemData();
        }
        m_item_count = 0;
#endif
    }

    void SetDisplayMode(MCToolbarDisplayMode p_mode) override
    {
        m_display_mode = p_mode;
#if GTK_MAJOR_VERSION < 4
        if (m_toolbar)
            _applyDisplayMode();
#endif
    }

    void SetVisible(bool p_visible) override
    {
        m_visible = p_visible;
#if GTK_MAJOR_VERSION < 4
        if (m_toolbar)
        {
            if (p_visible)
                gtk_widget_show(m_toolbar);
            else
                gtk_widget_hide(m_toolbar);
        }
#endif
    }

    bool GetVisible() override
    {
        return m_visible;
    }

private:
    MCToolbar              *m_owner;
    GtkWidget              *m_toolbar;
    GtkWidget              *m_parent;
    int                     m_item_count;
    bool                    m_visible;
    MCToolbarDisplayMode    m_display_mode;
    LnxToolbarItemData      m_items[256];

    void _applyDisplayMode()
    {
#if GTK_MAJOR_VERSION < 4
        if (!m_toolbar)
            return;
        GtkToolbarStyle t_style;
        switch (m_display_mode)
        {
            case kMCToolbarDisplayModeIconOnly:
                t_style = GTK_TOOLBAR_ICONS;
                break;
            case kMCToolbarDisplayModeLabelOnly:
                t_style = GTK_TOOLBAR_TEXT;
                break;
            case kMCToolbarDisplayModeIconAndLabel:
            case kMCToolbarDisplayModeDefault:
            default:
                t_style = GTK_TOOLBAR_BOTH;
                break;
        }
        gtk_toolbar_set_style(GTK_TOOLBAR(m_toolbar), t_style);
#endif
    }

    static void _onItemClicked(GtkToolButton *button, gpointer user_data)
    {
        int t_idx = GPOINTER_TO_INT(user_data);
        MCToolbarLinuxBackend *t_self =
            (MCToolbarLinuxBackend *)g_object_get_data(
                G_OBJECT(button), "backend");
        if (!t_self || t_idx < 0 || t_idx >= t_self->m_item_count)
            return;
        if (t_self->m_owner && *t_self->m_items[t_idx].name)
            t_self->m_owner->itemClicked(*t_self->m_items[t_idx].name);
    }
};

////////////////////////////////////////////////////////////////////////////////
// Factory

MCToolbarBackend *MCToolbarCreatePlatformBackend(MCToolbar *p_owner)
{
    return new MCToolbarLinuxBackend(p_owner);
}

#endif // TARGET_PLATFORM_LINUX
