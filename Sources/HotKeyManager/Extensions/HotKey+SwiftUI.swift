//
//  HotKey+SwiftUI.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/24.
//

import Sauce
import SwiftUI

public extension HotKey {
    var toSwiftUI: KeyboardShortcut? {
        guard let key = key else { return nil }
        
        // Map Modifiers to EventModifiers
        var eventModifiers: EventModifiers = []
        if modifiers.contains(.command) { eventModifiers.insert(.command) }
        if modifiers.contains(.shift) { eventModifiers.insert(.shift) }
        if modifiers.contains(.option) { eventModifiers.insert(.option) }
        if modifiers.contains(.control) { eventModifiers.insert(.control) }
        // Fn is not typically supported in SwiftUI KeyboardShortcut modifiers directly in the same way,
        // but we can try to map it if needed, though usually it's implicit or part of the key.
        
        // Map Key to KeyEquivalent
        let keyEquivalent: KeyEquivalent
        
        switch key {
        case .a: keyEquivalent = "a"
        case .b: keyEquivalent = "b"
        case .c: keyEquivalent = "c"
        case .d: keyEquivalent = "d"
        case .e: keyEquivalent = "e"
        case .f: keyEquivalent = "f"
        case .g: keyEquivalent = "g"
        case .h: keyEquivalent = "h"
        case .i: keyEquivalent = "i"
        case .j: keyEquivalent = "j"
        case .k: keyEquivalent = "k"
        case .l: keyEquivalent = "l"
        case .m: keyEquivalent = "m"
        case .n: keyEquivalent = "n"
        case .o: keyEquivalent = "o"
        case .p: keyEquivalent = "p"
        case .q: keyEquivalent = "q"
        case .r: keyEquivalent = "r"
        case .s: keyEquivalent = "s"
        case .t: keyEquivalent = "t"
        case .u: keyEquivalent = "u"
        case .v: keyEquivalent = "v"
        case .w: keyEquivalent = "w"
        case .x: keyEquivalent = "x"
        case .y: keyEquivalent = "y"
        case .z: keyEquivalent = "z"
        case .zero: keyEquivalent = "0"
        case .one: keyEquivalent = "1"
        case .two: keyEquivalent = "2"
        case .three: keyEquivalent = "3"
        case .four: keyEquivalent = "4"
        case .five: keyEquivalent = "5"
        case .six: keyEquivalent = "6"
        case .seven: keyEquivalent = "7"
        case .eight: keyEquivalent = "8"
        case .nine: keyEquivalent = "9"
        case .minus: keyEquivalent = "-"
        case .equal: keyEquivalent = "="
        case .leftBracket: keyEquivalent = "["
        case .rightBracket: keyEquivalent = "]"
        case .quote: keyEquivalent = "'" // or "\""
        case .semicolon: keyEquivalent = ";"
        case .backslash: keyEquivalent = "\\"
        case .comma: keyEquivalent = ","
        case .period: keyEquivalent = "."
        case .slash: keyEquivalent = "/"
        case .grave: keyEquivalent = "`"
        case .return: keyEquivalent = .return
        case .delete: keyEquivalent = .delete
        case .forwardDelete: keyEquivalent = .deleteForward
        case .escape: keyEquivalent = .escape
        case .tab: keyEquivalent = .tab
        case .space: keyEquivalent = .space
        case .upArrow: keyEquivalent = .upArrow
        case .downArrow: keyEquivalent = .downArrow
        case .leftArrow: keyEquivalent = .leftArrow
        case .rightArrow: keyEquivalent = .rightArrow
        case .home: keyEquivalent = .home
        case .end: keyEquivalent = .end
        case .pageUp: keyEquivalent = .pageUp
        case .pageDown: keyEquivalent = .pageDown
        case .f1: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF1FunctionKey)!))
        case .f2: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF2FunctionKey)!))
        case .f3: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF3FunctionKey)!))
        case .f4: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF4FunctionKey)!))
        case .f5: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF5FunctionKey)!))
        case .f6: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF6FunctionKey)!))
        case .f7: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF7FunctionKey)!))
        case .f8: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF8FunctionKey)!))
        case .f9: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF9FunctionKey)!))
        case .f10: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF10FunctionKey)!))
        case .f11: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF11FunctionKey)!))
        case .f12: keyEquivalent = KeyEquivalent(Character(UnicodeScalar(NSF12FunctionKey)!))
        default:
            // Fallback for other keys if possible, or return nil
            return nil
        }
        
        return KeyboardShortcut(keyEquivalent, modifiers: eventModifiers)
    }
}
