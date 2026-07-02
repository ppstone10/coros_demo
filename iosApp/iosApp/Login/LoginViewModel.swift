import Combine
import Foundation
import Shared

enum CorosAuthPage {
    case entrance
    case login
    case phoneRegister
    case emailRegister
    case verifyCode
    case passwordSetup
    case privacyPolicy
    case serviceTerms
    case signedIn
}

enum VerifyTargetKind {
    case phone
    case email
}

enum TermsPromptAction {
    case login
    case phoneCode
    case emailCode
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var state: LoginState
    @Published var page: CorosAuthPage
    @Published var acceptedTerms: Bool = false
    @Published var localError: String?
    @Published var codeInput: String = ""
    @Published var emailInput: String = ""
    @Published var setupPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var verifyTargetKind: VerifyTargetKind = .phone
    @Published var termsPromptAction: TermsPromptAction?
    @Published var unavailableDialogVisible: Bool = false
    @Published var toastMessage: String?

    private var legalReturnPage: CorosAuthPage = .phoneRegister
    private let adapter: SharedLoginAdapterProtocol

    init(adapter: SharedLoginAdapterProtocol = SharedLoginAdapter()) {
        self.adapter = adapter
        let initialState = adapter.snapshot()
        self.state = initialState
        self.page = initialState.isLoggedIn && initialState.currentSession != nil ? .signedIn : .entrance
    }

    var visibleError: String? {
        localError ?? state.errorMessage
    }

    var verifyCodeMessage: String {
        switch verifyTargetKind {
        case .email:
            return "验证码已发送至你的邮箱 \(state.account)，有效期10分钟"
        case .phone:
            return "验证码已发送至你的手机+86-\(state.account)，有效期10分钟"
        }
    }

    var canSubmitLogin: Bool {
        adapter.isLoginReady(
            account: state.account,
            password: state.password,
            isLoading: state.isLoading
        )
    }

    var canRequestPhoneCode: Bool {
        adapter.isPhoneAccountValid(state.account) && !state.isLoading
    }

    var canRequestEmailCode: Bool {
        adapter.isEmailAccountValid(emailInput) && !state.isLoading
    }

    var canRegisterWithPassword: Bool {
        adapter.isRegisterPasswordReady(
            password: setupPassword,
            confirmPassword: confirmPassword,
            isLoading: state.isLoading
        )
    }

    func showLogin() {
        adapter.setLoginMode()
        localError = nil
        page = .login
        refresh()
    }

    func showPhoneRegister() {
        adapter.setRegisterMode()
        localError = nil
        page = .phoneRegister
        refresh()
    }

    func showEmailRegister() {
        adapter.setRegisterMode()
        adapter.setUsername("")
        emailInput = ""
        localError = nil
        page = .emailRegister
        refresh()
    }

    func showPhoneRegisterFromEmail() {
        adapter.setUsername("")
        localError = nil
        page = .phoneRegister
        refresh()
    }

    func backToEntrance() {
        localError = nil
        page = .entrance
    }

    func backToRegistrationSource() {
        localError = nil
        page = verifyTargetKind == .email ? .emailRegister : .phoneRegister
    }

    func backToVerifyCode() {
        localError = nil
        page = .verifyCode
    }

    func openPrivacyPolicy() {
        legalReturnPage = page
        termsPromptAction = nil
        localError = nil
        page = .privacyPolicy
    }

    func openServiceTerms() {
        legalReturnPage = page
        termsPromptAction = nil
        localError = nil
        page = .serviceTerms
    }

    func closeLegalDocument() {
        localError = nil
        page = legalReturnPage
    }

    func showUnavailableFeature() {
        unavailableDialogVisible = true
    }

    func dismissUnavailableFeature() {
        unavailableDialogVisible = false
    }

    func dismissTermsPrompt() {
        termsPromptAction = nil
    }

    func acceptTermsPromptAndContinue() {
        guard let action = termsPromptAction else {
            acceptedTerms = true
            return
        }

        acceptedTerms = true
        termsPromptAction = nil

        switch action {
        case .login:
            submitLogin(skipTerms: true)
        case .phoneCode:
            requestPhoneVerifyCode(skipTerms: true)
        case .emailCode:
            requestEmailVerifyCode(skipTerms: true)
        }
    }

    func updateAccount(_ value: String) {
        adapter.setUsername(value)
        localError = nil
        refresh()
    }

    func updatePhone(_ value: String) {
        adapter.setUsername(adapter.normalizePhoneInput(value))
        localError = nil
        refresh()
    }

    func updateEmail(_ value: String) {
        emailInput = adapter.normalizeEmailInput(value)
        localError = nil
    }

    func updatePassword(_ value: String) {
        adapter.setPassword(value)
        localError = nil
        refresh()
    }

    func updateCode(_ value: String) {
        codeInput = adapter.normalizeVerifyCodeInput(value)
        localError = nil
    }

    func updateSetupPassword(_ value: String) {
        setupPassword = adapter.normalizePasswordInput(value)
        localError = nil
    }

    func updateConfirmPassword(_ value: String) {
        confirmPassword = adapter.normalizePasswordInput(value)
        localError = nil
    }

    func toggleTerms() {
        acceptedTerms.toggle()
        localError = nil
    }

    func requestPhoneVerifyCode(skipTerms: Bool = false) {
        if let message = adapter.validatePhoneAccount(state.account) {
            localError = message
            return
        }
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .phoneCode
            return
        }

        if let message = adapter.requestVerifyCode(account: state.account) {
            localError = message
            return
        }

        openVerifyPage(account: state.account, targetKind: .phone)
    }

    func requestEmailVerifyCode(skipTerms: Bool = false) {
        let email = adapter.normalizeEmailInput(emailInput)
        if let message = adapter.validateEmailAccount(email) {
            localError = message
            return
        }
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .emailCode
            return
        }

        if let message = adapter.requestVerifyCode(account: email) {
            localError = message
            return
        }

        openVerifyPage(account: email, targetKind: .email)
    }

    func resendVerifyCode() -> Bool {
        if let message = adapter.requestResentVerifyCode(account: state.account) {
            localError = message
            return false
        }

        codeInput = ""
        localError = nil
        return true
    }

    func submitCodeIfComplete() {
        guard codeInput.count == 4 else {
            return
        }
        submitCode()
    }

    func submitCode() {
        if let message = adapter.validateVerifyCode(codeInput) {
            localError = message
            return
        }

        if let message = adapter.verifyCode(account: state.account, code: codeInput) {
            localError = message
            return
        }

        adapter.setVerifyCode(codeInput)
        setupPassword = ""
        confirmPassword = ""
        localError = nil
        page = .passwordSetup
        refresh()
    }

    func submitLogin(skipTerms: Bool = false) {
        guard skipTerms || acceptedTerms else {
            termsPromptAction = .login
            return
        }

        adapter.setLoginMode()
        adapter.submit()
        refresh()
        handleEffect(adapter.consumeEffect())
    }

    func register() {
        if let message = adapter.validateRegisterPassword(
            password: setupPassword,
            confirmPassword: confirmPassword
        ) {
            localError = message
            return
        }

        adapter.setRegisterMode()
        adapter.setPassword(setupPassword)
        adapter.setVerifyCode(codeInput)
        adapter.submit()
        refresh()
        handleEffect(adapter.consumeEffect())
    }

    func logout() {
        adapter.logout()
        refresh()
        handleEffect(adapter.consumeEffect())
    }

    private func openVerifyPage(account: String, targetKind: VerifyTargetKind) {
        adapter.setRegisterMode()
        adapter.setUsername(account)
        adapter.setDisplayName(account)
        verifyTargetKind = targetKind
        codeInput = ""
        localError = nil
        page = .verifyCode
        refresh()
    }

    private func refresh() {
        state = adapter.snapshot()
    }

    private func handleEffect(_ effect: LoginEffect?) {
        switch effect {
        case let effect as LoginEffectAuthSucceeded:
            if effect.mode == AuthMode.register_ {
                adapter.clearSessionSilently()
                acceptedTerms = false
                setupPassword = ""
                confirmPassword = ""
                page = .login
                localError = nil
                refresh()
                toastMessage = "注册成功"
            } else {
                page = .signedIn
                localError = nil
                toastMessage = "登录成功"
            }

        case _ as LoginEffectNavigateHome:
            page = .signedIn
            localError = nil
            toastMessage = "登录成功"

        case _ as LoginEffectLoggedOut:
            acceptedTerms = false
            page = .entrance
            toastMessage = "已退出登录"

        case _ as LoginEffectSessionExpired:
            page = .login
            toastMessage = "会话已失效，请重新登录"

        case let effect as LoginEffectShowMessage:
            toastMessage = effect.message

        case nil:
            break

        default:
            break
        }
    }
}
