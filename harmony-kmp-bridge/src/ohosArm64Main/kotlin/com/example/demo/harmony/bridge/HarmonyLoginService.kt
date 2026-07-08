package com.example.demo.harmony.bridge

import com.example.demo.common.login.AuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.LoginFacade
import com.example.demo.common.login.LoginStore
import com.example.demo.common.login.MockAuthStore
import com.tencent.tmm.knoi.annotation.ServiceProvider

@ServiceProvider
open class HarmonyLoginService {
    private var dataSource: AuthStoreDataSource = MemoryAuthStoreDataSource()
    private var facade: LoginFacade = createFacade(dataSource)

    fun stateSnapshot(): String {
        return HarmonyLoginJson.stateSnapshot(facade.state)
    }

    fun exportStoreSnapshot(): String {
        return HarmonyLoginJson.storeSnapshot(dataSource.load())
    }

    fun restoreStoreSnapshot(json: String): Boolean {
        if (json.isBlank()) return false
        return try {
            val store = HarmonyLoginJson.parseStoreSnapshot(json)
            dataSource = MemoryAuthStoreDataSource(store)
            facade = createFacade(dataSource)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun validateStoreSnapshotRoundTrip(json: String): Boolean {
        return HarmonyLoginJson.isStoreSnapshotRoundTripStable(json)
    }

    fun validateCurrentStoreSnapshotRoundTrip(): Boolean {
        return HarmonyLoginJson.isStoreSnapshotRoundTripStable(exportStoreSnapshot())
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

    fun submit() {
        facade.submit()
    }

    fun logout() {
        facade.logout()
    }

    fun clearSessionSilently() {
        facade.clearSessionSilently()
    }

    fun consumeEffectSnapshot(): String {
        return HarmonyLoginJson.effectSnapshot(facade.consumeEffect())
    }

    fun validateLogin(account: String, password: String): Boolean {
        return facade.isLoginReady(account, password, isLoading = false)
    }

    fun validateLoginInput(account: String, password: String): String {
        return facade.validateLoginInput(account, password).orEmpty()
    }

    fun requestVerifyCode(account: String): String {
        return facade.requestVerifyCode(account).orEmpty()
    }

    fun requestResentVerifyCode(account: String): String {
        return facade.requestResentVerifyCode(account).orEmpty()
    }

    fun verifyCode(account: String, code: String): String {
        return facade.verifyCode(account, code).orEmpty()
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
            countryRegion = countryRegion,
            gender = gender
        )
    }

    fun deleteCurrentAccount(): String {
        return facade.deleteCurrentAccount().orEmpty()
    }

    private fun createFacade(dataSource: AuthStoreDataSource): LoginFacade {
        return LoginFacade(LoginStore.create(LocalMockAuthRepository(dataSource)))
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
}
