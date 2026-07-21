import SwiftUI

struct HeroArcView: View {
    let steps: Int; let calories: Int; let minutes: Int
    var body: some View {
        ZStack {
            Circle().trim(from: 0.13, to: 0.87).stroke(AppColors.Health.gauge, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(90)).frame(width: 125, height: 125)
            HStack {
                metric(icon: AppImages.Health.steps, value: "\(steps)", unit: appLocalized("health_unit_steps"), color: AppColors.Health.steps)
                Spacer()
                metric(icon: AppImages.Health.calories, value: "\(calories)", unit: appLocalized("health_unit_calories"), color: AppColors.Health.calories)
                Spacer()
                metric(icon: AppImages.Health.active, value: "\(minutes)", unit: appLocalized("health_unit_minutes"), color: AppColors.Health.active)
            }
        }
        .frame(height: 128).padding(.horizontal, 20)
    }
    private func metric(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(icon).resizable().renderingMode(.template).scaledToFit().foregroundStyle(color).frame(width: 22, height: 22)
            Text(value).font(.system(size: 28)).foregroundStyle(.white)
            Text(unit).font(.system(size: AppTypography.caption)).foregroundStyle(AppColors.Health.metricUnit)
        }.frame(width: 82)
    }
}
