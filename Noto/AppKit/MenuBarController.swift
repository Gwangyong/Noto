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

        menu.addItem(
            menuItem(
                title: isPanelOpen ? "패널 닫기" : "패널 열기",
                action: #selector(togglePanel)
            )
        )
        menu.addItem(menuItem(title: "설정 열기", action: #selector(openSettings)))
        menu.addItem(menuItem(title: "업데이트 확인", action: #selector(checkForUpdates)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "종료", action: #selector(quit)))

        statusItem?.menu = menu
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func togglePanel() {
        onTogglePanel?()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func checkForUpdates() {
        onCheckForUpdates?()
    }

    @objc private func quit() {
        onQuit?()
    }

    private static func makeStatusIcon() -> NSImage {
        let size = NSSize(width: 15, height: 15)
        let image = NSImage(size: size)

        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let glyphRect = NSRect(x: 1.5, y: 1.5, width: 12, height: 12)
        let glyphPath = NSBezierPath(roundedRect: glyphRect, xRadius: 4.5, yRadius: 4.5)
        NSColor.controlAccentColor.withAlphaComponent(0.88).setFill()
        glyphPath.fill()

        NSColor.white.withAlphaComponent(0.92).setFill()
        NSBezierPath(ovalIn: NSRect(x: 6, y: 6, width: 3, height: 3)).fill()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
