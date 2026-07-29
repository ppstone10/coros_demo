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
                        ScenarioPickerView(viewModel: viewModel)
                    }
            }
        }
        .onChange(of: languageStore.current) { _ in screenState.page = .main; viewModel.load() }
        .background(AppColors.Core.black)
        .onAppear {
            if viewModel.cards.isEmpty {
                viewModel.load()
            }
            viewModel.onEffect = { effect in
                // HealthEffect subclasses from KMP are flat types, not nested
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
                .offset(y: max(0, screenState.dragOffset))
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

            if screenState.refreshPhase != .idle {
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
                .zIndex(4)
            }

            HeroTopRow(
                dateLabel: viewModel.dateLabel,
                isSyncing: screenState.refreshPhase == .refreshing || viewModel.isLoading,
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
        screenState.refreshPhase == .refreshing ||
            screenState.refreshPhase == .resetting ||
            viewModel.isLoading
    }

    private var pullProgress: CGFloat {
        min(max(screenState.dragOffset / HealthPullRefreshConfiguration.refreshThreshold, 0), 1)
    }

    private var refreshIndicatorTop: CGFloat {
        healthRefreshIndicatorTop(
            bodyTop: heroHeight + screenState.dragOffset,
            indicatorHeight: refreshIndicatorHeight
        )
    }

    private var refreshIndicatorOpacity: CGFloat {
        switch screenState.refreshPhase {
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
        switch screenState.refreshPhase {
        case .dragging, .armed:
            return Double(pullProgress * 45)
        default:
            return 0
        }
    }

    private var refreshPrompt: String {
        switch screenState.refreshPhase {
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(card.id == "TodayActivity" ? AppImages.Health.todayHeader : card.icon).resizable().scaledToFit().frame(width: 20, height: 20)
                Text(card.title).font(.system(size: 16, weight: .medium)).foregroundStyle(AppColors.Health.cardTitle).lineLimit(1)
                Spacer(minLength: 0)
                if card.id == "HealthCheck", let measuredTime = card.visual?.caption {
                    Text(localizedHealthText(measuredTime))
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.Health.muted)
                        .lineLimit(1)
                }
            }
            if card.isEmpty {
                Text(card.summary).font(.system(size: 14)).foregroundStyle(AppColors.Health.muted)
                    .padding(.top, 12)
            } else if let visual = card.visual {
                HealthCardVisualContent(
                    cardType: card.id,
                    visual: visual,
                    onWeightEdit: {
                        weightPickerValue = Double(visual.primaryValue ?? "") ?? 60.0
                        showsWeightPicker = true
                    }
                )
            } else {
                Text(card.summary).font(.system(size: 14)).foregroundStyle(card.isRisk ? AppColors.Health.risk : AppColors.Health.muted)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.Health.card).clipShape(RoundedRectangle(cornerRadius: 8))
        .clipped()
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

private struct HealthCardVisualContent: View {
    let cardType: String
    let visual: HealthCardVisualData
    let onWeightEdit: () -> Void

    private var contentMinimumHeight: CGFloat {
        switch cardType {
        case "TodayActivity": 58
        case "WeeklyPlan": 110
        case "TrainingLoad": 60
        case "TrainingAssessment": 130
        case "Recovery": 78
        case "RunningAbility", "CyclingAbility": 71
        case "HeartRate", "Stress", "RestingHeartRate", "HrvAssessment", "Sleep": 60
        case "HealthCheck": 114
        case "BodyManagement": 121
        default: 0
        }
    }

    var body: some View {
        Group {
            switch cardType {
            case "TodayActivity": ActivityView(visual: visual)
            case "WeeklyPlan": WeeklyPlanView(visual: visual)
            case "TrainingLoad": TrainingLoadView(visual: visual)
            case "TrainingAssessment": TrainingAssessmentView(visual: visual)
            case "Recovery": RecoveryView(visual: visual)
            case "RunningAbility", "CyclingAbility": AbilityView(cardType: cardType, visual: visual)
            case "HeartRate", "Stress": TrendView(cardType: cardType, visual: visual)
            case "RestingHeartRate": RestingHeartRateView(visual: visual)
            case "HrvAssessment": HrvAssessmentView(visual: visual)
            case "Sleep": SleepView(visual: visual)
            case "HealthCheck": HealthGridView(visual: visual)
            case "BodyManagement": BodyView(visual: visual, onWeightEdit: onWeightEdit)
            default: EmptyView()
            }
        }
        .frame(minHeight: contentMinimumHeight, alignment: .topLeading)
    }
}

private struct HealthWeightPickerSheet: View {
    let current: Double
    let onConfirm: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var weightTenths = 600

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(appLocalized("common_cancel")) { dismiss() }
                Spacer()
                Text(appLocalized("profile_weight_picker")).font(.system(size: 19, weight: .semibold))
                Spacer()
                Button(appLocalized("common_confirm")) {
                    onConfirm(Double(weightTenths) / 10.0)
                    dismiss()
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 58)
            Picker("", selection: $weightTenths) {
                ForEach(300...2000, id: \.self) {
                    Text(String(format: "%.1f", Double($0) / 10.0))
                }
            }
            .pickerStyle(.wheel)
            .colorScheme(.dark)
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .background(AppColors.Account.sheet.ignoresSafeArea())
        .onAppear { weightTenths = Int((current * 10.0).rounded()).clamped(to: 300...2000) }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    HealthDashboardView(
        viewModel: HealthDashboardViewModel(),
        onOpenDetail: { _ in },
        onOpenEditor: {},
        onWatchTap: {}
    )
        .environmentObject(AppLanguageStore.shared)
}
