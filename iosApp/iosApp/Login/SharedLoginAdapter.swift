import Foundation
import Shared

protocol SharedLoginAdapterProtocol {
    func snapshot() -> LoginState
    func setLoginMode()
    func setRegisterMode()
    func setUsername(_ value: String)
    func setPassword(_ value: String)
    func setVerifyCode(_ value: String)
    func setDisplayName(_ value: String)
    func setRegion(_ value: String)
    func normalizePhoneInput(_ value: String) -> String
    func normalizeEmailInput(_ value: String) -> String
    func normalizeVerifyCodeInput(_ value: String) -> String
    func normalizePasswordInput(_ value: String) -> String
    func isLoginReady(account: String, password: String, isLoading: Bool) -> Bool
    func isPhoneAccountValid(_ account: String) -> Bool
    func isEmailAccountValid(_ email: String) -> Bool
    func isRegisterPasswordReady(password: String, confirmPassword: String, isLoading: Bool) -> Bool
    func validatePhoneAccount(_ account: String) -> String?
    func validateEmailAccount(_ email: String) -> String?
    func validateVerifyCode(_ code: String) -> String?
    func validateRegisterPassword(password: String, confirmPassword: String) -> String?
    func requestVerifyCode(account: String) -> String?
    func requestResentVerifyCode(account: String) -> String?
    func verifyCode(account: String, code: String) -> String?
    func submit()
    func logout()
    func clearSessionSilently()
    func consumeEffect() -> LoginEffect?
}

final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private let facade = LoginFacade()

    func snapshot() -> LoginState {
        facade.state
    }

    func setLoginMode() {
        facade.setLoginMode()
    }

    func setRegisterMode() {
        facade.setRegisterMode()
    }

    func setUsername(_ value: String) {
        facade.setUsername(value: value)
    }

    func setPassword(_ value: String) {
        facade.setPassword(value: value)
    }

    func setVerifyCode(_ value: String) {
        facade.setVerifyCode(value: value)
    }

    func setDisplayName(_ value: String) {
        facade.setDisplayName(value: value)
    }

    func setRegion(_ value: String) {
        facade.setRegion(value: value)
    }

    func normalizePhoneInput(_ value: String) -> String {
        facade.normalizePhoneInput(value: value)
    }

    func normalizeEmailInput(_ value: String) -> String {
        facade.normalizeEmailInput(value: value)
    }

    func normalizeVerifyCodeInput(_ value: String) -> String {
        facade.normalizeVerifyCodeInput(value: value)
    }

    func normalizePasswordInput(_ value: String) -> String {
        facade.normalizePasswordInput(value: value)
    }

    func isLoginReady(account: String, password: String, isLoading: Bool) -> Bool {
        facade.isLoginReady(account: account, password: password, isLoading: isLoading)
    }

    func isPhoneAccountValid(_ account: String) -> Bool {
        facade.isPhoneAccountValid(account: account)
    }

    func isEmailAccountValid(_ email: String) -> Bool {
        facade.isEmailAccountValid(email: email)
    }

    func isRegisterPasswordReady(password: String, confirmPassword: String, isLoading: Bool) -> Bool {
        facade.isRegisterPasswordReady(
            password: password,
            confirmPassword: confirmPassword,
            isLoading: isLoading
        )
    }

    func validatePhoneAccount(_ account: String) -> String? {
        facade.validatePhoneAccount(account: account)
    }

    func validateEmailAccount(_ email: String) -> String? {
        facade.validateEmailAccount(email: email)
    }

    func validateVerifyCode(_ code: String) -> String? {
        facade.validateVerifyCode(code: code)
    }

    func validateRegisterPassword(password: String, confirmPassword: String) -> String? {
        facade.validateRegisterPassword(password: password, confirmPassword: confirmPassword)
    }

    func requestVerifyCode(account: String) -> String? {
        facade.requestVerifyCode(account: account)
    }

    func requestResentVerifyCode(account: String) -> String? {
        facade.requestResentVerifyCode(account: account)
    }

    func verifyCode(account: String, code: String) -> String? {
        facade.verifyCode(account: account, code: code)
    }

    func submit() {
        facade.submit()
    }

    func logout() {
        facade.logout()
    }

    func clearSessionSilently() {
        facade.clearSessionSilently()
    }

    func consumeEffect() -> LoginEffect? {
        facade.consumeEffect()
    }
}
