import Combine
import Foundation

enum CorosAuthPage {
    case entrance
    case login
    case phoneRegister
    case verifyCode
    case passwordSetup
    case signedIn
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var state: IOSLoginState
    @Published var page: CorosAuthPage
    @Published var acceptedTerms: Bool = false
    @Published var localError: String?
    @Published var codeInput: String = ""
    @Published var setupPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var toastMessage: String?

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

    func backToEntrance() {
        localError = nil
        page = .entrance
    }

    func backToPhoneRegister() {
        localError = nil
        page = .phoneRegister
    }

    func backToVerifyCode() {
        localError = nil
        page = .verifyCode
    }

    func updateAccount(_ value: String) {
        adapter.setUsername(value)
        localError = nil
        refresh()
    }

    func updatePhone(_ value: String) {
        let filtered = String(value.filter(\.isNumber).prefix(11))
        adapter.setUsername(filtered)
        localError = nil
        refresh()
    }

    func updatePassword(_ value: String) {
        adapter.setPassword(value)
        localError = nil
        refresh()
    }

    func updateCode(_ value: String) {
        codeInput = String(value.filter(\.isNumber).prefix(4))
        localError = nil
    }

    func updateSetupPassword(_ value: String) {
        setupPassword = String(value.prefix(20))
        localError = nil
    }

    func updateConfirmPassword(_ value: String) {
        confirmPassword = String(value.prefix(20))
        localError = nil
    }

    func toggleTerms() {
        acceptedTerms.toggle()
        localError = nil
    }

    func sendCode() {
        guard state.account.count == 11 else {
            localError = "请输入11位手机号"
            return
        }
        guard acceptedTerms else {
            localError = "请先阅读并同意隐私政策和服务条款"
            return
        }

        if let message = adapter.requestVerifyCode(account: state.account) {
            localError = message
            return
        }

        adapter.setRegisterMode()
        adapter.setDisplayName(state.account)
        codeInput = ""
        localError = nil
        page = .verifyCode
        refresh()
    }

    func showEmailRegisterUnavailable() {
        localError = "当前先实现手机号注册"
    }

    func submitCode() {
        guard codeInput.count == 4 else {
            localError = "请输入验证码"
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

    func login() {
        guard acceptedTerms else {
            localError = "请先阅读并同意隐私政策和服务条款"
            return
        }

        adapter.setLoginMode()
        adapter.submit()
        refresh()
        handleEffect(adapter.consumeEffect(), submitContext: .login)
    }

    func register() {
        guard setupPassword.count >= 6, setupPassword.count <= 20 else {
            localError = "密码需要为6-20位"
            return
        }
        guard setupPassword.contains(where: \.isLetter), setupPassword.contains(where: \.isNumber) else {
            localError = "密码需要包含字母和数字"
            return
        }
        guard setupPassword == confirmPassword else {
            localError = "两次输入的密码不一致"
            return
        }

        adapter.setRegisterMode()
        adapter.setPassword(setupPassword)
        adapter.setVerifyCode(codeInput)
        adapter.submit()
        refresh()
        handleEffect(adapter.consumeEffect(), submitContext: .register)
    }

    func logout() {
        adapter.logout()
        refresh()
        handleEffect(adapter.consumeEffect(), submitContext: nil)
    }

    private enum SubmitContext {
        case login
        case register
    }

    private func refresh() {
        state = adapter.snapshot()
    }

    private func handleEffect(_ effect: IOSLoginEffect?, submitContext: SubmitContext?) {
        switch effect {
        case .authSucceeded:
            if submitContext == .register {
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
        case .loggedOut:
            acceptedTerms = false
            page = .entrance
            toastMessage = "已退出登录"
        case .showMessage(let message):
            toastMessage = message
        case nil:
            break
        }
    }
}
