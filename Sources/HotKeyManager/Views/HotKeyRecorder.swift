//
//  HotKeyRecorder.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import AppKit
import Sauce
import SwiftUI

public extension HotKeyManager {
    struct Recorder: View {
        public let name: HotKeyManager.Name
        public let modifirsSide: Bool
        public let onChange: ((HotKey?) -> Void)?

        @State private var hotKey: HotKey?
        @State private var isRecording: Bool = false
        @State private var currentModifiers: Modifiers = []

        // Double Tap Detection
        @State private var lastModifierFlags: NSEvent.ModifierFlags = []
        @State private var lastModifierTime: TimeInterval = 0

        // Monitor for recording
        @State private var monitor: Any?

        public init(
            for name: HotKeyManager.Name,
            modifirsSide: Bool = false,
            onChange: ((HotKey?) -> Void)? = nil
        ) {
            self.name = name
            self.modifirsSide = modifirsSide
            self.onChange = onChange
        }

        public var body: some View {
            VStack(alignment: .center, spacing: 6) {
                HotKeyView(
                    modifiers: isRecording ? currentModifiers : (hotKey?.modifiers ?? []),
                    key: isRecording ? nil : hotKey?.key,
                    isActive: isRecording,
                    isDoubleTap: isRecording ? false : (hotKey?.isDoubleTap ?? false),
                    clearHotKey: clearHotKey
                )
                .onTapGesture {
                    startRecording()
                }

                if modifirsSide {
                    if let hotKey = hotKey, !isRecording, !hotKey.modifiers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            if hotKey.modifiers.sorted.contains(where: { $0.kind.supportsSideSelection }) {
                                Text("Modifier side:", bundle: .module)
                            }

                            ForEach(hotKey.modifiers.sorted) { modifier in
                                if modifier.kind.supportsSideSelection {
                                    HStack {
                                        Label {
                                            Text(modifier.kind.displayName)
                                        } icon: {
                                            Image(systemName: modifier.kind.symbolIcon)
                                        }
                                        .foregroundStyle(.primary)
                                        .frame(width: 100, alignment: .leading)

                                        Picker("", selection: Binding(
                                            get: { modifier.side },
                                            set: { newSide in
                                                updateModifierSide(kind: modifier.kind, side: newSide)
                                            }
                                        )) {
                                            ForEach(Modifier.Side.allCases, id: \.self) { side in
                                                Text(side.displayName).tag(side)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.segmented)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onAppear {
                loadHotKey()
            }
            .onDisappear {
                stopRecording()
            }
        }

        private func loadHotKey() {
            hotKey = HotKeyManager.getShortcut(for: name)
        }

        private func startRecording() {
            guard !isRecording else { return }
            isRecording = true
            currentModifiers = []

            // Add local monitor to capture keys
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
                handleEvent(event)
                return nil // Consume event while recording
            }
        }

        private func stopRecording() {
            isRecording = false
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            currentModifiers = []
            lastModifierFlags = []
            lastModifierTime = 0
        }

        private func handleEvent(_ event: NSEvent) {
            if event.type == .flagsChanged {
                handleModifiers(event)
            } else if event.type == .keyDown {
                handleKeyDown(event)
            }
        }

        private func handleModifiers(_ event: NSEvent) {
            let modifiers = Modifiers.from(cocoa: event.modifierFlags)
            currentModifiers = modifiers
            lastModifierFlags = event.modifierFlags

            if !modifiers.isEmpty {
                // Press
                recordingTask?.cancel()
                recordingTask = nil

                // Check for Double Tap
                let now = Date().timeIntervalSince1970
                if let lastPressed = lastPressedModifiers,
                   lastPressed == modifiers,
                   (now - lastPressTime) < 0.3
                {
                    let newHotKey = HotKey(key: nil, modifiers: modifiers, isDoubleTap: true)
                    saveHotKey(newHotKey)
                    return
                }

                lastPressedModifiers = modifiers
                lastPressTime = now

                let newHotKey = HotKey(key: nil, modifiers: modifiers, isDoubleTap: false)
                saveHotKey(newHotKey, stop: false)

            } else {
                // Release
                recordingTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                    if !Task.isCancelled {
                        await MainActor.run {
                            stopRecording()
                        }
                    }
                }
            }
        }

        private func handleKeyDown(_ event: NSEvent) {
            recordingTask?.cancel()
            recordingTask = nil

            if event.keyCode == 53 { // Escape
                stopRecording()
                return
            }

            guard let key = Sauce.shared.key(for: Int(event.keyCode)) else { return }

            // Prepare modifiers
            var modifiers = Modifiers.from(cocoa: event.modifierFlags)
            modifiers = modifiers.removing(kind: .fn)

            // Only force Fn modifier if it's actually a Function key (F1-F12, etc.)
            // We do NOT want to force Fn for Arrow keys even if the system sets the flag (implicit Fn).
            if key.isFunctionKey {
                modifiers.modifiers.insert(.fn)
            }

            // Validate
            guard isValid(key: key, modifiers: modifiers) else { return }

            let newHotKey = HotKey(key: key, modifiers: modifiers)
            saveHotKey(newHotKey)
        }

        private func isValid(key: Key, modifiers: Modifiers) -> Bool {
            if !modifiers.isEmpty { return true }

            // Reject bare Arrow keys
            if key == .leftArrow || key == .rightArrow || key == .upArrow || key == .downArrow {
                return false
            }

            // Allow specific bare keys
            let allowedBareKeys: Set<Key> = [
                .home, .end, .pageUp, .pageDown, .forwardDelete
            ]

            if allowedBareKeys.contains(key) { return true }
            if key.isFunctionKey { return true }

            return false
        }

        @State private var lastPressedModifiers: Modifiers?
        @State private var lastPressTime: TimeInterval = 0
        @State private var recordingTask: Task<Void, Never>?

        // Removed checkDoubleTap as logic is moved to handleEvent
        private func checkDoubleTap(event: NSEvent, currentModifiers: Modifiers) {}

        private func updateModifierSide(kind: Modifier.Kind, side: Modifier.Side) {
            guard var hotKey = hotKey else { return }
            hotKey.modifiers = hotKey.modifiers.setting(kind: kind, to: side)
            self.hotKey = hotKey
            HotKeyManager.setShortcut(hotKey, for: name)
            onChange?(hotKey)
        }

        private func clearHotKey() {
            HotKeyManager.setShortcut(nil, for: name)
            hotKey = nil
            onChange?(nil)
        }

        private func saveHotKey(_ newHotKey: HotKey, stop: Bool = true) {
            HotKeyManager.setShortcut(newHotKey, for: name)
            hotKey = newHotKey
            onChange?(newHotKey)
            if stop {
                stopRecording()
            }
        }
    }
}

#Preview {
    List {
        HotKeyManager.Recorder(for: .init("toggleApp", default: HotKey(key: .a, modifiers: [.command, .shift])))

        HotKeyManager.Recorder(for: .init("toggleApp", default: HotKey(key: .a, modifiers: [.command, .shift])), modifirsSide: true)
    }
}
