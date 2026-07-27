import SwiftUI

struct ScenarioPickerView: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.scenarios, id: \.code) { scenario in
                    ScenarioRow(
                        name: scenario.code,
                        displayKey: scenario.displayKey,
                        viewModel: viewModel,
                        dismiss: dismiss
                    )
                }
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

#Preview {
    ScenarioPickerView(viewModel: HealthDashboardViewModel())
        .preferredColorScheme(.dark)
}
