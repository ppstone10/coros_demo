import SwiftUI
import Shared

struct AbilityView: View {
    let cardType: String
    let visual: HealthCardVisualData

    private var progress: CGFloat {
        CGFloat(max(0, min(1, visual.progress?.doubleValue ?? 0)))
    }

    private var accent: Color {
        cardType == "RunningAbility"
            ? AppColors.Health.visualOrange
            : AppColors.Health.visualGreen
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
            .frame(minHeight: 71, alignment: .leading)
            Spacer(minLength: 8)
            AbilityGaugeOverviewView(progress: progress, accent: accent)
        }
        .frame(minHeight: 71, alignment: .center)
    }
}

#Preview("Running ability") {
    AbilityView(cardType: "RunningAbility", visual: previewHealthVisual("RunningAbility"))
        .healthVisualPreviewSurface()
}

private struct AbilityGaugeOverviewView: View {
    let progress: CGFloat
    let accent: Color

    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height - 5)
                let radius = (size.width - 10) * 0.42
                let segments = 30
                for index in 0..<segments {
                    let start = 180 + Double(index) * 180 / Double(segments)
                    let end = start + 180 / Double(segments) * 0.68
                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(start),
                        endAngle: .degrees(end),
                        clockwise: false
                    )
                    let filled = (Double(index) + 0.5) / Double(segments) <= Double(progress)
                    context.stroke(path, with: .color(filled ? accent : AppColors.Health.gaugeTrack), lineWidth: 3)
                }
                let angle = Double.pi + Double(progress) * Double.pi
                var needle = Path()
                needle.move(to: center)
                needle.addLine(
                    to: CGPoint(
                        x: center.x + cos(angle) * radius * 0.78,
                        y: center.y + sin(angle) * radius * 0.78
                    )
                )
                context.stroke(needle, with: .color(AppColors.Health.cardTitle), lineWidth: 1.5)
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)),
                    with: .color(AppColors.Health.cardTitle)
                )
            }
            .frame(width: 121, height: 60)
            HStack {
                Text("0")
                Spacer()
                Text("100")
            }
            .font(.system(size: 10))
            .foregroundStyle(AppColors.Health.muted)
        }
        .frame(width: 121, height: 71)
    }
}
