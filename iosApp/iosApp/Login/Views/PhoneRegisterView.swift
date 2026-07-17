import SwiftUI

struct PhoneRegisterView: View {
    @ObservedObject var viewModel: LoginViewModel
    let router: AuthRouter

    @State private var acceptedTerms = false
    @State private var localError: String?
    @State private var termsPromptAction: TermsPromptAction?
    @State private var showUnavailable = false

    var body: some View {
        AuthBlackPage(onBack: { router.pop() }, showFeedback: true, onUnavailableClick: { showUnavailable = true }) {
            AuthTitle(appLocalized("auth_phone_register"))
            Spacer().frame(height: 60)
            PhoneInput(
                text: Binding(get: { viewModel.state.account }, set: { viewModel.updatePhone($0) }),
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
                enabled: canSendPhoneCode,
                isLoading: viewModel.state.isLoading,
                action: { requestPhoneVerifyCode() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Button(action: {
                viewModel.updateAccount("")
                router.replaceTop(.emailRegister)
            }) {
                Text(appLocalized("auth_email_register")).foregroundStyle(corosRed).font(.system(size: 18))
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
                        requestPhoneVerifyCode(skipTerms: true)
                    }
                )
            }
            if showUnavailable { UnavailableFeatureDialog(onDismiss: { showUnavailable = false }) }
        }
    }

    private var canSendPhoneCode: Bool {
        let account = viewModel.normalizePhoneInput(viewModel.state.account)
        return account.count == 11 && !viewModel.state.isLoading
    }

    private func requestPhoneVerifyCode(skipTerms: Bool = false) {
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .phoneCode
            return
        }
        let account = viewModel.normalizePhoneInput(viewModel.state.account)
        if viewModel.hasAccount(account) {
            localError = appLocalized("auth_error_account_exists")
            return
        }
        let message = viewModel.requestPhoneVerifyCode()
        if message == nil || message?.isEmpty == true {
            viewModel.updateDisplayName(account)
            router.push(.verifyCode(account: account, targetKind: .phone))
        } else {
            localError = message
        }
    }
}
