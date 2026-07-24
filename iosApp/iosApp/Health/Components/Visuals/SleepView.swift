import SwiftUI
import Shared

struct SleepView: View {
    let visual: HealthCardVisualData
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    valueText(visual.primaryValue, 32); unitText(visual.primaryUnit, size: 20)
                    valueText(visual.secondaryValue, 32); unitText(visual.secondaryUnit, size: 20)
                }
                Text("\(visual.startTime ?? "--") – \(visual.endTime ?? "--")").font(.system(size: 12)).foregroundStyle(AppColors.Health.muted)
            }
            .padding(.top, 8).frame(width: 141, alignment: .leading).frame(minHeight: 60, alignment: .leading)
            Spacer()
            SleepStageOverviewView(stages: visual.sleepStages).frame(width: 130, height: 56).clipped()
        }.frame(minHeight: 60)
    }
}

struct SleepStageOverviewView: View {
    let stages: [SleepStageSegment]
    var body: some View {
        Canvas { context, size in
            let total = max(1, stages.map { Int($0.startMinute + $0.durationMinutes) }.max() ?? 1)
            for stage in stages {
                let x = size.width * CGFloat(stage.startMinute) / CGFloat(total)
                let width = max(2, size.width * CGFloat(stage.durationMinutes) / CGFloat(total) - 2)
                let name = stage.stage.name
                let y: CGFloat = stageOffset(name)
                let color: Color = stageColor(name)
                context.fill(Path(roundedRect: CGRect(x: x, y: y, width: width, height: 7), cornerRadius: 2), with: .color(color))
            }
        }
    }
}
