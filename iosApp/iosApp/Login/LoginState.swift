import Foundation

enum IOSAuthMode: Equatable {
    case login
    case register
}

struct IOSAuthSession: Equatable {
    var account: String
    var displayName: String
}

struct IOSLoginState: Equatable {
    var mode: IOSAuthMode = .login
    var username: String = ""
    var password: String = ""
    var verifyCode: String = ""
    var displayName: String = ""
    var selectedRegion: String = "CN"
    var currentSession: IOSAuthSession?
    var isLoading: Bool = false
    var isLoggedIn: Bool = false
    var errorMessage: String?

    var account: String {
        username
    }

    var canSubmit: Bool {
        guard !isLoading,
              !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            return false
        }
        return mode == .login || (!verifyCode.isEmpty && !selectedRegion.isEmpty)
    }
}

enum IOSLoginEffect: Equatable {
    case authSucceeded(displayName: String)
    case loggedOut
    case showMessage(String)
}
