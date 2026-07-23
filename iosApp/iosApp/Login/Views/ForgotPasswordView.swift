import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var account = ""
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: { router.pop() }, showFeedback: false) {
            AuthTitle(appLocalized("auth_find_password"))
            Spacer().frame(height: 60)
            UnderlineInput(
                text: Binding(
                    get: { account },
                    set: { account = $0.trimmingCharacters(in: .whitespacesAndNewlines); localError = nil }
                ),
                placeholder: appLocalized("auth_account_placeholder"),
                keyboardType: .emailAddress,
                autoFocus: true
            )
            Spacer().frame(height: 72)
            CorosFilledButton(
                text: appLocalized("auth_next_step"),
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
            validationMessage = appLocalized("auth_validation_phone_invalid")
        } else {
            validationMessage = viewModel.validatePhoneAccount(normalizedAccount)
        }

        if let validationMessage {
            localError = validationMessage
            return
        }
        guard viewModel.hasAccount(normalizedAccount) else {
            localError = appLocalized("auth_error_account_not_found")
            return
        }
        router.push(.resetPassword(account: normalizedAccount))
    }
}
 
 #Preview {
     ForgotPasswordView(
         viewModel: LoginViewModel(),
         router: AuthRouter(
             push: { _ in },
             pop: {},
             replaceTop: { _ in },
             resetTo: { _ in },
             resetKeepingEntranceAndPush: { _ in }
         )
     )
     .preferredColorScheme(.dark)
 }
