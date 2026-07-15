import SwiftUI
import Combine
import UIKit

struct HealthCard: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let isRisk: Bool
}

private let defaultHealthCards: [HealthCard] = [
    HealthCard(id: "weeklyPlan", title: "本周计划", summary: "本周无计划", icon: AppImages.Health.weeklyPlan, isRisk: false),
    HealthCard(id: "trainingLoad", title: "本周负荷", summary: "本周负荷 526，建议范围 300-700", icon: AppImages.Health.trainingLoad, isRisk: false),
    HealthCard(id: "trainingAssessment", title: "训练量评估", summary: "将在第一次运动后 7 天评估您的训练量", icon: AppImages.Health.trainingAssessment, isRisk: false),
    HealthCard(id: "recovery", title: "体力恢复", summary: "恢复评分 78，预计 14 小时后恢复", icon: AppImages.Health.recovery, isRisk: false),
    HealthCard(id: "running", title: "跑步能力", summary: "记录一笔 25min 以上的户外跑步运动", icon: AppImages.Health.runningAbility, isRisk: false),
    HealthCard(id: "cycling", title: "骑行FTP", summary: "连接功率计，完成一次 20min 以上稳定骑行", icon: AppImages.Health.cyclingAbility, isRisk: false),
    HealthCard(id: "heartRate", title: "心率", summary: "佩戴手表记录心率数据", icon: AppImages.Health.heartRate, isRisk: false),
    HealthCard(id: "stress", title: "压力", summary: "佩戴手表或进行健康快测获取压力", icon: AppImages.Health.stress, isRisk: false),
    HealthCard(id: "sleep", title: "睡眠", summary: "昨夜睡眠 7小时18分，质量 86", icon: AppImages.Health.sleep, isRisk: false),
    HealthCard(id: "hrv", title: "HRV评估", summary: "睡觉时佩戴手表获取数据", icon: AppImages.Health.hrv, isRisk: false),
    HealthCard(id: "rhr", title: "静息心率", summary: "睡觉时佩戴手表或进行静息心率测试", icon: AppImages.Health.restingHeartRate, isRisk: false),
    HealthCard(id: "healthCheck", title: "健康快测", summary: "使用手表“健康快测”获取数据", icon: AppImages.Health.healthCheck, isRisk: false),
    HealthCard(id: "body", title: "体型管理", summary: "体重 68.2 kg · 本周主要锻炼部位", icon: AppImages.Health.body, isRisk: false)
]

struct HealthDashboardView: View {
    @Binding var isFullscreen: Bool
    @State private var cards = defaultHealthCards
    @State private var editing = false
    @State private var detail: HealthCard?

    var body: some View {
        Group {
            if editing {
                HealthCardEditor(initial: cards, onClose: closeEditor, onSave: saveCards)
            } else if let detail {
                HealthDetailView(card: detail) {
                    self.detail = nil
                    isFullscreen = false
                }
            } else {
                dashboard
            }
        }
        .background(Color.black)
        .onAppear(perform: loadCards)
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 0) {
                HealthHeroView()
                ForEach(cards) { card in
                    Button {
                        detail = card
                        isFullscreen = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(card.icon).resizable().scaledToFit().frame(width: 22, height: 22)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(card.title).font(.system(size: 16, weight: .medium)).foregroundStyle(.white)
                                Text(card.summary).font(.system(size: 12)).foregroundStyle(AppColors.Health.muted).lineLimit(2)
                            }
                            Spacer(minLength: 8)
                            if card.isRisk { Circle().fill(AppColors.Health.risk).frame(width: 7, height: 7) }
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
                }

                Button {
                    editing = true
                    isFullscreen = true
                } label: {
                    Text(AppText.Health.editCards)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(red: 221 / 255, green: 221 / 255, blue: 221 / 255))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(AppColors.Health.card)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(18)
                Spacer().frame(height: 24)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }

    private func loadCards() {
        guard let ids = UserDefaults.standard.stringArray(forKey: "health_card_order") else { return }
        let byID = Dictionary(uniqueKeysWithValues: defaultHealthCards.map { ($0.id, $0) })
        let restored = ids.compactMap { byID[$0] }
        if restored.count >= 3 { cards = restored }
    }

    private func closeEditor() {
        editing = false
        isFullscreen = false
    }

    private func saveCards(_ value: [HealthCard]) {
        cards = value
        UserDefaults.standard.set(value.map(\.id), forKey: "health_card_order")
        closeEditor()
    }
}

private struct HealthHeroView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppText.Health.date).font(.system(size: 11)).foregroundStyle(Color.gray)
                    Text(AppText.Health.today).font(.system(size: 28, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
                Image(AppImages.Health.calendar).resizable().scaledToFit().frame(width: 23, height: 23)
                Spacer().frame(width: 18)
                Image(AppImages.Health.device).resizable().scaledToFit().frame(width: 23, height: 23)
            }
            .padding(.top, 10)

            Spacer().frame(height: 46)
            ZStack {
                Circle()
                    .trim(from: 0.13, to: 0.87)
                    .stroke(AppColors.Health.gauge, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: 125, height: 125)
                HStack {
                    HealthMetric(icon: AppImages.Health.steps, value: "8769", unit: AppText.Health.steps, color: AppColors.Health.steps)
                    Spacer()
                    HealthMetric(icon: AppImages.Health.calories, value: "769", unit: AppText.Health.calories, color: AppColors.Health.calories)
                    Spacer()
                    HealthMetric(icon: AppImages.Health.active, value: "69", unit: AppText.Health.minutes, color: AppColors.Health.active)
                }
            }
            .frame(height: 128)
        }
        .padding(.horizontal, 20)
        .frame(height: 292, alignment: .top)
        .background(Color.black)
    }
}

private struct HealthMetric: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(icon).resizable().renderingMode(.template).scaledToFit().foregroundStyle(color).frame(width: 22, height: 22)
            Text(value).font(.system(size: 28)).foregroundStyle(.white)
            Text(unit).font(.system(size: 11)).foregroundStyle(Color.gray)
        }
        .frame(width: 82)
    }
}

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

    private var inactive: [HealthCard] { defaultHealthCards.filter { !active.contains($0) } }

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
                Button(action: onBack) { Text(AppText.Common.back).font(.system(size: 38, weight: .light)) }
                Spacer()
                Text(card.title).font(.system(size: 19))
                Spacer().frame(width: 32)
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
