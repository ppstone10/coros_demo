import SwiftUI
import Shared

struct WeeklyPlanView: View {
    let visual: HealthCardVisualData
    @State private var selectedDay: Int = 0

    private var plan: WeeklyDayPlan? {
        visual.weeklyDayPlans.first { Int($0.dayIndex) == selectedDay }
    }

    var body: some View {
        let initDay = visual.highlightedIndex?.intValue ?? 0
        VStack(spacing: 8) {
            HStack {
                ForEach(Array(visual.chartPoints.prefix(7).enumerated()), id: \.offset) { index, point in
                    Button {
                        selectedDay = index
                    } label: {
                        Text(appLocalized(point.label))
                            .font(.system(size: 14))
                            .foregroundStyle(index == selectedDay ? .white : AppColors.Health.muted)
                            .frame(width: 28, height: 28)
                            .background(index == selectedDay ? AppColors.Health.action : .clear)
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
                        valueText(plan?.workoutDurationMinutes?.stringValue, 12)
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
                MiniBarsView(points: visual.chartPoints, highlightedIndex: selectedDay, width: 80, height: 36, dense: true)
            }.padding(.horizontal, 16).frame(height: 64).background(AppColors.Health.activityTile).clipShape(RoundedRectangle(cornerRadius: 6))
        }.padding(.top, 8)
        .onAppear { selectedDay = initDay }
    }
}
