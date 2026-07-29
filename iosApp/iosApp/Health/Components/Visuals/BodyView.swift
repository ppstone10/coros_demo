import SwiftUI
import Shared

struct BodyView: View {
    let visual: HealthCardVisualData
    let onWeightEdit: () -> Void
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                captionText(visual.caption, size: 14)
                Button(action: onWeightEdit) {
                    HStack(alignment: .center, spacing: 4) {
                        valueText(visual.primaryValue, 32)
                        unitText(visual.primaryUnit, size: 20)
                        Image(AppImages.Profile.edit).resizable().scaledToFit().frame(width: 16, height: 16)
                    }
                }.buttonStyle(.plain)
                captionText(visual.detail, size: 12)
            }.frame(width: 141, alignment: .leading).padding(.top, 8)
            Spacer()
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(AppImages.Health.bodyFront).resizable().scaledToFit().frame(width: 52, height: 108)
                    Image(AppImages.Health.bodyBack).resizable().scaledToFit().frame(width: 52, height: 108)
                }
                Text(appLocalized("health_visual_weekly_primary_muscles"))
                    .font(.system(size: 11)).foregroundStyle(AppColors.Health.muted).lineLimit(1)
            }.frame(width: 142).clipped()
        }
    }
}
