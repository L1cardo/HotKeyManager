//
//  HotKeyManager.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Combine
import Foundation
import SwiftUI

/// Global keyboard hotkeys manager.
public enum HotKeyManager {
    /// A strongly-typed name for a hotkey.
    public struct Name: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
        public let rawValue: String
        public let defaultHotKey: HotKey?

        public init(rawValue: String) {
            self.rawValue = rawValue
            self.defaultHotKey = nil
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
            self.defaultHotKey = nil
        }

        public init(_ name: String, default defaultHotKey: HotKey? = nil) {
            self.rawValue = name
            self.defaultHotKey = defaultHotKey

            if let defaultHotKey {
                HotKeyManager.registerDefault(defaultHotKey, for: name)
            }

            // Register default if not present
            if defaultHotKey != nil, !HotKeyManager.userDefaultsContains(name: self) {
                HotKeyManager.setHotKey(defaultHotKey, for: self)
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

    static func registerDefault(_ hotkey: HotKey, for name: String) {
        _lock.lock()
        defer { _lock.unlock() }
        _defaults[name] = hotkey
    }

    private static func userDefaultsKey(for name: Name) -> String {
        "\(userDefaultsPrefix)\(name.rawValue)"
    }

    static func userDefaultsContains(name: Name) -> Bool {
        UserDefaults.standard.object(forKey: userDefaultsKey(for: name)) != nil
    }

    // MARK: - Public API

    /// Get the current hotkey for a name.
    public static func getHotKey(for name: Name) -> HotKey? {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey(for: name)),
            let hotkey = try? JSONDecoder().decode(HotKey.self, from: data)
        else {
            return nil
        }
        return hotkey
    }

    /// Set the hotkey for a name.
    public static func setHotKey(_ hotkey: HotKey?, for name: Name) {
        if let hotkey = hotkey {
            if let data = try? JSONEncoder().encode(hotkey) {
                UserDefaults.standard.set(data, forKey: userDefaultsKey(for: name))
            }
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey(for: name))
        }

        // Notify listeners (implementation detail: could use NotificationCenter or Combine)
        NotificationCenter.default.post(name: .hotKeyByNameDidChange, object: nil, userInfo: ["name": name])
    }

    /// Reset the hotkey to its default.
    public static func reset(_ name: Name) {
        setHotKey(name.defaultHotKey, for: name)
    }

    /// Reset all hotkeys to their defaults.
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

        for (name, hotkey) in defaultsToRestore {
            setHotKey(hotkey, for: Name(rawValue: name))
        }
    }

    // MARK: - Event Registration

    /// Register a handler for a specific event on a hotkey.
    /// - Parameters:
    ///   - event: The event to listen for (e.g. .keyDown, .doubleTapUp).
    ///   - name: The name of the hotkey to monitor.
    ///   - action: The closure to execute when the event occurs.
    @MainActor
    public static func on(_ event: Event, for name: Name, perform action: @escaping () -> Void) {
        HotKeyMonitor.shared.register(event: event, for: name, action: action)
    }

    /// Unregister all handlers for a hotkey.
    /// - Parameter name: The name of the hotkey.
    @MainActor
    public static func unregister(for name: Name) {
        HotKeyMonitor.shared.unregister(for: name)
    }
}
