import Foundation
import Shared

@MainActor
final class HealthDashboardViewModel: ObservableObject {
    @Published private(set) var cards: [HealthCard] = []
    @Published private(set) var dateLabel = appLocalized("health_demo_date")
    @Published private(set) var steps = 8769
    @Published private(set) var calories = 769
    @Published private(set) var activeMinutes = 69
    @Published private(set) var isLoading = false
    @Published private(set) var syncCycle = 0
    @Published private(set) var isDataCorrupted = false
    @Published private(set) var selectedScenario = "Normal"

    private let adapter: SharedLoginAdapterProtocol

    init(adapter: SharedLoginAdapterProtocol = SharedLoginAdapter()) {
        self.adapter = adapter
        load()
    }

    func load() {
        if let pd = adapter.loadHealthDashboard() {
            apply(pd)
        } else {
            isDataCorrupted = adapter.healthDashboardError() == "CorruptedData"
        }
    }

    private func apply(_ pd: PersistedDashboard) {
        isDataCorrupted = false
        dateLabel = localizedHealthText(pd.uiState.dateLabel)
        selectedScenario = pd.scenario.name
        if let ds = pd.uiState.dailySummary {
            steps = ds.steps?.intValue ?? 0
            calories = ds.calories?.intValue ?? 0
            activeMinutes = ds.activeMinutes?.intValue ?? 0
        }
        cards = pd.uiState.cards.map { c in
            HealthCard(id: c.type.name, title: localizedHealthText(c.title),
                       summary: localizedHealthText(c.summary),
                       icon: iconForCardType(c.type.name), isRisk: c.status.name == "Risk",
                       status: c.status.name, visual: c.visual)
        }
    }

    func selectScenario(_ name: String) {
        if adapter.selectHealthScenario(name) {
            selectedScenario = name
        }
    }

    func saveCardConfiguration(_ typeIDs: [String]) -> String? {
        let result = adapter.saveHealthCardConfiguration(typeIDs)
        if result == nil { return adapter.healthCardSaveError() }
        load(); return nil
    }

    func refresh() async {
        guard !isLoading else { return }
        syncCycle += 1
        isLoading = true
        try? await Task.sleep(nanoseconds: 4_460_000_000)
        if let refreshed = adapter.refreshHealthDashboard() {
            apply(refreshed)
        } else {
            isDataCorrupted = adapter.healthDashboardError() == "CorruptedData"
        }
        isLoading = false
    }
}

func localizedHealthText(_ spec: LocalizedTextSpec) -> String {
    let format = appLocalized(spec.key)
    let arguments: [CVarArg] = spec.arguments.map { $0 as NSString }
    return String(format: format, arguments: arguments)
}

func iconForCardType(_ name: String) -> String {
    switch name {
    case "TodayActivity": return AppImages.Health.todayActivity
    case "WeeklyPlan": return AppImages.Health.weeklyPlan
    case "TrainingLoad": return AppImages.Health.trainingLoad
    case "TrainingAssessment": return AppImages.Health.trainingAssessment
    case "Recovery": return AppImages.Health.recovery
    case "RunningAbility": return AppImages.Health.runningAbility
    case "CyclingAbility": return AppImages.Health.cyclingAbility
    case "HeartRate": return AppImages.Health.heartRate
    case "Stress": return AppImages.Health.stress
    case "Sleep": return AppImages.Health.sleep
    case "HrvAssessment": return AppImages.Health.hrv
    case "RestingHeartRate": return AppImages.Health.restingHeartRate
    case "HealthCheck": return AppImages.Health.healthCheck
    case "BodyManagement": return AppImages.Health.body
    default: return AppImages.Health.heartRate
    }
}
