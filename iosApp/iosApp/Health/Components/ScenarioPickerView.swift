import SwiftUI

struct ScenarioPickerView: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                ScenarioRow(name: "Normal", displayKey: "health_scenario_normal", viewModel: viewModel, dismiss: dismiss)
                ScenarioRow(name: "PartialMissing", displayKey: "health_scenario_partial_missing", viewModel: viewModel, dismiss: dismiss)
                ScenarioRow(name: "AllEmpty", displayKey: "health_scenario_all_empty", viewModel: viewModel, dismiss: dismiss)
                ScenarioRow(name: "Abnormal", displayKey: "health_scenario_abnormal", viewModel: viewModel, dismiss: dismiss)
                ScenarioRow(name: "ReadFailure", displayKey: "health_scenario_read_failure", viewModel: viewModel, dismiss: dismiss)
            }
            .scrollContentBackground(.hidden).background(AppColors.Core.black)
            .navigationTitle(appLocalized("health_select_scenario")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(appLocalized("common_cancel")) { dismiss() } } }
        }
    }
}

private struct ScenarioRow: View {
    let name: String; let displayKey: String
    @ObservedObject var viewModel: HealthDashboardViewModel
    let dismiss: DismissAction
    var body: some View {
        Button(action: { viewModel.selectScenario(name); dismiss() }) {
            HStack {
                Text(appLocalized(displayKey)).foregroundColor(.white); Spacer()
                if viewModel.selectedScenario == name { Image(systemName: "checkmark").foregroundColor(AppColors.Health.steps) }
            }
        }.listRowBackground(AppColors.Health.card)
    }
}
