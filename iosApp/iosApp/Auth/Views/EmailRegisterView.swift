import SwiftUI

struct EmailRegisterView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var acceptedTerms = false
    @State private var emailInput = ""
    @State private var localError: String?
    @State private var termsPromptAction: TermsPromptAction?
    @State private var showUnavailable = false

    var body: some View {
        AuthBlackPage(onBack: { router.pop() }, showFeedback: true, onUnavailableClick: { showUnavailable = true }) {
            AuthTitle(appLocalized("auth_email_register"))
            Spacer().frame(height: 60)
            UnderlineInput(
                text: $emailInput,
                placeholder: appLocalized("auth_email_placeholder"),
                keyboardType: .emailAddress,
                autoFocus: true
            )
            Spacer().frame(height: 44)
            AgreementRow(
                accepted: acceptedTerms,
                onToggle: { acceptedTerms.toggle(); localError = nil },
                onPrivacyClick: { router.push(.privacyPolicy) },
                onServiceTermsClick: { router.push(.serviceTerms) }
            )
            Spacer().frame(height: 28)
            CorosFilledButton(
                text: appLocalized("auth_send_code"),
                color: corosButtonRed,
                enabled: canSendEmailCode,
                isLoading: viewModel.state.isLoading,
                action: { requestEmailVerifyCode() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Button(action: {
                viewModel.updateAccount("")
                router.replaceTop(.phoneRegister)
            }) {
                Text(appLocalized("auth_phone_register")).foregroundStyle(corosRed).font(.system(size: 18))
                    .frame(maxWidth: .infinity).padding(.top, 26)
            }.buttonStyle(.plain)
            Spacer(minLength: 80)
        }
        .overlay {
            if termsPromptAction != nil {
                TermsConsentSheet(
                    onDismiss: { termsPromptAction = nil },
                    onPrivacyClick: { router.push(.privacyPolicy) },
                    onServiceTermsClick: { router.push(.serviceTerms) },
                    onAgree: {
                        acceptedTerms = true
                        termsPromptAction = nil
                        requestEmailVerifyCode(skipTerms: true)
                    }
                )
            }
            if showUnavailable { UnavailableFeatureDialog(onDismiss: { showUnavailable = false }) }
        }
    }

    private var canSendEmailCode: Bool {
        let email = viewModel.normalizeEmailInput(emailInput)
        return email.contains("@") && email.contains(".") && !viewModel.state.isLoading
    }

    private func requestEmailVerifyCode(skipTerms: Bool = false) {
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .emailCode
            return
        }
        let email = viewModel.normalizeEmailInput(emailInput)
        if viewModel.hasAccount(email) {
            localError = appLocalized("auth_error_account_exists")
            return
        }
        let message = viewModel.requestEmailVerifyCode(email: email)
        if message == nil || message?.isEmpty == true {
            viewModel.updateAccount(email)
            viewModel.updateDisplayName(email)
            router.push(.verifyCode(account: email, targetKind: .email))
        } else {
            localError = message
        }
    }
}
 
 #Preview {
     EmailRegisterView(
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
