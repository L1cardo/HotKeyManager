//
//  Key+Extensions.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import Sauce

public extension Key {
    var isFunctionKey: Bool {
        switch self {
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10,
             .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20:
            return true
        default:
            return false
        }
    }
}
