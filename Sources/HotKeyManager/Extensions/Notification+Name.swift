//
//  Notification+Name.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/24.
//

import Foundation

public extension Notification.Name {
    static let hotKeyByNameDidChange = Notification.Name("HotKeyManager_hotKeyByNameDidChange")
    static let recorderActiveStatusDidChange = Notification.Name("HotKeyManager_recorderActiveStatusDidChange")
}
