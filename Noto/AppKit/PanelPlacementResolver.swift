//
//  PanelPlacementResolver.swift
//  Noto
//

import CoreGraphics

struct PanelPlacementResolver {
    enum HorizontalDirection {
        case rightOfCharacter
        case leftOfCharacter
    }

    enum VerticalDirection {
        case belowCharacter
        case aboveCharacter
    }

    struct Placement {
        let origin: CGPoint
        let horizontalDirection: HorizontalDirection
        let verticalDirection: VerticalDirection

        var opensLeft: Bool {
            horizontalDirection == .leftOfCharacter
        }

        var opensUp: Bool {
            verticalDirection == .aboveCharacter
        }
    }

    static func resolve(
        characterFrame: CGRect,
        visibleScreenFrame: CGRect,
        panelSize: CGSize = CGSize(
            width: DesignTokens.Size.panelWidth,
            height: DesignTokens.Size.placementPanelHeight
        ),
        gap: CGFloat = DesignTokens.Size.panelGap,
        clampPadding: CGFloat = DesignTokens.Size.screenClampPadding,
        menuBarInset: CGFloat = DesignTokens.Size.desktopMenuBarInset
    ) -> Placement {
        let characterCenter = CGPoint(x: characterFrame.midX, y: characterFrame.midY)
        let screenCenter = CGPoint(x: visibleScreenFrame.midX, y: visibleScreenFrame.midY)

        let horizontal: HorizontalDirection = characterCenter.x < screenCenter.x
            ? .rightOfCharacter
            : .leftOfCharacter
        let vertical: VerticalDirection = characterCenter.y < screenCenter.y
            ? .belowCharacter
            : .aboveCharacter

        let rawX: CGFloat = horizontal == .rightOfCharacter
            ? characterFrame.maxX + gap
            : characterFrame.minX - gap - panelSize.width

        let rawY: CGFloat = vertical == .belowCharacter
            ? characterFrame.minY
            : characterFrame.maxY - panelSize.height

        let minX = visibleScreenFrame.minX + clampPadding
        let maxX = visibleScreenFrame.maxX - panelSize.width - clampPadding
        let minY = visibleScreenFrame.minY + menuBarInset + clampPadding
        let maxY = visibleScreenFrame.maxY - panelSize.height - clampPadding

        return Placement(
            origin: CGPoint(
                x: clamp(rawX, min: minX, max: maxX),
                y: clamp(rawY, min: minY, max: maxY)
            ),
            horizontalDirection: horizontal,
            verticalDirection: vertical
        )
    }

    static func clampedCharacterOrigin(
        _ origin: CGPoint,
        visibleScreenFrame: CGRect,
        characterSize: CGSize = CGSize(
            width: DesignTokens.Size.characterSize,
            height: DesignTokens.Size.characterSize
        ),
        clampPadding: CGFloat = DesignTokens.Size.screenClampPadding,
        menuBarInset: CGFloat = DesignTokens.Size.desktopMenuBarInset
    ) -> CGPoint {
        let minX = visibleScreenFrame.minX + clampPadding
        let maxX = visibleScreenFrame.maxX - characterSize.width - clampPadding
        let minY = visibleScreenFrame.minY + menuBarInset + clampPadding
        let maxY = visibleScreenFrame.maxY - characterSize.height - clampPadding

        return CGPoint(
            x: clamp(origin.x, min: minX, max: maxX),
            y: clamp(origin.y, min: minY, max: maxY)
        )
    }

    private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        guard minValue <= maxValue else { return minValue }
        return Swift.max(minValue, Swift.min(value, maxValue))
    }
}
