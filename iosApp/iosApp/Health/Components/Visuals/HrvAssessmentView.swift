import SwiftUI
import Shared

struct HrvAssessmentView: View {
    let visual: HealthCardVisualData

    private var fraction: CGFloat {
        guard let range = visual.range else { return 0.5 }
        return CGFloat(max(0, min(1, (range.current - range.minimum) / max(1, range.maximum - range.minimum))))
    }

    private var normalRangeText: String? {
        guard
            let range = visual.range,
            let normalMin = range.normalMin?.intValue,
            let normalMax = range.normalMax?.intValue
        else { return nil }
        let unit = visual.primaryUnit.map(localizedHealthText) ?? ""
        return String(
            format: appLocalized("health_visual_normal_range_short"),
            "\(normalMin)",
            "\(normalMax)",
            unit
        )
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                if let caption = visual.caption {
                    Text(localizedHealthText(caption))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                captionText(visual.detail, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer(minLength: 8)
            HrvAssessmentOverviewView(
                visual: visual,
                fraction: fraction,
                normalRangeText: normalRangeText
            )
            .frame(width: 130)
        }
        .frame(minHeight: 60, alignment: .center)
    }
}

private struct HrvAssessmentOverviewView: View {
    let visual: HealthCardVisualData
    let fraction: CGFloat
    let normalRangeText: String?

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let markerX = max(4, min(geometry.size.width - 4, geometry.size.width * fraction))
                let segments = visual.range?.segments ?? []
                let rangeMinimum = visual.range?.minimum ?? 0
                let rangeWidth = max(1, (visual.range?.maximum ?? 1) - rangeMinimum)
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                            Rectangle()
                                .fill(segmentColor(segment.level.name))
                                .frame(
                                    width: geometry.size.width * CGFloat(
                                        max(0, segment.maximum - segment.minimum) / rangeWidth
                                    )
                                )
                        }
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .frame(height: 4)
                    .clipShape(Capsule())
                    .offset(y: 10)
                    Path { path in
                        path.move(to: CGPoint(x: markerX, y: 2))
                        path.addLine(to: CGPoint(x: markerX - 4, y: 14))
                        path.addLine(to: CGPoint(x: markerX + 4, y: 14))
                        path.closeSubpath()
                    }
                    .fill(.white)
                }
            }
            .frame(height: 18)
            if let normalRangeText {
                HStack(spacing: 4) {
                    Circle().fill(AppColors.Health.visualGreen).frame(width: 5, height: 5)
                    Text(normalRangeText)
                        .font(.system(size: 10)).foregroundStyle(AppColors.Health.muted).lineLimit(1)
                }
            }
        }
    }

    private func segmentColor(_ level: String) -> Color {
        switch level {
        case "VeryLow": AppColors.Health.warning
        case "Low": AppColors.Health.visualYellow
        case "Normal": AppColors.Health.visualGreen
        default: AppColors.Health.visualOrange
        }
    }
}
