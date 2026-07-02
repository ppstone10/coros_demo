package com.example.demo.common.login

class LoginUseCase(
    private val authRepository: AuthRepository
) {
    fun execute(account: String, password: String): LoginResult {
        val normalizedAccount = account.trim()

        if (normalizedAccount.isBlank()) {
            return LoginResult.Failure(
                code = MockError.InvalidParam.code,
                message = "请输入账号"
            )
        }

        if (password.isBlank()) {
            return LoginResult.Failure(
                code = MockError.InvalidParam.code,
                message = "请输入密码"
            )
        }

        if (password.length < LoginRules.PasswordMinLength) {
            return LoginResult.Failure(
                code = MockError.InvalidParam.code,
                message = "密码需要为6-20位"
            )
        }

        return authRepository.login(
            LoginRequestDto(
                account = normalizedAccount,
                password = password
            )
        )
    }
}

class RegisterUseCase(
    private val authRepository: AuthRepository
) {
    fun execute(
        account: String,
        password: String,
        verifyCode: String,
        region: String,
        displayName: String?
    ): LoginResult {
        return authRepository.register(
            RegisterRequestDto(
                account = account.trim(),
                password = password,
                verifyCode = verifyCode.trim(),
                region = region.trim(),
                displayName = displayName
            )
        )
    }
}
