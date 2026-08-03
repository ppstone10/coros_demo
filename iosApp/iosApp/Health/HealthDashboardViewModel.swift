import Foundation
import Shared

struct NormalEditValidationIssue: Decodable {
    let fieldId: String
    let labelKey: String
    let labelArguments: [String]
    let reason: String
    let reasonArguments: [String]
}

struct NormalEditSaveResult: Decodable {
    let success: Bool
    let issue: NormalEditValidationIssue?
}

enum AccountRefreshPhase: Equatable {
    case idle
    case refreshing
    case resetting
}

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
    @Published private(set) var scenarios: [HealthScenarioDescriptor] = []
    @Published private(set) var editNotice: (id: Int, messageKey: String)?
    @Published private(set) var accountRefreshPending = false
    @Published private(set) var accountRefreshPhase: AccountRefreshPhase = .idle
    private var editNoticeSequence = 0
    private var accountRefreshTask: Task<Void, Never>?

    var onEffect: ((HealthEffect) -> Void)?

    private let adapter: SharedLoginAdapterProtocol

    init(adapter: SharedLoginAdapterProtocol = SharedLoginAdapter()) {
        self.adapter = adapter
        self.scenarios = adapter.healthScenarioDescriptors()
    }

    func load() {
        adapter.loadHealth()
        apply(adapter.healthState())
        if let effect = adapter.consumeHealthEffect() {
            onEffect?(effect)
        }
    }

    func staleForNewAccount(shouldRefreshOnDashboard: Bool) {
        accountRefreshTask?.cancel()
        accountRefreshTask = nil
        accountRefreshPhase = .idle
        adapter.staleHealthForNewAccount()
        apply(adapter.healthState())
        accountRefreshPending = shouldRefreshOnDashboard
    }

    func startPendingAccountRefresh() {
        guard accountRefreshPending, accountRefreshPhase == .idle, !isLoading else { return }
        accountRefreshPending = false
        accountRefreshPhase = .refreshing
        accountRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let refreshed = await self.refresh()
            guard !Task.isCancelled else { return }
            guard refreshed else {
                self.accountRefreshPhase = .idle
                self.accountRefreshTask = nil
                self.accountRefreshPending = true
                return
            }
            self.accountRefreshPhase = .resetting
            do {
                try await Task.sleep(
                    nanoseconds: HealthPullRefreshConfiguration.settleDurationNanoseconds
                )
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self.accountRefreshPhase = .idle
            self.accountRefreshTask = nil
        }
    }

    func selectScenario(_ name: String) {
        if adapter.selectHealthScenario(name) {
            selectedScenario = name
        }
    }

    func saveCardConfiguration(_ typeIDs: [String]) {
        if let error = adapter.saveHealthCardConfiguration(typeIDs) {
            // Error message returned directly; relay via callback.
            // HealthEffect construction from Swift is not needed here.
            return
        }
        load()
    }

    func saveBodyWeight(_ weightKg: Double) {
        guard adapter.saveHealthBodyWeight(weightKg) == nil else { return }
        apply(adapter.healthState())
    }

    var editableSections: [String] {
        adapter.healthEditableSectionNames()
    }

    func normalEditFormJson(_ section: String) -> String? {
        adapter.normalHealthEditFormJson(section)
    }

    func defaultNormalEditFormJson(_ section: String) -> String? {
        adapter.defaultNormalHealthEditFormJson(section)
    }

    func mutateNormalEditFormJson(
        _ section: String,
        valuesSpec: String,
        groupID: String,
        operation: String,
        rowIndex: Int = -1
    ) -> String? {
        adapter.mutateNormalHealthEditFormJson(
            section,
            valuesSpec: valuesSpec,
            groupID: groupID,
            operation: operation,
            rowIndex: rowIndex
        )
    }

    func saveNormalEditForm(_ section: String, valuesSpec: String) -> NormalEditSaveResult {
        let json = adapter.saveNormalHealthEditFormResultJson(section, valuesSpec: valuesSpec)
        let result = json.data(using: .utf8).flatMap {
            try? JSONDecoder().decode(NormalEditSaveResult.self, from: $0)
        } ?? NormalEditSaveResult(success: false, issue: nil)
        if result.success {
            editNoticeSequence += 1
            editNotice = (editNoticeSequence, "health_edit_saved_refresh")
        }
        return result
    }

    func restoreAllNormalDefaults() {
        guard adapter.restoreAllNormalHealthDefaults() else { return }
        editNoticeSequence += 1
        editNotice = (editNoticeSequence, "health_edit_defaults_refresh")
    }

    func clearEditNotice(id: Int) {
        if editNotice?.id == id {
            editNotice = nil
        }
    }

    @discardableResult
    func refresh() async -> Bool {
        guard !isLoading else { return false }
        syncCycle += 1
        isLoading = true
        do {
            try await Task.sleep(
                nanoseconds: HealthPullRefreshConfiguration.syncingDurationNanoseconds
            )
        } catch {
            isLoading = false
            return false
        }
        guard !Task.isCancelled else {
            isLoading = false
            return false
        }
        adapter.refreshHealth()
        apply(adapter.healthState())
        if let effect = adapter.consumeHealthEffect() {
            onEffect?(effect)
        }
        isLoading = false
        return true
    }

    private func apply(_ state: HealthState?) {
        guard let state = state else {
            isDataCorrupted = true
            return
        }
        if let error = state.error {
            if error.name == "CorruptedData" || error.name == "AuthRequired" {
                isDataCorrupted = true
                return
            }
        }
        guard let uiState = state.uiState else {
            isDataCorrupted = true
            return
        }
        isDataCorrupted = false
        dateLabel = localizedHealthText(uiState.dateLabel)
        selectedScenario = state.currentScenario.name
        if let ds = uiState.dailySummary {
            steps = ds.steps?.intValue ?? 0
            calories = ds.calories?.intValue ?? 0
            activeMinutes = ds.activeMinutes?.intValue ?? 0
        } else {
            steps = 0
            calories = 0
            activeMinutes = 0
        }
        cards = uiState.cards.map { c in
            HealthCard(id: c.type.name, title: localizedHealthText(c.title),
                       summary: localizedHealthText(c.summary),
                       icon: iconForCardType(c.type.name), isRisk: c.status.name == "Risk",
                       status: c.status.name, visual: c.visual)
        }
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
