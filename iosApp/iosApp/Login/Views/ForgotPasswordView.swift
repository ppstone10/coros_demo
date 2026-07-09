import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var account = ""
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: { router.pop() }, showFeedback: false) {
            AuthTitle("找回密码")
            Spacer().frame(height: 60)
            UnderlineInput(
                text: Binding(
                    get: { account },
                    set: { account = $0.trimmingCharacters(in: .whitespacesAndNewlines); localError = nil }
                ),
                placeholder: "输入手机号或邮箱",
                keyboardType: .emailAddress,
                autoFocus: true
            )
            Spacer().frame(height: 72)
            CorosFilledButton(
                text: "下一步",
                color: corosButtonRed,
                enabled: !account.isEmpty,
                action: verifyAccount
            )
            ErrorText(localError)
            Spacer(minLength: 80)
        }
    }

    private func verifyAccount() {
        let rawAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEmail = rawAccount.contains("@")
        let normalizedAccount = isEmail ? viewModel.normalizeEmailInput(rawAccount) : rawAccount
        let validationMessage: String?
        if isEmail {
            validationMessage = viewModel.validateEmailAccount(normalizedAccount)
        } else if rawAccount != viewModel.normalizePhoneInput(rawAccount) {
            validationMessage = "请输入11位手机号"
        } else {
            validationMessage = viewModel.validatePhoneAccount(normalizedAccount)
        }

        if let validationMessage {
            localError = validationMessage
            return
        }
        guard viewModel.hasAccount(normalizedAccount) else {
            localError = "账号不存在"
            return
        }
        router.push(.resetPassword(account: normalizedAccount))
    }
}
