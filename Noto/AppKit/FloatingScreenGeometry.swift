//
//  FloatingScreenGeometry.swift
//  Noto
//

import AppKit
import CoreGraphics

enum FloatingScreenGeometry {
    static func topLeftVisibleFrame(for screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame

        return CGRect(
            x: visibleFrame.minX,
            y: desktopMaxY - visibleFrame.maxY,
            width: visibleFrame.width,
            height: visibleFrame.height
        )
    }

    static func appKitFrame(fromTopLeftRect rect: CGRect, on screen: NSScreen) -> CGRect {
        _ = screen
        return CGRect(
            x: rect.minX,
            y: desktopMaxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func topLeftPoint(fromAppKitPoint point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: desktopMaxY - point.y)
    }

    static func screen(containingTopLeftPoint point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { screen in
            topLeftVisibleFrame(for: screen)
                .insetBy(dx: -DesignTokens.Size.characterSize, dy: -DesignTokens.Size.characterSize)
                .contains(point)
        }
    }

    private static var desktopMaxY: CGFloat {
        NSScreen.screens.map(\.frame.maxY).max() ?? 0
    }
}
