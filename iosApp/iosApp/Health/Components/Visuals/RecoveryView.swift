import SwiftUI
import Shared

struct RecoveryView: View {
    let visual: HealthCardVisualData

    private var progress: CGFloat {
        CGFloat(max(0, min(1, visual.progress?.doubleValue ?? 0)))
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
            .frame(minHeight: 78, alignment: .leading)
            Spacer(minLength: 8)
            RecoveryGaugeOverviewView(progress: progress)
        }
        .frame(minHeight: 78, alignment: .center)
    }
}

#Preview("Recovery") {
    RecoveryView(visual: previewHealthVisual("Recovery"))
        .healthVisualPreviewSurface()
}

private struct RecoveryGaugeOverviewView: View {
    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            Canvas { context, _ in
                let center = CGPoint(x: 57, y: 55)
                let radius: CGFloat = 52
                var track = Path()
                track.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(360),
                    clockwise: false
                )
                context.stroke(
                    track,
                    with: .color(AppColors.Health.gaugeTrack),
                    style: StrokeStyle(lineWidth: 4, lineCap: .butt)
                )
                if progress > 0 {
                    var active = Path()
                    active.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(180 + 180 * Double(progress)),
                        clockwise: false
                    )
                    context.stroke(
                        active,
                        with: .color(AppColors.Health.visualCyan),
                        style: StrokeStyle(lineWidth: 4, lineCap: .butt)
                    )
                }
            }
            .frame(width: 114, height: 58)
            Image(AppImages.Health.recoveryStatus)
                .resizable()
                .scaledToFit()
                .frame(width: 21, height: 30)
                .padding(.top, 20)
            Text(appLocalized(progress >= 0.7 ? "health_visual_recovery_ready" : "health_visual_recovery_low"))
                .font(.system(size: 11))
                .foregroundStyle(AppColors.Health.cardTitle)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: 114, height: 78)
    }
}
