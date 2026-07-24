import SwiftUI
import Shared

struct TrendView: View {
    let cardType: String
    let visual: HealthCardVisualData
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 2) { valueText(visual.primaryValue, 32); unitText(visual.primaryUnit, size: 20) }
                captionText(visual.caption, size: 12)
            }
            .padding(.top, 8)
            .frame(width: 141, alignment: .leading)
            .frame(minHeight: 60, alignment: .leading)
            Spacer()
            if cardType == "HeartRate" {
                HeartRateIntervalOverviewView(points: visual.chartPoints).frame(width: 166, height: 44).clipped()
            } else {
                StressOverviewView(points: visual.chartPoints).frame(width: 166, height: 56).clipped()
            }
        }
        .frame(minHeight: 60)
    }
}

struct HeartRateIntervalOverviewView: View {
    let points: [HealthChartPoint]
    var body: some View {
        Canvas { context, size in
            guard !points.isEmpty else { return }
            let chartMinimum = points.map { $0.minimum?.doubleValue ?? $0.value }.min() ?? 0
            let chartMaximum = points.map { $0.maximum?.doubleValue ?? $0.value }.max() ?? 1
            let span = max(1, chartMaximum - chartMinimum)
            let verticalPadding: CGFloat = 3; let drawableHeight = max(1, size.height - verticalPadding * 2)
            let denominator = max(1, points.count - 1)
            for (index, point) in points.enumerated() {
                let minV = point.minimum?.doubleValue ?? point.value; let maxV = point.maximum?.doubleValue ?? point.value
                let x = CGFloat(index) / CGFloat(denominator) * size.width
                let highY = verticalPadding + drawableHeight * CGFloat(1 - (maxV - chartMinimum) / span)
                let lowY = max(highY + 1, verticalPadding + drawableHeight * CGFloat(1 - (minV - chartMinimum) / span))
                var path = Path(); path.move(to: CGPoint(x: x, y: highY)); path.addLine(to: CGPoint(x: x, y: lowY))
                context.stroke(path, with: .color(AppColors.Health.visualPink), lineWidth: 1)
            }
        }
    }
}

struct StressOverviewView: View {
    let points: [HealthChartPoint]
    var body: some View {
        Canvas { context, size in
            guard !points.isEmpty else { return }
            let values = points.map(\.value); let high = max(100, values.max() ?? 100)
            let step: CGFloat = 2; let count = max(2, Int(size.width / step))
            for index in 0..<count {
                let chartPosition = Double(index) / Double(count - 1) * Double(values.count - 1)
                let leftIndex = min(values.count - 1, max(0, Int(chartPosition)))
                let rightIndex = min(values.count - 1, leftIndex + 1)
                let fraction = chartPosition - Double(leftIndex)
                let interpolated = values[leftIndex] + (values[rightIndex] - values[leftIndex]) * fraction
                let h = max(2, size.height * CGFloat(interpolated / high))
                let color: Color = interpolated >= 80 ? AppColors.Health.visualOrange : interpolated >= 60 ? AppColors.Health.visualYellow : interpolated >= 35 ? AppColors.Health.stressGood : AppColors.Health.stressLow
                var path = Path()
                path.move(to: CGPoint(x: CGFloat(index) * step, y: size.height))
                path.addLine(to: CGPoint(x: CGFloat(index) * step, y: size.height - h))
                context.stroke(path, with: .color(color), lineWidth: 1)
            }
        }
    }
}
