import SwiftUI
import Shared
import Lottie

enum DashboardPage: Equatable {
    case main
    case scenarioPicker
}

struct DashboardScreenState {
    var page: DashboardPage = .main
    var dragOffset: CGFloat = 0
    var refreshPhase: HealthPullRefreshPhase = .idle
}

struct HealthDashboardView: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    let onOpenDetail: (HealthCard) -> Void
    let onOpenEditor: () -> Void
    let onOpenNormalDataEditor: () -> Void
    let onWatchTap: () -> Void
    @EnvironmentObject private var languageStore: AppLanguageStore
    @State private var screenState = DashboardScreenState()
    @State private var heroHeight: CGFloat = 0
    @State private var refreshIndicatorHeight: CGFloat = 0
    @State private var refreshTask: Task<Void, Never>?
    @State private var weightPickerValue = 60.0
    @State private var showsWeightPicker = false
    var body: some View {
        Group {
            switch screenState.page {
            case .main, .scenarioPicker:
                mainDashboard
                    .sheet(isPresented: .init(get: { screenState.page == .scenarioPicker }, set: { if !$0 { screenState.page = .main } })) {
                        ScenarioPickerView(
                            viewModel: viewModel,
                            onOpenNormalDataEditor: {
                                screenState.page = .main
                                onOpenNormalDataEditor()
                            }
                        )
                    }
            }
        }
        .onChange(of: languageStore.current) { _ in screenState.page = .main; viewModel.load() }
        .background(AppColors.Core.black)
        .onAppear {
            viewModel.startPendingAccountRefresh()
            if !viewModel.accountRefreshPending,
               viewModel.accountRefreshPhase == .idle,
               viewModel.cards.isEmpty {
                viewModel.load()
            }
            viewModel.onEffect = { effect in
                // HealthEffect subclasses from KMP are flat types, not nested
            }
        }
        .onChange(of: viewModel.accountRefreshPending) { pending in
            if pending {
                viewModel.startPendingAccountRefresh()
            }
        }
        .onChange(of: viewModel.isLoading) { isLoading in
            if !isLoading {
                viewModel.startPendingAccountRefresh()
            }
        }
        .sheet(isPresented: $showsWeightPicker) {
            HealthWeightPickerSheet(current: weightPickerValue) { selected in
                viewModel.saveBodyWeight(selected)
            }
        }
    }

    private var mainDashboard: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isDataCorrupted {
                        Text(appLocalized("health_data_corrupted"))
                            .font(.system(size: AppTypography.supporting))
                            .foregroundStyle(AppColors.Health.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 360)
                            .padding(.horizontal, AppSpacing.screen)
                    } else {
                        HeroArcView(steps: viewModel.steps, calories: viewModel.calories,
                                    minutes: viewModel.activeMinutes)

                        ForEach(viewModel.cards) { card in
                            if card.id == "BodyManagement" {
                                cardRow(card)
                                    .contentShape(Rectangle())
                                    .onTapGesture { onOpenDetail(card) }
                                    .padding(.horizontal, AppSpacing.screen)
                                    .padding(.vertical, AppSpacing.xSmall)
                            } else {
                                Button {
                                    onOpenDetail(card)
                                } label: {
                                    cardRow(card)
                                }.buttonStyle(.plain)
                                .padding(.horizontal, AppSpacing.screen)
                                .padding(.vertical, AppSpacing.xSmall)
                            }
                        }

                        Button {
                            onOpenEditor()
                        } label: {
                            Text(appLocalized("health_edit_cards"))
                                .font(.system(size: AppTypography.label))
                                .foregroundStyle(AppColors.Health.editText)
                                .padding(.horizontal, AppSpacing.actionHorizontal).padding(.vertical, AppSpacing.medium)
                                .background(AppColors.Health.card).clipShape(Capsule())
                        }.buttonStyle(.plain).padding(AppSpacing.large)
                    }
                }
                .offset(y: max(0, effectiveDragOffset))
                .animation(
                    .easeOut(duration: HealthPullRefreshConfiguration.settleDuration),
                    value: viewModel.accountRefreshPhase
                )
                .background(
                    ScrollViewPanObserver(
                        isRefreshing: isPullInteractionLocked,
                        onPullChanged: updatePull,
                        onPullEnded: endPull
                    )
                )
            }
            .padding(.top, heroHeight)
            .scrollIndicators(.hidden)
            .zIndex(1)

            if effectiveRefreshPhase != .idle {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.Health.steps))
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(refreshIconRotation))
                    Text(refreshPrompt)
                        .font(.system(size: AppTypography.supporting))
                        .foregroundColor(AppColors.Health.muted)
                }
                .fixedSize()
                .background(
                    GeometryReader { proxy in
                        AppColors.Core.clear.preference(
                            key: RefreshIndicatorHeightPreferenceKey.self,
                            value: proxy.size.height
                        )
                    }
                )
                .onPreferenceChange(RefreshIndicatorHeightPreferenceKey.self) {
                    refreshIndicatorHeight = $0
                }
                .offset(y: refreshIndicatorTop)
                .opacity(refreshIndicatorOpacity)
                .scaleEffect(0.94 + 0.06 * refreshIndicatorOpacity)
                .animation(
                    .easeOut(duration: HealthPullRefreshConfiguration.settleDuration),
                    value: viewModel.accountRefreshPhase
                )
                .zIndex(4)
            }

            HeroTopRow(
                dateLabel: viewModel.dateLabel,
                isSyncing: effectiveRefreshPhase == .refreshing || viewModel.isLoading,
                syncCycle: viewModel.syncCycle,
                onTapWatch: onWatchTap,
                onLongPressWatch: { screenState.page = .scenarioPicker }
            )
            .background(
                GeometryReader { proxy in
                    AppColors.Core.clear.preference(
                        key: HeroHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            )
            .onPreferenceChange(HeroHeightPreferenceKey.self) {
                heroHeight = $0
            }
            .zIndex(3)
        }
        .background(AppColors.Core.black)
        .ignoresSafeArea(edges: .top)
        .onDisappear {
            refreshTask?.cancel()
            refreshTask = nil
            screenState.dragOffset = 0
            screenState.refreshPhase = .idle
        }
    }

    private var isPullInteractionLocked: Bool {
        effectiveRefreshPhase == .refreshing ||
            effectiveRefreshPhase == .resetting ||
            viewModel.isLoading
    }

    private var effectiveRefreshPhase: HealthPullRefreshPhase {
        switch viewModel.accountRefreshPhase {
        case .refreshing:
            return .refreshing
        case .resetting:
            return .resetting
        case .idle:
            return screenState.refreshPhase
        }
    }

    private var effectiveDragOffset: CGFloat {
        switch viewModel.accountRefreshPhase {
        case .refreshing:
            return HealthPullRefreshConfiguration.refreshHoldOffset
        case .resetting:
            return 0
        case .idle:
            return screenState.dragOffset
        }
    }

    private var pullProgress: CGFloat {
        min(max(screenState.dragOffset / HealthPullRefreshConfiguration.refreshThreshold, 0), 1)
    }

    private var refreshIndicatorTop: CGFloat {
        healthRefreshIndicatorTop(
            bodyTop: heroHeight + effectiveDragOffset,
            indicatorHeight: refreshIndicatorHeight
        )
    }

    private var refreshIndicatorOpacity: CGFloat {
        switch effectiveRefreshPhase {
        case .idle:
            return 0
        case .dragging:
            return min(pullProgress / 0.4, 1)
        case .armed, .refreshing:
            return 1
        case .resetting:
            return min(
                max(
                    screenState.dragOffset / HealthPullRefreshConfiguration.refreshHoldOffset,
                    0
                ),
                1
            )
        }
    }

    private var refreshIconRotation: Double {
        switch effectiveRefreshPhase {
        case .dragging, .armed:
            return Double(pullProgress * 45)
        default:
            return 0
        }
    }

    private var refreshPrompt: String {
        switch effectiveRefreshPhase {
        case .dragging:
            return appLocalized("health_pull_to_refresh")
        case .armed:
            return appLocalized("health_release_to_refresh")
        case .refreshing, .resetting:
            return appLocalized("health_data_syncing")
        case .idle:
            return ""
        }
    }

    private func updatePull(_ distance: CGFloat) {
        guard !isPullInteractionLocked else { return }
        let offset = min(
            max(distance * HealthPullRefreshConfiguration.pullResistance, 0),
            HealthPullRefreshConfiguration.maxPullOffset
        )
        screenState.dragOffset = offset
        screenState.refreshPhase = healthPullRefreshPhase(offset: offset)
    }

    private func endPull(_: CGFloat, _ gestureBeganAtTop: Bool) {
        guard gestureBeganAtTop, !isPullInteractionLocked else {
            resetPullWithoutRefresh()
            return
        }
        if screenState.refreshPhase == .armed {
            beginRefresh()
        } else {
            resetPullWithoutRefresh()
        }
    }

    private func beginRefresh() {
        refreshTask?.cancel()
        withAnimation(.easeOut(duration: HealthPullRefreshConfiguration.settleDuration)) {
            screenState.dragOffset = HealthPullRefreshConfiguration.refreshHoldOffset
        }
        refreshTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: HealthPullRefreshConfiguration.settleDurationNanoseconds
            )
            guard !Task.isCancelled else { return }
            screenState.refreshPhase = .refreshing
            await viewModel.refresh()
            guard !Task.isCancelled else { return }
            screenState.refreshPhase = .resetting
            withAnimation(.easeOut(duration: HealthPullRefreshConfiguration.settleDuration)) {
                screenState.dragOffset = 0
            }
            try? await Task.sleep(
                nanoseconds: HealthPullRefreshConfiguration.settleDurationNanoseconds
            )
            guard !Task.isCancelled else { return }
            screenState.refreshPhase = .idle
            refreshTask = nil
        }
    }

    private func resetPullWithoutRefresh() {
        refreshTask?.cancel()
        screenState.refreshPhase = .resetting
        withAnimation(.easeOut(duration: HealthPullRefreshConfiguration.settleDuration)) {
            screenState.dragOffset = 0
        }
        refreshTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: HealthPullRefreshConfiguration.settleDurationNanoseconds
            )
            guard !Task.isCancelled else { return }
            screenState.refreshPhase = .idle
            refreshTask = nil
        }
    }

    private func cardRow(_ card: HealthCard) -> some View {
        HealthDashboardCardRow(card: card) {
            weightPickerValue = Double(card.visual?.primaryValue ?? "") ?? 60.0
            showsWeightPicker = true
        }
    }

}

private struct HeroHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct RefreshIndicatorHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    HealthDashboardView(
        viewModel: HealthDashboardViewModel(
            previewState: HealthPreviewFixtures.shared.normalState()
        ),
        onOpenDetail: { _ in },
        onOpenEditor: {},
        onOpenNormalDataEditor: {},
        onWatchTap: {}
    )
        .environmentObject(AppLanguageStore.shared)
}
