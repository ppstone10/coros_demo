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

    fun requestVerifyCode(account: String): String? {
        return when (val result = store.requestVerifyCode(account)) {
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

    fun submit() {
        store.dispatch(LoginAction.SubmitClicked)
    }

    fun logout() {
        store.dispatch(LoginAction.LogoutClicked)
    }

    fun clearSessionSilently() {
        store.clearSessionSilently()
    }

    fun consumeEffectPayload(): LoginEffectPayload? {
        return store.consumeEffectPayload()
    }
}
