<div align="center">
  <img src="./ScreenShot/HotKeyManager_EN.png" alt="HotKeyManager" width="300">
  <h1>HotKeyManager</h1>
  <p>
    Powerful, modern, and easy-to-use keyboard shortcut manager for macOS
  </p>

  <p>
    <strong><a href="./README.CN.md">🇨🇳中文</a></strong>  | <strong>🇬🇧English</strong>
  </p>

  <p>
    <img src="https://img.shields.io/badge/platform-macOS>=15-lightgrey?style=flat-square&logo=apple" alt="Platform: macOS>=15">
    <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT">
    <img src="https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift" alt="Swift 6.0">
    <img src="https://img.shields.io/badge/SwiftUI-blue?style=flat-square" alt="SwiftUI">
  </p>
</div>

---

**HotKeyManager** is a powerful, modern, and easy-to-use keyboard shortcut manager for macOS, built with SwiftUI and Swift Concurrency. It provides a robust way to record, store, and monitor global hotkeys in your application.

## Features

- 🚀 **Modern API**: Built with Swift Concurrency (`async`/`await`) and SwiftUI.
- 🎯 **Double Tap Support**: Detects double-tap shortcuts (e.g., double-tap `Cmd`).
- 🎨 **Beautiful UI**: Includes a polished, customizable `HotKeyRecorder` view.
- 💾 **Persistence**: Automatically saves and loads shortcuts using `UserDefaults`.
- 🛡️ **Safe & Robust**: Handles edge cases like implicit `Fn` keys on laptops and prevents conflicts.
- 🌍 **Localized**: Supports English, Chinese, Japanese, Spanish, French, and German and more.

## Installation

Add `HotKeyManager` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/L1cardo/HotKeyManager", branch: "main")
]
```

## Usage

### 1. Define Shortcuts

Use `HotKeyManager.Name` to define your shortcuts. You can use string literals for convenience.

```swift
import HotKeyManager

extension HotKeyManager.Name {
    // With a default value
    static let startRecording = Self("startRecording", default: HotKey(key: nil, modifiers: [.command], isDoubleTap: true))
    // Without a default value
    static let stopRecording = Self("stopRecording")
}
```

### 2. Record Shortcuts

Add the `HotKeyRecorder` view to your settings UI.

```swift
import HotKeyManager
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                HotKeyManager.Recorder(for: .startRecording)
                HotKeyManager.Recorder(for: .stopRecording)
            }
        }
    }
}
```

### 3. Listen for Events

Register handlers for your shortcuts. You can listen for `.keyDown`, `.keyUp`.

```swift
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        ...
    }
}

class AppDelegate: NSResponder, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        HotKeyManager.on(.keyDown, for: .startRecording) {
            print("Key Down Triggered!")
        }

        HotKeyManager.on(.keyUp, for: .stopRecording) {
            print("Key Up Triggered!")
        }
    }
}
```

## Advanced

### Modifier Side Selection
You can allow users to distinguish between left and right modifiers (e.g., `Left Cmd` vs `Right Cmd`).

```swift
HotKeyManager.Recorder(for: .toggleApp, modifirsSide: true)
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
- [Sauce](https://github.com/Clipy/Sauce)
- [Hex](https://github.com/kitlangton/Hex)

## 📞 Support

- **Email**: [albert.abdilim@foxmail.com](mailto:albert.abdilim@foxmail.com)
- **GitHub Issues**: [Report issues here](https://github.com/L1cardo/HotKeyManager/issues)
