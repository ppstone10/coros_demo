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
    @State private var selectedWeeklyDays: [String: Int] = [:]

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
                HealthCardVisualContent(
                    cardType: card.id,
                    visual: visual,
                    selectedWeeklyDay: selectedWeeklyDays[card.id],
                    onWeeklyDaySelected: { selectedWeeklyDays[card.id] = $0 }
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
    let selectedWeeklyDay: Int?
    let onWeeklyDaySelected: (Int) -> Void
    private let green = AppColors.Health.visualGreen
    private var points: [HealthChartPoint] { visual.chartPoints }
    private var contentMinimumHeight: CGFloat {
        switch visual.kind.name {
        case "TodayActivity": 58
        case "WeeklyPlan": 110
        case "TrainingLoad": 60
        case "TrainingAssessment": 130
        case "RecoveryGauge", "AbilityGauge": 78
        case "TrendBars", "RangeIndicator", "SleepStages": 60
        case "HealthCheckGrid": 114
        case "BodyMap": 121
        default: 0
        }
    }

    @ViewBuilder var body: some View {
        Group {
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
        .frame(minHeight: contentMinimumHeight, alignment: .topLeading)
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
        }.padding(.top, 10)
    }

    private var weekly: some View {
        let selectedIndex = selectedWeeklyDay ?? visual.highlightedIndex?.intValue ?? 0
        let plan = visual.weeklyDayPlans.first { Int($0.dayIndex) == selectedIndex }
        return VStack(spacing: 8) {
            HStack {
                ForEach(Array(points.prefix(7).enumerated()), id: \.offset) { index, point in
                    Button {
                        onWeeklyDaySelected(index)
                    } label: {
                        Text(appLocalized(point.label))
                            .font(.system(size: 14))
                            .foregroundStyle(index == selectedIndex ? .white : AppColors.Health.muted)
                            .frame(width: 28, height: 28)
                            .background(index == selectedIndex ? AppColors.Health.action : .clear)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    if index < 6 { Spacer() }
                }
            }
            HStack(spacing: 8) {
                Image(AppImages.Health.todayRunner).resizable().scaledToFit().frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan?.workoutName.map(localizedHealthText) ?? appLocalized("health_visual_weekly_rest_day"))
                        .font(.system(size: 14)).foregroundStyle(.white).lineLimit(1)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        value(plan?.workoutDurationMinutes?.stringValue, 12)
                        if plan?.workoutDurationMinutes != nil {
                            Text(appLocalized("health_unit_minutes_long"))
                                .font(.custom("COROS-APP-Bold", size: 12))
                                .foregroundStyle(AppColors.Health.muted)
                        }
                        if let load = plan?.workoutTrainingLoad {
                            Text("  \(load.intValue) \(appLocalized("health_visual_training_load_short"))")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.Health.muted)
                        }
                    }
                }
                Spacer()
                bars(forceColor: nil, highlightedIndex: selectedIndex)
                    .frame(width: 80, height: 36)
            }.padding(.horizontal, 16).frame(height: 64).background(AppColors.Health.activityTile).clipShape(RoundedRectangle(cornerRadius: 6))
        }.padding(.top, 8)
    }

    private var load: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                value(visual.primaryValue, 32)
                caption(visual.caption, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer()
            LoadOverview(visual: visual)
        }
        .frame(minHeight: 60)
    }

    private var assessment: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let c = visual.caption { Text(localizedHealthText(c)).font(.system(size: 20, weight: .semibold)).foregroundStyle(AppColors.Health.visualOrange) }
            caption(visual.detail, size: 14)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 0) {
                ForEach(Array(visual.metrics.prefix(3).enumerated()), id: \.offset) { index, item in
                    metric(item, accent: .white, valueSize: 30)
                        .frame(width: 82, alignment: .leading)
                    if index < 2 {
                        Spacer(minLength: 0)
                        Divider().background(AppColors.Health.divider).frame(width: 1, height: 42)
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .padding(.top, 8)
        .frame(minHeight: 130, alignment: .topLeading)
    }

    private var gauge: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20) }
                caption(visual.caption, size: 12)
                caption(visual.detail, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 78, alignment: .leading)
            Spacer(minLength: 8)
            GaugeOverview(cardType: cardType, visual: visual)
        }
        .frame(minHeight: 78)
    }

    private var trend: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    value(visual.primaryValue, 32)
                    unit(visual.primaryUnit, size: 20)
                }
                caption(visual.caption, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer()
            if cardType == "HeartRate" {
                HeartRateIntervalOverview(points: points)
                    .frame(width: 166, height: 44)
                    .clipped()
            } else {
                StressOverview(points: points)
                    .frame(width: 166, height: 56)
                    .clipped()
            }
        }
        .frame(minHeight: 60)
    }

    private var range: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    value(visual.primaryValue, 32)
                    unit(visual.primaryUnit, size: 20)
                }
                caption(cardType == "RestingHeartRate" ? visual.caption : visual.detail, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer()
            RangeIndicatorOverview(cardType: cardType, visual: visual)
                .frame(width: 130)
        }
        .frame(minHeight: 60)
    }

    private var sleep: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    value(visual.primaryValue, 32)
                    unit(visual.primaryUnit, size: 20)
                    value(visual.secondaryValue, 32)
                    unit(visual.secondaryUnit, size: 20)
                }
                Text("\(visual.startTime ?? "--") – \(visual.endTime ?? "--")")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.Health.muted)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer()
            SleepStageOverview(stages: visual.sleepStages)
                .frame(width: 130, height: 56)
                .clipped()
        }
        .frame(minHeight: 60)
    }

    private var healthGrid: some View {
        VStack(alignment: .leading, spacing: 7) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3), spacing: 8) {
                ForEach(Array(visual.metrics.enumerated()), id: \.offset) { _, m in metric(m, accent: .white) }
            }
        }.padding(.top, 8)
    }

    private var bodyMap: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) { caption(visual.caption, size: 14); HStack(alignment: .lastTextBaseline, spacing: 2) { value(visual.primaryValue, 32); unit(visual.primaryUnit, size: 20) }; caption(visual.detail, size: 12) }.frame(width: 141, alignment: .leading).padding(.top, 8)
            Spacer()
            VStack(spacing: 0) { HStack(spacing: 4) { Image(AppImages.Health.bodyFront).resizable().scaledToFit().frame(width: 52, height: 108); Image(AppImages.Health.bodyBack).resizable().scaledToFit().frame(width: 52, height: 108) }; HStack(spacing: 3) { ForEach(Array(visual.metrics.prefix(2).enumerated()), id: \.offset) { index, m in if index > 0 { Text("·") }; Text(localizedHealthText(m.label)) } }.font(.system(size: 11)).foregroundStyle(AppColors.Health.muted).lineLimit(1) }.frame(width: 142).clipped()
        }
    }

    private var bars: some View { bars(forceColor: nil) }

    private func bars(forceColor: Color?) -> some View {
        bars(forceColor: forceColor, highlightedIndex: visual.highlightedIndex?.intValue, dense: false)
    }

    private func bars(forceColor: Color?, highlightedIndex: Int?) -> some View {
        bars(forceColor: forceColor, highlightedIndex: highlightedIndex, dense: true)
    }

    private func bars(forceColor: Color?, highlightedIndex: Int?, dense: Bool) -> some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: dense ? 2 : 5) {
                let high = max(1, points.map(\.value).max() ?? 1)
                ForEach(Array(points.enumerated()), id: \.offset) { index, p in
                    Capsule().fill(forceColor ?? (index == highlightedIndex ? AppColors.Health.visualCyan : barColor(p.level.name)))
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
    HealthDashboardView(isFullscreen: .constant(false), onWatchTap: {})
        .environmentObject(AppLanguageStore.shared)
}

private struct RangeIndicatorOverview: View {
    let cardType: String
    let visual: HealthCardVisualData

    private var fraction: CGFloat {
        guard let range = visual.range else { return 0.5 }
        return CGFloat(max(0, min(1, (range.current - range.minimum) / max(1, range.maximum - range.minimum))))
    }

    private var headerText: String? {
        if cardType == "RestingHeartRate" {
            return visual.detail.map(localizedHealthText)
        }
        guard
            let range = visual.range,
            let normalMin = range.normalMin?.intValue,
            let normalMax = range.normalMax?.intValue
        else { return nil }
        let unit = visual.primaryUnit.map(localizedHealthText) ?? ""
        return String(
            format: appLocalized("health_visual_normal_range_short"),
            "\(normalMin)", "\(normalMax)", unit
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            if let headerText {
                Text(headerText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.Health.muted)
                    .lineLimit(1)
            }
            GeometryReader { geometry in
                let markerX = max(4, min(geometry.size.width - 4, geometry.size.width * fraction))
                ZStack(alignment: .topLeading) {
                    if cardType == "HrvAssessment" {
                        HStack(spacing: 0) {
                            Rectangle().fill(AppColors.Health.warning).frame(width: geometry.size.width * 0.18)
                            Rectangle().fill(AppColors.Health.visualYellow).frame(width: geometry.size.width * 0.20)
                            Rectangle().fill(AppColors.Health.visualGreen).frame(width: geometry.size.width * 0.38)
                            Rectangle().fill(AppColors.Health.visualOrange)
                        }
                        .frame(height: 4)
                        .clipShape(Capsule())
                    } else {
                        Capsule().fill(AppColors.Health.visualPink).frame(height: 4)
                    }
                    Path { path in
                        path.move(to: CGPoint(x: markerX, y: 7))
                        path.addLine(to: CGPoint(x: markerX - 4, y: 14))
                        path.addLine(to: CGPoint(x: markerX + 4, y: 14))
                        path.closeSubpath()
                    }
                    .fill(.white)
                }
            }
            .frame(height: 14)
            if cardType == "HrvAssessment", let caption = visual.caption {
                HStack(spacing: 4) {
                    Circle().fill(AppColors.Health.visualGreen).frame(width: 5, height: 5)
                    Text(localizedHealthText(caption))
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.Health.muted)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct HeartRateIntervalOverview: View {
    let points: [HealthChartPoint]

    var body: some View {
        Canvas { context, size in
            guard !points.isEmpty else { return }
            let chartMinimum = points.map { $0.minimum?.doubleValue ?? $0.value }.min() ?? 0
            let chartMaximum = points.map { $0.maximum?.doubleValue ?? $0.value }.max() ?? 1
            let span = max(1, chartMaximum - chartMinimum)
            let verticalPadding: CGFloat = 3
            let drawableHeight = max(1, size.height - verticalPadding * 2)
            let denominator = max(1, points.count - 1)

            for (index, point) in points.enumerated() {
                let minimum = point.minimum?.doubleValue ?? point.value
                let maximum = point.maximum?.doubleValue ?? point.value
                let x = CGFloat(index) / CGFloat(denominator) * size.width
                let highY = verticalPadding + drawableHeight * CGFloat(1 - (maximum - chartMinimum) / span)
                let lowY = max(
                    highY + 1,
                    verticalPadding + drawableHeight * CGFloat(1 - (minimum - chartMinimum) / span)
                )
                var path = Path()
                path.move(to: CGPoint(x: x, y: highY))
                path.addLine(to: CGPoint(x: x, y: lowY))
                context.stroke(path, with: .color(AppColors.Health.visualPink), lineWidth: 1)
            }
        }
    }
}

private struct LoadOverview: View {
    let visual: HealthCardVisualData

    var body: some View {
        VStack(spacing: 4) {
            Canvas { context, size in
                let points = visual.chartPoints
                guard !points.isEmpty else { return }
                let high = max(1, points.map(\.value).max() ?? 1)
                let gap: CGFloat = 5
                let barWidth = max(1, (size.width - gap * CGFloat(points.count - 1)) / CGFloat(points.count))
                for (index, point) in points.enumerated() {
                    let x = CGFloat(index) * (barWidth + gap)
                    let radius = min(barWidth / 2, 2)
                    context.fill(
                        Path(roundedRect: CGRect(x: x, y: 0, width: barWidth, height: size.height), cornerRadius: radius),
                        with: .color(AppColors.Health.gaugeTrack)
                    )
                    let height = point.value <= 0
                        ? CGFloat(2)
                        : max(3, size.height * CGFloat(point.value / high))
                    context.fill(
                        Path(roundedRect: CGRect(x: x, y: size.height - height, width: barWidth, height: height), cornerRadius: radius),
                        with: .color(AppColors.Health.visualCyan)
                    )
                }
            }
            .frame(height: 36)

            HStack {
                ForEach(Array(visual.chartPoints.prefix(7).enumerated()), id: \.offset) { index, point in
                    Text(appLocalized(point.label))
                        .font(.system(size: 9))
                        .foregroundStyle(index == visual.highlightedIndex?.intValue ? .white : AppColors.Health.muted)
                    if index < min(6, visual.chartPoints.count - 1) {
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(width: 130)
    }
}

private struct StressOverview: View {
    let points: [HealthChartPoint]

    var body: some View {
        Canvas { context, size in
            guard !points.isEmpty else { return }
            let values = points.map(\.value)
            let high = max(100, values.max() ?? 100)
            let step: CGFloat = 2
            let count = max(2, Int(size.width / step))
            for index in 0..<count {
                let chartPosition = Double(index) / Double(count - 1) * Double(values.count - 1)
                let leftIndex = min(values.count - 1, max(0, Int(chartPosition)))
                let rightIndex = min(values.count - 1, leftIndex + 1)
                let fraction = chartPosition - Double(leftIndex)
                let interpolated = values[leftIndex] + (values[rightIndex] - values[leftIndex]) * fraction
                let height = max(2, size.height * CGFloat(interpolated / high))
                let color: Color = interpolated >= 80
                    ? AppColors.Health.visualOrange
                    : interpolated >= 60
                        ? AppColors.Health.visualYellow
                        : interpolated >= 35
                            ? AppColors.Health.stressGood
                            : AppColors.Health.stressLow
                var path = Path()
                let x = CGFloat(index) * step
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x, y: size.height - height))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }
        }
    }
}

private struct SleepStageOverview: View {
    let stages: [SleepStageSegment]

    var body: some View {
        Canvas { context, size in
            let total = max(1, stages.map { Int($0.startMinute + $0.durationMinutes) }.max() ?? 1)
            for stage in stages {
                let start = Int(stage.startMinute)
                let duration = Int(stage.durationMinutes)
                let x = size.width * CGFloat(start) / CGFloat(total)
                let width = max(2, size.width * CGFloat(duration) / CGFloat(total) - 2)
                let name = stage.stage.name
                let y: CGFloat = name == "Awake" ? 0 : name == "Rem" ? 16 : name == "Deep" ? 48 : 32
                let color: Color = name == "Awake"
                    ? AppColors.Health.visualYellow
                    : name == "Rem"
                        ? AppColors.Health.visualCyan
                        : name == "Deep"
                            ? AppColors.Health.visualDeepBlue
                            : AppColors.Health.visualBlue
                context.fill(
                    Path(roundedRect: CGRect(x: x, y: y, width: width, height: 7), cornerRadius: 2),
                    with: .color(color)
                )
            }
        }
    }
}

private struct RecoveryGaugeOverview: View {
    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            Canvas { context, _ in
                let center = CGPoint(x: 57, y: 55)
                let radius: CGFloat = 52
                var track = Path()
                track.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360),
                    clockwise: false
                )
                context.stroke(track, with: .color(AppColors.Health.gaugeTrack), style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                if progress > 0 {
                    var active = Path()
                    active.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(180 + 180 * Double(progress)),
                        clockwise: false
                    )
                    context.stroke(active, with: .color(AppColors.Health.visualCyan), style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                }
            }
            .frame(width: 114, height: 58)

            Image(AppImages.Health.recoveryStatus)
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 30)
                .padding(.top, 20)

            Text(appLocalized(progress >= 0.7 ? "health_visual_recovery_ready" : "health_visual_recovery_low"))
                .font(.system(size: 11))
                .foregroundStyle(AppColors.Health.cardTitle)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: 114, height: 78)
    }
}

private struct GaugeOverview: View {
    let cardType: String
    let visual: HealthCardVisualData

    private var progress: CGFloat {
        CGFloat(max(0, min(1, visual.progress?.doubleValue ?? 0)))
    }

    private var accent: Color {
        cardType == "RunningAbility"
            ? AppColors.Health.visualOrange
            : cardType == "CyclingAbility"
                ? AppColors.Health.visualGreen
                : AppColors.Health.visualCyan
    }

    @ViewBuilder var body: some View {
        if cardType == "Recovery" {
            RecoveryGaugeOverview(progress: progress)
        } else {
            VStack(spacing: 0) {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height - 5)
                    let radius = (size.width - 10) * 0.42
                    let segments = 30
                    for index in 0..<segments {
                        let start = 180 + Double(index) * 180 / Double(segments)
                        let end = start + 180 / Double(segments) * 0.68
                        var path = Path()
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(start),
                            endAngle: .degrees(end),
                            clockwise: false
                        )
                        let filled = (Double(index) + 0.5) / Double(segments) <= Double(progress)
                        context.stroke(
                            path,
                            with: .color(filled ? accent : AppColors.Health.gaugeTrack),
                            lineWidth: 3
                        )
                    }
                    let angle = Double.pi + Double(progress) * Double.pi
                    var needle = Path()
                    needle.move(to: center)
                    needle.addLine(to: CGPoint(
                        x: center.x + cos(angle) * radius * 0.78,
                        y: center.y + sin(angle) * radius * 0.78
                    ))
                    context.stroke(needle, with: .color(AppColors.Health.cardTitle), lineWidth: 1.5)
                    context.fill(
                        Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)),
                        with: .color(AppColors.Health.cardTitle)
                    )
                }
                .frame(width: 121, height: 60)
                HStack {
                    Text("0")
                    Spacer()
                    Text("100")
                }
                .font(.system(size: 10))
                .foregroundStyle(AppColors.Health.muted)
            }
            .frame(width: 121, height: 71)
        }
    }
}
