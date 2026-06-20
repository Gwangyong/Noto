//
//  FloatingRootView.swift
//  Noto
//

import SwiftData
import SwiftUI

struct FloatingRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TaskPanelViewModel.sample()
    @State private var isPanelOpen = true
    @State private var characterOrigin = CGPoint(x: 72, y: 74)
    @State private var dragStartOrigin: CGPoint?
    @State private var didLoadPersistedState = false
    @GestureState private var isPressing = false

    var body: some View {
        GeometryReader { proxy in
            let visibleFrame = CGRect(origin: .zero, size: proxy.size)
            let characterSize = CGSize(
                width: DesignTokens.Size.characterSize,
                height: DesignTokens.Size.characterSize
            )
            let characterFrame = CGRect(origin: characterOrigin, size: characterSize)
            let panelHeight = viewModel.screen == .settings
                ? DesignTokens.Size.settingsPanelHeight
                : DesignTokens.Size.placementPanelHeight
            let placement = PanelPlacementResolver.resolve(
                characterFrame: characterFrame,
                visibleScreenFrame: visibleFrame,
                panelSize: CGSize(width: DesignTokens.Size.panelWidth, height: panelHeight)
            )

            ZStack(alignment: .topLeading) {
                desktopBackground

                if isPanelOpen {
                    TaskPanelView(
                        viewModel: viewModel,
                        onCollapse: {
                            withAnimation(.easeOut(duration: DesignTokens.Motion.panelOpenDuration)) {
                                isPanelOpen = false
                            }
                        }
                    )
                    .position(
                        x: placement.origin.x + DesignTokens.Size.panelWidth / 2,
                        y: placement.origin.y + panelHeight / 2
                    )
                    .transition(.opacity.combined(with: .scale(scale: DesignTokens.Motion.panelOpenInitialScale)))
                    .zIndex(1)
                }

                FloatingCharacterView(
                    remainingCount: viewModel.remainingCount,
                    isActive: isPanelOpen,
                    isDragging: dragStartOrigin != nil,
                    isPressed: isPressing
                )
                .position(x: characterFrame.midX, y: characterFrame.midY)
                .gesture(characterGesture(in: visibleFrame))
                .zIndex(2)
            }
            .preferredColorScheme(viewModel.settings.theme.preferredColorScheme)
            .onAppear {
                configurePersistenceIfNeeded()
                characterOrigin = PanelPlacementResolver.clampedCharacterOrigin(
                    characterOrigin,
                    visibleScreenFrame: visibleFrame
                )
            }
            .onChange(of: proxy.size) { _, newSize in
                let newVisibleFrame = CGRect(origin: .zero, size: newSize)
                characterOrigin = PanelPlacementResolver.clampedCharacterOrigin(
                    characterOrigin,
                    visibleScreenFrame: newVisibleFrame
                )
            }
        }
        .frame(minWidth: 560, minHeight: 480)
    }

    private var desktopBackground: some View {
        Color(nsColor: .windowBackgroundColor)
            .ignoresSafeArea()
    }

    private func configurePersistenceIfNeeded() {
        guard !didLoadPersistedState else { return }

        let store = TaskPanelStore(modelContext: modelContext)

        do {
            let snapshot = try store.loadOrSeed(default: viewModel.snapshot)
            viewModel.applySnapshot(snapshot)
        } catch {
            logPersistenceError("load", error)
        }

        viewModel.onSnapshotChange = { snapshot in
            do {
                try store.save(snapshot)
            } catch {
                logPersistenceError("save", error)
            }
        }
        didLoadPersistedState = true
    }

    private func logPersistenceError(_ operation: String, _ error: Error) {
        #if DEBUG
        print("Noto persistence \(operation) failed: \(error)")
        #endif
    }

    private func characterGesture(in visibleFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isPressing) { _, state, _ in
                state = true
            }
            .onChanged { value in
                if dragStartOrigin == nil {
                    dragStartOrigin = characterOrigin
                }

                let start = dragStartOrigin ?? characterOrigin
                let proposedOrigin = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )
                characterOrigin = PanelPlacementResolver.clampedCharacterOrigin(
                    proposedOrigin,
                    visibleScreenFrame: visibleFrame
                )
            }
            .onEnded { value in
                let movedDistance = hypot(value.translation.width, value.translation.height)
                dragStartOrigin = nil

                guard movedDistance <= 4 else { return }
                withAnimation(.easeOut(duration: DesignTokens.Motion.panelOpenDuration)) {
                    isPanelOpen.toggle()
                }
            }
    }
}

private extension TaskPanelSettings.Theme {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

#Preview {
    FloatingRootView()
        .frame(width: 720, height: 520)
}
