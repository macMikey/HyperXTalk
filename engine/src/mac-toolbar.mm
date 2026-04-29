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
// macOS NSToolbar backend for MCToolbar.
// Ported from the org.openxtalk.nstoolbar extension (Emily-Elizabeth Howard).
//

#import <Cocoa/Cocoa.h>

#include "prefix.h"
#include "toolbar.h"

////////////////////////////////////////////////////////////////////////////////
// Forward declare C++ backend so ObjC delegate can hold a pointer to it.
// The @implementation that calls OnItemClicked() is split into a category
// defined AFTER the complete C++ class body.

class MCToolbarMacBackend;

////////////////////////////////////////////////////////////////////////////////
// NSToolbarDelegate interface

@interface MCNSToolbarDelegate : NSObject <NSToolbarDelegate>
@property (nonatomic, assign) MCToolbarMacBackend *backend;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *itemMeta;
@property (nonatomic, strong) NSMutableArray<NSString *>  *itemOrder;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSImage *> *itemImages;
@end

////////////////////////////////////////////////////////////////////////////////
// NSToolbarDelegate implementation — all delegate methods EXCEPT
// toolbarItemClicked:, which is in the (MCBackendActions) category below
// so that it can see the complete MCToolbarMacBackend definition.

@implementation MCNSToolbarDelegate

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _itemMeta   = [NSMutableDictionary dictionary];
        _itemOrder  = [NSMutableArray array];
        _itemImages = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [_itemOrder copy];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    NSMutableArray *allowed = [_itemOrder mutableCopy];
    [allowed addObject:NSToolbarFlexibleSpaceItemIdentifier];
    [allowed addObject:NSToolbarSpaceItemIdentifier];
    return [allowed copy];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    // Pass through system items
    if ([itemIdentifier hasPrefix:@"NSToolbar"])
        return nil;

    NSMutableDictionary *meta = _itemMeta[itemIdentifier];
    if (!meta)
        return nil;

    NSToolbarItem *item = [[NSToolbarItem alloc]
                            initWithItemIdentifier:itemIdentifier];

    NSString *label = meta[@"label"] ?: itemIdentifier;
    item.label        = label;
    item.paletteLabel = label;
    item.toolTip      = meta[@"tooltip"] ?: @"";

    NSImage *img = _itemImages[itemIdentifier];
    if (!img)
    {
        NSString *iconName = meta[@"iconName"] ?: @"";
        if (iconName.length > 0)
        {
            if (@available(macOS 11.0, *))
            {
                img = [NSImage imageWithSystemSymbolName:iconName
                                 accessibilityDescription:label];
            }
            if (!img)
                img = [NSImage imageNamed:iconName];
        }
    }
    if (img)
        item.image = img;

    item.target        = self;
    item.action        = @selector(toolbarItemClicked:);
    item.autovalidates = NO;
    item.enabled       = [meta[@"enabled"] boolValue];

    return item;
}

@end

////////////////////////////////////////////////////////////////////////////////
// C++ backend implementation

class MCToolbarMacBackend : public MCToolbarBackend
{
public:
    MCToolbarMacBackend(MCToolbar *p_owner)
        : m_owner(p_owner), m_toolbar(nil), m_delegate(nil), m_window(nil)
    {
    }

    ~MCToolbarMacBackend() override
    {
    }

    void Create(void *p_window_handle) override
    {
        @autoreleasepool
        {
            // Use the owner object's ID as the toolbar identifier so it's
            // unique per stack.
            char t_id_buf[32];
            snprintf(t_id_buf, sizeof(t_id_buf), "mctoolbar_%p", (void *)m_owner);
            NSString *t_ident = [NSString stringWithUTF8String:t_id_buf];

            m_delegate = [[MCNSToolbarDelegate alloc] init];
            m_delegate.backend = this;

            m_toolbar = [[NSToolbar alloc] initWithIdentifier:t_ident];
            m_toolbar.delegate = m_delegate;
            m_toolbar.allowsUserCustomization = YES;

            m_window = (NSWindow *)p_window_handle;
            if (m_window)
            {
                // Attaching a toolbar shrinks the content area in-place, which
                // causes the window contents to creep down by the toolbar height
                // on every open/close cycle.  Capture the content rect first,
                // then restore it after attaching so the content area stays put.
                NSRect t_content = [m_window
                                    contentRectForFrameRect:m_window.frame];
                m_window.toolbar = m_toolbar;
                NSRect t_new_frame = [m_window
                                      frameRectForContentRect:t_content];
                [m_window setFrame:t_new_frame display:NO];
            }
        }
    }

    void Destroy() override
    {
        @autoreleasepool
        {
            if (m_toolbar && m_window)
            {
                // Capture the content rect WITH the toolbar attached.  This is
                // the stack's true usable area (below the toolbar).  We must do
                // this BEFORE detaching, because window.toolbar = nil expands
                // the content area in-place (frame stays, content grows by
                // toolbar height), which fires ProcessDidResize → m_content
                // is saved with the bloated value → on the next open the frame
                // is set too large before the toolbar is re-attached, causing
                // the content to creep down by one toolbar height per cycle.
                NSRect t_content = [m_window contentRectForFrameRect:m_window.frame];

                m_toolbar.delegate = nil;
                if ([m_window.toolbar isEqual:m_toolbar])
                    m_window.toolbar = nil;
                m_toolbar = nil;

                // Shrink the frame so the content area stays at exactly the
                // same rect it had while the toolbar was attached.  This fires
                // ProcessDidResize with the correct (small) content, which
                // saves the right m_content for the engine.
                NSRect t_new_frame = [m_window frameRectForContentRect:t_content];
                [m_window setFrame:t_new_frame display:NO];
            }
            m_window   = nil;
            m_delegate = nil;
        }
    }

    void AddItem(const MCToolbarItem *p_item) override
    {
        @autoreleasepool
        {
            NSString *t_ident = _nameToNSString(p_item->GetName());

            NSMutableDictionary *meta = [NSMutableDictionary dictionary];
            meta[@"label"]    = _stringRefToNSString(p_item->GetLabel());
            meta[@"tooltip"]  = _stringRefToNSString(p_item->GetTooltip());
            meta[@"iconName"] = _stringRefToNSString(p_item->GetIcon());
            meta[@"enabled"]  = @(p_item->GetEnabled());

            m_delegate.itemMeta[t_ident]  = meta;
            [m_delegate.itemOrder addObject:t_ident];

            if (m_toolbar)
            {
                NSInteger t_index = (NSInteger)m_toolbar.items.count;
                [m_toolbar insertItemWithItemIdentifier:t_ident atIndex:t_index];
            }
        }
    }

    void RemoveItem(MCNameRef p_name) override
    {
        @autoreleasepool
        {
            NSString *t_ident = _nameToNSString(p_name);

            if (m_toolbar)
            {
                NSArray *items = m_toolbar.items;
                for (NSInteger i = (NSInteger)items.count - 1; i >= 0; i--)
                {
                    if ([((NSToolbarItem *)items[i]).itemIdentifier
                            isEqualToString:t_ident])
                    {
                        [m_toolbar removeItemAtIndex:i];
                        break;
                    }
                }
            }

            [m_delegate.itemMeta   removeObjectForKey:t_ident];
            [m_delegate.itemOrder  removeObject:t_ident];
            [m_delegate.itemImages removeObjectForKey:t_ident];
        }
    }

    void UpdateItem(const MCToolbarItem *p_item) override
    {
        @autoreleasepool
        {
            NSString *t_ident = _nameToNSString(p_item->GetName());

            NSMutableDictionary *meta = m_delegate.itemMeta[t_ident];
            if (!meta)
                return;

            meta[@"label"]   = _stringRefToNSString(p_item->GetLabel());
            meta[@"tooltip"] = _stringRefToNSString(p_item->GetTooltip());
            meta[@"enabled"] = @(p_item->GetEnabled());

            // Push live updates to existing toolbar items
            if (m_toolbar)
            {
                for (NSToolbarItem *item in m_toolbar.items)
                {
                    if ([item.itemIdentifier isEqualToString:t_ident])
                    {
                        NSString *lbl = meta[@"label"];
                        item.label        = lbl;
                        item.paletteLabel = lbl;
                        item.toolTip      = meta[@"tooltip"] ?: @"";
                        item.enabled      = p_item->GetEnabled();
                        break;
                    }
                }
            }

            // Icon update: reload image if icon name changed
            NSString *t_icon = _stringRefToNSString(p_item->GetIcon());
            if (t_icon.length > 0)
            {
                NSImage *img = nil;
                if (@available(macOS 11.0, *))
                    img = [NSImage imageWithSystemSymbolName:t_icon
                                     accessibilityDescription:meta[@"label"]];
                if (!img)
                    img = [NSImage imageNamed:t_icon];
                if (img)
                {
                    m_delegate.itemImages[t_ident] = img;
                    if (m_toolbar)
                    {
                        for (NSToolbarItem *item in m_toolbar.items)
                        {
                            if ([item.itemIdentifier isEqualToString:t_ident])
                            {
                                item.image = img;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }

    void ClearItems() override
    {
        @autoreleasepool
        {
            if (m_toolbar)
            {
                while (m_toolbar.items.count > 0)
                    [m_toolbar removeItemAtIndex:0];
            }
            [m_delegate.itemMeta   removeAllObjects];
            [m_delegate.itemOrder  removeAllObjects];
            [m_delegate.itemImages removeAllObjects];
        }
    }

    void SetDisplayMode(MCToolbarDisplayMode p_mode) override
    {
        if (m_toolbar)
            m_toolbar.displayMode = (NSToolbarDisplayMode)p_mode;
    }

    void SetVisible(bool p_visible) override
    {
        if (m_toolbar)
            m_toolbar.visible = p_visible ? YES : NO;
    }

    bool GetVisible() override
    {
        return m_toolbar ? (m_toolbar.visible == YES) : false;
    }

    // Called by the ObjC delegate when an item is clicked
    void OnItemClicked(MCNameRef p_name)
    {
        if (m_owner)
            m_owner->itemClicked(p_name);
    }

private:
    MCToolbar              *m_owner;
    NSToolbar              *m_toolbar;
    MCNSToolbarDelegate    *m_delegate;
    NSWindow               *m_window;   // window the toolbar is attached to

    static NSString *_stringRefToNSString(MCStringRef p_str)
    {
        if (!p_str || MCStringIsEmpty(p_str))
            return @"";
        MCAutoStringRefAsCString t_cstr;
        if (!t_cstr.Lock(p_str))
            return @"";
        return [NSString stringWithUTF8String:*t_cstr];
    }

    static NSString *_nameToNSString(MCNameRef p_name)
    {
        if (!p_name)
            return @"";
        return _stringRefToNSString(MCNameGetString(p_name));
    }
};

////////////////////////////////////////////////////////////////////////////////
// MCNSToolbarDelegate category — defined here so it can see the complete
// MCToolbarMacBackend class and call OnItemClicked().

@implementation MCNSToolbarDelegate (MCBackendActions)

- (void)toolbarItemClicked:(NSToolbarItem *)item
{
    if (!_backend)
        return;

    NSString *ident = item.itemIdentifier;
    MCAutoStringRef t_str;
    /* UNCHECKED */ MCStringCreateWithCString([ident UTF8String], &t_str);
    MCNewAutoNameRef t_name;
    /* UNCHECKED */ MCNameCreate(*t_str, &t_name);
    _backend->OnItemClicked(*t_name);
}

@end

////////////////////////////////////////////////////////////////////////////////
// Factory

MCToolbarBackend *MCToolbarCreatePlatformBackend(MCToolbar *p_owner)
{
    return new MCToolbarMacBackend(p_owner);
}
