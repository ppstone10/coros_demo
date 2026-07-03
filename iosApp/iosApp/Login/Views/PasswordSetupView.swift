import SwiftUI

struct PasswordSetupView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: { path.removeLast() }, showFeedback: false) {
            AuthTitle("设置登录密码")
            Spacer().frame(height: 60)
            UnderlineInput(
                text: $password,
                placeholder: "输入新的密码",
                isPassword: true,
                autoFocus: true
            )
            Spacer().frame(height: 48)
            UnderlineInput(
                text: $confirmPassword,
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
        password.count >= 6 && password.count <= 20 &&
        password.rangeOfCharacter(from: .letters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil &&
        password == confirmPassword && !viewModel.state.isLoading
    }

    private func register() {
        if password.count < 6 || password.count > 20 {
            localError = "密码需要为6-20位"; return
        }
        if password.rangeOfCharacter(from: .letters) == nil || password.rangeOfCharacter(from: .decimalDigits) == nil {
            localError = "密码需要包含字母和数字"; return
        }
        if password != confirmPassword {
            localError = "两次输入的密码不一致"; return
        }
        viewModel.requestRegisterMode()
        viewModel.updatePassword(password)
        viewModel.submit()
    }
}
