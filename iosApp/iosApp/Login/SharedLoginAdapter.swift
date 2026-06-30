import Foundation

#if canImport(Shared)
import Shared
#endif

protocol SharedLoginAdapterProtocol {
    func snapshot() -> IOSLoginState
    func setUsername(_ value: String)
    func setPassword(_ value: String)
    func submit()
    func consumeEffect() -> IOSLoginEffect?
}

#if canImport(Shared)
final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private let facade = LoginFacade()

    func snapshot() -> IOSLoginState {
        let sharedState = facade.state
        return IOSLoginState(
            username: sharedState.username,
            password: sharedState.password,
            isLoading: sharedState.isLoading,
            isLoggedIn: sharedState.isLoggedIn,
            errorMessage: sharedState.errorMessage
        )
    }

    func setUsername(_ value: String) {
        facade.setUsername(value: value)
    }

    func setPassword(_ value: String) {
        facade.setPassword(value: value)
    }

    func submit() {
        facade.submit()
    }

    func consumeEffect() -> IOSLoginEffect? {
        guard let payload = facade.consumeEffectPayload() else {
            return nil
        }

        switch payload.type {
        case "NavigateHome":
            return .navigateHome(displayName: payload.displayName ?? "")
        case "ShowMessage":
            return .showMessage(payload.message ?? "")
        default:
            return nil
        }
    }
}
#else
final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private var state = IOSLoginState()
    private var pendingEffect: IOSLoginEffect?

    func snapshot() -> IOSLoginState {
        state
    }

    func setUsername(_ value: String) {
        state.username = value
        state.errorMessage = nil
    }

    func setPassword(_ value: String) {
        state.password = value
        state.errorMessage = nil
    }

    func submit() {
        guard state.canSubmit else {
            state.errorMessage = "请输入用户名和密码"
            pendingEffect = .showMessage("请输入用户名和密码")
            return
        }

        if state.username.trimmingCharacters(in: .whitespacesAndNewlines) == "demo"
            && state.password == "demo123" {
            state.isLoggedIn = true
            state.errorMessage = nil
            pendingEffect = .navigateHome(displayName: "Demo User")
        } else {
            state.isLoggedIn = false
            state.errorMessage = "用户名或密码不正确"
            pendingEffect = .showMessage("用户名或密码不正确")
        }
    }

    func consumeEffect() -> IOSLoginEffect? {
        let effect = pendingEffect
        pendingEffect = nil
        return effect
    }
}
#endif
