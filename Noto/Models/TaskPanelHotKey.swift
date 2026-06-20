//
//  TaskPanelHotKey.swift
//  Noto
//

import AppKit
import Foundation

struct TaskPanelHotKey: Equatable {
    let keyCode: UInt16
    let carbonModifiers: UInt32

    static let `default` = TaskPanelHotKey(
        keyCode: KeyCode.space,
        carbonModifiers: CarbonModifier.shift
    )

    init(keyCode: UInt16, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    init?(keyCodeValue: Int?, modifierValue: Int?) {
        guard let keyCodeValue,
              let modifierValue,
              let keyCode = UInt16(exactly: keyCodeValue),
              let modifiers = UInt32(exactly: modifierValue),
              modifiers != 0
        else {
            return nil
        }

        self.init(keyCode: keyCode, carbonModifiers: modifiers)
    }

    init?(event: NSEvent) {
        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { return nil }

        self.init(keyCode: event.keyCode, carbonModifiers: modifiers)
    }

    var keyCodeValue: Int {
        Int(keyCode)
    }

    var modifierValue: Int {
        Int(carbonModifiers)
    }

    var displayText: String {
        "\(modifierSymbols) \(keyLabel)"
    }

    private var modifierSymbols: String {
        var symbols = ""

        if carbonModifiers & CarbonModifier.control != 0 {
            symbols += "⌃"
        }
        if carbonModifiers & CarbonModifier.option != 0 {
            symbols += "⌥"
        }
        if carbonModifiers & CarbonModifier.shift != 0 {
            symbols += "⇧"
        }
        if carbonModifiers & CarbonModifier.command != 0 {
            symbols += "⌘"
        }

        return symbols
    }

    private var keyLabel: String {
        Self.keyLabels[keyCode] ?? "Key \(keyCode)"
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        let deviceFlags = flags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0

        if deviceFlags.contains(.command) {
            modifiers |= CarbonModifier.command
        }
        if deviceFlags.contains(.shift) {
            modifiers |= CarbonModifier.shift
        }
        if deviceFlags.contains(.option) {
            modifiers |= CarbonModifier.option
        }
        if deviceFlags.contains(.control) {
            modifiers |= CarbonModifier.control
        }

        return modifiers
    }

    private enum KeyCode {
        static let space: UInt16 = 49
    }

    private enum CarbonModifier {
        static let command: UInt32 = 1 << 8
        static let shift: UInt32 = 1 << 9
        static let option: UInt32 = 1 << 11
        static let control: UInt32 = 1 << 12
    }

    private static let keyLabels: [UInt16: String] = [
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        4: "H",
        5: "G",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        16: "Y",
        17: "T",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        22: "6",
        23: "5",
        25: "9",
        26: "7",
        28: "8",
        29: "0",
        31: "O",
        32: "U",
        34: "I",
        35: "P",
        37: "L",
        38: "J",
        40: "K",
        45: "N",
        46: "M",
        48: "Tab",
        49: "Space",
        51: "Delete",
        53: "Esc",
        123: "←",
        124: "→",
        125: "↓",
        126: "↑"
    ]
}
