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
        self.pendingEffect = adapter.consumeEffect()
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

    func updateRegion(_ value: String) {
        adapter.setRegion(value)
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

    func normalizeVerifyCodeInput(_ value: String) -> String {
        adapter.normalizeVerifyCodeInput(value)
    }

    func normalizePasswordInput(_ value: String) -> String {
        adapter.normalizePasswordInput(value)
    }

    func hasAccount(_ account: String) -> Bool {
        adapter.hasAccount(account)
    }

    func canSubmitLogin() -> Bool {
        adapter.isLoginReady(account: state.account, password: state.password, isLoading: state.isLoading)
    }

    func canRegisterWithPassword(password: String, confirmPassword: String) -> Bool {
        adapter.isRegisterPasswordReady(
            password: password,
            confirmPassword: confirmPassword,
            isLoading: state.isLoading
        )
    }

    func canSubmitResetPassword(newPassword: String, confirmPassword: String) -> Bool {
        adapter.isResetPasswordReady(
            newPassword: newPassword,
            confirmPassword: confirmPassword,
            isLoading: state.isLoading
        )
    }

    func canSubmitProfile(_ profile: ProfileDraft) -> Bool {
        adapter.isProfileRequiredComplete(
            username: profile.username,
            birthDate: profile.birthDate,
            heightCm: Int32(profile.heightCm ?? 0),
            weightKg: profile.weightKg ?? 0.0,
            gender: profile.gender?.rawValue ?? "",
            isLoading: state.isLoading
        )
    }

    func validatePhoneAccount(_ account: String) -> String? {
        adapter.validatePhoneAccount(account)
    }

    func validateEmailAccount(_ email: String) -> String? {
        adapter.validateEmailAccount(email)
    }

    func validateRegisterPassword(password: String, confirmPassword: String) -> String? {
        adapter.validateRegisterPassword(password: password, confirmPassword: confirmPassword)
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

    func verifyCodeRemainingSeconds(account: String) -> Int {
        adapter.verifyCodeRemainingSeconds(account: account)
    }

    func resetPasswordMessage(account: String, newPassword: String) -> String? {
        adapter.resetPassword(account: account, newPassword: newPassword)
    }

    func submitProfile(_ profile: ProfileDraft) {
        adapter.submitProfile(
            avatarUri: profile.avatarUri,
            username: profile.username,
            birthDate: profile.birthDate,
            heightCm: Int32(profile.heightCm ?? 0),
            weightKg: profile.weightKg ?? 0.0,
            measurementSystem: profile.measurementSystem.rawValue,
            phone: profile.phone,
            countryRegion: profile.countryRegion,
            gender: profile.gender?.rawValue ?? ""
        )
        refresh()
    }

    /// Saves an edit made inside the signed-in area without letting the root
    /// coordinator reset the selected tab for the ProfileSaved effect.
    func submitInlineProfile(_ profile: ProfileDraft) -> String? {
        submitProfile(profile)
        guard let effect = consumeEffect() else { return state.errorMessage }
        if effect is LoginEffectProfileSaved {
            toastMessage = appLocalized("profile_saved")
            return nil
        }
        if let messageEffect = effect as? LoginEffectShowMessage {
            return messageEffect.message
        }
        return state.errorMessage
    }

    func deleteCurrentAccountMessage() -> String? {
        let message = adapter.deleteCurrentAccount()
        refresh()
        return message
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

    func pauseSession() {
        adapter.pauseSession()
        refresh()
    }

    func resumeSession() {
        adapter.resumeSession()
        refresh()
    }

    func handleInitialEffectIfNeeded() {
        guard pendingEffect != nil else { return }
        effectTrigger &+= 1
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

enum ProfileGender: String, CaseIterable, Hashable {
    case female = "Female"
    case male = "Male"

    var title: String {
        switch self {
        case .female: return appLocalized("common_female")
        case .male: return appLocalized("common_male")
        }
    }

    var iconName: String {
        switch self {
        case .female: return "icon_female"
        case .male: return "icon_male"
        }
    }
}

enum ProfileMeasurementSystem: String, CaseIterable, Hashable {
    case metric = "Metric"
    case imperial = "Imperial"

    var title: String {
        switch self {
        case .metric: return appLocalized("profile_unit_metric")
        case .imperial: return appLocalized("profile_unit_imperial")
        }
    }
}

struct ProfileDraft: Equatable {
    var avatarUri: String?
    var username: String
    var birthDate: String
    var heightCm: Int?
    var weightKg: Double?
    var measurementSystem: ProfileMeasurementSystem
    var phone: String
    var countryRegion: String
    var gender: ProfileGender?
}
