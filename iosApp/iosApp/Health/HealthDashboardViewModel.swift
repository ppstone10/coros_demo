import Foundation
import Shared

@MainActor
final class HealthDashboardViewModel: ObservableObject {
    @Published private(set) var cards: [HealthCard] = defaultHealthCards
    @Published private(set) var dateLabel = appLocalized("health_demo_date")
    @Published private(set) var steps = 8769
    @Published private(set) var calories = 769
    @Published private(set) var activeMinutes = 69
    @Published private(set) var isLoading = false
    @Published private(set) var selectedScenario = "Normal"

    private let adapter: SharedLoginAdapterProtocol

    init(adapter: SharedLoginAdapterProtocol = SharedLoginAdapter()) {
        self.adapter = adapter
        load()
    }

    func load() {
        guard let pd = adapter.loadHealthDashboard() else { return }
        dateLabel = localizedHealthText(pd.uiState.dateLabel)
        selectedScenario = pd.scenario.name

        if let ds = pd.uiState.dailySummary {
            steps = ds.steps?.intValue ?? 0
            calories = ds.calories?.intValue ?? 0
            activeMinutes = ds.activeMinutes?.intValue ?? 0
        }

        let byID = Dictionary(uniqueKeysWithValues: defaultHealthCards.map { ($0.id, $0) })
        let typeOrder: [String] = pd.enabledCardTypes.map { $0.name }

        var dynamic = [HealthCard]()
        for c in pd.uiState.cards {
            let tn = c.type.name
            let t = byID[tn]
            dynamic.append(HealthCard(
                id: t?.id ?? tn,
                title: localizedHealthText(c.title),
                summary: localizedHealthText(c.summary),
                icon: t?.icon ?? AppImages.Health.heartRate,
                isRisk: c.status.name == "Risk"
            ))
        }

        if typeOrder.count == dynamic.count && !typeOrder.isEmpty {
            var o = [HealthCard]()
            for n in typeOrder {
                if let f = dynamic.first(where: { $0.id == n }) { o.append(f) }
            }
            cards = o
        } else {
            cards = dynamic
        }
    }

    func selectScenario(_ name: String) {
        selectedScenario = name
        _ = adapter.selectHealthScenario(name)
    }

    func saveCardConfiguration(_ typeIDs: [String]) {
        _ = adapter.saveHealthCardConfiguration(typeIDs)
        load()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        try? await Task.sleep(nanoseconds: 4_460_000_000)
        load()
        isLoading = false
    }

    var scenarioNames: [String] { ["Normal", "PartialMissing", "AllEmpty", "Abnormal", "ReadFailure"] }
    var scenarioDisplayNames: [String] {
        ["health_scenario_normal", "health_scenario_partial_missing", "health_scenario_all_empty", "health_scenario_abnormal", "health_scenario_read_failure"]
            .map { appLocalized($0) }
    }
}

private func localizedHealthText(_ spec: LocalizedTextSpec) -> String {
    let format = appLocalized(spec.key)
    let arguments: [CVarArg] = spec.arguments.map { $0 as NSString }
    return String(format: format, arguments: arguments)
}
