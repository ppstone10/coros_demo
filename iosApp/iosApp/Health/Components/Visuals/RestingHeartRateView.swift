import SwiftUI
import Shared

struct RestingHeartRateView: View {
    let visual: HealthCardVisualData

    private var fraction: CGFloat {
        guard let range = visual.range else { return 0.5 }
        return CGFloat(max(0, min(1, (range.current - range.minimum) / max(1, range.maximum - range.minimum))))
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    valueText(visual.primaryValue, 32)
                    unitText(visual.primaryUnit, size: 20)
                }
                captionText(visual.caption, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer(minLength: 8)
            RestingHeartRateOverviewView(visual: visual, fraction: fraction)
                .frame(width: 130)
        }
        .frame(minHeight: 60, alignment: .center)
    }
}

#Preview("Resting heart rate") {
    RestingHeartRateView(visual: previewHealthVisual("RestingHeartRate"))
        .healthVisualPreviewSurface()
}

private struct RestingHeartRateOverviewView: View {
    let visual: HealthCardVisualData
    let fraction: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                DashedVerticalRule(color: AppColors.Health.muted)
                    .frame(width: 2, height: 12)
                captionText(visual.detail, size: 11)
            }
            GeometryReader { geometry in
                let markerX = max(4, min(geometry.size.width - 4, geometry.size.width * fraction))
                let averageFraction = CGFloat(max(0, min(1, ((visual.range?.average?.doubleValue ?? 0) - (visual.range?.minimum ?? 0)) / max(1, (visual.range?.maximum ?? 1) - (visual.range?.minimum ?? 0)))))
                ZStack(alignment: .topLeading) {
                    Capsule()
                        .fill(AppColors.Health.visualPink)
                        .frame(height: 4)
                        .offset(y: 10)
                    Path { path in
                        path.move(to: CGPoint(x: markerX, y: 2))
                        path.addLine(to: CGPoint(x: markerX - 4, y: 14))
                        path.addLine(to: CGPoint(x: markerX + 4, y: 14))
                        path.closeSubpath()
                    }
                    .fill(.white)
                    if visual.range?.average != nil {
                        Path { path in
                            let x = geometry.size.width * averageFraction
                            path.move(to: CGPoint(x: x, y: 2))
                            path.addLine(to: CGPoint(x: x, y: 18))
                        }
                        .stroke(.white, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    }
                }
            }
            .frame(height: 18)
            HStack {
                Text("\(Int(visual.range?.minimum ?? 0))")
                Spacer()
                Text("\(Int(visual.range?.maximum ?? 0))")
            }
            .font(.system(size: 10))
            .foregroundStyle(AppColors.Health.muted)
        }
    }
}

private struct DashedVerticalRule: View {
    let color: Color
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        }
    }
}
