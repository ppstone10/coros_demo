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
    val profile: UserProfile? = null,
    val issuedAtEpochMs: Long = 0L,
    val expireAtEpochMs: Long = 0L
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

data class MockAuthRegion(
    val region: String,
    val displayName: String,
    val isDefault: Boolean = false
)

fun MockAuthRegion.toDomain() = AuthRegion(region, displayName, isDefault)
fun AuthRegion.toMockRegion() = MockAuthRegion(region, displayName, isDefault)

/** 将认证区域、国家代码或旧版国家展示名称归一为可持久化的稳定代码。 */
fun String.toProfileCountryCode(fallback: String = "CN"): String {
    return when (trim().uppercase()) {
        "US", "\u7F8E\u56FD", "UNITED STATES", "UNITED STATES OF AMERICA" -> "US"
        "GB", "UK", "\u82F1\u56FD", "UNITED KINGDOM", "GREAT BRITAIN" -> "GB"
        "JP", "\u65E5\u672C", "JAPAN" -> "JP"
        "CN", "\u4E2D\u56FD", "CHINA", "PEOPLE'S REPUBLIC OF CHINA" -> "CN"
        else -> when (fallback.trim().uppercase()) {
            "US" -> "US"
            "GB", "UK" -> "GB"
            "JP" -> "JP"
            else -> "CN"
        }
    }
}

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
    val profile: UserProfile? = null,
    val issuedAtEpochMs: Long = 0L,
    val expireAtEpochMs: Long = 0L
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
    val countryRegion: String = "CN",
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

sealed interface SessionResumeResult {
    data class Active(val session: AuthSession) : SessionResumeResult
    data object NoSession : SessionResumeResult
    data object Expired : SessionResumeResult
    data class Failure(val error: MockError) : SessionResumeResult
}

enum class MockError(val code: String, val message: String) {
    AuthRequired("AUTH_REQUIRED", AuthMessageKeys.ErrorAuthRequired),
    InvalidParam("AUTH_INVALID_PARAM", AuthMessageKeys.ErrorInvalidParam),
    AccountExists("AUTH_ACCOUNT_EXISTS", AuthMessageKeys.ErrorAccountExists),
    AccountNotFound("AUTH_ACCOUNT_NOT_FOUND", AuthMessageKeys.ErrorAccountNotFound),
    PasswordIncorrect("AUTH_PASSWORD_INCORRECT", AuthMessageKeys.ErrorPasswordIncorrect),
    NewPasswordSameAsOld("AUTH_NEW_PASSWORD_SAME_AS_OLD", AuthMessageKeys.ErrorNewPasswordSameAsOld),
    VerifyCodeInvalid("AUTH_VERIFY_CODE_INVALID", AuthMessageKeys.ErrorVerifyCodeInvalid),
    VerifyCodeExpired("AUTH_VERIFY_CODE_EXPIRED", AuthMessageKeys.ErrorVerifyCodeExpired),
    EmptyData("AUTH_EMPTY_DATA", AuthMessageKeys.ErrorEmptyData),
    CorruptedData("AUTH_CORRUPTED_DATA", AuthMessageKeys.ErrorCorruptedData),
    PersistFailed("AUTH_PERSIST_FAILED", AuthMessageKeys.ErrorPersistFailed),
    RegionRequired("AUTH_REGION_REQUIRED", AuthMessageKeys.ErrorRegionRequired),
    MinimumCardsRequired("HEALTH_MINIMUM_CARDS", AuthMessageKeys.ErrorMinimumCardsRequired)
}

/** 对应 auth_mock.proto 的 MockErrorMessage；错误只在内存中传递，不作为登录态持久化。 */
data class MockErrorMessage(val code: String, val message: String)

fun MockError.toProtoMessage() = MockErrorMessage(
    code = when (this) {
        MockError.AuthRequired -> "AUTH_REQUIRED"
        MockError.InvalidParam -> "INVALID_PARAM"
        MockError.AccountExists -> "ACCOUNT_EXISTS"
        MockError.AccountNotFound -> "ACCOUNT_NOT_FOUND"
        MockError.PasswordIncorrect -> "PASSWORD_INCORRECT"
        MockError.VerifyCodeInvalid -> "VERIFY_CODE_INVALID"
        MockError.VerifyCodeExpired -> "VERIFY_CODE_EXPIRED"
        MockError.PersistFailed -> "PERSIST_FAILED"
        MockError.RegionRequired -> "REGION_REQUIRED"
        MockError.NewPasswordSameAsOld -> "NEW_PASSWORD_SAME_AS_OLD"
        MockError.EmptyData -> "EMPTY_DATA"
        MockError.CorruptedData -> "CORRUPTED_DATA"
        MockError.MinimumCardsRequired -> "HEALTH_MINIMUM_CARDS"
    },
    message = message
)

fun MockErrorMessage.toMockError(): MockError? = MockError.entries.firstOrNull {
    it.toProtoMessage().code == code
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

enum class PostLoginRoute {
    SignedIn,
    ProfileCompletion
}

sealed interface LoginEffect {
    data class NavigateHome(val user: UserDto) : LoginEffect
    data class AuthSucceeded(val session: AuthSession, val mode: AuthMode, val nextRoute: PostLoginRoute) : LoginEffect {
        val isNextRouteSignedIn: Boolean get() = nextRoute == PostLoginRoute.SignedIn
    }
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
        profile = profile,
        issuedAtEpochMs = issuedAtEpochMs,
        expireAtEpochMs = expireAtEpochMs
    )
}

fun AuthSession.toMockSession(): MockAuthSession {
    return MockAuthSession(
        userId = userId,
        account = account,
        displayName = displayName.orEmpty(),
        region = region,
        isValid = isValid,
        profile = profile,
        issuedAtEpochMs = issuedAtEpochMs,
        expireAtEpochMs = expireAtEpochMs
    )
}
