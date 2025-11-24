//
//  HotKeyConstants.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Foundation

/// Central repository for timing thresholds and magic numbers used for HotKey processing.
public enum HotKeyConstants {
    // MARK: - Hotkey Timing Thresholds
    
    /// Maximum time between two hotkey taps to be considered a double-tap.
    ///
    /// **Value:** 0.3 seconds
    public static let doubleTapWindow: TimeInterval = 0.3
    
    /// Minimum duration for modifier-only hotkeys to avoid conflicts with OS shortcuts.
    ///
    /// **Value:** 0.3 seconds
    public static let modifierOnlyMinimumDuration: TimeInterval = 0.3
    
    /// Time window for canceling press-and-hold on different key press.
    ///
    /// **Value:** 1.0 second
    public static let pressAndHoldCancelWindow: TimeInterval = 1.0
    
    // MARK: - Default Settings
    
    /// Default minimum time a key must be held to register as valid press.
    ///
    /// **Value:** 0.2 seconds
    public static let defaultMinimumKeyTime: TimeInterval = 0.2
}
