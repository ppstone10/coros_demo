package com.example.demo.common.login

class LoginUseCase(
    private val authRepository: AuthRepository
) {
    fun execute(username: String, password: String): LoginResult {
        val normalizedUsername = username.trim()

        if (normalizedUsername.isBlank()) {
            return LoginResult.Failure(
                code = "AUTH_USERNAME_REQUIRED",
                message = "请输入用户名"
            )
        }

        if (password.isBlank()) {
            return LoginResult.Failure(
                code = "AUTH_PASSWORD_REQUIRED",
                message = "请输入密码"
            )
        }

        return authRepository.login(
            LoginRequestDto(
                username = normalizedUsername,
                password = password
            )
        )
    }
}
