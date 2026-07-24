import SwiftUI
import Shared
import Lottie
import UIKit

struct HealthDashboardView: View {
    @Binding var isFullscreen: Bool
    let onWatchTap: () -> Void
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var editing = false
    @State private var detail: HealthCard?
    @State private var showScenarioPicker = false
    @State private var dragOffset: CGFloat = 0
    var body: some View {
        Group {
            if editing {
                HealthCardEditor(initial: viewModel.cards, onClose: closeEditor, onSave: saveCards)
            } else if let detail {
                HealthDetailView(card: detail) { self.detail = nil; isFullscreen = false }
            } else {
                dashboard
            }
        }
        .onChange(of: languageStore.current) { _, _ in detail = nil; isFullscreen = false; viewModel.load() }
        .background(AppColors.Core.black)
        .sheet(isPresented: $showScenarioPicker) { ScenarioPickerView(viewModel: viewModel) }
    }

    private var dashboard: some View {
        VStack(spacing: 0) {
            HeroTopRow(dateLabel: viewModel.dateLabel, isSyncing: viewModel.isLoading,
                       syncCycle: viewModel.syncCycle,
                       onTapWatch: onWatchTap,
                       onLongPressWatch: { showScenarioPicker = true })
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
                                    detail = card; isFullscreen = true
                                } label: {
                                    cardRow(card)
                                }.buttonStyle(.plain)
                                    .padding(.horizontal, AppSpacing.screen)
                                    .padding(.vertical, AppSpacing.xSmall)
                            }

                            Button {
                                editing = true; isFullscreen = true
                            } label: {
                                Text(appLocalized("health_edit_cards"))
                                    .font(.system(size: AppTypography.label))
                                    .foregroundStyle(AppColors.Health.editText)
                                    .padding(.horizontal, AppSpacing.actionHorizontal).padding(.vertical, AppSpacing.medium)
                                    .background(AppColors.Health.card).clipShape(Capsule())
                            }.buttonStyle(.plain).padding(AppSpacing.large)
                        }
                    }
                    .offset(y: max(0, dragOffset))
                    .background(
                        ScrollViewPanObserver(
                            isRefreshing: viewModel.isLoading,
                            onPullChanged: { distance in
                                guard !viewModel.isLoading else { return }
                                dragOffset = min(distance * 0.4, 250)
                            },
                            onPullEnded: { distance, gestureBeganAtTop in
                                let shouldRefresh = gestureBeganAtTop && distance >= 64 && !viewModel.isLoading
                                if shouldRefresh {
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 55 }
                                    Task { await viewModel.refresh() }
                                } else {
                                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 0 }
                                }
                            }
                        )
                    )
                }
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.isLoading) { _, loading in
                    if !loading {
                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 0 }
                    }
                }

                if dragOffset > 10 || viewModel.isLoading {
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

    private func closeEditor() { editing = false; isFullscreen = false }
    private func saveCards(_ value: [HealthCard]) {
        viewModel.saveCardConfiguration(value.map { $0.id })
        viewModel.load(); closeEditor()
    }
}

private struct ScrollViewPanObserver: UIViewRepresentable {
    let isRefreshing: Bool
    let onPullChanged: (CGFloat) -> Void
    let onPullEnded: (CGFloat, Bool) -> Void

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        configure(view)
        return view
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        configure(uiView)
        uiView.attachToEnclosingScrollViewIfNeeded()
    }

    private func configure(_ view: ObserverView) {
        view.isRefreshing = isRefreshing
        view.onPullChanged = onPullChanged
        view.onPullEnded = onPullEnded
    }

    final class ObserverView: UIView {
        weak var observedScrollView: UIScrollView?
        var isRefreshing = false
        var onPullChanged: ((CGFloat) -> Void)?
        var onPullEnded: ((CGFloat, Bool) -> Void)?
        private var gestureBeganAtTop = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                self?.attachToEnclosingScrollViewIfNeeded()
            }
        }

        func attachToEnclosingScrollViewIfNeeded() {
            guard observedScrollView == nil else { return }
            var ancestor = superview
            while let view = ancestor {
                if let scrollView = view as? UIScrollView {
                    observedScrollView = scrollView
                    scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
                    return
                }
                ancestor = view.superview
            }
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let scrollView = observedScrollView else { return }
            switch recognizer.state {
            case .began:
                gestureBeganAtTop = !isRefreshing &&
                    scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + 1
            case .changed:
                guard gestureBeganAtTop else { return }
                onPullChanged?(max(0, recognizer.translation(in: scrollView).y))
            case .ended:
                let distance = max(0, recognizer.translation(in: scrollView).y)
                onPullEnded?(distance, gestureBeganAtTop)
                gestureBeganAtTop = false
            case .cancelled, .failed:
                onPullEnded?(0, false)
                gestureBeganAtTop = false
            default:
                break
            }
        }

        deinit {
            observedScrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handlePan(_:)))
        }
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
