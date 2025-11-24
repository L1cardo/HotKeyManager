//
//  HotKeyMonitor.swift
//  HotKeyManager
//
//  Created by Licardo on 2025/11/23.
//

import AppKit
import Combine
import Foundation
import Sauce

/// Internal monitor that listens for system events and dispatches them to registered handlers.
@MainActor
final class HotKeyMonitor {
    static let shared = HotKeyMonitor()

    private var handlers: [HotKeyManager.Name: [HotKeyManager.Event: [() -> Void]]] = [:]
    private var processors: [HotKeyManager.Name: HotKeyProcessor] = [:]
    private var eventMonitor: Any?
    private var localEventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Listen for hotkey changes to update processors
        NotificationCenter.default.publisher(for: .hotKeyByNameDidChange)
            .sink { [weak self] notification in
                guard let name = notification.userInfo?["name"] as? HotKeyManager.Name else { return }
                self?.updateProcessor(for: name)
            }
            .store(in: &cancellables)
            
        startMonitoring()
    }

    func register(event: HotKeyManager.Event, for name: HotKeyManager.Name, action: @escaping () -> Void) {
        var eventHandlers = handlers[name] ?? [:]
        var actions = eventHandlers[event] ?? []
        actions.append(action)
        eventHandlers[event] = actions
        handlers[name] = eventHandlers
        
        // Ensure we have a processor for this name
        if processors[name] == nil {
            updateProcessor(for: name)
        }
    }
    
    func unregister(for name: HotKeyManager.Name) {
        handlers.removeValue(forKey: name)
        processors.removeValue(forKey: name)
    }
    
    private func updateProcessor(for name: HotKeyManager.Name) {
        if let hotKey = HotKeyManager.getHotKey(for: name) {
            // Preserve existing state if possible, or create new
            if processors[name] == nil {
                processors[name] = HotKeyProcessor(hotkey: hotKey)
            } else {
                processors[name]?.hotkey = hotKey
            }
        } else {
            processors[name] = nil
        }
    }

    private func startMonitoring() {
        // Global monitor (cannot block events)
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            self?.handle(event: event)
        }
        
        // Local monitor (can block events)
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            if self?.handle(event: event) == true {
                return nil // Consume event if handled
            }
            return event
        }
    }
    
    @discardableResult
    private func handle(event: NSEvent) -> Bool {
        guard let keyEvent = KeyEvent(event) else { return false }
        
        var handled = false
        
        // Iterate through all processors
        // Note: In a real app with many hotkeys, this might need optimization (e.g. indexing by key)
        // Iterate through all processors
        // Note: In a real app with many hotkeys, this might need optimization (e.g. indexing by key)
        for (name, var processor) in processors {
            let output = processor.process(keyEvent: keyEvent)
            
            // ALWAYS update the processor state, even if output is nil.
            // The processor might have changed internal state (e.g. .idle -> .pressAndHold, or setting lastTapAt)
            // without emitting an output event yet.
            processors[name] = processor
            
            if let output = output {
                // Dispatch event
                if let eventType = output.toEvent() {
                    if let actions = handlers[name]?[eventType] {
                        actions.forEach { $0() }
                        handled = true
                    }
                }
                
                // If the processor says "cancel" or "discard", we might still consider it "handled"
                // in terms of the state machine, but maybe not for the event consumer.
                // For now, if we got an output, we assume the processor "acted" on it.
            }
        }
        
        return handled
    }
}

// MARK: - Extensions

private extension HotKeyProcessor.Output {
    func toEvent() -> HotKeyManager.Event? {
        switch self {
        case .keyDown: return .keyDown
        case .keyUp: return .keyUp
        case .cancel, .discard: return nil
        }
    }
}

private extension KeyEvent {
    init?(_ event: NSEvent) {
        // Use CGEvent flags if available to preserve left/right side information
        let modifiers: Modifiers
        if let cgEvent = event.cgEvent {
            modifiers = Modifiers.from(carbonFlags: cgEvent.flags)
        } else {
            modifiers = Modifiers.from(cocoa: event.modifierFlags)
        }
        
        // Sauce maps key codes to Key enum
        let key = Sauce.shared.key(for: Int(event.keyCode))
        
        if event.type == .flagsChanged {
            self.init(key: nil, modifiers: modifiers)
        } else if event.type == .keyUp {
            // On keyUp, we want to indicate that the key is no longer pressed.
            // HotKeyProcessor expects the "current state" or "event".
            // If we pass the key that was released, HotKeyProcessor might think it's still pressed
            // if it doesn't distinguish between Up/Down.
            // By passing nil, we effectively say "The key component is gone".
            self.init(key: nil, modifiers: modifiers)
        } else {
            self.init(key: key, modifiers: modifiers)
        }
    }
}
