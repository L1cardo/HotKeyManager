# HotKeyManager

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English

**HotKeyManager** is a powerful, modern, and easy-to-use keyboard shortcut manager for macOS, built with SwiftUI and Swift Concurrency. It provides a robust way to record, store, and monitor global hotkeys in your application.

### Features

- 🚀 **Modern API**: Built with Swift Concurrency (`async`/`await`) and SwiftUI.
- 🎯 **Double Tap Support**: Detects double-tap shortcuts (e.g., double-tap `Cmd`).
- 🎨 **Beautiful UI**: Includes a polished, customizable `HotKeyRecorder` view.
- 💾 **Persistence**: Automatically saves and loads shortcuts using `UserDefaults`.
- 🛡️ **Safe & Robust**: Handles edge cases like implicit `Fn` keys on laptops and prevents conflicts.
- 🌍 **Localized**: Supports English, Chinese, Japanese, Spanish, French, and German.

### Installation

Add `HotKeyManager` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/HotKeyManager", branch: "main")
]
```

### Usage

#### 1. Define Shortcuts

Use `HotKeyManager.Name` to define your shortcuts. You can use string literals for convenience.

```swift
extension HotKeyManager.Name {
    static let toggleApp: Self = "toggleApp"
    static let screenshot = Self("screenshot", default: HotKey(key: .s, modifiers: [.command, .shift]))
}
```

#### 2. Record Shortcuts

Add the `HotKeyRecorder` view to your settings UI.

```swift
import HotKeyManager
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                HotKeyManager.Recorder(for: .toggleApp)
                HotKeyManager.Recorder(for: .screenshot)
            }
        }
    }
}
```

#### 3. Listen for Events

Register handlers for your shortcuts. You can listen for `.keyDown`, `.keyUp`, or even double-tap events.

```swift
@main
struct MyApp: App {
    init() {
        // Simple Key Down
        HotKeyManager.on(.keyDown, for: .toggleApp) {
            print("Toggle App Triggered!")
        }

        // Double Tap (if recorded as such)
        HotKeyManager.on(.keyDown, for: "doubleTapCmd") {
            print("Double Tap Command Triggered!")
        }
    }
}
```

### Advanced

#### Modifier Side Selection
You can allow users to distinguish between left and right modifiers (e.g., `Left Cmd` vs `Right Cmd`).

```swift
HotKeyManager.Recorder(for: .toggleApp, modifirsSide: true)
```

---

<a name="中文"></a>
## 中文

**HotKeyManager** 是一个专为 macOS打造的强大、现代且易用的全局快捷键管理库。它基于 SwiftUI 和 Swift Concurrency 构建，为您提供了录制、存储和监听全局快捷键的一站式解决方案。

### 特性

- 🚀 **现代 API**: 基于 Swift Concurrency (`async`/`await`) 和 SwiftUI 构建。
- 🎯 **双击支持**: 支持检测修饰键双击（例如：双击 `Cmd`）。
- 🎨 **精美 UI**: 内置精致、可定制的 `HotKeyRecorder` 录制视图。
- 💾 **自动持久化**: 使用 `UserDefaults` 自动保存和加载快捷键设置。
- 🛡️ **安全稳健**: 完美处理笔记本上的隐式 `Fn` 键等边缘情况，防止冲突。
- 🌍 **多语言支持**: 支持中文、英语、日语、西班牙语、法语和德语。

### 安装

将 `HotKeyManager` 添加到您的 `Package.swift`：

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/HotKeyManager", branch: "main")
]
```

### 使用方法

#### 1. 定义快捷键

使用 `HotKeyManager.Name` 定义您的快捷键。支持直接使用字符串字面量。

```swift
extension HotKeyManager.Name {
    static let toggleApp: Self = "toggleApp"
    static let screenshot = Self("screenshot", default: HotKey(key: .s, modifiers: [.command, .shift]))
}
```

#### 2. 录制快捷键

将 `HotKeyRecorder` 视图添加到您的设置界面中。

```swift
import HotKeyManager
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("通用") {
                HotKeyManager.Recorder(for: .toggleApp)
                HotKeyManager.Recorder(for: .screenshot)
            }
        }
    }
}
```

#### 3. 监听事件

注册快捷键的处理程序。您可以监听 `.keyDown`（按下）、`.keyUp`（抬起）甚至双击事件。

```swift
@main
struct MyApp: App {
    init() {
        // 简单的按下事件
        HotKeyManager.on(.keyDown, for: .toggleApp) {
            print("切换应用快捷键触发！")
        }

        // 双击事件（如果录制为双击）
        HotKeyManager.on(.keyDown, for: "doubleTapCmd") {
            print("双击 Command 触发！")
        }
    }
}
```

### 进阶功能

#### 区分左右修饰键
您可以允许用户区分左右修饰键（例如：`左 Cmd` vs `右 Cmd`）。

```swift
HotKeyManager.Recorder(for: .toggleApp, modifirsSide: true)
```
