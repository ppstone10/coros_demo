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
    func isResetPasswordReady(newPassword: String, confirmPassword: String, isLoading: Bool) -> Bool
    func hasAccount(_ account: String) -> Bool
    func isProfileRequiredComplete(
        username: String,
        birthDate: String,
        heightCm: Int32,
        weightKg: Double,
        gender: String,
        isLoading: Bool
    ) -> Bool
    func validatePhoneAccount(_ account: String) -> String?
    func validateEmailAccount(_ email: String) -> String?
    func validateVerifyCode(_ code: String) -> String?
    func validateRegisterPassword(password: String, confirmPassword: String) -> String?
    func requestVerifyCode(account: String) -> String?
    func requestResentVerifyCode(account: String) -> String?
    func verifyCode(account: String, code: String) -> String?
    func verifyCodeRemainingSeconds(account: String) -> Int
    func resetPassword(account: String, newPassword: String) -> String?
    func submitProfile(
        avatarUri: String?,
        username: String,
        birthDate: String,
        heightCm: Int32,
        weightKg: Double,
        measurementSystem: String,
        phone: String,
        countryRegion: String,
        gender: String
    )
    func deleteCurrentAccount() -> String?
    func submit()
    func logout()
    func clearSessionSilently()
    func pauseSession()
    func resumeSession()
    func consumeEffect() -> LoginEffect?
    func loadHealthDashboard() -> PersistedDashboard?
    func selectHealthScenario(_ name: String) -> Bool
    func refreshHealthDashboard() -> PersistedDashboard?
    func healthDashboardError() -> String?
    func saveHealthCardConfiguration(_ typeNames: [String]) -> PersistedDashboard?
    func healthCardSaveError() -> String?
}

final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private static let storeKey = "training_auth_mock_store"
    private let facade: LoginFacade

    init() {
        let defaults = UserDefaults.standard
        let healthKey = "health_dashboard_store"
        let healthStore = JsonHealthDashboardStateDataSource(
            readString: { userId in defaults.string(forKey: "\(healthKey)_\(userId)") },
            writeString: { userId, json in
                defaults.set(json, forKey: "\(healthKey)_\(userId)")
                return true
            }
        )
        self.facade = LoginFacadeFactory().createPersistent(
            loadJson: {
                defaults.string(forKey: Self.storeKey)
            },
            saveJson: { json in
                defaults.set(json, forKey: Self.storeKey)
                return KotlinBoolean(bool: defaults.synchronize())
            },
            healthStateDataSource: healthStore
        )
        syncClock()
        facade.restoreSession()
    }

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

    func isResetPasswordReady(newPassword: String, confirmPassword: String, isLoading: Bool) -> Bool {
        facade.isResetPasswordReady(
            newPassword: newPassword,
            confirmPassword: confirmPassword,
            isLoading: isLoading
        )
    }

    func hasAccount(_ account: String) -> Bool {
        facade.hasAccount(account: account)
    }

    func isProfileRequiredComplete(
        username: String,
        birthDate: String,
        heightCm: Int32,
        weightKg: Double,
        gender: String,
        isLoading: Bool
    ) -> Bool {
        facade.isProfileRequiredComplete(
            username: username,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            gender: gender,
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
        syncClock()
        return facade.requestVerifyCode(account: account)
    }

    func requestResentVerifyCode(account: String) -> String? {
        syncClock()
        return facade.requestResentVerifyCode(account: account)
    }

    func verifyCode(account: String, code: String) -> String? {
        syncClock()
        return facade.verifyCode(account: account, code: code)
    }

    func verifyCodeRemainingSeconds(account: String) -> Int {
        syncClock()
        return Int(facade.verifyCodeRemainingSeconds(account: account))
    }

    func resetPassword(account: String, newPassword: String) -> String? {
        facade.resetPassword(account: account, newPassword: newPassword)
    }

    func submitProfile(
        avatarUri: String?,
        username: String,
        birthDate: String,
        heightCm: Int32,
        weightKg: Double,
        measurementSystem: String,
        phone: String,
        countryRegion: String,
        gender: String
    ) {
        facade.submitProfile(
            avatarUri: avatarUri,
            username: username,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            measurementSystem: measurementSystem,
            phone: phone,
            countryRegion: countryRegion,
            gender: gender
        )
    }

    func deleteCurrentAccount() -> String? {
        facade.deleteCurrentAccount()
    }

    func submit() {
        syncClock()
        facade.submit()
    }

    func logout() {
        facade.logout()
    }

    func clearSessionSilently() {
        facade.clearSessionSilently()
    }

    func pauseSession() {
        syncClock()
        facade.pauseSession()
    }

    func resumeSession() {
        syncClock()
        facade.restoreSession()
    }

    func consumeEffect() -> LoginEffect? {
        facade.consumeEffect()
    }

    func loadHealthDashboard() -> PersistedDashboard? {
        facade.loadHealthDashboard()
    }
    
    func selectHealthScenario(_ name: String) -> Bool {
        facade.selectHealthScenario(name: name)
    }

    func refreshHealthDashboard() -> PersistedDashboard? {
        facade.refreshHealthDashboard()
    }

    func healthDashboardError() -> String? {
        facade.healthDashboardError()
    }
    
    func saveHealthCardConfiguration(_ typeNames: [String]) -> PersistedDashboard? {
        facade.saveHealthCardConfiguration(typeNames: typeNames)
    }
    
    func healthCardSaveError() -> String? {
        facade.healthCardSaveError()
    }

    private func syncClock() {
        facade.setCurrentTimeEpochMs(
            value: Int64(Date().timeIntervalSince1970 * 1_000)
        )
    }
}
