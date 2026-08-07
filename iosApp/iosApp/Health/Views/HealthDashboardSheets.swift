import SwiftUI

struct HealthWeightPickerSheet: View {
    let current: Double
    let onConfirm: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var weightTenths = 600

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(appLocalized("common_cancel")) { dismiss() }
                Spacer()
                Text(appLocalized("profile_weight_picker")).font(.system(size: 19, weight: .semibold))
                Spacer()
                Button(appLocalized("common_confirm")) {
                    onConfirm(Double(weightTenths) / 10.0)
                    dismiss()
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 58)
            Picker("", selection: $weightTenths) {
                ForEach(300...2000, id: \.self) {
                    Text(String(format: "%.1f", Double($0) / 10.0))
                }
            }
            .pickerStyle(.wheel)
            .colorScheme(.dark)
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .background(AppColors.Account.sheet.ignoresSafeArea())
        .onAppear { weightTenths = Int((current * 10.0).rounded()).clamped(to: 300...2000) }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview("Weight picker") {
    HealthWeightPickerSheet(current: 60, onConfirm: { _ in })
}
