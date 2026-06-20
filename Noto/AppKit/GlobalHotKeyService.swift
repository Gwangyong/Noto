//
//  GlobalHotKeyService.swift
//  Noto
//

import Carbon
import Combine
import Foundation

final class GlobalHotKeyService: ObservableObject {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var registeredHotKey: TaskPanelHotKey?
    private var onTrigger: (() -> Void)?

    init() {
        installEventHandler()
    }

    func register(_ hotKey: TaskPanelHotKey, onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        if registeredHotKey == hotKey, hotKeyRef != nil {
            return
        }

        unregister()

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        var nextHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(hotKey.keyCode),
            hotKey.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &nextHotKeyRef
        )

        guard status == noErr else {
            #if DEBUG
            print("Noto global hotkey registration failed: \(status)")
            #endif
            registeredHotKey = nil
            hotKeyRef = nil
            return
        }

        registeredHotKey = hotKey
        hotKeyRef = nextHotKeyRef
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        hotKeyRef = nil
        registeredHotKey = nil
    }

    deinit {
        unregister()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }

                let service = Unmanaged<GlobalHotKeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                service.handleHotKeyPressed()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        #if DEBUG
        if status != noErr {
            print("Noto global hotkey event handler failed: \(status)")
        }
        #endif
    }

    private func handleHotKeyPressed() {
        DispatchQueue.main.async { [weak self] in
            self?.onTrigger?()
        }
    }

    private static let signature: OSType = {
        var result: UInt32 = 0
        for scalar in "Noto".unicodeScalars {
            result = (result << 8) + scalar.value
        }
        return result
    }()
}
