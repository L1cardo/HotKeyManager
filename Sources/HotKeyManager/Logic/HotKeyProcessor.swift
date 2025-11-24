//
//  HotKeyProcessor.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Foundation
import Sauce
import SwiftUI

public struct HotKeyProcessor {
    private let now: () -> Date

    public var hotkey: HotKey
    public var useDoubleTapOnly: Bool = false
    public var minimumKeyTime: TimeInterval = 0.15

    public private(set) var state: State = .idle
    private var lastTapAt: Date?
    private var isDirty: Bool = false

    public static let doubleTapThreshold: TimeInterval = HotKeyConstants.doubleTapWindow
    public static let pressAndHoldCancelThreshold: TimeInterval = HotKeyConstants.pressAndHoldCancelWindow

    public enum Output: Equatable, Sendable {
        case keyDown
        case keyUp
        case cancel
        case discard
    }

    public enum State: Equatable, Sendable {
        case idle
        case pressAndHold(startTime: Date, isDoubleTap: Bool)
        case doubleTapLock
    }

    public var isMatched: Bool {
        if case .pressAndHold = state { return true }
        if case .doubleTapLock = state { return true }
        return false
    }

    public init(
        hotkey: HotKey,
        useDoubleTapOnly: Bool = false,
        minimumKeyTime: TimeInterval = 0.15,
        now: @escaping () -> Date = { Date() }
    ) {
        self.hotkey = hotkey
        self.useDoubleTapOnly = useDoubleTapOnly
        self.minimumKeyTime = minimumKeyTime
        self.now = now
    }

    public mutating func process(keyEvent: KeyEvent) -> Output? {
        // 1. Check for cancellation (ESC)
        if keyEvent.key == .escape {
            if state != .idle {
                reset()
                return .cancel
            }
            return nil
        }

        // 2. Handle dirty state (blocking input until full release)
        if isDirty {
            if chordIsFullyReleased(keyEvent) {
                isDirty = false
            }
            return nil
        }

        // 3. Process based on current state
        switch state {
        case .idle:
            if chordMatchesHotkey(keyEvent) {
                return handleMatchingChord(keyEvent)
            } else if !chordIsFullyReleased(keyEvent) {
                // Non-matching chord pressed from idle -> ignore
                return nil
            }

        case .pressAndHold(let startTime, let isDoubleTap):
            if chordMatchesHotkey(keyEvent) {
                // Still holding the hotkey
                return nil
            } else if isReleaseForActiveHotkey(keyEvent) {
                // Released the hotkey
                return handleRelease(startTime: startTime, isDoubleTap: isDoubleTap)
            } else {
                // Changed to a different chord (e.g. added extra modifier)
                return handleNonmatchingChord(keyEvent)
            }

        case .doubleTapLock:
            if chordMatchesHotkey(keyEvent) {
                // Pressed hotkey again while locked -> unlock
                // We return .keyUp to signal the end of the "locked" session
                reset()
                return .keyUp
            } else if keyEvent.key != nil || !keyEvent.modifiers.isEmpty {
                // Any other key press -> cancel lock
                return nil
            }
        }

        return nil
    }

    public mutating func processMouseClick() -> Output? {
        // Mouse clicks should generally cancel or be ignored depending on context.
        // For modifier-only hotkeys, a click usually means "user is doing something else", so we discard.

        if case .pressAndHold(let startTime, _) = state {
            // If it's a modifier-only hotkey, check duration
            if hotkey.key == nil {
                let elapsed = now().timeIntervalSince(startTime)
                if elapsed < HotKeyConstants.modifierOnlyMinimumDuration {
                    reset()
                    return .discard
                }
            }
        }
        return nil
    }

    private mutating func handleMatchingChord(_ keyEvent: KeyEvent) -> Output? {
        // Only check for double tap if the hotkey is configured as such
        let isDoubleTapCandidate = hotkey.isDoubleTap ? isDoubleTapCandidate() : false

        // Transition from Idle -> PressAndHold
        state = .pressAndHold(startTime: now(), isDoubleTap: isDoubleTapCandidate)

        if hotkey.isDoubleTap {
            if isDoubleTapCandidate {
                return .keyDown
            } else {
                return nil
            }
        } else {
            // Normal hotkey (e.g. Cmd+Z) -> Trigger immediately
            return .keyDown
        }
    }

    private mutating func handleRelease(startTime: Date, isDoubleTap: Bool) -> Output? {
        let elapsed = now().timeIntervalSince(startTime)

        // Check if this was a valid press duration
        let isValidDuration = checkDuration(elapsed: elapsed)

        if !isValidDuration {
            reset()
            // Even if invalid duration (too short/long), we should record the tap time for potential double tap
            // But wait, if it's invalid, maybe we shouldn't?
            // Actually, for double tap, the first tap is usually short.
            // If checkDuration returns false (too short), it might be a valid "tap" for double tap purposes.

            // Let's refine checkDuration.
            // If it's modifier only, we have a minimum duration to avoid accidental clicks.
            // But for double tap, we want quick taps.

            // If hotkey.isDoubleTap is true, we should be lenient with the first tap's duration?
            // No, double tap usually implies two quick taps.

            // If we return .discard, we reset state.
            // We should set lastTapAt here if it was a "clean" release.
            lastTapAt = now()
            return .discard
        }

        if hotkey.isDoubleTap {
            if isDoubleTap {
                // Successful double tap release
                // We should reset to idle so the next tap is a fresh start.
                // We also clear lastTapAt so we don't trigger a "triple tap" or chain incorrectly.
                reset()
                lastTapAt = nil
                return .keyUp
            } else {
                reset()
                lastTapAt = now()
                return nil
            }
        }

        reset()
        lastTapAt = now()
        return .keyUp
    }

    private mutating func handleNonmatchingChord(_ keyEvent: KeyEvent) -> Output? {
        if case .pressAndHold(let startTime, _) = state {
            let elapsed = now().timeIntervalSince(startTime)
            if elapsed < HotKeyProcessor.pressAndHoldCancelThreshold {
                // Changed too quickly -> discard
                reset()
                isDirty = true
                return .discard
            }
        }

        if state != .idle {
            reset()
            isDirty = true
            return .keyUp
        }

        // If we are idle, and the chord doesn't match, we shouldn't necessarily become dirty.
        // If we become dirty, we block subsequent inputs until full release.
        // This causes the "Left works, then Right fails" issue because releasing Left might leave us clean,
        // but pressing Right (which doesn't match Left) triggers this function.
        // If we set isDirty = true here, we block the Right press.

        // Only set dirty if we are partially matching or if it's a "near miss"?
        // Or just don't set dirty at all in idle for non-matching chords.
        // If it doesn't match, we just ignore it.

        // However, we need to prevent "backsliding" or accidental triggers.
        // But for side switching, we want to allow it.

        return nil
    }

    private func checkDuration(elapsed: TimeInterval) -> Bool {
        // If double tap is enabled, we don't enforce minimum duration for the first tap
        if hotkey.isDoubleTap {
            return true
        }

        // For normal hotkeys (Cmd+A), we don't need a minimum duration.
        // If the user pressed it, they pressed it.
        // We only need debounce for Modifier-Only hotkeys to avoid accidental triggers.

        if hotkey.key != nil {
            return true
        }

        // For Modifier-Only hotkeys (e.g. "Cmd"), we use a tiny debounce to filter noise.
        return elapsed >= 0.05
    }

    private func isDoubleTapCandidate() -> Bool {
        guard let lastTap = lastTapAt else {
            return false
        }
        let timeSinceLastTap = now().timeIntervalSince(lastTap)
        let threshold = HotKeyProcessor.doubleTapThreshold
        return timeSinceLastTap < threshold
    }

    private mutating func reset() {
        state = .idle
    }

    // MARK: - Helpers

    private func chordMatchesHotkey(_ event: KeyEvent) -> Bool {
        guard let key = hotkey.key else {
            // Modifier only
            return event.key == nil && event.modifiers.matchesExactly(hotkey.modifiers)
        }

        // Key + Modifiers
        guard event.key == key else { return false }

        // 1. Exact match
        if event.modifiers.matchesExactly(hotkey.modifiers) {
            return true
        }

        // 2. Relaxed match for implicit Fn keys
        // If the event has Fn, but the hotkey doesn't, and it's a function/nav key, we ignore Fn.
        if shouldIgnoreImplicitFn(for: key, eventModifiers: event.modifiers) {
            let strippedModifiers = event.modifiers.removing(kind: .fn)
            if strippedModifiers.matchesExactly(hotkey.modifiers) {
                return true
            }
        }

        return false
    }

    private func shouldIgnoreImplicitFn(for key: Key, eventModifiers: Modifiers) -> Bool {
        // Only relevant if event has Fn and hotkey doesn't
        guard eventModifiers.contains(.fn), !hotkey.modifiers.contains(.fn) else { return false }

        // Check for keys that often have implicit Fn (Arrows, Home/End, F-keys)
        return key.isFunctionKey ||
            key == .leftArrow || key == .rightArrow ||
            key == .upArrow || key == .downArrow ||
            key == .home || key == .end ||
            key == .pageUp || key == .pageDown ||
            key == .forwardDelete
    }

    private func chordIsFullyReleased(_ event: KeyEvent) -> Bool {
        return event.key == nil && event.modifiers.isEmpty
    }

    private func isReleaseForActiveHotkey(_ event: KeyEvent) -> Bool {
        // If it doesn't match the hotkey, it's effectively a release (or a change to something else).
        // We want to trigger keyUp as soon as the chord is broken.
        return !chordMatchesHotkey(event)
    }
}
