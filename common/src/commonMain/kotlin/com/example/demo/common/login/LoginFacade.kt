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

    fun submit() {
        store.dispatch(LoginAction.SubmitClicked)
    }

    fun consumeEffectPayload(): LoginEffectPayload? {
        return store.consumeEffectPayload()
    }
}
