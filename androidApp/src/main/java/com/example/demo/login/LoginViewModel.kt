package com.example.demo.login

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginAction
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.LoginRules
import com.example.demo.common.login.LoginState
import com.example.demo.common.login.LoginStore
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.MockResult
import com.example.demo.common.login.MockVerifyCodeState
import com.example.demo.common.login.UserProfile
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.health.AndroidHealthDashboardStateDataSource

class LoginViewModel(
    private val store: LoginStore = LoginStore.createFake()
) {
    var state: LoginState by mutableStateOf(store.state)
        private set

    var effect: LoginEffect? by mutableStateOf(null)
        private set

    fun onModeChanged(mode: AuthMode) {
        dispatch(LoginAction.ModeChanged(mode))
    }

    fun onUsernameChanged(value: String) {
        dispatch(LoginAction.UsernameChanged(value))
    }

    fun onPasswordChanged(value: String) {
        dispatch(LoginAction.PasswordChanged(value))
    }

    fun onSubmit() {
        dispatch(LoginAction.SubmitClicked)
    }

    fun onVerifyCodeChanged(value: String) {
        dispatch(LoginAction.VerifyCodeChanged(value))
    }

    fun onDisplayNameChanged(value: String) {
        dispatch(LoginAction.DisplayNameChanged(value))
    }

    fun onRegionChanged(value: String) {
        dispatch(LoginAction.RegionChanged(value))
    }

    fun onProfileSubmitted(profile: UserProfile) {
        dispatch(LoginAction.ProfileSubmitted(profile))
    }

    fun updateProfileMessage(profile: UserProfile): String? {
        val message = when (val result = store.updateProfile(profile)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
        state = store.state
        return message
    }

    fun onLogout() {
        dispatch(LoginAction.LogoutClicked)
    }

    fun onExpireSession() {
        dispatch(LoginAction.ExpireSessionClicked)
    }

    fun onAppBackgrounded() {
        store.pauseSession()
        state = store.state
    }

    fun onAppForegrounded() {
        store.resumeSession()
        state = store.state
        effect = store.consumeEffect()
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

    fun canSubmitLogin(): Boolean {
        return LoginRules.isLoginReady(state.account, state.password, state.isLoading)
    }

    fun canRequestPhoneCode(): Boolean {
        return LoginRules.isPhoneAccountValid(state.account) && !state.isLoading
    }

    fun canRequestEmailCode(email: String): Boolean {
        return LoginRules.isEmailAccountValid(email) && !state.isLoading
    }

    fun canRegisterWithPassword(password: String, confirmPassword: String): Boolean {
        return LoginRules.isRegisterPasswordReady(password, confirmPassword, state.isLoading)
    }

    fun canSubmitResetPassword(
        newPassword: String,
        confirmPassword: String
    ): Boolean {
        return newPassword.isNotBlank() &&
            newPassword == confirmPassword &&
            !state.isLoading
    }

    fun canSubmitProfile(profile: UserProfile): Boolean {
        return profile.isRequiredComplete && !state.isLoading
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

    fun changePasswordMessage(
        account: String,
        oldPassword: String,
        newPassword: String
    ): String? {
        return when (val result = store.changePassword(account, oldPassword, newPassword)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun resetPasswordMessage(
        account: String,
        newPassword: String
    ): String? {
        return when (val result = store.resetPassword(account, newPassword)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun deleteCurrentAccountMessage(): String? {
        val message = when (val result = store.deleteCurrentAccount()) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
        state = store.state
        return message
    }

    fun hasAccount(account: String): Boolean {
        return store.hasAccount(account)
    }

    fun requestVerifyCode(
        account: String,
        code: String = LocalMockAuthRepository.DefaultVerifyCode
    ): MockResult<MockVerifyCodeState> {
        return store.requestVerifyCode(account, code)
    }

    fun requestVerifyCodeMessage(account: String): String? {
        return when (val result = requestVerifyCode(account)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun requestResentVerifyCodeMessage(account: String): String? {
        return when (
            val result = requestVerifyCode(
                account,
                LocalMockAuthRepository.ResentVerifyCode
            )
        ) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun verifyCode(account: String, code: String): MockResult<Unit> {
        return store.verifyCode(account, code)
    }

    fun verifyCodeMessage(account: String, code: String): String? {
        return when (val result = verifyCode(account, code)) {
            is MockResult.Success -> null
            is MockResult.Failure -> result.error.message
        }
    }

    fun clearSessionSilently() {
        store.clearSessionSilently()
        state = store.state
    }

    fun loadHealthDashboard() = store.loadHealthDashboard()

    fun selectHealthScenario(scenario: HealthMockScenario) = store.selectHealthScenario(scenario)

    fun saveHealthCardConfiguration(types: List<com.example.demo.common.health.HealthCardType>) =
        store.saveHealthCardConfiguration(types)

    fun onEffectConsumed() {
        effect = null
    }

    private fun dispatch(action: LoginAction) {
        store.dispatch(action)
        state = store.state
        effect = store.consumeEffect()
    }

    companion object {
        fun create(context: Context): LoginViewModel {
            val repository = LocalMockAuthRepository(
                AndroidAuthStoreDataSource(context.applicationContext),
                nowEpochMs = { System.currentTimeMillis() }
            )
            return LoginViewModel(
                LoginStore.create(
                    authRepository = repository,
                    healthStateDataSource = AndroidHealthDashboardStateDataSource(context.applicationContext)
                )
            )
        }
    }
}
