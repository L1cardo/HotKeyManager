//
//  KeyEvent.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Sauce

public enum InputEvent {
    case keyboard(KeyEvent)
    case mouseClick
}

public struct KeyEvent {
    public let key: Key?
    public let modifiers: Modifiers

    public init(key: Key?, modifiers: Modifiers) {
        self.key = key
        self.modifiers = modifiers
    }
}
