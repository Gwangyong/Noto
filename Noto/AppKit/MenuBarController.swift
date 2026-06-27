//
//  MenuBarController.swift
//  Noto
//

import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject, ObservableObject {
    var onTogglePanel: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onCheckForUpdates: (() -> Void)?
    var onQuit: (() -> Void)?

    private var statusItem: NSStatusItem?
    private var remainingCount = 0
    private var isPanelOpen = false

    func update(isVisible: Bool, remainingCount: Int, isPanelOpen: Bool) {
        self.remainingCount = remainingCount
        self.isPanelOpen = isPanelOpen

        guard isVisible else {
            removeStatusItem()
            return
        }

        ensureStatusItem()
        updateButton()
        rebuildMenu()
    }

    func invalidate() {
        removeStatusItem()
    }

    private func ensureStatusItem() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
    }

    private func removeStatusItem() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    private func updateButton() {
        guard let button = statusItem?.button else { return }

        button.image = Self.makeStatusIcon()
        button.imagePosition = .imageLeading
        button.title = " \(remainingCount)"
        button.font = .systemFont(ofSize: 11, weight: .semibold)
        button.toolTip = "Noto - 남은 할 일 \(remainingCount)개"
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.showsStateColumn = false

        menu.addItem(
            menuItem(
                title: isPanelOpen ? "패널 닫기" : "패널 열기",
                action: #selector(togglePanel)
            )
        )
        menu.addItem(menuItem(title: "설정 열기", action: #selector(openSettingsFromMenu)))
        menu.addItem(menuItem(title: "업데이트 확인", action: #selector(checkForUpdates)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "종료", action: #selector(quit)))

        statusItem?.menu = menu
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = true
        item.image = nil
        item.onStateImage = nil
        item.offStateImage = nil
        item.mixedStateImage = nil
        item.state = .off
        return item
    }

    @objc private func togglePanel() {
        onTogglePanel?()
    }

    @objc private func openSettingsFromMenu() {
        onOpenSettings?()
    }

    @objc private func checkForUpdates() {
        onCheckForUpdates?()
    }

    @objc private func quit() {
        onQuit?()
    }

    private static func makeStatusIcon() -> NSImage {
        let size = NSSize(width: 16, height: 16)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        NSColor.black.setStroke()
        NSColor.black.setFill()

        let facePath = NSBezierPath(roundedRect: NSRect(x: 2.5, y: 2.5, width: 11, height: 11), xRadius: 4.5, yRadius: 4.5)
        facePath.lineWidth = 1.6
        facePath.stroke()

        NSBezierPath(ovalIn: NSRect(x: 5.1, y: 8.1, width: 1.4, height: 1.4)).fill()
        NSBezierPath(ovalIn: NSRect(x: 9.5, y: 8.1, width: 1.4, height: 1.4)).fill()

        let mouthPath = NSBezierPath()
        mouthPath.move(to: NSPoint(x: 6.3, y: 5.6))
        mouthPath.line(to: NSPoint(x: 9.7, y: 5.6))
        mouthPath.lineWidth = 1.2
        mouthPath.lineCapStyle = .round
        mouthPath.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
