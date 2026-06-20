//
//  FloatingPanelController.swift
//  Noto
//

import AppKit
import SwiftData
import SwiftUI

@MainActor
final class FloatingPanelController {
    private var panel: InteractiveFloatingPanel?

    func show(modelContainer: ModelContainer) {
        if let panel {
            panel.orderFrontRegardless()
            panel.makeKey()
            return
        }

        let rootView = FloatingRootView()
            .modelContainer(modelContainer)
        let hostingController = NSHostingController(rootView: rootView)
        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 420, height: 488)
        let initialFrame = CGRect(
            x: visibleFrame.midX - 210,
            y: visibleFrame.midY - 244,
            width: 420,
            height: 488
        )
        let panel = InteractiveFloatingPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentViewController = hostingController
        panel.title = ""
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isFloatingPanel = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.level = .floating
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.layer?.isOpaque = false
        panel.contentView?.superview?.wantsLayer = true
        panel.contentView?.superview?.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView?.superview?.layer?.isOpaque = false
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel
    }
}

struct FloatingPanelLauncher: View {
    let modelContainer: ModelContainer
    let panelController: FloatingPanelController

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .background(
                FloatingWindowAccessor { window in
                    hideBootstrapWindow(window)
                }
            )
            .onAppear {
                panelController.show(modelContainer: modelContainer)
            }
    }

    private func hideBootstrapWindow(_ window: NSWindow) {
        window.setFrame(CGRect(x: -10_000, y: -10_000, width: 1, height: 1), display: false)
        window.orderOut(nil)
    }
}

private final class InteractiveFloatingPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
