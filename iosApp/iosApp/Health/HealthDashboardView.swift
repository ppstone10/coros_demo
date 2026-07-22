import SwiftUI
import Shared
import Lottie
import UIKit

struct HealthDashboardView: View {
    @Binding var isFullscreen: Bool
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
        VStack(alignment: .leading, spacing: card.isEmpty ? 12 : 8) {
            HStack(spacing: 5) {
                Image(card.id == "TodayActivity" ? AppImages.Health.todayHeader : card.icon).resizable().scaledToFit().frame(width: 20, height: 20)
                Text(card.title).font(.system(size: 16, weight: .medium)).foregroundStyle(AppColors.Health.cardTitle).lineLimit(1)
                Spacer(minLength: 0)
            }
            if card.isEmpty {
                Text(card.summary).font(.system(size: 14)).foregroundStyle(AppColors.Health.muted)
            } else if let visual = card.visual {
                HealthVisualCardContent(visual: visual)
            } else {
                Text(card.summary).font(.system(size: 14)).foregroundStyle(card.isRisk ? AppColors.Health.risk : AppColors.Health.muted)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: cardMinimumHeight(card), alignment: .leading)
        .background(AppColors.Health.card).clipShape(RoundedRectangle(cornerRadius: 8))
        .clipped()
    }

    private func cardMinimumHeight(_ card: HealthCard) -> CGFloat {
        card.isEmpty ? 82 : figmaCardHeight(card.visual)
    }

    private func figmaCardHeight(_ visual: HealthCardVisualData?) -> CGFloat {
        switch visual?.kind.name {
        case "TodayActivity": 114
        case "WeeklyPlan": 178
        case "TrainingAssessment": 206
        case "HealthCheckGrid": 180
        case "BodyMap": 188
        default: 122
        }
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

private struct HealthVisualCardContent: View {
    let visual: HealthCardVisualData
    private let green = AppColors.Health.visualGreen
    private var points: [HealthChartPoint] { visual.chartPoints }

    @ViewBuilder var body: some View {
        switch visual.kind.name {
        case "TodayActivity": activity
        case "WeeklyPlan": weekly
        case "TrainingLoad": load
        case "TrainingAssessment": assessment
        case "RecoveryGauge", "AbilityGauge": gauge
        case "TrendBars": trend
        case "RangeIndicator": range
        case "SleepStages": sleep
        case "HealthCheckGrid": healthGrid
        case "BodyMap": bodyMap
        default: EmptyView()
        }
    }

    private var activity: some View {
        HStack(spacing: 12) {
            Image(AppImages.Health.activityMap).resizable().scaledToFill().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 3) { value(visual.primaryValue, 24); unit(visual.primaryUnit, size: 16) }
                HStack(spacing: 3) {
                    if let d = visual.detail { Text(localizedHealthText(d)) }
                    if let c = visual.caption { Text(localizedHealthText(c)) }
                }.font(.system(size: 12)).foregroundStyle(AppColors.Health.muted).lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(AppImages.Health.todayRunner).resizable().scaledToFit().frame(width: 24, height: 24)
        }
    }

    private var weekly: some View {
        VStack(spacing: 8) {
            HStack { ForEach(Array(points.prefix(7).enumerated()), id: \.offset) { index, point in Text(appLocalized(point.label)).font(.system(size: 14)).foregroundStyle(index == visual.highlightedIndex?.intValue ? .white : AppColors.Health.muted).frame(width: 28, height: 28).background(index == visual.highlightedIndex?.intValue ? AppColors.Health.action : .clear).clipShape(Circle()); if index < 6 { Spacer() } } }
            HStack(spacing: 8) {
                Image(AppImages.Health.todayRunner).resizable().scaledToFit().frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 2) {
                    if let c = visual.caption { Text(localizedHealthText(c)).font(.system(size: 14)).foregroundStyle(.white).lineLimit(1) }
                    HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 12); unit(visual.primaryUnit, size: 12) }
                }
                Spacer(); bars.frame(width: 80, height: 36)
            }.padding(.horizontal, 16).frame(height: 64).background(AppColors.Health.activityTile).clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var load: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) { value(visual.primaryValue, 32); caption(visual.caption, size: 12) }.frame(width: 141, alignment: .leading)
            Spacer(); bars(forceColor: AppColors.Health.visualCyan).frame(width: 130, height: 54).clipped()
        }
    }

    private var assessment: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let c = visual.caption { Text(localizedHealthText(c)).font(.system(size: 20, weight: .semibold)).foregroundStyle(AppColors.Health.visualOrange) }
            caption(visual.detail, size: 14).lineSpacing(2)
            Spacer(minLength: 4)
            HStack { ForEach(Array(visual.metrics.prefix(3).enumerated()), id: \.offset) { index, m in metric(m, accent: .white, valueSize: 30); if index < 2 { Spacer(); Divider().background(AppColors.Health.divider).frame(height: 42); Spacer() } } }
        }
    }

    private var gauge: some View {
        HStack {
            VStack(alignment: .leading) { HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20) }; caption(visual.detail, size: 12) }.frame(width: 141, alignment: .leading)
            Spacer(minLength: 8)
            ZStack {
                Circle().trim(from: 0.5, to: 1).stroke(AppColors.Health.gaugeTrack, style: StrokeStyle(lineWidth: 4, lineCap: .butt)).rotationEffect(.degrees(0))
                Circle().trim(from: 0.5, to: 0.5 + 0.5 * (visual.progress?.doubleValue ?? 0)).stroke(AppColors.Health.visualCyan, style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                VStack { Spacer(); caption(visual.caption, size: 12) }
            }.frame(width: 114, height: 72).clipped()
        }
    }

    private var trend: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) { HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20) }; caption(visual.caption, size: 12) }.frame(width: 141)
            Spacer(); bars.frame(width: 166, height: 56).clipped()
        }
    }

    private var range: some View {
        HStack {
            VStack(alignment: .leading) { HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20) }; caption(visual.detail, size: 12) }.frame(width: 141, alignment: .leading)
            Spacer()
            VStack(spacing: 4) { caption(visual.caption, size: 12)
              GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.Health.rangeTrack).frame(height: 5)
                    Capsule().fill(green).frame(width: geo.size.width * 0.35, height: 5).offset(x: geo.size.width * 0.35)
                    Circle().fill(.white).frame(width: 12, height: 12).offset(x: geo.size.width * rangeFraction - 6)
                }
              }.frame(height: 14)
            }.frame(width: 130)
        }
    }

    private var rangeFraction: CGFloat {
        guard let r = visual.range else { return 0.5 }
        return CGFloat(max(0, min(1, (r.current - r.minimum) / max(1, r.maximum - r.minimum))))
    }

    private var sleep: some View {
        HStack {
            VStack(alignment: .leading) { HStack(alignment: .lastTextBaseline, spacing: 3) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20); value(visual.secondaryValue, 32); unit(visual.secondaryUnit, size: 20) }; Text("\(visual.startTime ?? "--") – \(visual.endTime ?? "--")").font(.system(size: 12)).foregroundStyle(AppColors.Health.muted) }.frame(width: 141, alignment: .leading)
            Spacer()
            HStack(alignment: .top, spacing: 2) {
                ForEach(Array(visual.sleepStages.enumerated()), id: \.offset) { _, s in
                    RoundedRectangle(cornerRadius: 2).fill(stageColor(s.stage.name)).frame(height: 7).offset(y: stageOffset(s.stage.name)).layoutPriority(Double(s.durationMinutes))
                }
            }.frame(width: 130, height: 56, alignment: .top).clipped()
        }
    }

    private var healthGrid: some View {
        VStack(alignment: .leading, spacing: 7) {
            caption(visual.caption)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3), spacing: 8) {
                ForEach(Array(visual.metrics.enumerated()), id: \.offset) { _, m in metric(m, accent: .white) }
            }
        }
    }

    private var bodyMap: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { caption(visual.caption, size: 14); HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20) }; caption(visual.detail, size: 12) }.frame(width: 141, alignment: .leading)
            Spacer()
            VStack(spacing: 0) { HStack(spacing: 4) { Image(AppImages.Health.bodyFront).resizable().scaledToFit().frame(width: 52, height: 108); Image(AppImages.Health.bodyBack).resizable().scaledToFit().frame(width: 52, height: 108) }; HStack(spacing: 3) { ForEach(Array(visual.metrics.prefix(2).enumerated()), id: \.offset) { index, m in if index > 0 { Text("·") }; Text(localizedHealthText(m.label)) } }.font(.system(size: 11)).foregroundStyle(AppColors.Health.muted).lineLimit(1) }.frame(width: 142).clipped()
        }
    }

    private var bars: some View { bars(forceColor: nil) }

    private func bars(forceColor: Color?) -> some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 5) {
                let high = max(1, points.map(\.value).max() ?? 1)
                ForEach(Array(points.enumerated()), id: \.offset) { index, p in
                    Capsule().fill(forceColor ?? (index == visual.highlightedIndex?.intValue ? green : barColor(p.level.name)))
                        .frame(height: max(2, geo.size.height * p.value / high))
                }
            }
        }
    }

    private func value(_ text: String?, _ size: CGFloat) -> some View { Text(text ?? "--").font(.custom("COROS-APP-Bold", size: size)).foregroundStyle(.white).lineLimit(1) }
    @ViewBuilder private func unit(_ spec: LocalizedTextSpec?, size: CGFloat = 16) -> some View { if let spec { Text(localizedHealthText(spec)).font(.custom("COROS-APP-Bold", size: size)).foregroundStyle(AppColors.Health.metricUnit).lineLimit(1) } }
    @ViewBuilder private func caption(_ spec: LocalizedTextSpec?, size: CGFloat = 12) -> some View { if let spec { Text(localizedHealthText(spec)).font(.system(size: size)).foregroundStyle(AppColors.Health.muted).lineLimit(2) } }
    private func metric(_ m: HealthMetric, accent: Color, valueSize: CGFloat = 30) -> some View { VStack(alignment: .leading, spacing: 1) { HStack(alignment: .lastTextBaseline, spacing: 2) { Text(m.value).font(.custom("COROS-APP-Bold", size: valueSize)).foregroundStyle(accent); unit(m.unit) }; Text(localizedHealthText(m.label)).font(.system(size: 12)).foregroundStyle(AppColors.Health.muted) } }
    private func stageOffset(_ name: String) -> CGFloat { name == "Awake" ? 0 : name == "Rem" ? 16 : name == "Deep" ? 48 : 32 }
    private func stageColor(_ name: String) -> Color { name == "Awake" ? AppColors.Health.visualOrange : name == "Rem" ? AppColors.Health.visualPurple : name == "Deep" ? AppColors.Health.visualDeepBlue : AppColors.Health.visualBlue }
    private func barColor(_ name: String) -> Color { name == "High" ? AppColors.Health.warning : name == "Elevated" ? AppColors.Health.visualOrange : name == "Good" ? AppColors.Health.visualYellow : AppColors.Health.visualBar }
}

#Preview {
    HealthDashboardView(isFullscreen: .constant(false))
        .environmentObject(AppLanguageStore.shared)
}
