import SwiftUI
import Shared

struct MiniBarsView: View {
    let points: [HealthChartPoint]
    let highlightedIndex: Int?
    var width: CGFloat = 130
    var height: CGFloat = 54
    var dense: Bool = false
    var forceColor: Color? = nil
    var showTrack: Bool = false

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: dense ? 2 : 5) {
                let high = max(1, points.map(\.value).max() ?? 1)
                ForEach(Array(points.enumerated()), id: \.offset) { index, p in
                    ZStack(alignment: .bottom) {
                        if showTrack {
                            RoundedRectangle(cornerRadius: 2).fill(AppColors.Health.gaugeTrack)
                                .frame(height: geo.size.height)
                        }
                        RoundedRectangle(cornerRadius: 2).fill(forceColor ?? (index == highlightedIndex ? AppColors.Health.visualCyan : barColor(p.level.name)))
                            .frame(height: max(2, geo.size.height * p.value / high))
                    }
                }
            }
        }
        .frame(width: width, height: height)
    }
}
