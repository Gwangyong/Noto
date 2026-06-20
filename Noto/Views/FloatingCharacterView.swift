//
//  FloatingCharacterView.swift
//  Noto
//

import SwiftUI

struct FloatingCharacterView: View {
    let remainingCount: Int
    let isActive: Bool
    let isDragging: Bool
    let isPressed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsBadge: Bool {
        !isActive && remainingCount > 0
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let metrics = animationMetrics(for: timeline.date)

            ZStack(alignment: .topTrailing) {
                characterBody(eyeScale: metrics.eyeScale)
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
                                .shadow(color: Color.black.opacity(0.18), radius: 7, x: 0, y: 3)
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
        .accessibilityValue(remainingCount > 0 ? "남은 할 일 \(remainingCount)개" : "남은 할 일 없음")
    }

    private func characterBody(eyeScale: CGFloat) -> some View {
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
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        .blendMode(.screen)
                }
                .overlay {
                    NotoCharacterBlobShape()
                        .stroke(DesignTokens.Colors.characterHairline, lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 8)

            face(eyeScale: eyeScale)

            if isActive {
                glasses
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(width: DesignTokens.Size.characterSize, height: DesignTokens.Size.characterSize)
    }

    private func face(eyeScale: CGFloat) -> some View {
        ZStack {
            HStack(spacing: 11) {
                Circle()
                    .frame(width: 6, height: 6)
                    .scaleEffect(x: 1, y: eyeScale)
                Circle()
                    .frame(width: 6, height: 6)
                    .scaleEffect(x: 1, y: eyeScale)
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
                .fill(Color.white.opacity(0.16))
                .overlay(
                    Circle()
                        .stroke(DesignTokens.Colors.characterInk, lineWidth: 1.7)
                )
                .frame(width: 15, height: 15)

            Rectangle()
                .fill(DesignTokens.Colors.characterInk)
                .frame(width: 4, height: 1.7)

            Circle()
                .fill(Color.white.opacity(0.16))
                .overlay(
                    Circle()
                        .stroke(DesignTokens.Colors.characterInk, lineWidth: 1.7)
                )
                .frame(width: 15, height: 15)
        }
        .offset(y: 1)
    }

    private func animationMetrics(for date: Date) -> (floatOffset: CGFloat, eyeScale: CGFloat) {
        guard !reduceMotion else { return (0, 1) }

        let now = date.timeIntervalSinceReferenceDate
        let floatOffset: CGFloat
        if isActive || isDragging {
            floatOffset = 0
        } else {
            let floatProgress = now.truncatingRemainder(dividingBy: DesignTokens.Motion.floatDuration) / DesignTokens.Motion.floatDuration
            floatOffset = -sin(floatProgress * .pi) * DesignTokens.Size.characterFloatOffset
        }

        let blinkProgress = now.truncatingRemainder(dividingBy: DesignTokens.Motion.blinkDuration) / DesignTokens.Motion.blinkDuration
        let eyeScale: CGFloat = (0.93...0.955).contains(blinkProgress) ? 0.12 : 1

        return (floatOffset, eyeScale)
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

#Preview {
    HStack(spacing: 24) {
        FloatingCharacterView(remainingCount: 3, isActive: false, isDragging: false, isPressed: false)
        FloatingCharacterView(remainingCount: 3, isActive: true, isDragging: false, isPressed: false)
    }
    .padding(40)
    .background(DesignTokens.Colors.documentBackground)
}
