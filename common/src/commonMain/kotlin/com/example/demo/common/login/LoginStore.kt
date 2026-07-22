package com.example.demo.common.login

import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.health.HealthDashboardStateDataSource
import com.example.demo.common.health.HealthDashboardStore
import com.example.demo.common.health.InMemoryHealthDashboardStateDataSource
import com.example.demo.common.health.PersistedDashboard

class LoginStore(
    private val authRepository: AuthRepository,
    private val loginUseCase: LoginUseCase = LoginUseCase(authRepository),
    private val registerUseCase: RegisterUseCase = RegisterUseCase(authRepository),
    private val healthStateDataSource: HealthDashboardStateDataSource = InMemoryHealthDashboardStateDataSource()
) {
    private val healthDashboardStore = HealthDashboardStore(authRepository, healthStateDataSource)
    var state: LoginState = createInitialState(authRepository)
        private set

    private var pendingEffect: LoginEffect? = null

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
        val deletedUserId = state.currentSession?.userId
        val result = authRepository.deleteCurrentAccount()
        if (result is MockResult.Success) {
            deletedUserId?.let(healthDashboardStore::clear)
            state = state.copy(
                isLoggedIn = false,
                currentSession = null,
                password = "",
                verifyCode = "",
                errorMessage = null
            )
            pendingEffect = LoginEffect.AccountDeleted
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

    fun resumeSession() {
        when (val result = authRepository.resumeSession()) {
            is SessionResumeResult.Active -> {
                state = state.copy(currentSession = result.session, isLoggedIn = true, errorMessage = null)
            }
            SessionResumeResult.NoSession -> {
                state = state.copy(currentSession = null, isLoggedIn = false, errorMessage = null)
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
            is SessionResumeResult.Failure -> {
                state = state.copy(errorMessage = result.error.message)
                pendingEffect = LoginEffect.ShowMessage(result.error.message)
            }
        }
    }

    /** 健康业务只经共享层读取认证后的本地 mock 数据。 */
    fun loadHealthDashboard(): MockResult<PersistedDashboard> = healthDashboardStore.load()

    fun selectHealthScenario(scenario: HealthMockScenario): MockResult<Unit> =
        healthDashboardStore.selectScenario(scenario)

    fun refreshHealthDashboard(): MockResult<PersistedDashboard> = healthDashboardStore.refresh()

    fun saveHealthCardConfiguration(types: List<com.example.demo.common.health.HealthCardType>): MockResult<PersistedDashboard> =
        healthDashboardStore.saveCardConfiguration(types)

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
            loginUseCase.execute(state.username, state.password)
        }

        when (result) {
            is LoginResult.Success -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    currentSession = result.session,
                    errorMessage = null,
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
                    errorMessage = result.message
                )
                pendingEffect = LoginEffect.ShowMessage(result.message)
            }
        }
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
                state = state.copy(
                    isLoading = false,
                    errorMessage = result.error.message
                )
                result
            }
        }
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

    private fun restoreSession() = resumeSession()

    companion object {
        fun createFake(): LoginStore {
            return create(LocalMockAuthRepository(InMemoryAuthStoreDataSource()))
        }

        fun create(
            authRepository: AuthRepository,
            healthStateDataSource: HealthDashboardStateDataSource = InMemoryHealthDashboardStateDataSource()
        ): LoginStore {
            return LoginStore(authRepository, healthStateDataSource = healthStateDataSource)
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
