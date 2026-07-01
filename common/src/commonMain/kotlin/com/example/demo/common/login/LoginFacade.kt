package com.example.demo.common.login

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

    fun submit() {
        store.dispatch(LoginAction.SubmitClicked)
    }

    fun logout() {
        store.dispatch(LoginAction.LogoutClicked)
    }

    fun consumeEffectPayload(): LoginEffectPayload? {
        return store.consumeEffectPayload()
    }
}
