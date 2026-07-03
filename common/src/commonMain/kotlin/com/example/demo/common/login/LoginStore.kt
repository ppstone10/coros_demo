package com.example.demo.common.login

class LoginStore(
    private val authRepository: AuthRepository,
    private val loginUseCase: LoginUseCase = LoginUseCase(authRepository),
    private val registerUseCase: RegisterUseCase = RegisterUseCase(authRepository)
) {
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
        val result = authRepository.deleteCurrentAccount()
        if (result is MockResult.Success) {
            state = state.copy(
                isLoggedIn = false,
                currentSession = null,
                password = "",
                verifyCode = "",
                errorMessage = null
            )
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

    private fun submit() {
        if (!state.canSubmit) {
            val message = if (state.mode == AuthMode.Register) {
                "请输入账号、密码、区域和验证码"
            } else {
                "请输入账号和密码"
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
                pendingEffect = LoginEffect.AuthSucceeded(result.session, state.mode)
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
        state = state.copy(isLoading = true, errorMessage = null)
        when (val result = authRepository.saveProfile(profile)) {
            is MockResult.Success -> {
                state = state.copy(
                    isLoading = false,
                    isLoggedIn = true,
                    currentSession = result.data,
                    errorMessage = null
                )
                pendingEffect = LoginEffect.ProfileSaved(result.data)
            }

            is MockResult.Failure -> {
                state = state.copy(
                    isLoading = false,
                    errorMessage = result.error.message
                )
                pendingEffect = LoginEffect.ShowMessage(result.error.message)
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

    private fun restoreSession() {
        val session = authRepository.currentSession()
        state = state.copy(
            currentSession = session,
            isLoggedIn = session?.isValid == true,
            errorMessage = null
        )
    }

    companion object {
        fun createFake(): LoginStore {
            return create(LocalMockAuthRepository(InMemoryAuthStoreDataSource()))
        }

        fun create(authRepository: AuthRepository): LoginStore {
            return LoginStore(authRepository)
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
