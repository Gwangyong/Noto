//
//  FloatingCharacterView.swift
//  Noto
//

import SwiftUI

struct FloatingCharacterView: View {
    let remainingCount: Int
    let characterKind: FloatingCharacterKind
    let isActive: Bool
    let isDragging: Bool
    let isPressed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsBadge: Bool {
        !isActive
    }

    init(
        remainingCount: Int,
        characterKind: FloatingCharacterKind = .noto,
        isActive: Bool,
        isDragging: Bool,
        isPressed: Bool
    ) {
        self.remainingCount = remainingCount
        self.characterKind = characterKind
        self.isActive = isActive
        self.isDragging = isDragging
        self.isPressed = isPressed
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let metrics = animationMetrics(for: timeline.date)

            ZStack(alignment: .topTrailing) {
                FloatingCharacterArtwork(
                    characterKind: characterKind,
                    isActive: isActive,
                    metrics: metrics
                )
                .offset(y: metrics.floatOffset)
                .scaleEffect(isPressed ? DesignTokens.Motion.pressedScale : 1)
                .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isPressed)

                if showsBadge {
                    Text("\(remainingCount)")
                        .font(DesignTokens.Typography.badge)
                        .foregroundStyle(DesignTokens.Colors.onPrimary)
                        .frame(minWidth: DesignTokens.Size.badgeMinWidth)
                        .frame(height: DesignTokens.Size.badgeHeight)
                        .padding(.horizontal, 6)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.primary)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.96), lineWidth: 2.5)
                        )
                        .offset(x: 10, y: -11)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isActive ? "Noto 닫기" : "Noto 열기")
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let remainingText = remainingCount > 0 ? "남은 할 일 \(remainingCount)개" : "남은 할 일 없음"
        return "\(characterKind.accessibilityName), \(remainingText)"
    }

    private func animationMetrics(for date: Date) -> FloatingCharacterAnimationMetrics {
        guard !reduceMotion else {
            return FloatingCharacterAnimationMetrics.preview
        }

        let now = date.timeIntervalSinceReferenceDate
        let floatOffset: CGFloat
        if isActive || isDragging {
            floatOffset = 0
        } else {
            let floatProgress = now.truncatingRemainder(dividingBy: DesignTokens.Motion.floatDuration) / DesignTokens.Motion.floatDuration
            floatOffset = -sin(floatProgress * .pi) * DesignTokens.Size.characterFloatOffset
        }

        let blinkProgress = now.truncatingRemainder(dividingBy: DesignTokens.Motion.blinkDuration) / DesignTokens.Motion.blinkDuration
        let blinkScale: CGFloat = (0.93...0.955).contains(blinkProgress) ? 0.12 : 1
        let wave = sin(now / 3.8 * .pi * 2)
        let slowRotation = now.truncatingRemainder(dividingBy: 18) / 18 * 360
        let cloudOffset = CGFloat(sin(now / 5.5 * .pi * 2)) * 3.6
        let tailAngle = Angle.degrees(sin(now / 2.8 * .pi * 2) * 3.5)
        let antennaAngle = Angle.degrees(sin(now / 2.4 * .pi * 2) * 4.0)
        let starOpacity = 0.50 + (sin(now / 2.6 * .pi * 2) + 1) * 0.22

        return FloatingCharacterAnimationMetrics(
            floatOffset: floatOffset,
            blinkScale: blinkScale,
            blinkOpacity: blinkScale < 1 ? 0.38 : 1,
            breatheScale: 1 + CGFloat(wave) * 0.014,
            slowRotation: Angle.degrees(slowRotation),
            cloudOffset: cloudOffset,
            tailAngle: isDragging ? .degrees(-6) : tailAngle,
            antennaAngle: isDragging ? .degrees(8) : antennaAngle,
            starOpacity: starOpacity
        )
    }
}

struct FloatingCharacterAnimationMetrics {
    let floatOffset: CGFloat
    let blinkScale: CGFloat
    let blinkOpacity: Double
    let breatheScale: CGFloat
    let slowRotation: Angle
    let cloudOffset: CGFloat
    let tailAngle: Angle
    let antennaAngle: Angle
    let starOpacity: Double

    static let preview = FloatingCharacterAnimationMetrics(
        floatOffset: 0,
        blinkScale: 1,
        blinkOpacity: 1,
        breatheScale: 1,
        slowRotation: .degrees(-8),
        cloudOffset: 0,
        tailAngle: .degrees(0),
        antennaAngle: .degrees(0),
        starOpacity: 0.72
    )
}

struct FloatingCharacterArtwork: View {
    let characterKind: FloatingCharacterKind
    let isActive: Bool
    let metrics: FloatingCharacterAnimationMetrics

    var body: some View {
        Group {
            switch characterKind {
            case .noto:
                NotoBlobCharacter(isActive: isActive, metrics: metrics)
            case .miniEarth:
                MiniEarthCharacter(metrics: metrics)
            case .catLoaf:
                CatLoafCharacter(metrics: metrics)
            case .smallRobot:
                SmallRobotCharacter(isActive: isActive, metrics: metrics)
            case .moonPiece:
                MoonPieceCharacter(metrics: metrics)
            }
        }
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }
}

private struct NotoBlobCharacter: View {
    let isActive: Bool
    let metrics: FloatingCharacterAnimationMetrics

    var body: some View {
        ZStack {
            NotoCharacterBlobShape()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.Colors.characterTop,
                            DesignTokens.Colors.characterMid,
                            DesignTokens.Colors.characterBottom
                        ],
                        center: UnitPoint(x: 0.5, y: 0.16),
                        startRadius: 4,
                        endRadius: 74
                    )
                )
                .overlay {
                    NotoCharacterBlobShape()
                        .stroke(DesignTokens.Colors.characterHighlight, lineWidth: 1)
                        .blendMode(.screen)
                }
                .overlay {
                    NotoCharacterBlobShape()
                        .stroke(DesignTokens.Colors.characterHairline, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            face

            if isActive {
                glasses
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .scaleEffect(metrics.breatheScale)
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }

    private var face: some View {
        ZStack {
            HStack(spacing: 11) {
                Circle()
                    .frame(width: 6, height: 6)
                    .scaleEffect(x: 1, y: metrics.blinkScale)
                Circle()
                    .frame(width: 6, height: 6)
                    .scaleEffect(x: 1, y: metrics.blinkScale)
            }
            .foregroundStyle(DesignTokens.Colors.characterInk)
            .offset(y: 1)

            Capsule()
                .fill(DesignTokens.Colors.characterInk.opacity(0.5))
                .frame(width: 7, height: 1.8)
                .offset(y: 13)
        }
    }

    private var glasses: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(DesignTokens.Colors.characterLens)
                .overlay(
                    Circle()
                        .stroke(DesignTokens.Colors.characterInk, lineWidth: 1.7)
                )
                .frame(width: 15, height: 15)

            Rectangle()
                .fill(DesignTokens.Colors.characterInk)
                .frame(width: 4, height: 1.7)

            Circle()
                .fill(DesignTokens.Colors.characterLens)
                .overlay(
                    Circle()
                        .stroke(DesignTokens.Colors.characterInk, lineWidth: 1.7)
                )
                .frame(width: 15, height: 15)
        }
        .offset(y: 1)
    }
}

private struct MiniEarthCharacter: View {
    let metrics: FloatingCharacterAnimationMetrics

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: 34, height: 7)
                .blur(radius: 1.4)
                .offset(y: 24)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(light: 0xCDEDEA, dark: 0x80A9AD),
                            Color(light: 0x7DBFC7, dark: 0x4F7D86),
                            Color(light: 0x557F91, dark: 0x2D4651)
                        ],
                        center: UnitPoint(x: 0.28, y: 0.18),
                        startRadius: 3,
                        endRadius: 49
                    )
                )
                .frame(width: 47, height: 47)
                .overlay {
                    Circle()
                        .stroke(Color(light: 0xFFFFFF, dark: 0xD9F7FF, lightOpacity: 0.56, darkOpacity: 0.20), lineWidth: 1)
                        .blendMode(.screen)
                }
                .overlay {
                    Circle()
                        .stroke(DesignTokens.Colors.characterHairline, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            ZStack {
                EarthContinentShape(variant: .left)
                    .fill(Color(light: 0x9BC89C, dark: 0x6F9270))
                EarthContinentShape(variant: .right)
                    .fill(Color(light: 0xD3C88C, dark: 0x9C9165))
                EarthContinentShape(variant: .lower)
                    .fill(Color(light: 0x7EAD88, dark: 0x5D7F68))
            }
            .frame(width: 47, height: 47)
            .rotationEffect(metrics.slowRotation)
            .clipShape(Circle())

            EarthCloud(width: 20)
                .offset(x: -8 + metrics.cloudOffset, y: -10)
            EarthCloud(width: 15)
                .offset(x: 10 - metrics.cloudOffset * 0.8, y: 8)
                .opacity(0.78)

            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 10, height: 10)
                .blur(radius: 0.3)
                .offset(x: -11, y: -14)
        }
        .scaleEffect(metrics.breatheScale)
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }
}

private struct EarthCloud: View {
    let width: CGFloat

    var body: some View {
        Capsule()
            .fill(Color(light: 0xFFFFFF, dark: 0xE7FBFF, lightOpacity: 0.72, darkOpacity: 0.28))
            .frame(width: width, height: 5)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color(light: 0xFFFFFF, dark: 0xE7FBFF, lightOpacity: 0.70, darkOpacity: 0.24))
                    .frame(width: 8, height: 8)
                    .offset(x: 4, y: -2)
            }
    }
}

private struct CatLoafCharacter: View {
    let metrics: FloatingCharacterAnimationMetrics

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: 38, height: 7)
                .blur(radius: 1.2)
                .offset(y: 23)

            Capsule()
                .fill(Color(light: 0xBAA58F, dark: 0x73675A))
                .frame(width: 22, height: 8)
                .rotationEffect(metrics.tailAngle, anchor: .leading)
                .offset(x: 16, y: 8)

            CatEarShape(side: .left)
                .fill(Color(light: 0xE8D7C2, dark: 0x8E7F6E))
                .frame(width: 18, height: 16)
                .offset(x: -14, y: -9)

            CatEarShape(side: .right)
                .fill(Color(light: 0xE8D7C2, dark: 0x8E7F6E))
                .frame(width: 18, height: 16)
                .offset(x: 8, y: -9)

            CatLoafBodyShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(light: 0xF3E4D0, dark: 0xA0907B),
                            Color(light: 0xD7BFA4, dark: 0x74685A)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 48, height: 34)
                .overlay {
                    CatLoafBodyShape()
                        .stroke(Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.42, darkOpacity: 0.14), lineWidth: 1)
                        .blendMode(.screen)
                }
                .overlay {
                    CatLoafBodyShape()
                        .stroke(DesignTokens.Colors.characterHairline, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                .offset(y: 4)

            catFace

            HStack(spacing: 14) {
                Capsule()
                    .frame(width: 8, height: 2.4)
                Capsule()
                    .frame(width: 8, height: 2.4)
            }
            .foregroundStyle(Color(light: 0xAA8C72, dark: 0x5E5449, lightOpacity: 0.55, darkOpacity: 0.58))
            .offset(y: 16)
        }
        .scaleEffect(metrics.breatheScale)
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }

    private var catFace: some View {
        ZStack {
            HStack(spacing: 9) {
                Circle()
                    .frame(width: 4.8, height: 4.8)
                    .scaleEffect(x: 1, y: metrics.blinkScale)
                Circle()
                    .frame(width: 4.8, height: 4.8)
                    .scaleEffect(x: 1, y: metrics.blinkScale)
            }
            .foregroundStyle(Color(light: 0x3A3027, dark: 0x241F1B))
            .offset(y: 2)

            Capsule()
                .fill(Color(light: 0x3A3027, dark: 0x241F1B, lightOpacity: 0.42, darkOpacity: 0.50))
                .frame(width: 6, height: 1.5)
                .offset(y: 10)
        }
    }
}

private struct SmallRobotCharacter: View {
    let isActive: Bool
    let metrics: FloatingCharacterAnimationMetrics

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: 34, height: 7)
                .blur(radius: 1.2)
                .offset(y: 24)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(light: 0x6D7781, dark: 0x9BA9B4))
                    .frame(width: 2, height: 9)
                    .rotationEffect(metrics.antennaAngle, anchor: .bottom)
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(Color(light: 0xE6B957, dark: 0xF2CD73))
                            .frame(width: 6, height: 6)
                            .opacity(metrics.blinkOpacity)
                            .offset(y: -4)
                    }

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(light: 0xF5F7F6, dark: 0xAEB9BD),
                                Color(light: 0xC9D2D5, dark: 0x68757C)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 37)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.56, darkOpacity: 0.16), lineWidth: 1)
                            .blendMode(.screen)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DesignTokens.Colors.characterHairline, lineWidth: 1)
                    }
                    .overlay {
                        robotFace
                    }
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .offset(y: 1)
        }
        .scaleEffect(metrics.breatheScale)
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }

    private var robotFace: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(light: 0x40515A, dark: 0x27333A))
                .frame(width: 30, height: 19)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                }

            HStack(spacing: 6) {
                Capsule()
                    .fill(Color(light: 0x9BD0D8, dark: 0xBFEAF0))
                    .frame(width: 5, height: isActive ? 6 : 5)
                    .scaleEffect(x: 1, y: metrics.blinkScale)
                    .opacity(metrics.blinkOpacity)
                Capsule()
                    .fill(Color(light: 0x9BD0D8, dark: 0xBFEAF0))
                    .frame(width: 5, height: isActive ? 6 : 5)
                    .scaleEffect(x: 1, y: metrics.blinkScale)
                    .opacity(metrics.blinkOpacity)
            }
            .offset(y: -2)

            Capsule()
                .fill(Color(light: 0x9BD0D8, dark: 0xBFEAF0, lightOpacity: isActive ? 0.82 : 0.44, darkOpacity: isActive ? 0.90 : 0.50))
                .frame(width: isActive ? 10 : 7, height: 1.8)
                .offset(y: 7)
        }
    }
}

private struct MoonPieceCharacter: View {
    let metrics: FloatingCharacterAnimationMetrics

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.10))
                .frame(width: 31, height: 7)
                .blur(radius: 1.2)
                .offset(y: 24)

            SparkleShape()
                .fill(Color(light: 0xD69B3B, dark: 0xF0D28A, lightOpacity: 0.68, darkOpacity: 0.62))
                .frame(width: 8, height: 8)
                .opacity(metrics.starOpacity)
                .offset(x: 18, y: -15)

            SparkleShape()
                .fill(Color(light: 0xD69B3B, dark: 0xF0D28A, lightOpacity: 0.48, darkOpacity: 0.46))
                .frame(width: 6, height: 6)
                .opacity(1.2 - metrics.starOpacity)
                .offset(x: -19, y: -5)

            CrescentShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(light: 0xFFF5CE, dark: 0xD8C78F),
                            Color(light: 0xE0C976, dark: 0x8E8057),
                            Color(light: 0xB79B52, dark: 0x554C3A)
                        ],
                        center: UnitPoint(x: 0.28, y: 0.16),
                        startRadius: 3,
                        endRadius: 50
                    ),
                    style: FillStyle(eoFill: true)
                )
                .frame(width: 47, height: 47)
                .overlay {
                    CrescentShape()
                        .stroke(Color(light: 0xFFFFFF, dark: 0xFFFFFF, lightOpacity: 0.52, darkOpacity: 0.16), lineWidth: 1)
                        .blendMode(.screen)
                }
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            Group {
                Circle()
                    .frame(width: 6, height: 6)
                    .offset(x: -10, y: -9)
                Circle()
                    .frame(width: 4, height: 4)
                    .offset(x: -16, y: 8)
                Circle()
                    .frame(width: 3, height: 3)
                    .offset(x: -3, y: 12)
            }
            .foregroundStyle(Color(light: 0x987E42, dark: 0x3D372A, lightOpacity: 0.22, darkOpacity: 0.26))
        }
        .scaleEffect(metrics.breatheScale)
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }
}

private struct NotoCharacterBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: width * 0.50, y: 0))
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.46),
            control1: CGPoint(x: width * 0.80, y: 0),
            control2: CGPoint(x: width, y: height * 0.14)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.53, y: height),
            control1: CGPoint(x: width, y: height * 0.78),
            control2: CGPoint(x: width * 0.84, y: height)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.50),
            control1: CGPoint(x: width * 0.18, y: height),
            control2: CGPoint(x: 0, y: height * 0.84)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.50, y: 0),
            control1: CGPoint(x: 0, y: height * 0.16),
            control2: CGPoint(x: width * 0.18, y: 0)
        )
        path.closeSubpath()

        return path
    }
}

private enum EarthContinentVariant {
    case left
    case right
    case lower
}

private struct EarthContinentShape: Shape {
    let variant: EarthContinentVariant

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()

        switch variant {
        case .left:
            path.move(to: CGPoint(x: width * 0.18, y: height * 0.26))
            path.addCurve(to: CGPoint(x: width * 0.41, y: height * 0.18), control1: CGPoint(x: width * 0.22, y: height * 0.16), control2: CGPoint(x: width * 0.36, y: height * 0.12))
            path.addCurve(to: CGPoint(x: width * 0.48, y: height * 0.37), control1: CGPoint(x: width * 0.46, y: height * 0.24), control2: CGPoint(x: width * 0.52, y: height * 0.30))
            path.addCurve(to: CGPoint(x: width * 0.31, y: height * 0.49), control1: CGPoint(x: width * 0.42, y: height * 0.45), control2: CGPoint(x: width * 0.36, y: height * 0.48))
            path.addCurve(to: CGPoint(x: width * 0.15, y: height * 0.39), control1: CGPoint(x: width * 0.24, y: height * 0.49), control2: CGPoint(x: width * 0.16, y: height * 0.45))
            path.closeSubpath()
        case .right:
            path.move(to: CGPoint(x: width * 0.58, y: height * 0.27))
            path.addCurve(to: CGPoint(x: width * 0.82, y: height * 0.34), control1: CGPoint(x: width * 0.64, y: height * 0.20), control2: CGPoint(x: width * 0.76, y: height * 0.22))
            path.addCurve(to: CGPoint(x: width * 0.76, y: height * 0.58), control1: CGPoint(x: width * 0.88, y: height * 0.45), control2: CGPoint(x: width * 0.84, y: height * 0.55))
            path.addCurve(to: CGPoint(x: width * 0.55, y: height * 0.48), control1: CGPoint(x: width * 0.67, y: height * 0.62), control2: CGPoint(x: width * 0.56, y: height * 0.57))
            path.addCurve(to: CGPoint(x: width * 0.58, y: height * 0.27), control1: CGPoint(x: width * 0.53, y: height * 0.39), control2: CGPoint(x: width * 0.52, y: height * 0.33))
            path.closeSubpath()
        case .lower:
            path.move(to: CGPoint(x: width * 0.35, y: height * 0.62))
            path.addCurve(to: CGPoint(x: width * 0.55, y: height * 0.61), control1: CGPoint(x: width * 0.41, y: height * 0.57), control2: CGPoint(x: width * 0.49, y: height * 0.57))
            path.addCurve(to: CGPoint(x: width * 0.58, y: height * 0.81), control1: CGPoint(x: width * 0.62, y: height * 0.67), control2: CGPoint(x: width * 0.62, y: height * 0.76))
            path.addCurve(to: CGPoint(x: width * 0.37, y: height * 0.82), control1: CGPoint(x: width * 0.52, y: height * 0.88), control2: CGPoint(x: width * 0.41, y: height * 0.88))
            path.addCurve(to: CGPoint(x: width * 0.35, y: height * 0.62), control1: CGPoint(x: width * 0.31, y: height * 0.75), control2: CGPoint(x: width * 0.29, y: height * 0.67))
            path.closeSubpath()
        }

        return path
    }
}

private struct CatLoafBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()

        path.move(to: CGPoint(x: width * 0.18, y: height * 0.34))
        path.addCurve(
            to: CGPoint(x: width * 0.94, y: height * 0.44),
            control1: CGPoint(x: width * 0.34, y: height * 0.03),
            control2: CGPoint(x: width * 0.82, y: height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.72, y: height * 0.93),
            control1: CGPoint(x: width * 1.02, y: height * 0.70),
            control2: CGPoint(x: width * 0.93, y: height * 0.92)
        )
        path.addLine(to: CGPoint(x: width * 0.20, y: height * 0.93))
        path.addCurve(
            to: CGPoint(x: width * 0.18, y: height * 0.34),
            control1: CGPoint(x: width * 0.03, y: height * 0.93),
            control2: CGPoint(x: width * 0.01, y: height * 0.50)
        )
        path.closeSubpath()

        return path
    }
}

private enum CatEarSide {
    case left
    case right
}

private struct CatEarShape: Shape {
    let side: CatEarSide

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()

        switch side {
        case .left:
            path.move(to: CGPoint(x: width * 0.12, y: height * 0.95))
            path.addLine(to: CGPoint(x: width * 0.42, y: height * 0.06))
            path.addLine(to: CGPoint(x: width * 0.90, y: height * 0.88))
        case .right:
            path.move(to: CGPoint(x: width * 0.10, y: height * 0.88))
            path.addLine(to: CGPoint(x: width * 0.58, y: height * 0.06))
            path.addLine(to: CGPoint(x: width * 0.88, y: height * 0.95))
        }

        path.closeSubpath()
        return path
    }
}

private struct CrescentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        path.addEllipse(
            in: CGRect(
                x: rect.minX + rect.width * 0.34,
                y: rect.minY - rect.height * 0.06,
                width: rect.width * 0.92,
                height: rect.height * 1.08
            )
        )
        return path
    }
}

private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        var path = Path()

        path.move(to: CGPoint(x: width * 0.50, y: 0))
        path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.38))
        path.addLine(to: CGPoint(x: width, y: height * 0.50))
        path.addLine(to: CGPoint(x: width * 0.62, y: height * 0.62))
        path.addLine(to: CGPoint(x: width * 0.50, y: height))
        path.addLine(to: CGPoint(x: width * 0.38, y: height * 0.62))
        path.addLine(to: CGPoint(x: 0, y: height * 0.50))
        path.addLine(to: CGPoint(x: width * 0.38, y: height * 0.38))
        path.closeSubpath()

        return path
    }
}

#Preview {
    VStack(spacing: 22) {
        HStack(spacing: 16) {
            ForEach(FloatingCharacterKind.allCases) { kind in
                FloatingCharacterView(
                    remainingCount: 3,
                    characterKind: kind,
                    isActive: false,
                    isDragging: false,
                    isPressed: false
                )
            }
        }

        HStack(spacing: 16) {
            ForEach(FloatingCharacterKind.allCases) { kind in
                FloatingCharacterView(
                    remainingCount: 0,
                    characterKind: kind,
                    isActive: true,
                    isDragging: false,
                    isPressed: false
                )
            }
        }
    }
    .padding(40)
    .background(DesignTokens.Colors.documentBackground)
}
