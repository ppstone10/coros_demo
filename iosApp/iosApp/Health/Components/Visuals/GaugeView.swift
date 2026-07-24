import SwiftUI
import Shared

struct GaugeView: View {
    let cardType: String
    let visual: HealthCardVisualData

    private var progress: CGFloat { CGFloat(max(0, min(1, visual.progress?.doubleValue ?? 0))) }
    private var accent: Color {
        cardType == "RunningAbility" ? AppColors.Health.visualOrange
            : cardType == "CyclingAbility" ? AppColors.Health.visualGreen
            : AppColors.Health.visualCyan
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 2) { valueText(visual.primaryValue, 32); unitText(visual.primaryUnit, size: 20) }
                captionText(visual.caption, size: 12)
                captionText(visual.detail, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 78, alignment: .leading)
            Spacer(minLength: 8)
            if cardType == "Recovery" {
                RecoveryGaugeOverviewView(progress: progress)
            } else {
                AbilityGaugeOverviewView(progress: progress, accent: accent)
            }
        }
        .frame(minHeight: 78)
    }
}

struct RecoveryGaugeOverviewView: View {
    let progress: CGFloat
    var body: some View {
        ZStack(alignment: .top) {
            Canvas { context, _ in
                let center = CGPoint(x: 57, y: 55); let radius: CGFloat = 52
                var track = Path(); track.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                context.stroke(track, with: .color(AppColors.Health.gaugeTrack), style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                if progress > 0 {
                    var active = Path(); active.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(180 + 180 * Double(progress)), clockwise: false)
                    context.stroke(active, with: .color(AppColors.Health.visualCyan), style: StrokeStyle(lineWidth: 4, lineCap: .butt))
                }
            }.frame(width: 114, height: 58)
            Image(AppImages.Health.recoveryStatus).resizable().scaledToFit().frame(width: 21, height: 30).padding(.top, 20)
            Text(appLocalized(progress >= 0.7 ? "health_visual_recovery_ready" : "health_visual_recovery_low"))
                .font(.system(size: 11)).foregroundStyle(AppColors.Health.cardTitle).frame(maxHeight: .infinity, alignment: .bottom)
        }.frame(width: 114, height: 78)
    }
}

struct AbilityGaugeOverviewView: View {
    let progress: CGFloat
    let accent: Color
    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height - 5)
                let radius = (size.width - 10) * 0.42; let segments = 30
                for index in 0..<segments {
                    let start = 180 + Double(index) * 180 / Double(segments)
                    let end = start + 180 / Double(segments) * 0.68
                    var path = Path()
                    path.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
                    let filled = (Double(index) + 0.5) / Double(segments) <= Double(progress)
                    context.stroke(path, with: .color(filled ? accent : AppColors.Health.gaugeTrack), lineWidth: 3)
                }
                let angle = Double.pi + Double(progress) * Double.pi
                var needle = Path(); needle.move(to: center)
                needle.addLine(to: CGPoint(x: center.x + cos(angle) * radius * 0.78, y: center.y + sin(angle) * radius * 0.78))
                context.stroke(needle, with: .color(AppColors.Health.cardTitle), lineWidth: 1.5)
                context.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)), with: .color(AppColors.Health.cardTitle))
            }.frame(width: 121, height: 60)
            HStack { Text("0"); Spacer(); Text("100") }.font(.system(size: 10)).foregroundStyle(AppColors.Health.muted)
        }.frame(width: 121, height: 71)
    }
}
