package com.example.demo.common.login

class LoginStore(
    private val loginUseCase: LoginUseCase
) {
    var state: LoginState = LoginState()
        private set

    private var pendingEffect: LoginEffect? = null

    fun dispatch(action: LoginAction) {
        when (action) {
            is LoginAction.UsernameChanged -> {
                state = state.copy(
                    username = action.username,
                    errorMessage = null
                )
            }

            is LoginAction.PasswordChanged -> {
                state = state.copy(
                    password = action.password,
                    errorMessage = null
                )
            }

            LoginAction.SubmitClicked -> submit()
            LoginAction.EffectConsumed -> pendingEffect = null
        }
    }

    fun consumeEffect(): LoginEffect? {
        val effect = pendingEffect
        pendingEffect = null
        return effect
    }

    fun consumeEffectPayload(): LoginEffectPayload? {
        return when (val effect = consumeEffect()) {
            is LoginEffect.NavigateHome -> LoginEffectPayload(
                type = "NavigateHome",
                userId = effect.user.id,
                displayName = effect.user.displayName
            )

            is LoginEffect.ShowMessage -> LoginEffectPayload(
                type = "ShowMessage",
                message = effect.message
            )

            null -> null
        }
    }

    private fun submit() {
        if (!state.canSubmit) {
            val message = "请输入用户名和密码"
            state = state.copy(errorMessage = message)
            pendingEffect = LoginEffect.ShowMessage(message)
            return
        }

        state = state.copy(isLoading = true, errorMessage = null)

        when (val result = loginUseCase.execute(state.username, state.password)) {
            is LoginResult.Success -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    errorMessage = null
                )
                pendingEffect = LoginEffect.NavigateHome(result.user)
            }

            is LoginResult.Failure -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = false,
                    errorMessage = result.message
                )
                pendingEffect = LoginEffect.ShowMessage(result.message)
            }
        }
    }

    companion object {
        fun createFake(): LoginStore {
            return LoginStore(LoginUseCase(FakeAuthRepository()))
        }
    }
}
