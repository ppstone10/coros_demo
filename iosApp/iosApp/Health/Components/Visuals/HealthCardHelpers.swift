import SwiftUI
import Shared

func valueText(_ text: String?, _ size: CGFloat) -> some View {
    Text(text ?? "--").font(.custom("COROS-APP-Bold", size: size)).foregroundStyle(.white).lineLimit(1)
}

@ViewBuilder func unitText(_ spec: LocalizedTextSpec?, size: CGFloat = 16) -> some View {
    if let spec { Text(localizedHealthText(spec)).font(.custom("COROS-APP-Bold", size: size)).foregroundStyle(AppColors.Health.metricUnit).lineLimit(1) }
}

@ViewBuilder func captionText(_ spec: LocalizedTextSpec?, size: CGFloat = 12) -> some View {
    if let spec { Text(localizedHealthText(spec)).font(.system(size: size)).foregroundStyle(AppColors.Health.muted).lineLimit(2) }
}

func metricView(_ m: HealthMetric, accent: Color = .white, valueSize: CGFloat = 30) -> some View {
    VStack(alignment: .leading, spacing: 1) {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text(m.value).font(.custom("COROS-APP-Bold", size: valueSize)).foregroundStyle(accent)
            unitText(m.unit)
        }
        Text(localizedHealthText(m.label)).font(.system(size: 12)).foregroundStyle(AppColors.Health.muted)
    }
}

func barColor(_ name: String) -> Color {
    name == "High" ? AppColors.Health.warning : name == "Elevated" ? AppColors.Health.visualOrange : name == "Good" ? AppColors.Health.visualYellow : AppColors.Health.visualBar
}

func stageOffset(_ name: String) -> CGFloat {
    name == "Awake" ? 0 : name == "Rem" ? 16 : name == "Deep" ? 48 : 32
}

func stageColor(_ name: String) -> Color {
    name == "Awake" ? AppColors.Health.visualOrange : name == "Rem" ? AppColors.Health.visualPurple : name == "Deep" ? AppColors.Health.visualDeepBlue : AppColors.Health.visualBlue
}
