package com.example.demo.common.login

interface AuthStoreDataSource {
    fun load(): MockAuthStore
    fun save(store: MockAuthStore): Boolean
}

class InMemoryAuthStoreDataSource(
    initialStore: MockAuthStore = MockAuthStore()
) : AuthStoreDataSource {
    private var store: MockAuthStore = initialStore

    override fun load(): MockAuthStore = store

    override fun save(store: MockAuthStore): Boolean {
        this.store = store
        return true
    }
}

interface AuthRepository {
    fun availableRegions(): List<AuthRegion>
    fun hasAccount(account: String): Boolean
    fun requestVerifyCode(
        account: String,
        code: String = LocalMockAuthRepository.DefaultVerifyCode
    ): MockResult<MockVerifyCodeState>
    fun verifyCode(account: String, code: String): MockResult<Unit>
    fun verifyCodeRemainingSeconds(account: String): Int
    fun setCurrentTimeEpochMs(value: Long)
    fun currentSession(): AuthSession?
    fun requireSession(): AuthSession
    fun saveSession(session: AuthSession): MockResult<AuthSession>
    fun saveProfile(profile: UserProfile): MockResult<AuthSession>
    fun clearSession(): MockResult<Unit>
    fun markSessionExpired(): MockResult<Unit>
    fun pauseSession(): MockResult<Unit>
    fun resumeSession(): SessionResumeResult
    fun changePassword(account: String, oldPassword: String, newPassword: String): MockResult<Unit>
    fun resetPassword(account: String, newPassword: String): MockResult<Unit>
    fun deleteCurrentAccount(): MockResult<Unit>
    fun register(request: RegisterRequestDto): LoginResult
    fun login(request: LoginRequestDto): LoginResult
    fun verifyBusinessAccess(): MockResult<AuthSession>
}

class LocalMockAuthRepository(
    private val dataSource: AuthStoreDataSource,
    nowEpochMs: () -> Long = { 0L }
) : AuthRepository {
    private var nowEpochMs: () -> Long = nowEpochMs
    override fun availableRegions(): List<AuthRegion> = DefaultRegions.map { it.toDomain() }

    override fun hasAccount(account: String): Boolean {
        val normalizedAccount = account.trim()
        if (normalizedAccount.isBlank()) return false
        return loadStore().accounts.any {
            it.account.equals(normalizedAccount, ignoreCase = true)
        }
    }

    override fun requestVerifyCode(
        account: String,
        code: String
    ): MockResult<MockVerifyCodeState> {
        val normalizedAccount = account.trim()
        val normalizedCode = code.trim()
        if (
            normalizedAccount.isBlank() ||
            !isMockAccountFormatValid(normalizedAccount) ||
            normalizedCode.length != VerifyCodeLength ||
            !normalizedCode.all { it.isDigit() }
        ) {
            return MockResult.Failure(MockError.InvalidParam)
        }

        val store = loadStore()
        val codeState = MockVerifyCodeState(
            account = normalizedAccount,
            code = normalizedCode,
            expireAtEpochMs = nowEpochMs() + VerifyCodeTtlMs
        )
        val nextStore = store.copy(
            verifyCodes = store.verifyCodes.filterNot {
                it.account.equals(normalizedAccount, ignoreCase = true)
            } + codeState
        )

        return if (dataSource.save(nextStore)) {
            MockResult.Success(codeState)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun verifyCode(account: String, code: String): MockResult<Unit> {
        val normalizedAccount = account.trim()
        val verifyCode = code.trim()
        val savedCode = loadStore().verifyCodes.lastOrNull {
            it.account.equals(normalizedAccount, ignoreCase = true)
        } ?: return MockResult.Failure(MockError.VerifyCodeInvalid)

        return when {
            savedCode.expireAtEpochMs <= nowEpochMs() -> MockResult.Failure(MockError.VerifyCodeExpired)
            savedCode.code == verifyCode -> MockResult.Success(Unit)
            else -> MockResult.Failure(MockError.VerifyCodeInvalid)
        }
    }

    override fun verifyCodeRemainingSeconds(account: String): Int {
        val savedCode = loadStore().verifyCodes.lastOrNull {
            it.account.equals(account.trim(), ignoreCase = true)
        } ?: return 0
        val remainingMs = savedCode.expireAtEpochMs - nowEpochMs()
        return ((remainingMs.coerceAtLeast(0) + 999L) / 1000L).toInt()
    }

    override fun setCurrentTimeEpochMs(value: Long) {
        nowEpochMs = { value }
    }

    override fun currentSession(): AuthSession? {
        val session = loadStore().currentSession
            ?.toDomainOrNull()
            ?.takeIf { it.isValid }
            ?: return null
        return session
    }

    override fun requireSession(): AuthSession {
        return currentSession() ?: throw IllegalStateException(MockError.AuthRequired.code)
    }

    override fun saveSession(session: AuthSession): MockResult<AuthSession> {
        val store = loadStore()
        return if (dataSource.save(store.copy(currentSession = session.toMockSession()))) {
            MockResult.Success(session)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun saveProfile(profile: UserProfile): MockResult<AuthSession> {
        val session = currentSession() ?: return MockResult.Failure(MockError.AuthRequired)
        val cleanProfile = profile.copy(
            username = profile.username.trim(),
            phone = profile.phone.trim(),
            countryRegion = profile.countryRegion.toProfileCountryCode(session.region)
        )
        if (!cleanProfile.isRequiredComplete) {
            return MockResult.Failure(MockError.InvalidParam)
        }

        val store = loadStore()
        val updatedAccounts = store.accounts.map { account ->
            if (account.userId == session.userId) {
                account.copy(
                    displayName = cleanProfile.username,
                    profile = cleanProfile
                )
            } else {
                account
            }
        }
        val updatedSession = session.copy(
            displayName = cleanProfile.username,
            profile = cleanProfile,
            isValid = true
        )
        val nextStore = store.copy(
            accounts = updatedAccounts,
            currentSession = updatedSession.toMockSession()
        )

        return if (dataSource.save(nextStore)) {
            MockResult.Success(updatedSession)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun clearSession(): MockResult<Unit> {
        val store = loadStore()
        return if (dataSource.save(store.copy(currentSession = null))) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun markSessionExpired(): MockResult<Unit> {
        val store = loadStore()
        val session = store.currentSession?.toDomainOrNull()
            ?: return MockResult.Success(Unit)
        val expiredSession = session.copy(
            isValid = false,
            expireAtEpochMs = nowEpochMs()
        )
        return if (dataSource.save(store.copy(currentSession = expiredSession.toMockSession()))) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun pauseSession(): MockResult<Unit> {
        val store = loadStore()
        val session = store.currentSession?.toDomainOrNull()?.takeIf { it.isValid }
            ?: return MockResult.Success(Unit)
        val suspendedSession = session.copy(expireAtEpochMs = nowEpochMs() + SessionTtlMs)
        return if (dataSource.save(store.copy(currentSession = suspendedSession.toMockSession()))) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun resumeSession(): SessionResumeResult {
        val store = loadStore()
        val session = store.currentSession?.toDomainOrNull()
            ?: return SessionResumeResult.NoSession
        if (!session.isValid) {
            return when (clearSession()) {
                is MockResult.Success -> SessionResumeResult.Expired
                is MockResult.Failure -> SessionResumeResult.Failure(MockError.PersistFailed)
            }
        }
        if (session.expireAtEpochMs > 0L && session.expireAtEpochMs <= nowEpochMs()) {
            return when (clearSession()) {
                is MockResult.Success -> SessionResumeResult.Expired
                is MockResult.Failure -> SessionResumeResult.Failure(MockError.PersistFailed)
            }
        }
        if (session.expireAtEpochMs == 0L) return SessionResumeResult.Active(session)
        val activeSession = session.copy(expireAtEpochMs = 0L)
        return if (dataSource.save(store.copy(currentSession = activeSession.toMockSession()))) {
            SessionResumeResult.Active(activeSession)
        } else {
            SessionResumeResult.Failure(MockError.PersistFailed)
        }
    }

    override fun changePassword(
        account: String,
        oldPassword: String,
        newPassword: String
    ): MockResult<Unit> {
        val normalizedAccount = account.trim()
        if (
            normalizedAccount.isBlank() ||
            !isMockAccountFormatValid(normalizedAccount) ||
            oldPassword.isBlank() ||
            !LoginRules.isRegisterPasswordValid(newPassword)
        ) {
            return MockResult.Failure(MockError.InvalidParam)
        }

        val store = loadStore()
        val localAccount = store.accounts.firstOrNull {
            it.account.equals(normalizedAccount, ignoreCase = true)
        } ?: return MockResult.Failure(MockError.AccountNotFound)

        val oldHash = hashMockPassword(oldPassword)
        if (localAccount.passwordHash != oldHash) {
            return MockResult.Failure(MockError.PasswordIncorrect)
        }

        val newHash = hashMockPassword(newPassword)
        if (oldHash == newHash) {
            return MockResult.Failure(MockError.NewPasswordSameAsOld)
        }

        val nextAccounts = store.accounts.map {
            if (it.userId == localAccount.userId) it.copy(passwordHash = newHash) else it
        }

        return if (dataSource.save(store.copy(accounts = nextAccounts))) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun resetPassword(account: String, newPassword: String): MockResult<Unit> {
        val normalizedAccount = account.trim()
        if (
            normalizedAccount.isBlank() ||
            !isMockAccountFormatValid(normalizedAccount) ||
            !LoginRules.isRegisterPasswordValid(newPassword)
        ) {
            return MockResult.Failure(MockError.InvalidParam)
        }

        val store = loadStore()
        val localAccount = store.accounts.firstOrNull {
            it.account.equals(normalizedAccount, ignoreCase = true)
        } ?: return MockResult.Failure(MockError.AccountNotFound)

        val nextAccounts = store.accounts.map {
            if (it.userId == localAccount.userId) {
                it.copy(passwordHash = hashMockPassword(newPassword))
            } else {
                it
            }
        }

        return if (dataSource.save(store.copy(accounts = nextAccounts))) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun deleteCurrentAccount(): MockResult<Unit> {
        val session = currentSession() ?: return MockResult.Failure(MockError.AuthRequired)
        val store = loadStore()
        val nextStore = store.copy(
            accounts = store.accounts.filterNot { it.userId == session.userId },
            currentSession = null,
            verifyCodes = store.verifyCodes.filterNot {
                it.account.equals(session.account, ignoreCase = true)
            }
        )
        return if (dataSource.save(nextStore)) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun register(request: RegisterRequestDto): LoginResult {
        val account = request.account.trim()
        val password = request.password
        val region = request.region.trim()
        val displayName = request.displayName?.trim().orEmpty()

        val validationError = validateRegister(account, password, request.verifyCode, region)
        if (validationError != null) return validationError.toLoginFailure()

        val store = loadStore()
        if (store.accounts.any { it.account.equals(account, ignoreCase = true) }) {
            return MockError.AccountExists.toLoginFailure()
        }

        val accountModel = MockAccount(
            userId = buildUserId(account),
            account = account,
            passwordHash = hashMockPassword(password),
            displayName = displayName.ifBlank { account },
            region = region,
            profile = null
        )
        val session = AuthSession(
            userId = accountModel.userId,
            account = accountModel.account,
            displayName = accountModel.displayName,
            region = accountModel.region,
            isValid = true,
            profile = accountModel.profile,
            issuedAtEpochMs = nowEpochMs(),
            expireAtEpochMs = 0L
        )
        val nextStore = store.copy(
            accounts = store.accounts + accountModel,
            currentSession = session.toMockSession(),
            verifyCodes = store.verifyCodes.filterNot { it.account == account }
        )

        return if (dataSource.save(nextStore)) {
            LoginResult.Success(session)
        } else {
            MockError.PersistFailed.toLoginFailure()
        }
    }

    override fun login(request: LoginRequestDto): LoginResult {
        val account = request.account.trim()
        val password = request.password

        if (account.isBlank() || !isMockAccountFormatValid(account)) {
            return MockError.InvalidParam.toLoginFailure()
        }

        if (password.isBlank()) {
            return MockError.InvalidParam.toLoginFailure()
        }

        val store = loadStore()
        val localAccount = store.accounts.firstOrNull {
            it.account.equals(account, ignoreCase = true)
        } ?: return MockError.AccountNotFound.toLoginFailure()

        if (localAccount.passwordHash != hashMockPassword(password)) {
            return MockError.PasswordIncorrect.toLoginFailure()
        }

        val session = AuthSession(
            userId = localAccount.userId,
            account = localAccount.account,
            displayName = localAccount.displayName,
            region = localAccount.region,
            isValid = true,
            profile = localAccount.profile,
            issuedAtEpochMs = nowEpochMs(),
            expireAtEpochMs = 0L
        )

        return when (val result = saveSession(session)) {
            is MockResult.Success -> LoginResult.Success(result.data)
            is MockResult.Failure -> result.error.toLoginFailure()
        }
    }

    override fun verifyBusinessAccess(): MockResult<AuthSession> {
        return currentSession()?.let { MockResult.Success(it) }
            ?: MockResult.Failure(MockError.AuthRequired)
    }

    private fun loadStore(): MockAuthStore {
        val store = dataSource.load()
        return if (store.accounts.isEmpty() && !store.defaultAccountsInitialized) {
            store.copy(
                accounts = DefaultAccounts,
                defaultAccountsInitialized = true
            )
        } else if (store.accounts.isNotEmpty() && !store.defaultAccountsInitialized) {
            store.copy(defaultAccountsInitialized = true)
        } else {
            store
        }
    }

    private fun validateRegister(
        account: String,
        password: String,
        verifyCode: String,
        region: String
    ): MockError? {
        if (account.isBlank() || !isMockAccountFormatValid(account)) return MockError.InvalidParam
        if (!LoginRules.isRegisterPasswordValid(password)) return MockError.InvalidParam
        val savedCode = loadStore().verifyCodes.lastOrNull {
            it.account.equals(account, ignoreCase = true)
        } ?: return MockError.VerifyCodeInvalid
        if (savedCode.expireAtEpochMs <= nowEpochMs()) return MockError.VerifyCodeExpired
        if (verifyCode.length != VerifyCodeLength || verifyCode != savedCode.code) {
            return MockError.VerifyCodeInvalid
        }
        if (region.isBlank() || availableRegions().none { it.region == region }) {
            return MockError.RegionRequired
        }
        return null
    }

    private fun isMockAccountFormatValid(account: String): Boolean {
        val isEmailLike = account.contains("@") && account.substringAfter("@").contains(".")
        val isPhoneLike = account.length in 5..20 && account.all { it.isDigit() || it == '+' || it == '-' }
        return isEmailLike || isPhoneLike
    }

    private fun hashMockPassword(password: String): String {
        return "mock:${password.reversed()}:${password.length}"
    }

    private fun buildUserId(account: String): String {
        val hash = account.fold(17) { acc, char -> acc * 31 + char.code }
            .let { if (it < 0) -it else it }
        return "mock-user-$hash"
    }

    private fun MockError.toLoginFailure(): LoginResult.Failure {
        return LoginResult.Failure(code = code, message = message)
    }

    companion object {
        const val DefaultVerifyCode = "1234"
        const val ResentVerifyCode = "4321"
        private const val VerifyCodeLength = LoginRules.VerifyCodeLength
        private const val VerifyCodeTtlMs = 60 * 1000L
        // 仅在应用进入后台后开始计算；前台使用期间不会倒计时。
        const val SessionTtlMs = 10 * 1000L
        const val DefaultAccount = "13107012029"
        const val DefaultEmailAccount = "2232591785@qq.com"
        const val DefaultPassword = "123456"

        val DefaultRegions = listOf(
            MockAuthRegion(region = "CN", displayName = "China", isDefault = true),
            MockAuthRegion(region = "US", displayName = "United States")
        )

        private val DefaultAccounts = listOf(
            MockAccount(
                userId = "mock-user-default",
                account = DefaultAccount,
                passwordHash = "mock:${DefaultPassword.reversed()}:${DefaultPassword.length}",
                displayName = "COROS User",
                region = "CN",
                profile = null
            ),
            MockAccount(
                userId = "mock-user-default-email",
                account = DefaultEmailAccount,
                passwordHash = "mock:${DefaultPassword.reversed()}:${DefaultPassword.length}",
                displayName = "COROS Email User",
                region = "CN",
                profile = null
            )
        )
    }
}

class FakeAuthRepository : AuthRepository by LocalMockAuthRepository(InMemoryAuthStoreDataSource())
