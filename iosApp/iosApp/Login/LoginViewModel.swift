import Combine
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var state: IOSLoginState
    @Published var toastMessage: String?

    private let adapter: SharedLoginAdapterProtocol

    init(adapter: SharedLoginAdapterProtocol = SharedLoginAdapter()) {
        self.adapter = adapter
        self.state = adapter.snapshot()
    }

    func updateUsername(_ value: String) {
        adapter.setUsername(value)
        refresh()
    }

    func updatePassword(_ value: String) {
        adapter.setPassword(value)
        refresh()
    }

    func submit() {
        adapter.submit()
        refresh()
        handleEffect(adapter.consumeEffect())
    }

    private func refresh() {
        state = adapter.snapshot()
    }

    private func handleEffect(_ effect: IOSLoginEffect?) {
        switch effect {
        case .navigateHome(let displayName):
            toastMessage = "登录成功：\(displayName)"
        case .showMessage(let message):
            toastMessage = message
        case nil:
            break
        }
    }
}
