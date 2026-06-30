package com.example.demo.common.login

data class LoginRequestDto(
    val username: String,
    val password: String
)

data class UserDto(
    val id: String,
    val displayName: String,
    val accessToken: String
)

data class LoginState(
    val username: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val isLoggedIn: Boolean = false,
    val errorMessage: String? = null
) {
    val canSubmit: Boolean
        get() = username.isNotBlank() && password.isNotBlank() && !isLoading
}

sealed interface LoginAction {
    data class UsernameChanged(val username: String) : LoginAction
    data class PasswordChanged(val password: String) : LoginAction
    data object SubmitClicked : LoginAction
    data object EffectConsumed : LoginAction
}

sealed interface LoginEffect {
    data class NavigateHome(val user: UserDto) : LoginEffect
    data class ShowMessage(val message: String) : LoginEffect
}

data class LoginEffectPayload(
    val type: String,
    val message: String? = null,
    val userId: String? = null,
    val displayName: String? = null
)

sealed interface LoginResult {
    data class Success(val user: UserDto) : LoginResult
    data class Failure(val code: String, val message: String) : LoginResult
}
