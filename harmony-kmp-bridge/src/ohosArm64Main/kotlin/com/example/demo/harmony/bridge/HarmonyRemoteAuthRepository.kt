package com.example.demo.harmony.bridge

import com.example.demo.common.auth.mock.AuthJson
import com.example.demo.common.auth.mock.LocalMockAuthRepository
import com.example.demo.common.auth.mock.MockAuthStoreJson
import com.example.demo.common.auth.model.ActiveDeviceInfo
import com.example.demo.common.auth.model.AuthRegion
import com.example.demo.common.auth.model.AuthSession
import com.example.demo.common.auth.model.LoginRequestDto
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.MockAccount
import com.example.demo.common.auth.model.MockAuthSession
import com.example.demo.common.auth.model.MockAuthStore
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.MockErrorMessage
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.auth.model.MockVerifyCodeState
import com.example.demo.common.auth.model.RegisterRequestDto
import com.example.demo.common.auth.model.SessionResumeResult
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.model.toDomainOrNull
import com.example.demo.common.auth.model.toMockError
import com.example.demo.common.auth.repository.AuthRepository
import com.example.demo.common.auth.repository.AuthStoreDataSource

/**
 * HARM-002/003/008：鸿蒙远程认证仓库。
 *
 * 委托 [LocalMockAuthRepository]，但对 `login`/`register`/`resumeSessionInSameProcess`/
 * `restoreSessionOnColdStart` 先消费 ArkTS 侧经 [HarmonyLoginService] staging 的服务器结果。
 * 服务器为权威（MSRV-001）；staging 空时完全委托本地仓库（行为与现状一致）。
 * 槽位只消费一次并立即清空，`clearStaged` 可显式清空。
 */
internal class HarmonyRemoteAuthRepository(
    private val dataSource: AuthStoreDataSource,
    nowEpochMs: () -> Long = { 0L }
) : AuthRepository {

    private val delegate = LocalMockAuthRepository(dataSource, nowEpochMs)

    private sealed interface Staged {
        data class Session(val store: MockAuthStore) : Staged
        data class ForceConflict(val activeDevice: ActiveDeviceInfo?) : Staged
        data class Error(val code: String) : Staged
        data object Expired : Staged
    }

    private var staged: Staged? = null

    // ---- staging 入口（由 ArkTS 侧在触发 KMP 状态机前调用）----

    /** 服务器已签发会话（登录/注册成功）。json 为 mini store（含 currentSession）。 */
    fun stageServerLoginResult(json: String): Boolean {
        if (json.isBlank()) return false
        return try {
            val store = MockAuthStoreJson.decode(json)
            if (store.currentSession == null) return false
            staged = Staged.Session(store)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** 服务器返回 409 的 activeDevice（{deviceId, deviceName}）。 */
    fun stageForceLogin(json: String): Boolean {
        if (json.isBlank()) {
            staged = Staged.ForceConflict(null)
            return true
        }
        return try {
            val deviceId = AuthJson.optionalString(json, "deviceId").orEmpty()
            val deviceName = AuthJson.optionalString(json, "deviceName").orEmpty()
            val device = if (deviceId.isBlank() && deviceName.isBlank()) {
                null
            } else {
                ActiveDeviceInfo(deviceId, deviceName)
            }
            staged = Staged.ForceConflict(device)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** 服务器业务错误（code 为服务端错误码，映射到既有 [MockError] 语义）。 */
    fun stageServerError(code: String) {
        staged = Staged.Error(code)
    }

    /** 会话懒校验发现本地会话已过期（AUTH_REQUIRED）。 */
    fun stageSessionExpired() {
        staged = Staged.Expired
    }

    fun clearStaged() {
        staged = null
    }

    // ---- 覆盖点：消费 staging 后短路，否则委托本地 ----

    override fun login(request: LoginRequestDto): LoginResult {
        val current = staged
        staged = null
        return when (current) {
            is Staged.Session -> completeWithServerSession(current.store)
            is Staged.ForceConflict -> LoginResult.SessionActiveElsewhere(current.activeDevice)
            is Staged.Error -> errorResult(current.code)
            else -> delegate.login(request)
        }
    }

    override fun register(request: RegisterRequestDto): LoginResult {
        val current = staged
        staged = null
        return when (current) {
            is Staged.Session -> {
                val store = current.store
                val session = store.currentSession
                if (session == null) return delegate.register(request)
                val domain = session.toDomainOrNull() ?: return failure()
                val now = dataSource.load()
                val account = MockAccount(
                    userId = session.userId,
                    account = session.account,
                    passwordHash = mockHash(request.password),
                    displayName = session.displayName.ifBlank {
                        request.displayName?.trim().orEmpty()
                    }.ifBlank { session.account },
                    region = session.region.ifBlank { request.region },
                    profile = session.profile
                )
                dataSource.save(
                    now.copy(
                        accounts = now.accounts.filterNot { it.userId == session.userId } + account,
                        currentSession = session,
                        verifyCodes = now.verifyCodes.filterNot {
                            it.account.equals(session.account, ignoreCase = true)
                        },
                        defaultAccountsInitialized = true
                    )
                )
                LoginResult.Success(domain)
            }
            is Staged.Error -> errorResult(current.code)
            else -> delegate.register(request)
        }
    }

    override fun resumeSessionInSameProcess(): SessionResumeResult {
        if (staged is Staged.Expired) {
            staged = null
            delegate.clearSession()
            return SessionResumeResult.Expired
        }
        return delegate.resumeSessionInSameProcess()
    }

    override fun restoreSessionOnColdStart(): SessionResumeResult {
        if (staged is Staged.Expired) {
            staged = null
            delegate.clearSession()
            return SessionResumeResult.Expired
        }
        return delegate.restoreSessionOnColdStart()
    }

    // ---- 委托其余接口 ----

    override fun availableRegions(): List<AuthRegion> = delegate.availableRegions()
    override fun hasAccount(account: String): Boolean = delegate.hasAccount(account)
    override fun requestVerifyCode(account: String, code: String): MockResult<MockVerifyCodeState> =
        delegate.requestVerifyCode(account, code)
    override fun verifyCode(account: String, code: String): MockResult<Unit> =
        delegate.verifyCode(account, code)
    override fun verifyCodeRemainingSeconds(account: String): Int =
        delegate.verifyCodeRemainingSeconds(account)
    override fun setCurrentTimeEpochMs(value: Long) = delegate.setCurrentTimeEpochMs(value)
    override fun currentSession(): AuthSession? = delegate.currentSession()
    override fun requireSession(): AuthSession = delegate.requireSession()
    override fun saveSession(session: AuthSession): MockResult<AuthSession> =
        delegate.saveSession(session)
    override fun saveProfile(profile: UserProfile): MockResult<AuthSession> =
        delegate.saveProfile(profile)
    override fun clearSession(): MockResult<Unit> = delegate.clearSession()
    override fun markSessionExpired(): MockResult<Unit> = delegate.markSessionExpired()
    override fun pauseSession(): MockResult<Unit> = delegate.pauseSession()
    override fun resumeSession(): SessionResumeResult = delegate.resumeSession()
    override fun changePassword(account: String, oldPassword: String, newPassword: String): MockResult<Unit> =
        delegate.changePassword(account, oldPassword, newPassword)
    override fun resetPassword(account: String, newPassword: String): MockResult<Unit> =
        delegate.resetPassword(account, newPassword)
    override fun deleteCurrentAccount(): MockResult<Unit> = delegate.deleteCurrentAccount()
    override fun verifyBusinessAccess(): MockResult<AuthSession> = delegate.verifyBusinessAccess()

    private fun completeWithServerSession(serverStore: MockAuthStore): LoginResult {
        val session = serverStore.currentSession
        if (session == null) return failure()
        val domain = session.toDomainOrNull() ?: return failure()
        val now = dataSource.load()
        val accounts = now.accounts.map { account ->
            if (account.userId == session.userId) {
                account.copy(
                    displayName = session.displayName.ifBlank { account.displayName },
                    profile = session.profile ?: account.profile
                )
            } else {
                account
            }
        }
        val hasAccount = now.accounts.any { it.userId == session.userId }
        val finalAccounts = if (hasAccount) {
            accounts
        } else {
            val account = serverStore.accounts.firstOrNull { it.userId == session.userId }
                ?: MockAccount(
                    userId = session.userId,
                    account = session.account,
                    passwordHash = "",
                    displayName = session.displayName.ifBlank { session.account },
                    region = session.region,
                    profile = session.profile
                )
            accounts + account
        }
        dataSource.save(
            now.copy(
                accounts = finalAccounts,
                currentSession = session,
                defaultAccountsInitialized = true
            )
        )
        return LoginResult.Success(domain)
    }

    private fun errorResult(code: String): LoginResult.Failure {
        val error = MockErrorMessage(code, "").toMockError() ?: MockError.PersistFailed
        return LoginResult.Failure(error.code, error.message)
    }

    private fun failure(): LoginResult.Failure {
        return LoginResult.Failure(MockError.PersistFailed.code, MockError.PersistFailed.message)
    }

    private fun mockHash(password: String): String = "mock:${password.reversed()}:${password.length}"
}
