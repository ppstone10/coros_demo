import SwiftUI

struct ResetPasswordView: View {
    let account: String
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var localError: String?

    var body: some View {
        AuthBlackPage(onBack: { router.pop() }, showFeedback: false) {
            AuthTitle(appLocalized("auth_set_new_password"))
            Spacer().frame(height: 42)
            Text(appLocalized("auth_account"))
                .foregroundStyle(AppColors.Auth.inputText)
                .font(.system(size: 14))
            Spacer().frame(height: 8)
            DisabledUnderlineValue(value: account, placeholder: appLocalized("auth_account"))
            Spacer().frame(height: 42)
            UnderlineInput(
                text: Binding(
                    get: { newPassword },
                    set: { newPassword = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: appLocalized("auth_new_password_placeholder"),
                isPassword: true,
                autoFocus: true
            )
            Spacer().frame(height: 42)
            UnderlineInput(
                text: Binding(
                    get: { confirmPassword },
                    set: { confirmPassword = viewModel.normalizePasswordInput($0); localError = nil }
                ),
                placeholder: appLocalized("auth_confirm_new_password_placeholder"),
                isPassword: true
            )
            Spacer().frame(height: 8)
            Text(appLocalized("auth_password_rule"))
                .foregroundStyle(AppColors.Auth.inputText)
                .font(.system(size: 14))
            Spacer().frame(height: 72)
            CorosFilledButton(
                text: appLocalized("common_complete"),
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
        router.resetKeepingEntranceAndPush(.login)
        viewModel.toastMessage = appLocalized("auth_password_updated")
    }
}
 
 #Preview {
     ResetPasswordView(
         account: "user@example.com",
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
