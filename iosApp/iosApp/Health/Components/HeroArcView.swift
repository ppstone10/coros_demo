import SwiftUI

struct HeroArcView: View {
    let steps: Int; let calories: Int; let minutes: Int

    private var calorieProgress: CGFloat {
        CGFloat(max(0, min(800, calories))) / 800
    }

    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(AppColors.Health.gaugeTrack, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(135))
                if calorieProgress > 0 {
                    Circle()
                        .trim(from: 0, to: 0.75 * calorieProgress)
                        .stroke(
                            calorieProgress >= 0.75 ? AppColors.Health.visualOrange : AppColors.Health.visualYellow,
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(135))
                }
            }
            .frame(width: 116, height: 116)
            HStack {
                metric(icon: AppImages.Health.steps, value: "\(steps)", unit: appLocalized("health_unit_steps"))
                Spacer()
                metric(icon: AppImages.Health.calories, value: "\(calories)", unit: appLocalized("health_unit_calories"))
                Spacer()
                metric(icon: AppImages.Health.active, value: "\(minutes)", unit: appLocalized("health_unit_minutes"))
            }
        }
        .frame(height: 140).padding(.horizontal, 20)
    }
    private func metric(icon: String, value: String, unit: String) -> some View {
        VStack(spacing: 3) {
            Image(icon).resizable().scaledToFit().frame(width: 22, height: 22)
            Text(value).font(.system(size: 26)).foregroundStyle(.white)
            Text(unit).font(.system(size: AppTypography.caption)).foregroundStyle(AppColors.Health.metricUnit)
        }.frame(width: 82)
    }
}

#Preview {
    HeroArcView(steps: 99999, calories: 9999, minutes: 999)
        .preferredColorScheme(.dark)
}
