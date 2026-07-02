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

    fun onLogout() {
        dispatch(LoginAction.LogoutClicked)
    }

    fun onExpireSession() {
        dispatch(LoginAction.ExpireSessionClicked)
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
            return LoginViewModel(LoginStore.create(repository))
        }
    }
}
