import SwiftUI

struct ScenarioPickerView: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    let onOpenNormalDataEditor: () -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.scenarios, id: \.code) { scenario in
                    ScenarioRow(
                        name: scenario.code,
                        displayKey: scenario.displayKey,
                        viewModel: viewModel,
                        dismiss: dismiss,
                        onOpenNormalDataEditor: onOpenNormalDataEditor
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
    let onOpenNormalDataEditor: () -> Void
    var body: some View {
        Button(action: {
            viewModel.selectScenario(name)
            dismiss()
            if name == "Normal" {
                onOpenNormalDataEditor()
            }
        }) {
            HStack {
                Text(appLocalized(displayKey)).foregroundColor(.white); Spacer()
                if viewModel.selectedScenario == name { Image(systemName: "checkmark").foregroundColor(AppColors.Health.steps) }
            }
        }.listRowBackground(AppColors.Health.card)
    }
}

#Preview {
    ScenarioPickerView(
        viewModel: HealthDashboardViewModel(),
        onOpenNormalDataEditor: {}
    )
        .preferredColorScheme(.dark)
}
