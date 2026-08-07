package com.example.demo.common.auth.store
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.auth.mock.LocalMockAuthRepository
import com.example.demo.common.auth.model.AuthMessageKeys
import com.example.demo.common.auth.model.AuthMode
import com.example.demo.common.auth.model.AuthSession
import com.example.demo.common.auth.model.LoginAction
import com.example.demo.common.auth.model.LoginEffect
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.LoginState
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.MockVerifyCodeState
import com.example.demo.common.auth.model.PostLoginRoute
import com.example.demo.common.auth.model.SessionResumeResult
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.repository.AuthRepository
import com.example.demo.common.auth.repository.InMemoryAuthStoreDataSource
import com.example.demo.common.auth.usecase.LoginUseCase
import com.example.demo.common.auth.usecase.RegisterUseCase

class LoginStore(
    private val authRepository: AuthRepository,
    private val loginUseCase: LoginUseCase = LoginUseCase(authRepository),
    private val registerUseCase: RegisterUseCase = RegisterUseCase(authRepository),
    private val onDeleteUserData: (String) -> Boolean = { true }
) {
    var state: LoginState = createInitialState(authRepository)
        private set

    private var pendingEffect: LoginEffect? = null

    private var forceLoginPending = false

    fun dispatch(action: LoginAction) {
        when (action) {
            is LoginAction.ModeChanged -> {
                state = state.copy(
                    mode = action.mode,
                    errorMessage = null
                )
            }

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

            is LoginAction.VerifyCodeChanged -> {
                state = state.copy(
                    verifyCode = action.verifyCode,
                    errorMessage = null
                )
            }

            is LoginAction.DisplayNameChanged -> {
                state = state.copy(
                    displayName = action.displayName,
                    errorMessage = null
                )
            }

            is LoginAction.RegionChanged -> {
                state = state.copy(
                    selectedRegion = action.region,
                    errorMessage = null
                )
            }

            is LoginAction.ProfileSubmitted -> saveProfile(action.profile)
            LoginAction.SubmitClicked -> submit()
            LoginAction.LogoutClicked -> logout()
            LoginAction.ExpireSessionClicked -> expireSession()
            LoginAction.RestoreSession -> restoreSession()
            LoginAction.ConfirmForceLogin -> confirmForceLogin()
            LoginAction.CancelForceLogin -> cancelForceLogin()
            LoginAction.KickedDialogConfirmed -> confirmKickedDialog()
            LoginAction.EffectConsumed -> pendingEffect = null
        }
    }

    fun consumeEffect(): LoginEffect? {
        val effect = pendingEffect
        pendingEffect = null
        return effect
    }

    fun hasAccount(account: String): Boolean {
        return authRepository.hasAccount(account)
    }

    fun requestVerifyCode(
        account: String,
        code: String = LocalMockAuthRepository.DefaultVerifyCode
    ): MockResult<MockVerifyCodeState> {
        return authRepository.requestVerifyCode(account, code)
    }

    fun verifyCode(account: String, code: String): MockResult<Unit> {
        return authRepository.verifyCode(account, code)
    }

    fun verifyCodeRemainingSeconds(account: String): Int {
        return authRepository.verifyCodeRemainingSeconds(account)
    }

    fun setCurrentTimeEpochMs(value: Long) {
        authRepository.setCurrentTimeEpochMs(value)
    }

    fun changePassword(
        account: String,
        oldPassword: String,
        newPassword: String
    ): MockResult<Unit> {
        return authRepository.changePassword(account, oldPassword, newPassword)
    }

    fun resetPassword(
        account: String,
        newPassword: String
    ): MockResult<Unit> {
        return authRepository.resetPassword(account, newPassword)
    }

    fun deleteCurrentAccount(): MockResult<Unit> {
        val userId = authRepository.currentSession()?.userId
            ?: return MockResult.Failure(MockError.AuthRequired)
        if (!onDeleteUserData(userId)) {
            return MockResult.Failure(MockError.PersistFailed)
        }
        val result = authRepository.deleteCurrentAccount()
        if (result is MockResult.Success) {
            state = state.copy(
                isLoggedIn = false,
                currentSession = null,
                password = "",
                verifyCode = "",
                errorMessage = null
            )
            pendingEffect = LoginEffect.AccountDeleted
        } else if (result is MockResult.Failure && result.error == MockError.SessionExpiredElsewhere) {
            showKickedDialog()
        }
        return result
    }

    fun clearSessionSilently() {
        authRepository.clearSession()
        state = state.copy(
            isLoggedIn = false,
            currentSession = null,
            password = "",
            verifyCode = "",
            errorMessage = null
        )
    }

    fun pauseSession() {
        authRepository.pauseSession()
    }

    fun restoreSessionOnColdStart() {
        applySessionResumeResult(authRepository.restoreSessionOnColdStart())
    }

    fun resumeSessionInSameProcess() {
        applySessionResumeResult(authRepository.resumeSessionInSameProcess())
    }

    fun resumeSession() {
        restoreSessionOnColdStart()
    }

    private fun applySessionResumeResult(result: SessionResumeResult) {
        when (result) {
            is SessionResumeResult.Active -> {
                state = state.copy(currentSession = result.session, isLoggedIn = true, errorMessage = null)
            }
            SessionResumeResult.NoSession -> {
                if (state.kickedDialogShown) {
                    // 被顶弹窗已显示：忽略后续"无会话"结果，避免提前导航
                } else {
                    state = state.copy(currentSession = null, isLoggedIn = false, errorMessage = null)
                }
            }
            SessionResumeResult.Expired -> {
                state = state.copy(
                    isLoggedIn = false,
                    currentSession = null,
                    password = "",
                    verifyCode = "",
                    errorMessage = MockError.AuthRequired.message
                )
                pendingEffect = LoginEffect.SessionExpired
            }
            SessionResumeResult.KickedElsewhere -> {
                showKickedDialog()
            }
            is SessionResumeResult.Failure -> {
                state = state.copy(errorMessage = result.error.message)
                pendingEffect = LoginEffect.ShowMessage(result.error.message)
            }
        }
    }

    private fun submit() {
        if (!state.canSubmit) {
            val message = if (state.mode == AuthMode.Register) {
                AuthMessageKeys.ValidationRegisterIncomplete
            } else {
                AuthMessageKeys.ValidationLoginIncomplete
            }
            state = state.copy(errorMessage = message)
            pendingEffect = LoginEffect.ShowMessage(message)
            return
        }

        state = state.copy(isLoading = true, errorMessage = null)

        val result = if (state.mode == AuthMode.Register) {
            registerUseCase.execute(
                account = state.username,
                password = state.password,
                verifyCode = state.verifyCode,
                region = state.selectedRegion,
                displayName = state.displayName
            )
        } else {
            loginUseCase.execute(state.username, state.password, forceLoginPending)
        }
        forceLoginPending = false

        when (result) {
            is LoginResult.Success -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    currentSession = result.session,
                    errorMessage = null,
                    confirmForceLogin = false,
                    forceLoginActiveDevice = null,
                    kickedDialogShown = false,
                    password = "",
                    verifyCode = ""
                )
                val nextRoute = if (result.session.isProfileComplete) PostLoginRoute.SignedIn
                    else PostLoginRoute.ProfileCompletion
                pendingEffect = LoginEffect.AuthSucceeded(result.session, state.mode, nextRoute)
            }

            is LoginResult.Failure -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = false,
                    currentSession = null,
                    confirmForceLogin = false,
                    forceLoginActiveDevice = null,
                    errorMessage = result.message
                )
                pendingEffect = LoginEffect.ShowMessage(result.message)
            }

            is LoginResult.SessionActiveElsewhere -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = false,
                    confirmForceLogin = true,
                    forceLoginActiveDevice = result.activeDevice,
                    errorMessage = null
                )
                pendingEffect = LoginEffect.ShowForceLoginDialog(result.activeDevice)
            }
        }
    }

    /** 二次确认通过：以 force 重新登录，顶掉其他设备会话（MSRV-016）。 */
    private fun confirmForceLogin() {
        forceLoginPending = true
        submit()
    }

    private fun cancelForceLogin() {
        forceLoginPending = false
        state = state.copy(
            confirmForceLogin = false,
            forceLoginActiveDevice = null,
            isLoading = false
        )
    }

    private fun logout() {
        when (val result = authRepository.clearSession()) {
            is MockResult.Success -> {
                state = state.copy(
                    isLoggedIn = false,
                    currentSession = null,
                    password = "",
                    verifyCode = "",
                    errorMessage = null
                )
                pendingEffect = LoginEffect.LoggedOut
            }

            is MockResult.Failure -> {
                state = state.copy(errorMessage = result.error.message)
                pendingEffect = LoginEffect.ShowMessage(result.error.message)
            }
        }
    }

    private fun saveProfile(profile: UserProfile) {
        when (val result = updateProfile(profile)) {
            is MockResult.Success -> {
                pendingEffect = LoginEffect.ProfileSaved(result.data)
            }

            is MockResult.Failure -> {
                pendingEffect = LoginEffect.ShowMessage(result.error.message)
            }
        }
    }

    fun updateProfile(profile: UserProfile): MockResult<AuthSession> {
        state = state.copy(isLoading = true, errorMessage = null)
        return when (val result = authRepository.saveProfile(profile)) {
            is MockResult.Success -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    currentSession = result.data,
                    errorMessage = null
                )
                result
            }

            is MockResult.Failure -> {
                if (result.error == MockError.SessionExpiredElsewhere) {
                    showKickedDialog()
                } else {
                    state = state.copy(
                        isLoading = false,
                        errorMessage = result.error.message
                    )
                }
                result
            }
        }
    }

    /**
     * 被顶（MSRV-019）：弹出"该账号已在其他设备登录"确认弹窗（仅确认按钮）。
     * 不清会话、不跳转，由 `KickedDialogConfirmed` 确认后清会话并回登录页。
     */
    private fun showKickedDialog() {
        state = state.copy(
            isLoading = false,
            kickedDialogShown = true,
            errorMessage = null
        )
    }

    /** 被顶弹窗确认：清会话并回登录页（不带错误提示，MSRV-019）。 */
    private fun confirmKickedDialog() {
        state = state.copy(
            kickedDialogShown = false,
            isLoggedIn = false,
            currentSession = null,
            password = "",
            verifyCode = "",
            errorMessage = null
        )
        pendingEffect = LoginEffect.SessionKicked
    }

    /** 供健康数据源等平台层回调：检测到被顶时弹出确认弹窗（MSRV-019）。 */
    fun onSessionKicked() {
        showKickedDialog()
    }

    /** MSRV-019：前台周期性会话校验（被顶即弹窗）。 */
    fun checkSessionOnForeground() {
        applySessionResumeResult(authRepository.resumeSessionInSameProcess())
    }

    private fun expireSession() {
        when (val result = authRepository.markSessionExpired()) {
            is MockResult.Success -> {
                state = state.copy(
                    isLoggedIn = false,
                    currentSession = null,
                    password = "",
                    verifyCode = "",
                    errorMessage = MockError.AuthRequired.message
                )
                pendingEffect = LoginEffect.SessionExpired
            }

            is MockResult.Failure -> {
                state = state.copy(errorMessage = result.error.message)
                pendingEffect = LoginEffect.ShowMessage(result.error.message)
            }
        }
    }

    private fun restoreSession() = restoreSessionOnColdStart()

    companion object {
        fun createFake(): LoginStore {
            return create(LocalMockAuthRepository(InMemoryAuthStoreDataSource()))
        }

        fun create(
            authRepository: AuthRepository,
            onDeleteUserData: (String) -> Boolean = { true }
        ): LoginStore {
            return LoginStore(authRepository, onDeleteUserData = onDeleteUserData)
        }

        private fun createInitialState(authRepository: AuthRepository): LoginState {
            val regions = authRepository.availableRegions()
            val session = authRepository.currentSession()
            return LoginState(
                selectedRegion = regions.firstOrNull { it.isDefault }?.region
                    ?: regions.firstOrNull()?.region.orEmpty(),
                regions = regions,
                currentSession = session,
                isLoggedIn = session?.isValid == true
            )
        }
    }
}
