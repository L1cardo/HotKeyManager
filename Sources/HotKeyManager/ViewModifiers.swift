//
//  ViewModifiers.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/24.
//

import SwiftUI

public extension View {
    /**
     Associates a global keyboard shortcut with a control.

     This is mostly useful to have the keyboard shortcut show for a `Button` in a `Menu` or `MenuBarExtra`.

     It does not trigger the control's action.

     - Important: Do not use it in a `CommandGroup` as the shortcut recorder will think the shortcut is already taken. It does remove the shortcut while the recorder is active.
     */
    func globalHotKey(_ name: HotKeyManager.Name) -> some View {
        modifier(GlobalHotKeyViewModifier(name: name))
    }
}

private struct GlobalHotKeyViewModifier: ViewModifier {
    @State private var isRecorderActive = false
    @State private var triggerRefresh = false

    let name: HotKeyManager.Name

    func body(content: Content) -> some View {
        content
            .keyboardShortcut(isRecorderActive ? nil : HotKeyManager.getHotKey(for: name)?.toSwiftUI)
            .id(triggerRefresh)
            .onReceive(NotificationCenter.default.publisher(for: .hotKeyByNameDidChange)) { notification in
                guard let changedName = notification.userInfo?["name"] as? HotKeyManager.Name,
                      changedName == name
                else {
                    return
                }

                triggerRefresh.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .recorderActiveStatusDidChange)) { notification in
                isRecorderActive = notification.userInfo?["isActive"] as? Bool ?? false
            }
    }
}
