import SwiftUI
import Shared

struct BodyView: View {
    let visual: HealthCardVisualData
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                captionText(visual.caption, size: 14)
                HStack(alignment: .lastTextBaseline, spacing: 2) { valueText(visual.primaryValue, 32); unitText(visual.primaryUnit, size: 20) }
                captionText(visual.detail, size: 12)
            }.frame(width: 141, alignment: .leading).padding(.top, 8)
            Spacer()
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(AppImages.Health.bodyFront).resizable().scaledToFit().frame(width: 52, height: 108)
                    Image(AppImages.Health.bodyBack).resizable().scaledToFit().frame(width: 52, height: 108)
                }
                HStack(spacing: 3) {
                    ForEach(Array(visual.metrics.prefix(2).enumerated()), id: \.offset) { index, m in
                        if index > 0 { Text("·") }; Text(localizedHealthText(m.label))
                    }
                }.font(.system(size: 11)).foregroundStyle(AppColors.Health.muted).lineLimit(1)
            }.frame(width: 142).clipped()
        }
    }
}
