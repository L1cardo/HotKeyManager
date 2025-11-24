//
//  HotKeyManager.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Combine
import Foundation
import SwiftUI

/// Global keyboard shortcuts manager.
public enum HotKeyManager {
    /// A strongly-typed name for a hotkey.
    public struct Name: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
        public let rawValue: String
        public let defaultShortcut: HotKey?

        public init(rawValue: String) {
            self.rawValue = rawValue
            self.defaultShortcut = nil
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
            self.defaultShortcut = nil
        }

        public init(_ name: String, default defaultShortcut: HotKey? = nil) {
            self.rawValue = name
            self.defaultShortcut = defaultShortcut

            if let defaultShortcut {
                HotKeyManager.registerDefault(defaultShortcut, for: name)
            }

            // Register default if not present
            if defaultShortcut != nil, !HotKeyManager.userDefaultsContains(name: self) {
                HotKeyManager.setShortcut(defaultShortcut, for: self)
            }
        }
    }

    /// Events triggered by the hotkey processor.
    public enum Event: Equatable, Sendable {
        case keyDown
        case keyUp
    }

    // MARK: - Internal Storage

    private static let userDefaultsPrefix = "HotKeyManager_"
    private nonisolated(unsafe) static var _defaults: [String: HotKey] = [:]
    private static let _lock = NSLock()

    static func registerDefault(_ shortcut: HotKey, for name: String) {
        _lock.lock()
        defer { _lock.unlock() }
        _defaults[name] = shortcut
    }

    private static func userDefaultsKey(for name: Name) -> String {
        "\(userDefaultsPrefix)\(name.rawValue)"
    }

    static func userDefaultsContains(name: Name) -> Bool {
        UserDefaults.standard.object(forKey: userDefaultsKey(for: name)) != nil
    }

    // MARK: - Public API

    /// Get the current shortcut for a name.
    public static func getShortcut(for name: Name) -> HotKey? {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey(for: name)),
            let shortcut = try? JSONDecoder().decode(HotKey.self, from: data)
        else {
            return nil
        }
        return shortcut
    }

    /// Set the shortcut for a name.
    public static func setShortcut(_ shortcut: HotKey?, for name: Name) {
        if let shortcut = shortcut {
            if let data = try? JSONEncoder().encode(shortcut) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey(for: name))
            }
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey(for: name))
        }

        // Notify listeners (implementation detail: could use NotificationCenter or Combine)
        NotificationCenter.default.post(name: .hotKeyDidChange, object: nil, userInfo: ["name": name])
    }

    /// Reset the shortcut to its default.
    public static func reset(_ name: Name) {
        setShortcut(name.defaultShortcut, for: name)
    }

    /// Reset all shortcuts to their defaults.
    public static func resetAll() {
        // 1. Remove all HotKeyManager keys from UserDefaults
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(userDefaultsPrefix) {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // 2. Restore registered defaults
        _lock.lock()
        let defaultsToRestore = _defaults
        _lock.unlock()

        for (name, shortcut) in defaultsToRestore {
            setShortcut(shortcut, for: Name(rawValue: name))
        }
    }

    // MARK: - Event Registration

    /// Register a handler for a specific event on a shortcut.
    /// - Parameters:
    ///   - event: The event to listen for (e.g. .keyDown, .doubleTapUp).
    ///   - name: The name of the shortcut to monitor.
    ///   - action: The closure to execute when the event occurs.
    @MainActor
    public static func on(_ event: Event, for name: Name, perform action: @escaping () -> Void) {
        ShortcutMonitor.shared.register(event: event, for: name, action: action)
    }

    /// Unregister all handlers for a shortcut.
    /// - Parameter name: The name of the shortcut.
    @MainActor
    public static func unregister(for name: Name) {
        ShortcutMonitor.shared.unregister(for: name)
    }
}

extension Notification.Name {
    static let hotKeyDidChange = Notification.Name("HotKeyManager_HotKeyDidChange")
}
