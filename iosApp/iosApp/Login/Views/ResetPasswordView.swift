import SwiftUI

struct ResetPasswordView: View {
    let account: String
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: { path.removeLast() }, showFeedback: false) {
            AuthTitle("设置新密码")
            Spacer().frame(height: 42)
            Text("账号")
                .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .font(.system(size: 14))
            Spacer().frame(height: 8)
            DisabledUnderlineValue(value: account, placeholder: "账号")
            Spacer().frame(height: 42)
            UnderlineInput(
                text: Binding(
                    get: { newPassword },
                    set: { newPassword = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: "输入新的密码",
                isPassword: true,
                autoFocus: true
            )
            Spacer().frame(height: 42)
            UnderlineInput(
                text: Binding(
                    get: { confirmPassword },
                    set: { confirmPassword = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: "再次输入新密码",
                isPassword: true
            )
            Spacer().frame(height: 8)
            Text("6-20位，必须包含字母和数字")
                .foregroundStyle(Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255))
                .font(.system(size: 14))
            Spacer().frame(height: 72)
            CorosFilledButton(
                text: "完成",
                color: corosButtonRed,
                enabled: viewModel.canSubmitResetPassword(newPassword: newPassword, confirmPassword: confirmPassword),
                action: resetPassword
            )
            ErrorText(localError)
            Spacer(minLength: 80)
        }
    }

    private func resetPassword() {
        if let message = viewModel.validateRegisterPassword(password: newPassword, confirmPassword: confirmPassword) {
            localError = message
            return
        }
        if let message = viewModel.resetPasswordMessage(account: account, newPassword: newPassword) {
            localError = message
            return
        }
        path = NavigationPath()
        path.append(AuthRoute.login)
        viewModel.toastMessage = "密码已更新"
    }
}

