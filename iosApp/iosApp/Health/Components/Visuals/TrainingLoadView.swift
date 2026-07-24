import SwiftUI
import Shared

struct TrainingLoadView: View {
    let visual: HealthCardVisualData
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                valueText(visual.primaryValue, 32)
                captionText(visual.caption, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer()
            LoadOverviewView(visual: visual)
        }
        .frame(minHeight: 60)
    }
}

struct LoadOverviewView: View {
    let visual: HealthCardVisualData
    var body: some View {
        VStack(spacing: 4) {
            MiniBarsView(points: visual.chartPoints, highlightedIndex: visual.highlightedIndex?.intValue, width: 130, height: 36, dense: false, forceColor: AppColors.Health.visualCyan, showTrack: true)
            HStack {
                ForEach(Array(visual.chartPoints.prefix(7).enumerated()), id: \.offset) { index, point in
                    Text(appLocalized(point.label))
                        .font(.system(size: 9))
                        .foregroundStyle(index == visual.highlightedIndex?.intValue ? .white : AppColors.Health.muted)
                    if index < min(6, visual.chartPoints.count - 1) { Spacer(minLength: 0) }
                }
            }
        }
        .frame(width: 130)
    }
}
