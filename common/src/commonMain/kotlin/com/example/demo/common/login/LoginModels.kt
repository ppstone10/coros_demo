package com.example.demo.common.login

data class LoginRequestDto(
    val account: String,
    val password: String
)

data class RegisterRequestDto(
    val account: String,
    val password: String,
    val verifyCode: String,
    val region: String,
    val displayName: String?
)

data class AuthSession(
    val userId: String,
    val account: String,
    val displayName: String?,
    val region: String,
    val isValid: Boolean,
    val profile: UserProfile? = null
) {
    val resolvedDisplayName: String
        get() = profile?.username?.takeIf { it.isNotBlank() }
            ?: displayName?.takeIf { it.isNotBlank() }
            ?: account

    val isProfileComplete: Boolean
        get() = profile?.isRequiredComplete == true
}

data class AuthRegion(
    val region: String,
    val displayName: String,
    val isDefault: Boolean = false
)

data class MockAccount(
    val userId: String,
    val account: String,
    val passwordHash: String,
    val displayName: String,
    val region: String,
    val profile: UserProfile? = null
)

data class MockAuthSession(
    val userId: String = "",
    val account: String = "",
    val displayName: String = "",
    val region: String = "",
    val isValid: Boolean = false,
    val profile: UserProfile? = null
)

data class MockVerifyCodeState(
    val account: String,
    val code: String,
    val expireAtEpochMs: Long
)

data class MockAuthStore(
    val accounts: List<MockAccount> = emptyList(),
    val currentSession: MockAuthSession? = null,
    val verifyCodes: List<MockVerifyCodeState> = emptyList(),
    val defaultAccountsInitialized: Boolean = false
)

enum class UserGender {
    Female,
    Male
}

enum class MeasurementSystem {
    Metric,
    Imperial
}

data class UserProfile(
    val avatarUri: String? = null,
    val username: String = "",
    val birthDate: String = "",
    val heightCm: Int? = null,
    val weightKg: Double? = null,
    val measurementSystem: MeasurementSystem = MeasurementSystem.Metric,
    val phone: String = "",
    val countryRegion: String = "中国",
    val gender: UserGender? = null
) {
    val isRequiredComplete: Boolean
        get() = username.isNotBlank() &&
            birthDate.isNotBlank() &&
            heightCm != null &&
            weightKg != null &&
            gender != null
}

sealed interface MockResult<out T> {
    data class Success<T>(val data: T) : MockResult<T>
    data class Failure(val error: MockError) : MockResult<Nothing>
}

enum class MockError(val code: String, val message: String) {
    AuthRequired("AUTH_REQUIRED", "请先登录"),
    InvalidParam("AUTH_INVALID_PARAM", "请输入完整且有效的信息"),
    AccountExists("AUTH_ACCOUNT_EXISTS", "账号已存在"),
    AccountNotFound("AUTH_ACCOUNT_NOT_FOUND", "账号不存在"),
    PasswordIncorrect("AUTH_PASSWORD_INCORRECT", "密码不正确"),
    NewPasswordSameAsOld("AUTH_NEW_PASSWORD_SAME_AS_OLD", "新密码不能与旧密码相同"),
    VerifyCodeInvalid("AUTH_VERIFY_CODE_INVALID", "验证码不正确"),
    VerifyCodeExpired("AUTH_VERIFY_CODE_EXPIRED", "验证码已过期，请重新获取"),
    EmptyData("AUTH_EMPTY_DATA", "暂无本地账号数据"),
    CorruptedData("AUTH_CORRUPTED_DATA", "本地登录数据损坏"),
    PersistFailed("AUTH_PERSIST_FAILED", "本地登录状态保存失败")
}

enum class AuthMode {
    Login,
    Register
}

enum class VerifyTarget {
    Phone,
    Email
}

data class UserDto(
    val id: String,
    val account: String,
    val displayName: String,
    val region: String,
    val isValid: Boolean
)

data class LoginState(
    val mode: AuthMode = AuthMode.Login,
    val username: String = "",
    val password: String = "",
    val verifyCode: String = "",
    val displayName: String = "",
    val selectedRegion: String = "",
    val regions: List<AuthRegion> = emptyList(),
    val currentSession: AuthSession? = null,
    val isLoading: Boolean = false,
    val isLoggedIn: Boolean = currentSession?.isValid == true,
    val errorMessage: String? = null
) {
    val account: String
        get() = username

    val canSubmit: Boolean
        get() {
            if (isLoading) return false
            if (username.isBlank() || password.isBlank()) return false
            return mode == AuthMode.Login ||
                (verifyCode.isNotBlank() && selectedRegion.isNotBlank())
        }
}

sealed interface LoginAction {
    data class ModeChanged(val mode: AuthMode) : LoginAction
    data class UsernameChanged(val username: String) : LoginAction
    data class PasswordChanged(val password: String) : LoginAction
    data class VerifyCodeChanged(val verifyCode: String) : LoginAction
    data class DisplayNameChanged(val displayName: String) : LoginAction
    data class RegionChanged(val region: String) : LoginAction
    data class ProfileSubmitted(val profile: UserProfile) : LoginAction
    data object SubmitClicked : LoginAction
    data object LogoutClicked : LoginAction
    data object ExpireSessionClicked : LoginAction
    data object RestoreSession : LoginAction
    data object EffectConsumed : LoginAction
}

sealed interface LoginEffect {
    data class NavigateHome(val user: UserDto) : LoginEffect
    data class AuthSucceeded(val session: AuthSession, val mode: AuthMode) : LoginEffect
    data class ProfileSaved(val session: AuthSession) : LoginEffect
    data object LoggedOut : LoginEffect
    data object AccountDeleted : LoginEffect
    data object SessionExpired : LoginEffect
    data class ShowMessage(val message: String) : LoginEffect
}

sealed interface LoginResult {
    data class Success(val session: AuthSession) : LoginResult
    data class Failure(val code: String, val message: String) : LoginResult
}

fun MockAuthSession.toDomainOrNull(): AuthSession? {
    if (userId.isBlank() || account.isBlank()) return null
    return AuthSession(
        userId = userId,
        account = account,
        displayName = displayName.takeIf { it.isNotBlank() },
        region = region,
        isValid = isValid,
        profile = profile
    )
}

fun AuthSession.toMockSession(): MockAuthSession {
    return MockAuthSession(
        userId = userId,
        account = account,
        displayName = displayName.orEmpty(),
        region = region,
        isValid = isValid,
        profile = profile
    )
}
