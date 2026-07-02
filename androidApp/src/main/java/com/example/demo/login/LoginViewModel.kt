package com.example.demo.login

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginAction
import com.example.demo.common.login.LoginEffect
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

    fun hasAccount(account: String): Boolean {
        return store.hasAccount(account)
    }

    fun requestVerifyCode(
        account: String,
        code: String = LocalMockAuthRepository.DefaultVerifyCode
    ): MockResult<MockVerifyCodeState> {
        return store.requestVerifyCode(account, code)
    }

    fun verifyCode(account: String, code: String): MockResult<Unit> {
        return store.verifyCode(account, code)
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
