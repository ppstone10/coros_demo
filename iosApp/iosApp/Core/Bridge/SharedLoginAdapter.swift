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
    func profileDefaultUsername(_ account: String) -> String
    func profileDefaultPhone(_ account: String) -> String
    func profileDefaultEmail(_ account: String) -> String
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
        email: String,
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
    func healthState() -> HealthState?
    func loadHealth()
    func staleHealthForNewAccount()
    func selectHealthScenario(_ name: String) -> Bool
    func refreshHealth()
    func saveHealthCardConfiguration(_ typeNames: [String]) -> String?
    func saveHealthBodyWeight(_ weightKg: Double) -> String?
    func consumeHealthEffect() -> HealthEffect?
    func healthScenarioDescriptors() -> [HealthScenarioDescriptor]
    func healthEditableSectionNames() -> [String]
    func normalHealthEditFormJson(_ section: String) -> String?
    func defaultNormalHealthEditFormJson(_ section: String) -> String?
    func mutateNormalHealthEditFormJson(
        _ section: String,
        valuesSpec: String,
        groupID: String,
        operation: String,
        rowIndex: Int
    ) -> String?
    func saveNormalHealthEditForm(_ section: String, valuesSpec: String) -> Bool
    func saveNormalHealthEditFormResultJson(_ section: String, valuesSpec: String) -> String
    func restoreAllNormalHealthDefaults() -> Bool
}

final class SharedLoginAdapter: SharedLoginAdapterProtocol {
    private static let storeKey = "training_auth_mock_store"
    /// MSRV-007：iOS 模拟器访问宿主机 mock server 使用 localhost。
    private static let baseUrl = "http://localhost:3000"
    private let facade: LoginFacade
    let healthFacade: HealthFacade

    /// MSRV-002：Swift 平台层用 URLSession 实现同步 HTTP，通过信号量等待结果。
    private static func httpRequest(method: String, path: String, json: String?) -> IosHttpResponse {
        guard let url = URL(string: baseUrl + path) else {
            return IosHttpResponse(status: -1, body: "")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 5
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let json = json {
            request.httpBody = json.data(using: .utf8)
        }
        let semaphore = DispatchSemaphore(value: 0)
        var status = -1
        var body = ""
        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            status = (response as? HTTPURLResponse)?.statusCode ?? -1
            body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
        return IosHttpResponse(status: Int32(status), body: body)
    }

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
        let authDataSource = JsonAuthStoreDataSource(
            loadJson: { defaults.string(forKey: Self.storeKey) },
            saveJson: { json in
                defaults.set(json, forKey: Self.storeKey)
                return KotlinBoolean(bool: defaults.synchronize())
            }
        )
        // MSRV-002/007：HTTP 传输由 Swift 注入（URLSession），common/iosMain 只保留业务逻辑。
        IosMockServerConfig.shared.baseUrl = Self.baseUrl
        let transport = { (method: String, path: String, json: String?) -> IosHttpResponse in
            Self.httpRequest(method: method, path: path, json: json)
        }
        let repository = IosRemoteAuthRepository(
            http: transport,
            cache: authDataSource,
            sessionTtlMs: Int64(LocalMockAuthRepository.companion.SessionTtlMs)
        )
        self.facade = LoginFacadeFactory().createPersistent(authRepository: repository)
        let remoteHealthStore = IosRemoteHealthDashboardStateDataSource(
            http: transport,
            cache: healthStore
        )
        self.healthFacade = HealthFacadeFactory().createPersistent(
            authRepository: repository,
            stateDataSource: remoteHealthStore
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

    func profileDefaultUsername(_ account: String) -> String {
        facade.profileDefaultUsername(account: account)
    }

    func profileDefaultPhone(_ account: String) -> String {
        facade.profileDefaultPhone(account: account)
    }

    func profileDefaultEmail(_ account: String) -> String {
        facade.profileDefaultEmail(account: account)
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
        email: String,
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
            email: email,
            countryRegion: countryRegion,
            gender: gender
        )
    }

    func deleteCurrentAccount() -> String? {
        if let userId = facade.state.currentSession?.userId,
           !healthFacade.clearUserData(userId: userId) {
            return "auth_error_persist_failed"
        }
        return facade.deleteCurrentAccount()
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
        facade.resumeSessionInSameProcess()
    }

    func consumeEffect() -> LoginEffect? {
        facade.consumeEffect()
    }

    private func syncClock() {
        facade.setCurrentTimeEpochMs(
            value: Int64(Date().timeIntervalSince1970 * 1_000)
        )
    }
}
