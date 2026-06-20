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
        let hostingView = TransparentHostingView(rootView: rootView)
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

        panel.contentView = hostingView
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

private final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool {
        false
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureTransparentLayerChain()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        configureTransparentLayerChain()
    }

    private func configureTransparentLayerChain() {
        var view: NSView? = self
        while let currentView = view {
            currentView.wantsLayer = true
            currentView.layer?.backgroundColor = NSColor.clear.cgColor
            currentView.layer?.isOpaque = false
            view = currentView.superview
        }
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
