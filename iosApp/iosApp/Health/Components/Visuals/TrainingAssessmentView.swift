import SwiftUI
import Shared

struct TrainingAssessmentView: View {
    let visual: HealthCardVisualData
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let c = visual.caption { Text(localizedHealthText(c)).font(.system(size: 20, weight: .semibold)).foregroundStyle(AppColors.Health.visualOrange) }
            captionText(visual.detail, size: 14).lineSpacing(2).frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 0) {
                ForEach(Array(visual.metrics.prefix(3).enumerated()), id: \.offset) { index, item in
                    metricView(item, accent: .white, valueSize: 30).frame(width: 82, alignment: .leading)
                    if index < 2 { Spacer(minLength: 0); Divider().background(AppColors.Health.divider).frame(width: 1, height: 42); Spacer(minLength: 0) }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
        .padding(.top, 8)
        .frame(minHeight: 130, alignment: .topLeading)
    }
}
