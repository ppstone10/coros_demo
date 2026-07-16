import SwiftUI
import Combine
import UIKit
import Shared
import Lottie

struct HealthCard: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let isRisk: Bool
}

let defaultHealthCards: [HealthCard] = [
    HealthCard(id: "WeeklyPlan", title: "本周计划", summary: "本周无计划", icon: AppImages.Health.weeklyPlan, isRisk: false),
    HealthCard(id: "TrainingLoad", title: "本周负荷", summary: "本周负荷 526，建议范围 300-700", icon: AppImages.Health.trainingLoad, isRisk: false),
    HealthCard(id: "TrainingAssessment", title: "训练量评估", summary: "将在第一次运动后 7 天评估您的训练量", icon: AppImages.Health.trainingAssessment, isRisk: false),
    HealthCard(id: "Recovery", title: "体力恢复", summary: "恢复评分 78，预计 14 小时后恢复", icon: AppImages.Health.recovery, isRisk: false),
    HealthCard(id: "RunningAbility", title: "跑步能力", summary: "记录一笔 25min 以上的户外跑步运动", icon: AppImages.Health.runningAbility, isRisk: false),
    HealthCard(id: "CyclingAbility", title: "骑行FTP", summary: "连接功率计，完成一次 20min 以上稳定骑行", icon: AppImages.Health.cyclingAbility, isRisk: false),
    HealthCard(id: "HeartRate", title: "心率", summary: "佩戴手表记录心率数据", icon: AppImages.Health.heartRate, isRisk: false),
    HealthCard(id: "Stress", title: "压力", summary: "佩戴手表或进行健康快测获取压力", icon: AppImages.Health.stress, isRisk: false),
    HealthCard(id: "Sleep", title: "睡眠", summary: "昨夜睡眠 7小时18分，质量 86", icon: AppImages.Health.sleep, isRisk: false),
    HealthCard(id: "HrvAssessment", title: "HRV评估", summary: "睡觉时佩戴手表获取数据", icon: AppImages.Health.hrv, isRisk: false),
    HealthCard(id: "RestingHeartRate", title: "静息心率", summary: "睡觉时佩戴手表或进行静息心率测试", icon: AppImages.Health.restingHeartRate, isRisk: false),
    HealthCard(id: "HealthCheck", title: "健康快测", summary: "使用手表“健康快测”获取数据", icon: AppImages.Health.healthCheck, isRisk: false),
    HealthCard(id: "BodyManagement", title: "体型管理", summary: "体重 68.2 kg · 本周主要锻炼部位", icon: AppImages.Health.body, isRisk: false)
]

struct HealthDashboardView: View {
    @Binding var isFullscreen: Bool
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var editing = false
    @State private var detail: HealthCard?
    @State private var dragOffset: CGFloat = 0
    @State private var showScenarioPicker = false
    @State private var isAtScrollTop = true

    var body: some View {
        Group {
            if editing {
                HealthCardEditor(initial: viewModel.cards, onClose: closeEditor, onSave: saveCards)
            } else if let detail {
                HealthDetailView(card: detail) {
                    self.detail = nil
                    isFullscreen = false
                }
            } else {
                // Dashboard — 3 parts
                VStack(spacing: 0) {
                    // Part 1: Fixed top row
                    HeroTopRow(dateLabel: viewModel.dateLabel,
                               isSyncing: viewModel.isLoading,
                               onLongPressWatch: { showScenarioPicker = true })

                    // Part 2: Scrollable content
                    ZStack(alignment: .top) {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Track scroll offset to know when at top
                                GeometryReader { geo in
                                    Color.clear.preference(key: ScrollTopKey.self,
                                        value: geo.frame(in: .named("scrollSpace")).minY)
                                }
                                .frame(height: 0)

                                HeroArcView(steps: viewModel.steps,
                                            calories: viewModel.calories,
                                            minutes: viewModel.activeMinutes)
                                    .offset(y: max(0.0, dragOffset))

                                ForEach(viewModel.cards) { card in
                                    Button {
                                        detail = card
                                        isFullscreen = true
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(card.icon).resizable().scaledToFit().frame(width: 22, height: 22)
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(card.title).font(.system(size: 16, weight: .medium)).foregroundStyle(.white)
                                                Text(card.summary).font(.system(size: 12)).foregroundStyle(card.isRisk ? AppColors.Health.risk : AppColors.Health.muted).lineLimit(2)
                                            }
                                            Spacer(minLength: 8)
                                            Text("›").font(.system(size: 25, weight: .light)).foregroundStyle(Color.gray)
                                        }
                                        .padding(.horizontal, 15)
                                        .frame(maxWidth: .infinity, minHeight: 76)
                                        .background(AppColors.Health.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 5)
                                    .offset(y: max(0.0, dragOffset))
                                }

                                Button {
                                    editing = true
                                    isFullscreen = true
                                } label: {
                                    Text(AppText.Health.editCards)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(red: 221 / 255, green: 221 / 255, blue: 221 / 255))
                                        .padding(.horizontal, 28).padding(.vertical, 10)
                                        .background(AppColors.Health.card)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .padding(18)
                                .offset(y: max(0.0, dragOffset))
                            }
                        }
                        .coordinateSpace(name: "scrollSpace")
                        .scrollIndicators(.hidden)
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    let t = value.translation.height
                                    if isAtScrollTop && t > 0 && !viewModel.isLoading {
                                        dragOffset = min(t * 0.4, 250)
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.height > 80 && !viewModel.isLoading {
                                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 55 }
                                        Task { await viewModel.refresh() }
                                    } else {
                                        withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 0 }
                                    }
                                }
                        )
                        .onChange(of: viewModel.isLoading) { _, loading in
                            if !loading {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 0 }
                            }
                        }

                        // Refresh overlay
                        if dragOffset > 10 || viewModel.isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.Health.steps))
                                    .scaleEffect(0.8)
                                Text("数据同步中")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.Health.muted)
                            }
                            .padding(.top, 6)
                        }
                    }
                    .onPreferenceChange(ScrollTopKey.self) { topOffset in
                        isAtScrollTop = topOffset >= 0
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showScenarioPicker) {
            ScenarioPickerView(viewModel: viewModel)
        }
    }

    private func closeEditor() {
        editing = false
        isFullscreen = false
    }

    private func saveCards(_ value: [HealthCard]) {
        viewModel.saveCardConfiguration(value.map(\.id))
        viewModel.load()
        closeEditor()
    }
}

private struct ScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - HeroTopRow

private struct HeroTopRow: View {
    let dateLabel: String
    let isSyncing: Bool
    let onLongPressWatch: () -> Void

    @State private var lottieId = UUID()
    private var playback: LottiePlaybackMode {
        isSyncing ? .playing(.fromProgress(0, toProgress: 1, loopMode: LottieLoopMode.playOnce)) : .paused
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateLabel).font(.system(size: 11)).foregroundStyle(Color.gray)
                Text(AppText.Health.today).font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
            }
            Spacer()
            Image(AppImages.Health.calendar).resizable().scaledToFit().frame(width: 23, height: 23)
            Spacer().frame(width: 18)
            LottieView(animation: .named("watch_status"))
                .playbackMode(playback)
                .animationDidFinish { _ in lottieId = UUID() }
                .frame(width: 30, height: 30)
                .id(lottieId)
                .onLongPressGesture(perform: onLongPressWatch)
        }
        .padding(.horizontal, 20)
        .padding(.top, 54)
    }
}

// MARK: - HeroArcView

private struct HeroArcView: View {
    let steps: Int
    let calories: Int
    let minutes: Int

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.13, to: 0.87)
                .stroke(AppColors.Health.gauge, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(90))
                .frame(width: 125, height: 125)
            HStack {
                metricView(icon: AppImages.Health.steps, value: "\(steps)", unit: AppText.Health.steps, color: AppColors.Health.steps)
                Spacer()
                metricView(icon: AppImages.Health.calories, value: "\(calories)", unit: AppText.Health.calories, color: AppColors.Health.calories)
                Spacer()
                metricView(icon: AppImages.Health.active, value: "\(minutes)", unit: AppText.Health.minutes, color: AppColors.Health.active)
            }
        }
        .frame(height: 128)
        .padding(.horizontal, 20)
    }

    private func metricView(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(icon).resizable().renderingMode(.template).scaledToFit().foregroundStyle(color).frame(width: 22, height: 22)
            Text(value).font(.system(size: 28)).foregroundStyle(.white)
            Text(unit).font(.system(size: 11)).foregroundStyle(Color.gray)
        }
        .frame(width: 82)
    }
}

// MARK: - ScenarioPickerView

private struct ScenarioPickerView: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(Array(zip(viewModel.scenarioNames, viewModel.scenarioDisplayNames)), id: \.0) { name, display in
                Button(action: { viewModel.selectScenario(name); dismiss() }) {
                    HStack {
                        Text(display).foregroundColor(.white)
                        Spacer()
                        if viewModel.selectedScenario == name {
                            Image(systemName: "checkmark").foregroundColor(AppColors.Health.steps)
                        }
                    }
                }
                .listRowBackground(AppColors.Health.card)
            }
            .scrollContentBackground(.hidden).background(Color.black)
            .navigationTitle("选择数据场景")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}

// =========== CardEditor / ScrollViewAccessor / HealthDetailView — 原样保留 ===========

private struct HealthCardEditor: View {
    @State var active: [HealthCard]
    @State private var warning: String?
    @State private var draggingCardID: String?
    @State private var dragStartIndex: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var dragVisualOffset: CGFloat = 0
    @State private var dragScrollOffset: CGFloat = 0
    @State private var dragEdgeDirection = 0
    @State private var dragEdgeSpeed: CGFloat = 0
    @State private var editorScrollView: UIScrollView?
    private let editorRowHeight: CGFloat = 56
    private let dragScrollTicker = Timer.publish(every: 0.032, on: .main, in: .common).autoconnect()
    let onClose: () -> Void
    let onSave: ([HealthCard]) -> Void

    init(initial: [HealthCard], onClose: @escaping () -> Void, onSave: @escaping ([HealthCard]) -> Void) {
        _active = State(initialValue: initial)
        self.onClose = onClose
        self.onSave = onSave
    }

    private var inactive: [HealthCard] {
        let activeIDs = Set(active.map(\.id))
        return defaultHealthCards.filter { !activeIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Text(AppText.Common.back).font(.system(size: 38, weight: .light))
                }
                .frame(width: 64, alignment: .leading)
                Spacer()
                Text(AppText.Health.editCards).font(.system(size: 19, weight: .medium))
                Spacer()
                Button {
                    onSave(active)
                } label: {
                    Text(AppText.Common.save)
                        .font(.system(size: 14))
                        .frame(width: 64, height: 30)
                        .background(AppColors.Health.action)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 64)

            Text(AppText.Health.manageOrder).font(.system(size: 13)).foregroundStyle(AppColors.Health.muted)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 22).padding(.bottom, 10)
            if let warning {
                Text(warning).font(.system(size: 12)).foregroundStyle(Color.red).padding(.bottom, 8)
            }

            GeometryReader { geometry in
                List {
                    ForEach(active) { card in
                        editorRow(
                            card,
                            isAdd: false,
                            viewport: geometry.frame(in: .global)
                        ) {
                            remove(card)
                        }
                    }

                    if !inactive.isEmpty {
                        Section(AppText.Health.moreData) {
                            ForEach(inactive) { card in
                                editorRow(
                                    card,
                                    isAdd: true,
                                    viewport: geometry.frame(in: .global)
                                ) {
                                    active.append(card)
                                    warning = nil
                                }
                            }
                        }
                    }

                    Button(AppText.Health.restoreDefaults) {
                        active = defaultHealthCards
                        warning = nil
                    }
                    .foregroundStyle(AppColors.Health.action)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .background {
                    ScrollViewAccessor { scrollView in
                        if editorScrollView !== scrollView {
                            editorScrollView = scrollView
                        }
                    }
                }
                .onReceive(dragScrollTicker) { _ in autoScroll() }
            }
        }
        .background(Color.black)
        .onDisappear { endDrag() }
    }

    private func editorRow(
        _ card: HealthCard,
        isAdd: Bool,
        viewport: CGRect,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            if !isAdd {
                Text("⠿")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.Health.muted)
                    .frame(width: 18, height: 44)
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 2, coordinateSpace: .global)
                            .onChanged {
                                updateDrag(
                                    card,
                                    translation: $0.translation.height,
                                    locationY: $0.location.y,
                                    viewport: viewport
                                )
                            }
                            .onEnded { _ in endDrag() }
                    )
            }
            Image(card.icon).resizable().scaledToFit().frame(width: 22, height: 22)
            Text(card.title).font(.system(size: 15)).foregroundStyle(.white)
            Spacer()
            Button(action: action) {
                ZStack {
                    Circle().fill(isAdd ? AppColors.Health.addAction : Color(red: 239 / 255, green: 52 / 255, blue: 63 / 255))
                    Rectangle().fill(Color.white).frame(width: 16, height: 2)
                    if isAdd { Rectangle().fill(Color.white).frame(width: 2, height: 16) }
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
        }
        .frame(height: editorRowHeight)
        .contentShape(Rectangle())
        .offset(y: draggingCardID == card.id ? dragVisualOffset : 0)
        .scaleEffect(draggingCardID == card.id ? 1.015 : 1)
        .shadow(
            color: draggingCardID == card.id ? Color.black.opacity(0.55) : .clear,
            radius: 10,
            y: 4
        )
        .opacity(draggingCardID == card.id ? 0.94 : 1)
        .zIndex(draggingCardID == card.id ? 10 : 0)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 12))
        .listRowBackground(AppColors.Health.card)
    }

    private func updateDrag(
        _ card: HealthCard,
        translation: CGFloat,
        locationY: CGFloat,
        viewport: CGRect
    ) {
        if draggingCardID != card.id {
            draggingCardID = card.id
            dragStartIndex = active.firstIndex(of: card)
            dragScrollOffset = 0
        }
        dragTranslation = translation
        let edgeInset: CGFloat = 72
        if locationY < viewport.minY + edgeInset {
            dragEdgeDirection = -1
            let penetration = min(max((viewport.minY + edgeInset - locationY) / edgeInset, 0), 1)
            dragEdgeSpeed = 3 + penetration * 9
        } else if locationY > viewport.maxY - edgeInset {
            dragEdgeDirection = 1
            let penetration = min(max((locationY - (viewport.maxY - edgeInset)) / edgeInset, 0), 1)
            dragEdgeSpeed = 3 + penetration * 9
        } else {
            dragEdgeDirection = 0
            dragEdgeSpeed = 0
        }
        reconcileDrag(card)
    }

    private func reconcileDrag(_ card: HealthCard) {
        guard let start = dragStartIndex,
              let current = active.firstIndex(of: card),
              !active.isEmpty else { return }
        let effectiveTranslation = dragTranslation + dragScrollOffset
        let shift = Int((effectiveTranslation / editorRowHeight).rounded())
        let target = min(max(start + shift, 0), active.count - 1)
        let nextVisualOffset = effectiveTranslation - CGFloat(target - start) * editorRowHeight
        guard current != target else {
            dragVisualOffset = nextVisualOffset
            return
        }
        withAnimation(.easeInOut(duration: 0.14)) {
            dragVisualOffset = nextVisualOffset
            let moving = active.remove(at: current)
            active.insert(moving, at: target)
        }
    }

    private func autoScroll() {
        guard dragEdgeDirection != 0,
              dragEdgeSpeed > 0,
              let scrollView = editorScrollView,
              let cardID = draggingCardID,
              let card = active.first(where: { $0.id == cardID }),
              let current = active.firstIndex(of: card) else { return }
        let target = current + dragEdgeDirection
        guard active.indices.contains(target) else {
            dragEdgeDirection = 0
            dragEdgeSpeed = 0
            return
        }
        let minimumY = -scrollView.adjustedContentInset.top
        let maximumY = max(
            minimumY,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        )
        let currentY = scrollView.contentOffset.y
        let proposedY = currentY + CGFloat(dragEdgeDirection) * dragEdgeSpeed
        let nextY = min(max(proposedY, minimumY), maximumY)
        let appliedOffset = nextY - currentY
        guard abs(appliedOffset) > 0.1 else { return }
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: nextY), animated: false)
        dragScrollOffset += appliedOffset
        reconcileDrag(card)
    }

    private func endDrag() {
        draggingCardID = nil
        dragStartIndex = nil
        dragTranslation = 0
        dragVisualOffset = 0
        dragScrollOffset = 0
        dragEdgeDirection = 0
        dragEdgeSpeed = 0
    }

    private func remove(_ card: HealthCard) {
        guard active.count > 3 else {
            warning = AppText.Health.minimumCards
            return
        }
        active.removeAll { $0 == card }
        warning = nil
    }
}

private struct ScrollViewAccessor: UIViewRepresentable {
    let onResolve: (UIScrollView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        resolve(from: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        resolve(from: uiView)
    }

    private func resolve(from view: UIView) {
        DispatchQueue.main.async {
            var ancestor = view.superview
            while let current = ancestor {
                if let scrollView = findScrollView(in: current, excluding: view) {
                    onResolve(scrollView)
                    return
                }
                ancestor = current.superview
            }
        }
    }

    private func findScrollView(in view: UIView, excluding marker: UIView) -> UIScrollView? {
        if view !== marker, let scrollView = view as? UIScrollView {
            return scrollView
        }
        for subview in view.subviews where subview !== marker {
            if let scrollView = findScrollView(in: subview, excluding: marker) {
                return scrollView
            }
        }
        return nil
    }
}

private struct HealthDetailView: View {
    let card: HealthCard
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Text("‹").font(.system(size: 38, weight: .light)) }
                    .frame(width: 38)
                Text(card.title).font(.system(size: 19)).frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 38)
            }
            .foregroundStyle(.white).padding(.horizontal, 18).frame(height: 64)
            Spacer()
            Image(card.icon).resizable().scaledToFit().frame(width: 56, height: 56)
            Spacer().frame(height: 20)
            Text(AppText.Health.pending(card.title)).foregroundStyle(Color.gray).font(.system(size: 16))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
