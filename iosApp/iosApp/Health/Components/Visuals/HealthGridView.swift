import SwiftUI
import Shared

struct HealthGridView: View {
    let visual: HealthCardVisualData
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .leading), count: 3), spacing: 8) {
                ForEach(Array(visual.metrics.enumerated()), id: \.offset) { _, m in metricView(m, accent: .white) }
            }
        }.padding(.top, 8)
    }
}
