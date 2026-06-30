import Foundation

struct IOSLoginState: Equatable {
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var isLoggedIn: Bool = false
    var errorMessage: String?

    var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
            && !isLoading
    }
}

enum IOSLoginEffect: Equatable {
    case navigateHome(displayName: String)
    case showMessage(String)
}
