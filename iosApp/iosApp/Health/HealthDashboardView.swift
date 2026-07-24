import SwiftUI
import Shared
import Lottie

enum DashboardPage: Equatable {
    case main
    case detail(HealthCard)
    case editor
    case scenarioPicker
}

struct DashboardScreenState {
    var page: DashboardPage = .main
    var dragOffset: CGFloat = 0
}

struct HealthDashboardView: View {
    @Binding var isFullscreen: Bool
    let onWatchTap: () -> Void
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var screenState = DashboardScreenState()
    var body: some View {
        Group {
            switch screenState.page {
            case .editor:
                HealthCardEditor(initial: viewModel.cards, onClose: closeEditor, onSave: saveCards)
            case .detail(let card):
                HealthDetailView(card: card) { screenState.page = .main; isFullscreen = false }
            case .main, .scenarioPicker:
                mainDashboard
                    .sheet(isPresented: .init(get: { screenState.page == .scenarioPicker }, set: { if !$0 { screenState.page = .main } })) {
                        ScenarioPickerView(viewModel: viewModel)
                    }
            }
        }
        .onChange(of: languageStore.current) { _ in screenState.page = .main; isFullscreen = false; viewModel.load() }
        .background(AppColors.Core.black)
        .onAppear {
            viewModel.onEffect = { effect in
                // HealthEffect subclasses from KMP are flat types, not nested
            }
        }
    }

    private var mainDashboard: some View {
        VStack(spacing: 0) {
            HeroTopRow(dateLabel: viewModel.dateLabel, isSyncing: viewModel.isLoading,
                       syncCycle: viewModel.syncCycle,
                       onTapWatch: onWatchTap,
                       onLongPressWatch: { screenState.page = .scenarioPicker })
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
                                Button {
                                    screenState.page = .detail(card); isFullscreen = true
                                } label: {
                                    cardRow(card)
                                }.buttonStyle(.plain)
                                    .padding(.horizontal, AppSpacing.screen)
                                    .padding(.vertical, AppSpacing.xSmall)
                            }

                            Button {
                                screenState.page = .editor; isFullscreen = true
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
                            isRefreshing: viewModel.isLoading,
                            onPullChanged: { distance in
                                guard !viewModel.isLoading else { return }
                                screenState.dragOffset = min(distance * 0.4, 250)
                            },
                            onPullEnded: { distance, gestureBeganAtTop in
                                let shouldRefresh = gestureBeganAtTop && distance >= 64 && !viewModel.isLoading
                                if shouldRefresh {
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { screenState.dragOffset = 55 }
                                    Task { await viewModel.refresh() }
                                } else {
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { screenState.dragOffset = 0 }
                                }
                            }
                        )
                    )
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.isLoading) { _, loading in
                    if !loading {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { screenState.dragOffset = 0 }
                    }
                }

                if screenState.dragOffset > 10 || viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppColors.Health.steps)).scaleEffect(0.8)
                        Text(appLocalized("health_data_syncing")).font(.system(size: AppTypography.supporting)).foregroundColor(AppColors.Health.muted)
                    }.padding(.top, 6)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
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
                HealthCardVisualContent(cardType: card.id, visual: visual)
            } else {
                Text(card.summary).font(.system(size: 14)).foregroundStyle(card.isRisk ? AppColors.Health.risk : AppColors.Health.muted)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.Health.card).clipShape(RoundedRectangle(cornerRadius: 8))
        .clipped()
    }

    private func closeEditor() { screenState.page = .main; isFullscreen = false }
    private func saveCards(_ value: [HealthCard]) {
        viewModel.saveCardConfiguration(value.map { $0.id })
        viewModel.load(); closeEditor()
    }
}

private struct HealthCardVisualContent: View {
    let cardType: String
    let visual: HealthCardVisualData

    private var contentMinimumHeight: CGFloat {
        switch visual.kind.name {
        case "TodayActivity": 58; case "WeeklyPlan": 110; case "TrainingLoad": 60
        case "TrainingAssessment": 130; case "RecoveryGauge", "AbilityGauge": 78
        case "TrendBars", "RangeIndicator", "SleepStages": 60; case "HealthCheckGrid": 114
        case "BodyMap": 121; default: 0
        }
    }

    var body: some View {
        Group {
            switch visual.kind.name {
            case "TodayActivity": ActivityView(visual: visual)
            case "WeeklyPlan": WeeklyPlanView(visual: visual)
            case "TrainingLoad": TrainingLoadView(visual: visual)
            case "TrainingAssessment": TrainingAssessmentView(visual: visual)
            case "RecoveryGauge", "AbilityGauge": GaugeView(cardType: cardType, visual: visual)
            case "TrendBars": TrendView(cardType: cardType, visual: visual)
            case "RangeIndicator": RangeView(cardType: cardType, visual: visual)
            case "SleepStages": SleepView(visual: visual)
            case "HealthCheckGrid": HealthGridView(visual: visual)
            case "BodyMap": BodyView(visual: visual)
            default: EmptyView()
            }
        }
        .frame(minHeight: contentMinimumHeight, alignment: .topLeading)
    }
}

#Preview {
    HealthDashboardView(isFullscreen: .constant(false), onWatchTap: {})
        .environmentObject(AppLanguageStore.shared)
}
