package com.example.demo.auth.data

import com.example.demo.common.auth.mock.AuthJson
import com.example.demo.common.auth.mock.MockAuthStoreJson
import com.example.demo.common.auth.model.ActiveDeviceInfo
import com.example.demo.common.auth.model.AuthRegion
import com.example.demo.common.auth.model.AuthSession
import com.example.demo.common.auth.model.LoginRequestDto
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.MeasurementSystem
import com.example.demo.common.auth.model.MockAuthSession
import com.example.demo.common.auth.model.MockAuthStore
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.MockErrorMessage
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.auth.model.MockVerifyCodeState
import com.example.demo.common.auth.model.RegisterRequestDto
import com.example.demo.common.auth.model.SessionResumeResult
import com.example.demo.common.auth.model.UserGender
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.model.toDomainOrNull
import com.example.demo.common.auth.model.toMockError
import com.example.demo.common.auth.model.toMockSession
import com.example.demo.common.auth.repository.AuthRepository
import com.example.demo.common.auth.repository.AuthStoreDataSource
import com.example.demo.core.network.MockServerHttpClient

/**
 * Android 平台层远程认证数据源（MSRV-002/003）。
 * 实现与本地 [AuthRepository] 相同的同步接口，内部通过 HTTP 访问 mock server。
 * 会话与会话生命周期（TTL/冷启动懒校验）按 MSRV-006/019 由本地缓存承载，冷启动打
 * `GET /api/auth/session` 发现被顶（MSRV-016/019）。
 */
class RemoteAuthRepository(
    private val http: MockServerHttpClient,
    private val cache: AuthStoreDataSource,
    private val sessionTtlMs: Long = 10 * 1000L,
    private val deviceIdProvider: () -> String = { "device-default" },
    nowEpochMs: () -> Long = { 0L }
) : AuthRepository {
    private var nowEpochMs: () -> Long = nowEpochMs

    override fun availableRegions(): List<AuthRegion> {
        val response = http.post("/api/auth/regions", "{}")
        if (response.status !in 200..299) return emptyList()
        return AuthJson.parseObjectArray(response.body, "regions").map { json ->
            AuthRegion(
                region = AuthJson.optionalString(json, "region").orEmpty(),
                displayName = AuthJson.optionalString(json, "displayName", "display_name").orEmpty(),
                isDefault = AuthJson.parseBooleanOrDefault(json, defaultValue = false, "isDefault", "is_default")
            )
        }
    }

    override fun hasAccount(account: String): Boolean {
        val response = http.get("/api/auth/account?account=${account.urlEncoded()}")
        if (response.status !in 200..299) return false
        return AuthJson.parseBooleanOrDefault(response.body, defaultValue = false, "exists")
    }

    override fun requestVerifyCode(
        account: String,
        code: String
    ): MockResult<MockVerifyCodeState> {
        val response = http.post(
            "/api/auth/verify-code",
            """{"account":${account.jsonString()}}"""
        )
        if (response.status !in 200..299) return parseError(response).failure()
        val expireAtEpochMs = AuthJson.optionalRawValue(response.body, "expireAtEpochMs")
            ?.trim('"')?.toLongOrNull() ?: nowEpochMs()
        val state = MockVerifyCodeState(
            account = account,
            code = code,
            expireAtEpochMs = expireAtEpochMs
        )
        cacheVerifyCode(state)
        return MockResult.Success(state)
    }

    override fun verifyCode(account: String, code: String): MockResult<Unit> {
        val response = http.post(
            "/api/auth/verify-code/check",
            """{"account":${account.jsonString()},"code":${code.jsonString()}}"""
        )
        if (response.status in 200..299) return MockResult.Success(Unit)
        return parseError(response).failure()
    }

    override fun verifyCodeRemainingSeconds(account: String): Int {
        val saved = loadStore().verifyCodes.lastOrNull {
            it.account.equals(account.trim(), ignoreCase = true)
        } ?: return 0
        val remainingMs = saved.expireAtEpochMs - nowEpochMs()
        return ((remainingMs.coerceAtLeast(0) + 999L) / 1000L).toInt()
    }

    override fun setCurrentTimeEpochMs(value: Long) {
        nowEpochMs = { value }
    }

    override fun currentSession(): AuthSession? {
        return loadStore().currentSession
            ?.toDomainOrNull()
            ?.takeIf { it.isValid }
    }

    override fun requireSession(): AuthSession {
        return currentSession() ?: throw IllegalStateException(MockError.AuthRequired.code)
    }

    override fun saveSession(session: AuthSession): MockResult<AuthSession> {
        val store = loadStore()
        cache.save(store.copy(currentSession = session.toMockSession()))
        return MockResult.Success(session)
    }

    override fun saveProfile(profile: UserProfile): MockResult<AuthSession> {
        val session = currentSession() ?: return MockResult.Failure(MockError.AuthRequired)
        val response = http.put(
            "/api/auth/profile",
            """{"userId":${session.userId.jsonString()},"profile":${profile.toProfileJson()}}"""
        )
        if (response.status !in 200..299) return parseError(response).failure()
        val updated = parseSession(response.body)
            ?: return MockResult.Failure(MockError.CorruptedData)
        cache.save(loadStore().copy(currentSession = updated.toMockSession()))
        return MockResult.Success(updated)
    }

    override fun clearSession(): MockResult<Unit> {
        val session = currentSession()
        if (session != null) {
            http.post("/api/auth/logout", """{"userId":${session.userId.jsonString()}}""")
        }
        cache.save(loadStore().copy(currentSession = null))
        return MockResult.Success(Unit)
    }

    override fun markSessionExpired(): MockResult<Unit> {
        val store = loadStore()
        val session = store.currentSession?.toDomainOrNull() ?: return MockResult.Success(Unit)
        val expired = session.copy(isValid = false, expireAtEpochMs = nowEpochMs())
        cache.save(store.copy(currentSession = expired.toMockSession()))
        return MockResult.Success(Unit)
    }

    override fun pauseSession(): MockResult<Unit> {
        val store = loadStore()
        val session = store.currentSession?.toDomainOrNull()?.takeIf { it.isValid }
            ?: return MockResult.Success(Unit)
        val suspended = session.copy(expireAtEpochMs = nowEpochMs() + sessionTtlMs)
        cache.save(store.copy(currentSession = suspended.toMockSession()))
        return MockResult.Success(Unit)
    }

    override fun restoreSessionOnColdStart(): SessionResumeResult {
        val session = loadStore().currentSession?.toDomainOrNull() ?: return SessionResumeResult.NoSession
        checkSessionRemotely(session.userId)?.let { return it }

        val sessionAfter = loadStore().currentSession?.toDomainOrNull()
            ?: return SessionResumeResult.NoSession
        if (!sessionAfter.isValid) {
            return when (clearSession()) {
                is MockResult.Success -> SessionResumeResult.Expired
                is MockResult.Failure -> SessionResumeResult.Failure(MockError.PersistFailed)
            }
        }
        if (sessionAfter.expireAtEpochMs > 0L && sessionAfter.expireAtEpochMs <= nowEpochMs()) {
            return when (clearSession()) {
                is MockResult.Success -> SessionResumeResult.Expired
                is MockResult.Failure -> SessionResumeResult.Failure(MockError.PersistFailed)
            }
        }
        if (sessionAfter.expireAtEpochMs == 0L) return SessionResumeResult.Active(sessionAfter)
        val active = sessionAfter.copy(expireAtEpochMs = 0L)
        cache.save(loadStore().copy(currentSession = active.toMockSession()))
        return SessionResumeResult.Active(active)
    }

    override fun resumeSessionInSameProcess(): SessionResumeResult {
        val session = loadStore().currentSession?.toDomainOrNull()
            ?: return SessionResumeResult.NoSession
        // MSRV-019：暖恢复也打服务器懒校验，回前台即发现被顶
        checkSessionRemotely(session.userId)?.let { return it }

        val store = loadStore()
        val sessionAfter = store.currentSession?.toDomainOrNull()
            ?: return SessionResumeResult.NoSession
        if (!sessionAfter.isValid) {
            return when (clearSession()) {
                is MockResult.Success -> SessionResumeResult.Expired
                is MockResult.Failure -> SessionResumeResult.Failure(MockError.PersistFailed)
            }
        }
        if (sessionAfter.expireAtEpochMs == 0L) return SessionResumeResult.Active(sessionAfter)
        val active = sessionAfter.copy(expireAtEpochMs = 0L)
        cache.save(store.copy(currentSession = active.toMockSession()))
        return SessionResumeResult.Active(active)
    }

    /**
     * MSRV-019：打 `GET /api/auth/session` 懒校验。被顶返回 `KickedElsewhere`、失效返回 `Expired`
     * （均只清本地缓存，不发 logout，避免把其他设备的会话也清掉）；200 或网络失败返回 null。
     */
    private fun checkSessionRemotely(userId: String): SessionResumeResult? {
        val check = http.get("/api/auth/session?userId=${userId.urlEncoded()}")
        return when {
            check.status == 401 && check.body.contains("SESSION_EXPIRED_ELSEWHERE") -> {
                clearLocalSessionOnly()
                SessionResumeResult.KickedElsewhere
            }
            check.status == 401 && check.body.contains("AUTH_REQUIRED") -> {
                clearLocalSessionOnly()
                SessionResumeResult.Expired
            }
            else -> null
        }
    }

    /** 仅清本地会话缓存，不向服务器发 logout。 */
    private fun clearLocalSessionOnly() {
        cache.save(loadStore().copy(currentSession = null))
    }

    override fun resumeSession(): SessionResumeResult = restoreSessionOnColdStart()

    override fun changePassword(
        account: String,
        oldPassword: String,
        newPassword: String
    ): MockResult<Unit> {
        val response = http.post(
            "/api/auth/password/change",
            """{"account":${account.jsonString()},"oldPassword":${oldPassword.jsonString()},"newPassword":${newPassword.jsonString()}}"""
        )
        if (response.status in 200..299) return MockResult.Success(Unit)
        return parseError(response).failure()
    }

    override fun resetPassword(account: String, newPassword: String): MockResult<Unit> {
        val response = http.post(
            "/api/auth/password/reset",
            """{"account":${account.jsonString()},"newPassword":${newPassword.jsonString()}}"""
        )
        if (response.status in 200..299) return MockResult.Success(Unit)
        return parseError(response).failure()
    }

    override fun deleteCurrentAccount(): MockResult<Unit> {
        val session = currentSession() ?: return MockResult.Failure(MockError.AuthRequired)
        val response = http.delete("/api/auth/account", """{"userId":${session.userId.jsonString()}}""")
        if (response.status !in 200..299) return parseError(response).failure()
        cache.save(MockAuthStore())
        return MockResult.Success(Unit)
    }

    override fun register(request: RegisterRequestDto): LoginResult {
        val deviceId = deviceIdProvider()
        val response = http.post(
            "/api/auth/register",
            """{"account":${request.account.jsonString()},"password":${request.password.jsonString()},"verifyCode":${request.verifyCode.jsonString()},"region":${request.region.jsonString()},"displayName":${request.displayName?.jsonString() ?: "null"},"deviceId":${deviceId.jsonString()}}"""
        )
        if (response.status in 200..299) {
            val session = parseSession(response.body)
                ?: return MockError.CorruptedData.toLoginFailure()
            cache.save(loadStore().copy(currentSession = session.toMockSession()))
            return LoginResult.Success(session)
        }
        val error = parseError(response)
        return error.toLoginFailure()
    }

    override fun login(request: LoginRequestDto): LoginResult {
        val deviceId = request.deviceId.ifBlank { deviceIdProvider() }
        val response = http.post(
            "/api/auth/login",
            """{"account":${request.account.jsonString()},"password":${request.password.jsonString()},"deviceId":${deviceId.jsonString()},"force":${request.force}}"""
        )
        // MSRV-016：非 force 登录遇异地会话 -> 触发二次确认
        if (response.status == 409 && response.body.contains("SESSION_ACTIVE_ELSEWHERE")) {
            return LoginResult.SessionActiveElsewhere(parseActiveDevice(response.body))
        }
        if (response.status in 200..299) {
            val session = parseSession(response.body)
                ?: return MockError.CorruptedData.toLoginFailure()
            cache.save(loadStore().copy(currentSession = session.toMockSession()))
            return LoginResult.Success(session)
        }
        return parseError(response).toLoginFailure()
    }

    override fun verifyBusinessAccess(): MockResult<AuthSession> {
        return currentSession()?.let { MockResult.Success(it) }
            ?: MockResult.Failure(MockError.AuthRequired)
    }

    private fun cacheVerifyCode(state: MockVerifyCodeState) {
        val store = loadStore()
        cache.save(
            store.copy(
                verifyCodes = store.verifyCodes.filterNot {
                    it.account.equals(state.account, ignoreCase = true)
                } + state
            )
        )
    }

    private fun loadStore(): MockAuthStore = cache.load()

    private fun parseSession(json: String): AuthSession? {
        val sessionJson = AuthJson.optionalObject(json, "session") ?: return null
        val wrapped = """{"accounts":[],"currentSession":$sessionJson,"verifyCodes":[],"defaultAccountsInitialized":true}"""
        return runCatching { MockAuthStoreJson.decode(wrapped) }
            .getOrNull()
            ?.currentSession
            ?.toDomainOrNull()
    }

    private fun parseError(response: MockServerHttpClient.Response): MockError {
        val errorJson = AuthJson.optionalObject(response.body, "error") ?: return MockError.PersistFailed
        val code = AuthJson.optionalString(errorJson, "code").orEmpty()
        val message = AuthJson.optionalString(errorJson, "message").orEmpty()
        return MockErrorMessage(code, message).toMockError() ?: MockError.PersistFailed
    }

    private fun parseActiveDevice(json: String): ActiveDeviceInfo? {
        val errorJson = AuthJson.optionalObject(json, "error") ?: return null
        val active = AuthJson.optionalObject(errorJson, "activeDevice") ?: return null
        return ActiveDeviceInfo(
            deviceId = AuthJson.optionalString(active, "deviceId").orEmpty(),
            deviceName = AuthJson.optionalString(active, "deviceName").orEmpty()
        )
    }

    private fun MockError.failure(): MockResult.Failure {
        return MockResult.Failure(this)
    }

    private fun MockError.toLoginFailure(): LoginResult.Failure {
        return LoginResult.Failure(code = code, message = message)
    }
}

internal fun AuthSession.toMockSession(): MockAuthSession {
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

private fun UserProfile.toProfileJson(): String {
    return buildString {
        append('{')
        append("\"avatarUri\":")
        append(avatarUri?.jsonString() ?: "null")
        append(",\"username\":")
        append(username.jsonString())
        append(",\"birthDate\":")
        append(birthDate.jsonString())
        append(",\"heightCm\":")
        append(heightCm?.toString() ?: "null")
        append(",\"weightKg\":")
        append(weightKg?.toString() ?: "null")
        append(",\"measurementSystem\":")
        append(measurementSystem.toJsonName().jsonString())
        append(",\"phone\":")
        append(phone.jsonString())
        append(",\"email\":")
        append(email.jsonString())
        append(",\"countryRegion\":")
        append(countryRegion.jsonString())
        append(",\"gender\":")
        append(gender?.toJsonName()?.jsonString() ?: "null")
        append('}')
    }
}

private fun MeasurementSystem.toJsonName(): String = when (this) {
    MeasurementSystem.Metric -> "METRIC"
    MeasurementSystem.Imperial -> "IMPERIAL"
}

private fun UserGender.toJsonName(): String = when (this) {
    UserGender.Male -> "MALE"
    UserGender.Female -> "FEMALE"
}

private fun String.jsonString(): String = "\"${AuthJson.jsonEscaped(this)}\""

private fun String.urlEncoded(): String {
    return java.net.URLEncoder.encode(this, Charsets.UTF_8.name())
}
