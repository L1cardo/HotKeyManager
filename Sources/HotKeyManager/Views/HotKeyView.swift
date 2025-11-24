//
//  HotKeyView.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Sauce
import SwiftUI

// This view shows the actual "keys" in a more modern, subtle style.
public struct HotKeyView: View {
    public var modifiers: Modifiers
    public var key: Key?
    public var isActive: Bool
    public var isDoubleTap: Bool
    public var clearHotKey: () -> Void

    public init(modifiers: Modifiers, key: Key? = nil, isActive: Bool, isDoubleTap: Bool, clearHotKey: @escaping () -> Void) {
        self.modifiers = modifiers
        self.key = key
        self.isActive = isActive
        self.isDoubleTap = isDoubleTap
        self.clearHotKey = clearHotKey
    }

    private var isHotKeyEmpty: Bool {
        modifiers.isEmpty && key == nil
    }

    private var displayModifiers: [Modifier] {
        var mods = modifiers.modifiers
        // Visually add Fn modifier for keys that are implicitly Fn+Key
        switch key {
        case .home, .end, .pageUp, .pageDown, .forwardDelete:
            mods.insert(.fn)
        default:
            break
        }
        return Array(mods).sorted()
    }

    private var displayKey: Key? {
        // Visually map Home/End/etc back to their base key
        switch key {
        case .home: return .leftArrow
        case .end: return .rightArrow
        case .pageUp: return .upArrow
        case .pageDown: return .downArrow
        case .forwardDelete: return .delete
        default: return key
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(displayModifiers) { modifier in
                KeyView(text: modifier.stringValue)
                    .transition(.blurReplace)
            }

            if let key = displayKey {
                KeyView(text: key.toString)
            }

            if isDoubleTap {
                DoubleTapView(text: "Double Tap")
            }

            if !isHotKeyEmpty && !isActive {
                Button {
                    clearHotKey()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading)
                .padding(.trailing, -.infinity)
            }
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background {
            if isHotKeyEmpty {
                Text(isActive ? "Enter a key combination" : "Click to record", bundle: .module)
                    .foregroundStyle(.secondary)
                    .transition(.blurReplace)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(isActive ? 0.1 : 0))
                .stroke(Color.blue.opacity(isActive || isHotKeyEmpty ? 0.2 : 0), lineWidth: 1)
        )
        .animation(.bouncy(duration: 0.3), value: key)
        .animation(.bouncy(duration: 0.3), value: modifiers)
        .animation(.bouncy(duration: 0.3), value: isActive)
    }
}

public struct KeyView: View {
    public var text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.title.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        .black.mix(with: .white, by: 0.2)
                            .shadow(.inner(color: .white.opacity(0.3), radius: 1, y: 1))
                            .shadow(.inner(color: .white.opacity(0.1), radius: 5, y: 8))
                            .shadow(.inner(color: .black.opacity(0.3), radius: 1, y: -3))
                    )
            )
            .shadow(radius: 4, y: 2)
    }
}

public struct DoubleTapView: View {
    public var text: LocalizedStringKey

    public init(text: LocalizedStringKey) {
        self.text = text
    }

    public var body: some View {
        Text(text, bundle: .module)
            .padding(.horizontal)
            .font(.title.weight(.bold))
            .foregroundStyle(.blue)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        .black.mix(with: .white, by: 0.2)
                            .shadow(.inner(color: .white.opacity(0.3), radius: 1, y: 1))
                            .shadow(.inner(color: .white.opacity(0.1), radius: 5, y: 8))
                            .shadow(.inner(color: .black.opacity(0.3), radius: 1, y: -3))
                    )
            )
            .shadow(radius: 4, y: 2)
    }
}

#Preview {
    List {
        HotKeyView(
            modifiers: .init(modifiers: [.command, .shift, .control, .option, .fn]),
            key: .a,
            isActive: false,
            isDoubleTap: true,
            clearHotKey: {}
        )
        HotKeyView(
            modifiers: .init(modifiers: []),
            key: nil,
            isActive: true,
            isDoubleTap: false,
            clearHotKey: {}
        )
    }
}
