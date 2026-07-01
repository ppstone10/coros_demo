import Foundation
import Shared

protocol SharedLoginAdapterProtocol {
    func snapshot() -> IOSLoginState
    func setLoginMode()
    func setRegisterMode()
    func setUsername(_ value: String)
    func setPassword(_ value: String)
    func setVerifyCode(_ value: String)
    func setDisplayName(_ value: String)
    func setRegion(_ value: String)
    func requestVerifyCode(account: String) -> String?
    func verifyCode(account: String, code: String) -> String?
    func submit()
    func logout()
    func clearSessionSilently()
    func consumeEffect() -> IOSLoginEffect?
}

final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private let facade = LoginFacade()

    func snapshot() -> IOSLoginState {
        let sharedState = facade.state
        return IOSLoginState(
            mode: sharedState.mode == AuthMode.register_ ? .register : .login,
            username: sharedState.username,
            password: sharedState.password,
            verifyCode: sharedState.verifyCode,
            displayName: sharedState.displayName,
            selectedRegion: sharedState.selectedRegion,
            currentSession: sharedState.currentSession.map {
                IOSAuthSession(account: $0.account, displayName: $0.resolvedDisplayName)
            },
            isLoading: sharedState.isLoading,
            isLoggedIn: sharedState.isLoggedIn,
            errorMessage: sharedState.errorMessage
        )
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

    func requestVerifyCode(account: String) -> String? {
        facade.requestVerifyCode(account: account)
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

    func consumeEffect() -> IOSLoginEffect? {
        guard let payload = facade.consumeEffectPayload() else {
            return nil
        }

        switch payload.type {
        case "AuthSucceeded", "NavigateHome":
            return .authSucceeded(displayName: payload.displayName ?? "")
        case "LoggedOut":
            return .loggedOut
        case "ShowMessage", "SessionExpired":
            return .showMessage(payload.message ?? "")
        default:
            return nil
        }
    }
}
