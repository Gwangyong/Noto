//
//  FloatingWindowAccessor.swift
//  Noto
//

import AppKit
import SwiftUI

struct FloatingWindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorHostView(frame: .zero)
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            onResolve(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            guard let window = nsView?.window else { return }
            onResolve(window)
        }
    }
}

private final class WindowAccessorHostView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
