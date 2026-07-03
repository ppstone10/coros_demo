import Combine
import Foundation
import Shared

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var state: LoginState
    @Published var toastMessage: String?
    @Published private(set) var effectTrigger = 0
    private var pendingEffect: LoginEffect?

    let adapter: SharedLoginAdapterProtocol

    init(adapter: SharedLoginAdapterProtocol = SharedLoginAdapter()) {
        self.adapter = adapter
        self.state = adapter.snapshot()
    }

    func requestLoginMode() {
        adapter.setLoginMode()
        refresh()
    }

    func requestRegisterMode() {
        adapter.setRegisterMode()
        refresh()
    }

    func updateAccount(_ value: String) {
        adapter.setUsername(value)
        refresh()
    }

    func updatePassword(_ value: String) {
        adapter.setPassword(value)
        refresh()
    }

    func updateVerifyCode(_ value: String) {
        adapter.setVerifyCode(value)
        refresh()
    }

    func updateDisplayName(_ value: String) {
        adapter.setDisplayName(value)
        refresh()
    }

    func updatePhone(_ value: String) {
        updateAccount(adapter.normalizePhoneInput(value))
    }

    func normalizePhoneInput(_ value: String) -> String {
        adapter.normalizePhoneInput(value)
    }

    func normalizeEmailInput(_ value: String) -> String {
        adapter.normalizeEmailInput(value)
    }

    func requestPhoneVerifyCode() -> String? {
        if let message = adapter.validatePhoneAccount(state.account) {
            return message
        }
        if let message = adapter.requestVerifyCode(account: state.account) {
            return message
        }
        return nil
    }

    func requestEmailVerifyCode(email: String) -> String? {
        if let message = adapter.validateEmailAccount(email) {
            return message
        }
        if let message = adapter.requestVerifyCode(account: email) {
            return message
        }
        return nil
    }

    func verifyCodeMessage(account: String, code: String) -> String? {
        if let message = adapter.validateVerifyCode(code) {
            return message
        }
        if let message = adapter.verifyCode(account: account, code: code) {
            return message
        }
        return nil
    }

    func resendVerifyCode() -> String? {
        if let message = adapter.requestResentVerifyCode(account: state.account) {
            return message
        }
        return nil
    }

    func submit() {
        adapter.submit()
        refresh()
    }

    func logout() {
        adapter.logout()
        refresh()
    }

    func clearSessionSilently() {
        adapter.clearSessionSilently()
        refresh()
    }

    func consumeEffect() -> LoginEffect? {
        let e = pendingEffect
        pendingEffect = nil
        return e
    }

    private func refresh() {
        state = adapter.snapshot()
        if let newEffect = adapter.consumeEffect() {
            pendingEffect = newEffect
            effectTrigger &+= 1
        }
    }
}
