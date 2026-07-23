import SwiftUI

private let editorRowHeight: CGFloat = 56
private let allCardTypes: [(String, String)] = [
    ("TodayActivity", AppImages.Health.todayActivity),
    ("WeeklyPlan", AppImages.Health.weeklyPlan), ("TrainingLoad", AppImages.Health.trainingLoad),
    ("TrainingAssessment", AppImages.Health.trainingAssessment), ("Recovery", AppImages.Health.recovery),
    ("RunningAbility", AppImages.Health.runningAbility), ("CyclingAbility", AppImages.Health.cyclingAbility),
    ("HeartRate", AppImages.Health.heartRate), ("Stress", AppImages.Health.stress),
    ("Sleep", AppImages.Health.sleep), ("HrvAssessment", AppImages.Health.hrv),
    ("RestingHeartRate", AppImages.Health.restingHeartRate), ("HealthCheck", AppImages.Health.healthCheck),
    ("BodyManagement", AppImages.Health.body),
]

private func cardTitleKey(_ typeID: String) -> String {
    switch typeID {
    case "TodayActivity": "health_card_today_activity_title"
    case "WeeklyPlan": "health_card_weekly_plan_title"
    case "TrainingLoad": "health_card_training_load_title"
    case "TrainingAssessment": "health_card_training_assessment_title"
    case "Recovery": "health_card_recovery_title"
    case "RunningAbility": "health_card_running_ability_title"
    case "CyclingAbility": "health_card_cycling_ability_title"
    case "HeartRate": "health_card_heart_rate_title"
    case "Stress": "health_card_stress_title"
    case "Sleep": "health_card_sleep_title"
    case "HrvAssessment": "health_card_hrv_assessment_title"
    case "RestingHeartRate": "health_card_resting_heart_rate_title"
    case "HealthCheck": "health_card_health_check_title"
    case "BodyManagement": "health_card_body_management_title"
    default: "health_data_unavailable"
    }
}

private func editorCard(typeID: String, icon: String) -> HealthCard {
    HealthCard(id: typeID, title: appLocalized(cardTitleKey(typeID)), summary: "", icon: icon, isRisk: false)
}

struct HealthCardEditor: View {
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
    private let dragScrollTicker = Timer.publish(every: 0.032, on: .main, in: .common).autoconnect()
    let onClose: () -> Void
    let onSave: ([HealthCard]) -> Void

    init(initial: [HealthCard], onClose: @escaping () -> Void, onSave: @escaping ([HealthCard]) -> Void) {
        _active = State(initialValue: initial); self.onClose = onClose; self.onSave = onSave
    }

    private var inactive: [HealthCard] {
        let activeIDs = Set(active.map(\.id))
        return allCardTypes.filter { !activeIDs.contains($0.0) }.map { editorCard(typeID: $0.0, icon: $0.1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            editorBody
        }
        .background(AppColors.Core.black).onDisappear { endDrag() }
    }

    private var header: some View {
        HStack {
            Button(action: onClose) { Text(appLocalized("common_back")).font(.system(size: 38, weight: .light)) }.frame(width: 64, alignment: .leading)
            Spacer(); Text(appLocalized("health_edit_cards")).font(.system(size: AppTypography.sectionTitle, weight: .medium)); Spacer()
            Button { onSave(active) } label: {
                Text(appLocalized("common_save")).font(.system(size: AppTypography.action))
                    .frame(width: 64, height: 30).background(AppColors.Health.action).clipShape(RoundedRectangle(cornerRadius: 6))
            }.buttonStyle(.plain)
        }.foregroundStyle(.white).padding(.horizontal, 18).frame(height: 64)
    }

    private var editorBody: some View {
        VStack(spacing: 0) {
            Text(appLocalized("health_manage_cards")).font(.system(size: AppTypography.label)).foregroundStyle(AppColors.Health.muted)
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 22).padding(.bottom, 10)
            if let warning { Text(warning).font(.system(size: AppTypography.supporting)).foregroundStyle(AppColors.Health.warning).padding(.bottom, AppSpacing.small) }

            GeometryReader { geometry in
                List {
                    ForEach(active) { card in EditorRow(card: card, isAdd: false, viewport: geometry.frame(in: .global), action: { remove(card) }) }
                    if !inactive.isEmpty {
                        Section(appLocalized("health_more_daily_data")) {
                            ForEach(inactive) { card in EditorRow(card: card, isAdd: true, viewport: geometry.frame(in: .global), action: { active.append(card); warning = nil }) }
                        }
                    }
                    Button(appLocalized("health_restore_defaults")) {
                        active = allCardTypes.map { editorCard(typeID: $0.0, icon: $0.1) }; warning = nil
                    }.foregroundStyle(AppColors.Health.action)
                }
                .scrollContentBackground(.hidden).listStyle(.insetGrouped)
                .background { ScrollViewAccessor { sv in if editorScrollView !== sv { editorScrollView = sv } } }
                .onReceive(dragScrollTicker) { _ in autoScroll() }
            }
        }
    }

    private func remove(_ card: HealthCard) {
        guard active.count > 3 else { warning = appLocalized("health_minimum_cards"); return }
        active.removeAll { $0 == card }; warning = nil
    }

    private func EditorRow(card: HealthCard, isAdd: Bool, viewport: CGRect, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            if !isAdd {
                Text("⠿").font(.system(size: 18)).foregroundStyle(AppColors.Health.muted).frame(width: 18, height: 44).contentShape(Rectangle())
                    .highPriorityGesture(DragGesture(minimumDistance: 2, coordinateSpace: .global)
                        .onChanged { updateDrag(card, translation: $0.translation.height, locationY: $0.location.y, viewport: viewport) }
                        .onEnded { _ in endDrag() })
            }
            Image(card.icon).resizable().scaledToFit().frame(width: 22, height: 22)
            Text(card.title).font(.system(size: AppTypography.editorRow)).foregroundStyle(AppColors.Health.editorTitle)
            Spacer()
            Button(action: action) {
                ZStack { Circle().fill(isAdd ? AppColors.Health.addAction : AppColors.Health.removeAction)
                    Rectangle().fill(AppColors.Core.white).frame(width: 16, height: 2)
                    if isAdd { Rectangle().fill(AppColors.Core.white).frame(width: 2, height: 16) }
                }.frame(width: 30, height: 30)
            }.buttonStyle(.plain)
        }
        .frame(height: editorRowHeight).contentShape(Rectangle())
        .offset(y: draggingCardID == card.id ? dragVisualOffset : 0)
        .scaleEffect(draggingCardID == card.id ? 1.015 : 1)
        .shadow(color: draggingCardID == card.id ? AppColors.Core.overlaySoft : .clear, radius: 10, y: 4)
        .opacity(draggingCardID == card.id ? 0.94 : 1).zIndex(draggingCardID == card.id ? 10 : 0)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 12)).listRowBackground(AppColors.Health.card)
    }

    // MARK: - Drag Logic
    private func updateDrag(_ card: HealthCard, translation: CGFloat, locationY: CGFloat, viewport: CGRect) {
        if draggingCardID != card.id { draggingCardID = card.id; dragStartIndex = active.firstIndex(of: card); dragScrollOffset = 0 }
        dragTranslation = translation
        let inset: CGFloat = 72
        if locationY < viewport.minY + inset { dragEdgeDirection = -1; dragEdgeSpeed = 3 + min(max((viewport.minY + inset - locationY) / inset, 0), 1) * 9 }
        else if locationY > viewport.maxY - inset { dragEdgeDirection = 1; dragEdgeSpeed = 3 + min(max((locationY - (viewport.maxY - inset)) / inset, 0), 1) * 9 }
        else { dragEdgeDirection = 0; dragEdgeSpeed = 0 }
        reconcileDrag(card)
    }

    private func reconcileDrag(_ card: HealthCard) {
        guard let start = dragStartIndex, let current = active.firstIndex(of: card), !active.isEmpty else { return }
        let t = dragTranslation + dragScrollOffset; let shift = Int((t / editorRowHeight).rounded()); let target = min(max(start + shift, 0), active.count - 1)
        let nextOffset = t - CGFloat(target - start) * editorRowHeight
        guard current != target else { dragVisualOffset = nextOffset; return }
        withAnimation(.easeInOut(duration: 0.14)) { dragVisualOffset = nextOffset; let m = active.remove(at: current); active.insert(m, at: target) }
    }

    private func autoScroll() {
        guard dragEdgeDirection != 0, dragEdgeSpeed > 0, let sv = editorScrollView, let id = draggingCardID,
              let card = active.first(where: { $0.id == id }), let current = active.firstIndex(of: card) else { return }
        let target = current + dragEdgeDirection
        guard active.indices.contains(target) else { dragEdgeDirection = 0; dragEdgeSpeed = 0; return }
        let minY = -sv.adjustedContentInset.top
        let maxY = max(minY, sv.contentSize.height - sv.bounds.height + sv.adjustedContentInset.bottom)
        let nextY = min(max(sv.contentOffset.y + CGFloat(dragEdgeDirection) * dragEdgeSpeed, minY), maxY)
        let applied = nextY - sv.contentOffset.y
        guard abs(applied) > 0.1 else { return }
        sv.setContentOffset(CGPoint(x: sv.contentOffset.x, y: nextY), animated: false)
        dragScrollOffset += applied; reconcileDrag(card)
    }

    private func endDrag() {
        draggingCardID = nil; dragStartIndex = nil; dragTranslation = 0; dragVisualOffset = 0
        dragScrollOffset = 0; dragEdgeDirection = 0; dragEdgeSpeed = 0
    }
}

#Preview {
    HealthCardEditor(
        initial: [
            HealthCard(id: "TodayActivity", title: "今日活动", summary: "", icon: "health_today_activity", isRisk: false),
            HealthCard(id: "WeeklyPlan", title: "本周计划", summary: "", icon: "health_weekly_plan", isRisk: false),
            HealthCard(id: "TrainingLoad", title: "训练负荷", summary: "", icon: "health_training_load", isRisk: false),
            HealthCard(id: "HeartRate", title: "心率", summary: "", icon: "health_heart_rate", isRisk: false),
        ],
        onClose: {},
        onSave: { _ in }
    )
    .preferredColorScheme(.dark)
}
