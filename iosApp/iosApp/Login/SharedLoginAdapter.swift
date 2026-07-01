import Foundation

#if canImport(Shared)
import Shared
#endif

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

#if canImport(Shared)
final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private let facade = LoginFacade()

    func snapshot() -> IOSLoginState {
        let sharedState = facade.state
        return IOSLoginState(
            mode: sharedState.mode == AuthMode.register ? .register : .login,
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
#else
final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private struct Account {
        let account: String
        let password: String
        let displayName: String
        let region: String
    }

    private var state = IOSLoginState(selectedRegion: "CN")
    private var pendingEffect: IOSLoginEffect?
    private var accounts: [Account] = [
        Account(account: "13107012029", password: "123456", displayName: "COROS User", region: "CN")
    ]
    private var verifyCodes: [String: String] = [:]

    func snapshot() -> IOSLoginState {
        state
    }

    func setLoginMode() {
        state.mode = .login
        state.errorMessage = nil
    }

    func setRegisterMode() {
        state.mode = .register
        state.errorMessage = nil
    }

    func setUsername(_ value: String) {
        state.username = value
        state.errorMessage = nil
    }

    func setPassword(_ value: String) {
        state.password = value
        state.errorMessage = nil
    }

    func setVerifyCode(_ value: String) {
        state.verifyCode = value
        state.errorMessage = nil
    }

    func setDisplayName(_ value: String) {
        state.displayName = value
        state.errorMessage = nil
    }

    func setRegion(_ value: String) {
        state.selectedRegion = value
        state.errorMessage = nil
    }

    func requestVerifyCode(account: String) -> String? {
        let normalizedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isAccountFormatValid(normalizedAccount) else {
            return "请输入完整且有效的信息"
        }
        verifyCodes[normalizedAccount.lowercased()] = "1234"
        return nil
    }

    func verifyCode(account: String, code: String) -> String? {
        let normalizedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return verifyCodes[normalizedAccount] == code.trimmingCharacters(in: .whitespacesAndNewlines)
            ? nil
            : "验证码不正确"
    }

    func submit() {
        guard state.canSubmit else {
            let message = state.mode == .register ? "请输入账号、密码、区域和验证码" : "请输入账号和密码"
            state.errorMessage = message
            pendingEffect = .showMessage(message)
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        switch state.mode {
        case .login:
            login()
        case .register:
            register()
        }
    }

    func logout() {
        state.currentSession = nil
        state.isLoggedIn = false
        state.password = ""
        state.verifyCode = ""
        state.errorMessage = nil
        pendingEffect = .loggedOut
    }

    func clearSessionSilently() {
        state.currentSession = nil
        state.isLoggedIn = false
        state.password = ""
        state.verifyCode = ""
        state.errorMessage = nil
    }

    func consumeEffect() -> IOSLoginEffect? {
        let effect = pendingEffect
        pendingEffect = nil
        return effect
    }

    private func login() {
        let normalizedAccount = state.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isAccountFormatValid(normalizedAccount) else {
            fail("请输入完整且有效的信息")
            return
        }

        guard let account = accounts.first(where: { $0.account.caseInsensitiveCompare(normalizedAccount) == .orderedSame }) else {
            fail("账号不存在")
            return
        }

        guard account.password == state.password else {
            fail("密码不正确")
            return
        }

        succeed(account: account.account, displayName: account.displayName)
    }

    private func register() {
        let normalizedAccount = state.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isAccountFormatValid(normalizedAccount),
              state.password.count >= 6,
              state.verifyCode == "1234",
              !state.selectedRegion.isEmpty else {
            fail(state.verifyCode == "1234" ? "请输入完整且有效的信息" : "验证码不正确")
            return
        }

        guard !accounts.contains(where: { $0.account.caseInsensitiveCompare(normalizedAccount) == .orderedSame }) else {
            fail("账号已存在")
            return
        }

        let displayName = state.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = Account(
            account: normalizedAccount,
            password: state.password,
            displayName: displayName.isEmpty ? normalizedAccount : displayName,
            region: state.selectedRegion
        )
        accounts.append(account)
        verifyCodes[normalizedAccount.lowercased()] = nil
        succeed(account: account.account, displayName: account.displayName)
    }

    private func succeed(account: String, displayName: String) {
        state.isLoading = false
        state.isLoggedIn = true
        state.currentSession = IOSAuthSession(account: account, displayName: displayName)
        state.password = ""
        state.verifyCode = ""
        state.errorMessage = nil
        pendingEffect = .authSucceeded(displayName: displayName)
    }

    private func fail(_ message: String) {
        state.isLoading = false
        state.isLoggedIn = false
        state.currentSession = nil
        state.errorMessage = message
        pendingEffect = .showMessage(message)
    }

    private func isAccountFormatValid(_ account: String) -> Bool {
        let isEmail = account.contains("@") && account.split(separator: "@").last?.contains(".") == true
        let isPhone = account.count >= 5
            && account.count <= 20
            && account.allSatisfy { $0.isNumber || $0 == "+" || $0 == "-" }
        return isEmail || isPhone
    }
}
#endif
