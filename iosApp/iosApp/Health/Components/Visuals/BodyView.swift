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
                    bodyFigure(
                        base: AppImages.Health.bodyMaleFrontBase,
                        regions: visual.highlightedBodyRegions.filter { $0.hasSuffix("_front") }
                    )
                    bodyFigure(
                        base: AppImages.Health.bodyMaleBackBase,
                        regions: visual.highlightedBodyRegions.filter { $0.hasSuffix("_back") }
                    )
                }
                .frame(width: 108, height: 108)
                if let footer = visual.footer {
                    Text(localizedHealthText(footer))
                        .font(.system(size: 9))
                        .foregroundStyle(AppColors.Health.muted)
                        .lineLimit(1)
                }
            }.frame(width: 142).clipped()
        }
    }

    @ViewBuilder
    private func bodyFigure(base: String, regions: [String]) -> some View {
        ZStack {
            Image(base)
                .resizable()
                .scaledToFit()
            ForEach(regions, id: \.self) { region in
                bodyRegionLayer(region)
            }
        }
        .frame(width: 52, height: 108)
    }

    @ViewBuilder
    private func bodyRegionLayer(_ region: String) -> some View {
        if let assetName = AppImages.Health.bodyMuscleRegions[region] {
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppColors.Health.action)
        }
    }
}

#Preview("Body management") {
    BodyView(visual: previewHealthVisual("BodyManagement"), onWeightEdit: {})
        .healthVisualPreviewSurface()
}
