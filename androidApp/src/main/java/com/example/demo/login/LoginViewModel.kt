package com.example.demo.login

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.example.demo.common.login.LoginAction
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.LoginState
import com.example.demo.common.login.LoginStore

class LoginViewModel(
    private val store: LoginStore = LoginStore.createFake()
) {
    var state: LoginState by mutableStateOf(store.state)
        private set

    var effect: LoginEffect? by mutableStateOf(null)
        private set

    fun onUsernameChanged(value: String) {
        dispatch(LoginAction.UsernameChanged(value))
    }

    fun onPasswordChanged(value: String) {
        dispatch(LoginAction.PasswordChanged(value))
    }

    fun onSubmit() {
        dispatch(LoginAction.SubmitClicked)
    }

    fun onEffectConsumed() {
        effect = null
    }

    private fun dispatch(action: LoginAction) {
        store.dispatch(action)
        state = store.state
        effect = store.consumeEffect()
    }
}
