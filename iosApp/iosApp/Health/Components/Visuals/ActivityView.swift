import SwiftUI
import Shared

struct ActivityView: View {
    let visual: HealthCardVisualData
    var body: some View {
        HStack(spacing: 12) {
            Image(AppImages.Health.activityMap).resizable().scaledToFill().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 3) { valueText(visual.primaryValue, 24); unitText(visual.primaryUnit, size: 16) }
                HStack(spacing: 3) {
                    if let d = visual.detail { Text(localizedHealthText(d)) }
                    if let c = visual.caption { Text(localizedHealthText(c)) }
                }.font(.system(size: 12)).foregroundStyle(AppColors.Health.muted).lineLimit(1)
            }
            Spacer(minLength: 4)
            Image(AppImages.Health.todayRunner).resizable().scaledToFit().frame(width: 24, height: 24)
        }.padding(.top, 10)
    }
}
