import SwiftUI

struct PhoneRegisterView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    @State private var acceptedTerms = false
    @State private var localError: String?
    @State private var termsPromptAction: TermsPromptAction?
    @State private var showUnavailable = false

    var body: some View {
        AuthBlackPage(onBack: { path.removeLast() }, showFeedback: true, onUnavailableClick: { showUnavailable = true }) {
            AuthTitle("手机号注册")
            Spacer().frame(height: 60)
            PhoneInput(
                text: Binding(get: { viewModel.state.account }, set: { viewModel.updatePhone($0) }),
                autoFocus: true
            )
            Spacer().frame(height: 44)
            AgreementRow(
                accepted: acceptedTerms,
                onToggle: { acceptedTerms.toggle(); localError = nil },
                onPrivacyClick: { path.append(AuthRoute.privacyPolicy) },
                onServiceTermsClick: { path.append(AuthRoute.serviceTerms) }
            )
            Spacer().frame(height: 28)
            CorosFilledButton(
                text: "发送验证码",
                color: corosButtonRed,
                enabled: canSendPhoneCode,
                isLoading: viewModel.state.isLoading,
                action: { requestPhoneVerifyCode() }
            )
            ErrorText(localError ?? viewModel.state.errorMessage)
            Button(action: {
                viewModel.updateAccount("")
                path.append(AuthRoute.emailRegister)
            }) {
                Text("邮箱注册").foregroundStyle(corosRed).font(.system(size: 18))
                    .frame(maxWidth: .infinity).padding(.top, 26)
            }.buttonStyle(.plain)
            Spacer(minLength: 80)
        }
        .overlay {
            if termsPromptAction != nil {
                TermsConsentSheet(
                    onDismiss: { termsPromptAction = nil },
                    onPrivacyClick: { path.append(AuthRoute.privacyPolicy) },
                    onServiceTermsClick: { path.append(AuthRoute.serviceTerms) },
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
        let message = viewModel.requestPhoneVerifyCode()
        if message == nil || message?.isEmpty == true {
            let account = viewModel.state.account
            viewModel.updateDisplayName(account)
            path.append(AuthRoute.verifyCode(account: account, targetKind: .phone))
        } else {
            localError = message
        }
    }
}
