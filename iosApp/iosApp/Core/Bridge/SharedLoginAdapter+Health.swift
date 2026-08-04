import Foundation
import Shared

// MARK: - Health 桥接（按域拆分；healthFacade 为 internal，见 SharedLoginAdapter）

extension SharedLoginAdapter {
    func healthState() -> HealthState? {
        healthFacade.state
    }

    func loadHealth() {
        healthFacade.load()
    }

    func staleHealthForNewAccount() {
        healthFacade.staleForNewAccount()
    }

    func selectHealthScenario(_ name: String) -> Bool {
        healthFacade.selectScenario(name: name)
    }

    func refreshHealth() {
        healthFacade.refresh()
    }

    func saveHealthCardConfiguration(_ typeNames: [String]) -> String? {
        healthFacade.saveCardConfiguration(typeNames: typeNames)
    }

    func saveHealthBodyWeight(_ weightKg: Double) -> String? {
        healthFacade.saveBodyWeight(weightKg: weightKg)
    }

    func consumeHealthEffect() -> HealthEffect? {
        healthFacade.consumeEffect()
    }

    func healthScenarioDescriptors() -> [HealthScenarioDescriptor] {
        healthFacade.scenarioDescriptors()
    }

    func healthEditableSectionNames() -> [String] {
        healthFacade.editableSectionNames()
    }

    func normalHealthEditFormJson(_ section: String) -> String? {
        healthFacade.normalEditFormJson(sectionName: section)
    }

    func defaultNormalHealthEditFormJson(_ section: String) -> String? {
        healthFacade.defaultNormalEditFormJson(sectionName: section)
    }

    func mutateNormalHealthEditFormJson(
        _ section: String,
        valuesSpec: String,
        groupID: String,
        operation: String,
        rowIndex: Int
    ) -> String? {
        healthFacade.mutateNormalEditFormJson(
            sectionName: section,
            valuesSpec: valuesSpec,
            groupId: groupID,
            operationName: operation,
            rowIndex: Int32(rowIndex)
        )
    }

    func saveNormalHealthEditForm(_ section: String, valuesSpec: String) -> Bool {
        healthFacade.saveNormalEditForm(sectionName: section, valuesSpec: valuesSpec)
    }

    func saveNormalHealthEditFormResultJson(_ section: String, valuesSpec: String) -> String {
        healthFacade.saveNormalEditFormResultJson(sectionName: section, valuesSpec: valuesSpec)
    }

    func restoreAllNormalHealthDefaults() -> Bool {
        healthFacade.restoreAllNormalDefaults()
    }
}
