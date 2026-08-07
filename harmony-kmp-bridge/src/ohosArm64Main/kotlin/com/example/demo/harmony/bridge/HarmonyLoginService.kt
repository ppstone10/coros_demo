package com.example.demo.harmony.bridge

import com.example.demo.common.health.facade.HealthFacade
import com.example.demo.common.health.facade.HealthFacadeFactory
import com.example.demo.common.health.store.InMemoryHealthDashboardStateDataSource
import com.example.demo.common.auth.repository.AuthStoreDataSource
import com.example.demo.common.auth.mock.LocalMockAuthRepository
import com.example.demo.common.auth.facade.LoginFacade
import com.example.demo.common.auth.store.LoginStore
import com.example.demo.common.auth.model.MockAuthStore
import com.tencent.tmm.knoi.annotation.ServiceProvider
import kotlinx.cinterop.ExperimentalForeignApi
import platform.posix.time

@ServiceProvider
open class HarmonyLoginService {
    private val dataSource: MemoryAuthStoreDataSource = MemoryAuthStoreDataSource()
    private val healthDataSource = InMemoryHealthDashboardStateDataSource()
    private val remoteRepository = HarmonyRemoteAuthRepository(dataSource)
    private var facade: LoginFacade = createFacade(dataSource, healthDataSource)
    private var healthFacade: HealthFacade = createHealthFacade(dataSource, healthDataSource)
    private val healthBridge = HarmonyHealthBridge(healthDataSource, healthFacade)

    fun stateSnapshot(): String {
        return HarmonyLoginJson.stateSnapshot(facade.state)
    }

    fun exportStoreSnapshot(): String {
        val store = dataSource.load()
        val json = HarmonyLoginJson.storeSnapshot(store)
        return json.dropLast(1) + ""","_s":{"accounts":${store.accounts.size},"session":${store.currentSession != null},"defaultInit":${store.defaultAccountsInitialized}}}"""
    }

    fun restoreStoreSnapshot(json: String): Boolean {
        if (json.isBlank()) return false
        return try {
            val store = HarmonyLoginJson.parseStoreSnapshot(json)
            dataSource.replaceStore(store)
            facade = createFacade(dataSource, healthDataSource)
            healthFacade = createHealthFacade(dataSource, healthDataSource)
            healthBridge.updateFacade(healthFacade)
            syncClock()
            facade.restoreSession()
            healthBridge.restoreLegacyHealthFromStoreJson(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 仅合并账号到 store，不重建 facade（MSRV-016/018 登录发现用）。
     * 重建 facade 会清空已输入的账号/密码，登录提交前不得调用 [restoreStoreSnapshot]。
     */
    fun mergeAccounts(json: String): Boolean {
        if (json.isBlank()) return false
        return try {
            val store = HarmonyLoginJson.parseStoreSnapshot(json)
            dataSource.replaceStore(store)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun submit() {
        syncClock()
        facade.submit()
    }

    fun confirmForceLogin() {
        syncClock()
        facade.confirmForceLogin()
    }

    fun cancelForceLogin() {
        facade.cancelForceLogin()
    }

    /** MSRV-019：sync 请求检测到被顶时清会话并触发跳登录页。 */
    fun onSessionKicked() {
        facade.onSessionKicked()
    }

    /** MSRV-019：被顶弹窗确认，清会话并回登录页。 */
    fun confirmKickedDialog() {
        facade.confirmKickedDialog()
    }

    /** MSRV-019：前台周期性会话校验。 */
    fun checkSessionOnForeground() {
        syncClock()
        facade.checkSessionOnForeground()
    }

    // ---- HARM-002/003/008：服务器结果 staging（ArkTS 侧在触发 submit 前调用）----

    fun stageServerLoginResult(json: String): Boolean = remoteRepository.stageServerLoginResult(json)

    fun stageForceLogin(json: String): Boolean = remoteRepository.stageForceLogin(json)

    fun stageServerError(code: String) = remoteRepository.stageServerError(code)

    fun stageSessionExpired() = remoteRepository.stageSessionExpired()

    fun clearStaged() = remoteRepository.clearStaged()

    fun logout() {
        facade.logout()
    }

    fun clearSessionSilently() {
        facade.clearSessionSilently()
    }

    fun pauseSession() {
        syncClock()
        facade.pauseSession()
    }

    fun resumeSessionInSameProcess() {
        syncClock()
        facade.resumeSessionInSameProcess()
    }

    fun healthScenarioDescriptorsJson(): String = healthBridge.healthScenarioDescriptorsJson()

    fun healthEditableSectionsJson(): String = healthBridge.healthEditableSectionsJson()

    fun normalHealthEditFormJson(sectionName: String): String =
        healthBridge.normalHealthEditFormJson(sectionName)

    fun defaultNormalHealthEditFormJson(sectionName: String): String =
        healthBridge.defaultNormalHealthEditFormJson(sectionName)

    fun mutateNormalHealthEditFormJson(
        sectionName: String,
        valuesSpec: String,
        groupId: String,
        operationName: String,
        rowIndex: Int
    ): String = healthBridge.mutateNormalHealthEditFormJson(
        sectionName,
        valuesSpec,
        groupId,
        operationName,
        rowIndex
    )

    fun saveNormalHealthEditForm(sectionName: String, valuesSpec: String): Boolean =
        healthBridge.saveNormalHealthEditForm(sectionName, valuesSpec)

    fun saveNormalHealthEditFormResultJson(sectionName: String, valuesSpec: String): String =
        healthBridge.saveNormalHealthEditFormResultJson(sectionName, valuesSpec)

    fun restoreAllNormalHealthDefaults(): String = healthBridge.restoreAllNormalHealthDefaults()

    fun staleHealthForNewAccount() = healthBridge.staleHealthForNewAccount()

    fun consumeEffectSnapshot(): String {
        return HarmonyLoginJson.effectSnapshot(facade.consumeEffect())
    }

    fun setLoginMode() {
        facade.setLoginMode()
    }

    fun setRegisterMode() {
        facade.setRegisterMode()
    }

    fun setUsername(value: String) {
        facade.setUsername(value)
    }

    fun setPassword(value: String) {
        facade.setPassword(value)
    }

    fun setVerifyCode(value: String) {
        facade.setVerifyCode(value)
    }

    fun setDisplayName(value: String) {
        facade.setDisplayName(value)
    }

    fun setRegion(value: String) {
        facade.setRegion(value)
    }

    fun validateLogin(account: String, password: String): Boolean {
        return facade.isLoginReady(account, password, isLoading = false)
    }

    fun validateLoginInput(account: String, password: String): String {
        return facade.validateLoginInput(account, password).orEmpty()
    }

    fun requestVerifyCode(account: String): String {
        syncClock()
        return facade.requestVerifyCode(account).orEmpty()
    }

    fun requestResentVerifyCode(account: String): String {
        syncClock()
        return facade.requestResentVerifyCode(account).orEmpty()
    }

    fun verifyCode(account: String, code: String): String {
        syncClock()
        return facade.verifyCode(account, code).orEmpty()
    }

    fun verifyCodeRemainingSeconds(account: String): Int {
        syncClock()
        return facade.verifyCodeRemainingSeconds(account)
    }

    fun normalizePhoneInput(value: String): String {
        return facade.normalizePhoneInput(value)
    }

    fun normalizeEmailInput(value: String): String {
        return facade.normalizeEmailInput(value)
    }

    fun normalizeVerifyCodeInput(value: String): String {
        return facade.normalizeVerifyCodeInput(value)
    }

    fun normalizePasswordInput(value: String): String {
        return facade.normalizePasswordInput(value)
    }

    fun isLoginReady(account: String, password: String, isLoading: Boolean): Boolean {
        return facade.isLoginReady(account, password, isLoading)
    }

    fun isPhoneAccountValid(account: String): Boolean {
        return facade.isPhoneAccountValid(account)
    }

    fun isEmailAccountValid(email: String): Boolean {
        return facade.isEmailAccountValid(email)
    }

    fun isRegisterPasswordReady(password: String, confirmPassword: String, isLoading: Boolean): Boolean {
        return facade.isRegisterPasswordReady(password, confirmPassword, isLoading)
    }

    fun isResetPasswordReady(newPassword: String, confirmPassword: String, isLoading: Boolean): Boolean {
        return facade.isResetPasswordReady(newPassword, confirmPassword, isLoading)
    }

    fun hasAccount(account: String): Boolean {
        return facade.hasAccount(account)
    }

    fun isProfileRequiredComplete(
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        gender: String,
        isLoading: Boolean
    ): Boolean {
        return facade.isProfileRequiredComplete(username, birthDate, heightCm, weightKg, gender, isLoading)
    }

    fun validatePhoneAccount(account: String): String {
        return facade.validatePhoneAccount(account).orEmpty()
    }

    fun validateEmailAccount(email: String): String {
        return facade.validateEmailAccount(email).orEmpty()
    }

    fun validateVerifyCode(code: String): String {
        return facade.validateVerifyCode(code).orEmpty()
    }

    fun validateRegisterPassword(password: String, confirmPassword: String): String {
        return facade.validateRegisterPassword(password, confirmPassword).orEmpty()
    }

    fun resetPassword(account: String, newPassword: String): String {
        return facade.resetPassword(account, newPassword).orEmpty()
    }

    fun changePassword(account: String, oldPassword: String, newPassword: String): String {
        return facade.changePassword(account, oldPassword, newPassword).orEmpty()
    }

    fun submitProfile(
        avatarUri: String,
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        measurementSystem: String,
        phone: String,
        email: String,
        countryRegion: String,
        gender: String
    ) {
        facade.submitProfile(
            avatarUri = avatarUri.takeIf { it.isNotBlank() },
            username = username,
            birthDate = birthDate,
            heightCm = heightCm,
            weightKg = weightKg,
            measurementSystem = measurementSystem,
            phone = phone,
            email = email,
            countryRegion = countryRegion,
            gender = gender
        )
    }

    fun deleteCurrentAccount(): String {
        return facade.deleteCurrentAccount().orEmpty()
    }

    fun profileDefaultUsername(account: String): String = facade.profileDefaultUsername(account)
    fun profileDefaultPhone(account: String): String = facade.profileDefaultPhone(account)
    fun profileDefaultEmail(account: String): String = facade.profileDefaultEmail(account)

    fun loadHealthSnapshot(): String = healthBridge.loadHealthSnapshot()

    /** Side-effect-free common fixture for ArkUI Preview and screenshot tooling. */
    fun previewHealthSnapshot(): String = healthBridge.previewHealthSnapshot()

    fun selectHealthScene(name: String): String = healthBridge.selectHealthScene(name)

    fun refreshHealthSnapshot(): String = healthBridge.refreshHealthSnapshot()

    fun saveCardConfig(typeNamesCsv: String): String = healthBridge.saveCardConfig(typeNamesCsv)

    fun saveHealthBodyWeight(weightKg: Double): String = healthBridge.saveHealthBodyWeight(weightKg)

    fun exportHealthSnapshot(): String = healthBridge.exportHealthSnapshot()

    fun restoreHealthSnapshot(json: String): Boolean = healthBridge.restoreHealthSnapshot(json)

    @OptIn(ExperimentalForeignApi::class)
    private fun createFacade(
        dataSource: MemoryAuthStoreDataSource,
        healthDataSource: InMemoryHealthDashboardStateDataSource
    ): LoginFacade {
        return LoginFacade(
            LoginStore.create(
                authRepository = remoteRepository,
                onDeleteUserData = healthDataSource::clear
            )
        )
    }

    private fun createHealthFacade(
        dataSource: MemoryAuthStoreDataSource,
        healthDataSource: InMemoryHealthDashboardStateDataSource
    ): HealthFacade {
        return HealthFacadeFactory().createPersistent(
            authRepository = remoteRepository,
            stateDataSource = healthDataSource
        )
    }

    @OptIn(ExperimentalForeignApi::class)
    private fun syncClock() {
        facade.setCurrentTimeEpochMs(time(null) * 1000L)
    }
}

private class MemoryAuthStoreDataSource(
    initialStore: MockAuthStore = MockAuthStore()
) : AuthStoreDataSource {
    private var store: MockAuthStore = initialStore

    override fun load(): MockAuthStore = store

    override fun save(store: MockAuthStore): Boolean {
        this.store = store
        return true
    }

    fun replaceStore(newStore: MockAuthStore) {
        this.store = newStore
    }
}
