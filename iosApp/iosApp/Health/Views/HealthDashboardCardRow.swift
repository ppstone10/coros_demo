import SwiftUI
import Shared

struct HealthDashboardCardRow: View {
    let card: HealthCard
    let onWeightEdit: () -> Void

    var body: some View {
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
                    onWeightEdit: onWeightEdit
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

#Preview("Card row") {
    HealthDashboardCardRow(
        card: HealthCard(
            id: "Recovery",
            title: "Recovery",
            summary: "Ready",
            icon: "health_recovery_sports",
            isRisk: false,
            status: "Normal",
            visual: previewHealthVisual("Recovery")
        ),
        onWeightEdit: {}
    )
    .preferredColorScheme(.dark)
}
