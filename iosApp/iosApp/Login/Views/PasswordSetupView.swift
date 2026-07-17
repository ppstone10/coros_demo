import SwiftUI

struct PasswordSetupView: View {
    let targetKind: VerifyTargetKind
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?
    @State private var selectedRegion = "CN"
    @State private var showsRegionPicker = false

    var body: some View {
        AuthBlackPage(onBack: { backToRegisterPage() }, showFeedback: false) {
            AuthTitle(appLocalized("auth_set_login_password"))
            Spacer().frame(height: 60)
            UnderlineInput(
                text: Binding(
                    get: { password },
                    set: { password = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: appLocalized("auth_new_password_placeholder"),
                isPassword: true,
                autoFocus: true
            )
            Spacer().frame(height: 48)
            UnderlineInput(
                text: Binding(
                    get: { confirmPassword },
                    set: { confirmPassword = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: appLocalized("auth_confirm_password_placeholder"),
                isPassword: true
            )
            Spacer().frame(height: 8)
            Text(appLocalized("auth_password_rule"))
                .foregroundStyle(AppColors.Auth.inputText)
                .font(.system(size: 14))
            Spacer().frame(height: 12)
            Button(action: { showsRegionPicker = true }) {
                HStack(spacing: 12) {
                    Text(appLocalized("profile_country_region"))
                        .foregroundStyle(.white)
                        .font(.system(size: 19))
                    Spacer(minLength: 16)
                    Text(selectedRegion.countryRegionName)
                        .foregroundStyle(AppColors.Auth.primaryText)
                        .font(.system(size: 19))
                    Image("right_more")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(height: 66)
                .overlay(alignment: .bottom) { Rectangle().fill(corosLine).frame(height: 1) }
            }
            .buttonStyle(.plain)
            Spacer().frame(height: 44)
            CorosFilledButton(
                text: appLocalized("auth_register"),
                color: corosButtonRed,
                enabled: canRegister,
                isLoading: viewModel.state.isLoading,
                action: { register() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Spacer(minLength: 80)
        }
        .onAppear { selectedRegion = viewModel.state.selectedRegion }
        .sheet(isPresented: $showsRegionPicker) {
            RegistrationRegionPicker(region: $selectedRegion)
                .presentationDetents([.height(350)])
                .presentationCornerRadius(14)
        }
    }

    private var canRegister: Bool {
        viewModel.canRegisterWithPassword(password: password, confirmPassword: confirmPassword)
    }

    private func register() {
        if let message = viewModel.validateRegisterPassword(password: password, confirmPassword: confirmPassword) {
            localError = message
            return
        }
        if password != confirmPassword {
            localError = appLocalized("auth_validation_password_mismatch"); return
        }
        viewModel.requestRegisterMode()
        viewModel.updateRegion(selectedRegion)
        viewModel.updatePassword(password)
        viewModel.submit()
    }

    private func backToRegisterPage() {
        viewModel.updateVerifyCode("")
        router.resetKeepingEntranceAndPush(targetKind == .email ? .emailRegister : .phoneRegister)
    }
}

private struct RegistrationRegionPicker: View {
    @Binding var region: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRegion = "CN"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image("ic_profile_close")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(appLocalized("profile_country_region")).foregroundStyle(.white).font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: {
                    region = selectedRegion
                    dismiss()
                }) {
                    Image("ic_profile_check")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 58)
            .padding(.horizontal, 20)

            Picker("", selection: $selectedRegion) {
                Text(appLocalized("common_china")).tag("CN")
                Text(appLocalized("common_united_states")).tag("US")
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
        }
        .background(AppColors.Auth.sheet.ignoresSafeArea())
        .onAppear { selectedRegion = region }
    }
}

private extension String {
    var countryRegionName: String {
        countryDisplayName(self)
    }
}
