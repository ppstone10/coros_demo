import SwiftUI

struct PasswordSetupView: View {
    let targetKind: VerifyTargetKind
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: { backToRegisterPage() }, showFeedback: false) {
            AuthTitle("设置登录密码")
            Spacer().frame(height: 60)
            UnderlineInput(
                text: Binding(
                    get: { password },
                    set: { password = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: "输入新的密码",
                isPassword: true,
                autoFocus: true
            )
            Spacer().frame(height: 48)
            UnderlineInput(
                text: Binding(
                    get: { confirmPassword },
                    set: { confirmPassword = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: "再次输入密码",
                isPassword: true
            )
            Spacer().frame(height: 8)
            Text("6-20位必须包含字母和数字")
                .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .font(.system(size: 14))
            Spacer().frame(height: 80)
            CorosFilledButton(
                text: "注册",
                color: corosButtonRed,
                enabled: canRegister,
                isLoading: viewModel.state.isLoading,
                action: { register() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Spacer(minLength: 80)
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
            localError = "两次输入的密码不一致"; return
        }
        viewModel.requestRegisterMode()
        viewModel.updatePassword(password)
        viewModel.submit()
    }

    private func backToRegisterPage() {
        viewModel.updateVerifyCode("")
        router.resetKeepingEntranceAndPush(targetKind == .email ? .emailRegister : .phoneRegister)
    }
}
