package com.example.demo.common.login

@Suppress("unused") // Exported to Swift through Shared.framework; Kotlin callers do not reference it directly.
class LoginFacade(
    private val store: LoginStore
) {
    constructor() : this(LoginStore.createFake())

    val state: LoginState
        get() = store.state

    fun setUsername(value: String) {
        store.dispatch(LoginAction.UsernameChanged(value))
    }

    fun setPassword(value: String) {
        store.dispatch(LoginAction.PasswordChanged(value))
    }

    fun setRegisterMode() {
        store.dispatch(LoginAction.ModeChanged(AuthMode.Register))
    }

    fun setLoginMode() {
        store.dispatch(LoginAction.ModeChanged(AuthMode.Login))
    }

    fun setVerifyCode(value: String) {
        store.dispatch(LoginAction.VerifyCodeChanged(value))
    }

    fun setDisplayName(value: String) {
        store.dispatch(LoginAction.DisplayNameChanged(value))
    }

    fun setRegion(value: String) {
        store.dispatch(LoginAction.RegionChanged(value))
    }

    fun normalizePhoneInput(value: String): String {
        return LoginRules.normalizePhoneInput(value)
    }

    fun normalizeEmailInput(value: String): String {
        return LoginRules.normalizeEmailInput(value)
    }

    fun normalizeVerifyCodeInput(value: String): String {
        return LoginRules.normalizeVerifyCodeInput(value)
    }

    fun normalizePasswordInput(value: String): String {
        return LoginRules.normalizePasswordInput(value)
    }

    fun isLoginReady(account: String, password: String, isLoading: Boolean): Boolean {
        return LoginRules.isLoginReady(account, password, isLoading)
    }

    fun isPhoneAccountValid(account: String): Boolean {
        return LoginRules.isPhoneAccountValid(account)
    }

    fun isEmailAccountValid(email: String): Boolean {
        return LoginRules.isEmailAccountValid(email)
    }

    fun isRegisterPasswordReady(
        password: String,
        confirmPassword: String,
        isLoading: Boolean
    ): Boolean {
        return LoginRules.isRegisterPasswordReady(password, confirmPassword, isLoading)
    }

    fun isResetPasswordReady(
        newPassword: String,
        confirmPassword: String,
        isLoading: Boolean
    ): Boolean {
        return newPassword.isNotBlank() &&
            newPassword == confirmPassword &&
            !isLoading
    }

    fun hasAccount(account: String): Boolean {
        return store.hasAccount(account)
    }

    fun isProfileRequiredComplete(
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        gender: String,
        isLoading: Boolean
    ): Boolean {
        if (isLoading) return false
        return UserProfile(
            username = username,
            birthDate = birthDate,
            heightCm = heightCm.takeIf { it > 0 },
            weightKg = weightKg.takeIf { it > 0.0 },
            gender = gender.toUserGenderOrNull()
        ).isRequiredComplete
    }

    fun validatePhoneAccount(account: String): String? {
        return LoginRules.validatePhoneAccount(account).message
    }

    fun validateEmailAccount(email: String): String? {
        return LoginRules.validateEmailAccount(email).message
    }

    fun validateVerifyCode(code: String): String? {
        return LoginRules.validateVerifyCode(code).message
    }

    fun validateRegisterPassword(password: String, confirmPassword: String): String? {
        return LoginRules.validateRegisterPassword(password, confirmPassword).message
    }

    fun requestVerifyCode(account: String): String? {
        return when (val result = store.requestVerifyCode(account)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun requestResentVerifyCode(account: String): String? {
        return when (
            val result = store.requestVerifyCode(
                account = account,
                code = LocalMockAuthRepository.ResentVerifyCode
            )
        ) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun verifyCode(account: String, code: String): String? {
        return when (val result = store.verifyCode(account, code)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun resetPassword(account: String, newPassword: String): String? {
        return when (val result = store.resetPassword(account, newPassword)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun submitProfile(
        avatarUri: String?,
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        measurementSystem: String,
        phone: String,
        countryRegion: String,
        gender: String
    ) {
        store.dispatch(
            LoginAction.ProfileSubmitted(
                UserProfile(
                    avatarUri = avatarUri?.takeIf { it.isNotBlank() },
                    username = username,
                    birthDate = birthDate,
                    heightCm = heightCm.takeIf { it > 0 },
                    weightKg = weightKg.takeIf { it > 0.0 },
                    measurementSystem = measurementSystem.toMeasurementSystemOrDefault(),
                    phone = phone,
                    countryRegion = countryRegion,
                    gender = gender.toUserGenderOrNull()
                )
            )
        )
    }

    fun deleteCurrentAccount(): String? {
        return when (val result = store.deleteCurrentAccount()) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun submit() {
        store.dispatch(LoginAction.SubmitClicked)
    }

    fun logout() {
        store.dispatch(LoginAction.LogoutClicked)
    }

    fun clearSessionSilently() {
        store.clearSessionSilently()
    }

    fun consumeEffect(): LoginEffect? {
        return store.consumeEffect()
    }

    private fun String.toMeasurementSystemOrDefault(): MeasurementSystem {
        return when (this) {
            MeasurementSystem.Imperial.name -> MeasurementSystem.Imperial
            else -> MeasurementSystem.Metric
        }
    }

    private fun String.toUserGenderOrNull(): UserGender? {
        return when (this) {
            UserGender.Female.name -> UserGender.Female
            UserGender.Male.name -> UserGender.Male
            else -> null
        }
    }
}
