package com.example.demo.common.auth.usecase
import com.example.demo.common.auth.model.AuthMessageKeys
import com.example.demo.common.auth.model.LoginRequestDto
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.RegisterRequestDto
import com.example.demo.common.auth.repository.AuthRepository
import com.example.demo.common.auth.rules.LoginRules

class LoginUseCase(
    private val authRepository: AuthRepository
) {
    /** force=true 表示用户已在二次确认中同意挤下线其他设备（MSRV-016）。 */
    fun execute(account: String, password: String, force: Boolean = false): LoginResult {
        val normalizedAccount = account.trim()

        if (normalizedAccount.isBlank()) {
            return LoginResult.Failure(
                code = MockError.InvalidParam.code,
                message = AuthMessageKeys.ValidationAccountRequired
            )
        }

        if (password.isBlank()) {
            return LoginResult.Failure(
                code = MockError.InvalidParam.code,
                message = AuthMessageKeys.ValidationPasswordRequired
            )
        }

        if (password.length < LoginRules.PasswordMinLength) {
            return LoginResult.Failure(
                code = MockError.InvalidParam.code,
                message = AuthMessageKeys.ValidationPasswordLength
            )
        }

        return authRepository.login(
            LoginRequestDto(
                account = normalizedAccount,
                password = password,
                force = force
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
