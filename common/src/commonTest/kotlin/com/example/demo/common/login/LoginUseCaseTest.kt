package com.example.demo.common.login

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class LoginUseCaseTest {
    @Test
    fun registerSuccessSavesSession() {
        val repository = repository()

        val result = register(repository, account = "new.user@example.com")

        val success = assertIs<LoginResult.Success>(result)
        assertEquals("new.user@example.com", success.session.account)
        assertEquals(null, repository.currentSession())
    }

    @Test
    fun duplicateRegisterFails() {
        val repository = repository()
        register(repository, account = "repeat@example.com")

        val result = register(repository, account = "repeat@example.com")

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals(MockError.AccountExists.code, failure.code)
    }

    @Test
    fun invalidVerifyCodeFails() {
        val repository = repository()
        repository.requestVerifyCode("code@example.com")

        val result = repository.register(
            RegisterRequestDto(
                account = "code@example.com",
                password = "password1",
                verifyCode = "0000",
                region = "CN",
                displayName = "Code User"
            )
        )

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals(MockError.VerifyCodeInvalid.code, failure.code)
    }

    @Test
    fun resentVerifyCodeReplacesOriginalCode() {
        val repository = repository()
        repository.requestVerifyCode("resent@example.com")
        repository.requestVerifyCode("resent@example.com", LocalMockAuthRepository.ResentVerifyCode)

        val oldCodeResult = repository.verifyCode("resent@example.com", LocalMockAuthRepository.DefaultVerifyCode)
        val newCodeResult = repository.verifyCode("resent@example.com", LocalMockAuthRepository.ResentVerifyCode)

        assertIs<MockResult.Failure>(oldCodeResult)
        assertIs<MockResult.Success<Unit>>(newCodeResult)
    }

    @Test
    fun verifyCodeExpiresAfterTtl() {
        var now = 1000L
        val repository = LocalMockAuthRepository(
            InMemoryAuthStoreDataSource(),
            nowEpochMs = { now }
        )
        repository.requestVerifyCode("expired-code@example.com")
        now += 121_000L

        val result = repository.verifyCode("expired-code@example.com", LocalMockAuthRepository.DefaultVerifyCode)

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.VerifyCodeExpired, failure.error)
    }

    @Test
    fun sessionExpiresAfterBackgroundTtlAndIsRemovedFromPersistence() {
        var now = 1_000L
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = LocalMockAuthRepository(dataSource, nowEpochMs = { now })

        register(repository, account = "ttl@example.com")
        repository.clearSession()
        val login = assertIs<LoginResult.Success>(repository.login(LoginRequestDto("ttl@example.com", "password1")))
        assertEquals(0L, login.session.expireAtEpochMs)

        assertIs<MockResult.Success<Unit>>(repository.pauseSession())
        now += LocalMockAuthRepository.SessionTtlMs
        assertEquals(SessionResumeResult.Expired, repository.resumeSession())
        assertEquals(null, dataSource.load().currentSession)
    }

    @Test
    fun verifyCodeRemainingSecondsUsesTheSameClockAsExpiration() {
        var now = 1_000L
        val repository = LocalMockAuthRepository(
            InMemoryAuthStoreDataSource(),
            nowEpochMs = { now }
        )
        repository.requestVerifyCode("remaining-code@example.com")

        assertEquals(60, repository.verifyCodeRemainingSeconds("remaining-code@example.com"))
        now += 1_500L
        assertEquals(59, repository.verifyCodeRemainingSeconds("remaining-code@example.com"))
        now += 60_000L
        assertEquals(0, repository.verifyCodeRemainingSeconds("remaining-code@example.com"))
    }

    @Test
    fun loginSuccessSavesSession() {
        val repository = repository()
        register(repository, account = "login@example.com")
        repository.clearSession()

        val result = LoginUseCase(repository).execute("login@example.com", "password1")

        val success = assertIs<LoginResult.Success>(result)
        assertEquals("login@example.com", success.session.account)
        assertEquals(success.session, repository.currentSession())
    }

    @Test
    fun saveProfileMarksSessionCompleteAndPersistsForNextLogin() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "profile@example.com")

        LoginUseCase(repository).execute("profile@example.com", "password1")

        val saveResult = repository.saveProfile(
            UserProfile(
                username = "Runner Test",
                birthDate = "2002年11月17日",
                heightCm = 175,
                weightKg = 60.0,
                gender = UserGender.Male
            )
        )

        val savedSession = assertIs<MockResult.Success<AuthSession>>(saveResult).data
        assertEquals(true, savedSession.isProfileComplete)
        assertEquals("Runner Test", savedSession.resolvedDisplayName)

        repository.clearSession()
        val loginRepository = repository(dataSource)
        val loginResult = LoginUseCase(loginRepository).execute("profile@example.com", "password1")

        val loginSession = assertIs<LoginResult.Success>(loginResult).session
        assertEquals(true, loginSession.isProfileComplete)
        assertEquals("Runner Test", loginSession.resolvedDisplayName)
    }

    @Test
    fun incompleteProfileCannotBeSaved() {
        val repository = repository()
        register(repository, account = "incomplete-profile@example.com")

        val result = repository.saveProfile(UserProfile(username = "Missing Fields"))

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.InvalidParam, failure.error)
    }

    @Test
    fun defaultMockAccountCanLogin() {
        val repository = repository()

        val result = LoginUseCase(repository).execute(
            LocalMockAuthRepository.DefaultAccount,
            LocalMockAuthRepository.DefaultPassword
        )

        val success = assertIs<LoginResult.Success>(result)
        assertEquals(LocalMockAuthRepository.DefaultAccount, success.session.account)
    }

    @Test
    fun registeredAccountCanLoginAgainFromMockStore() {
        val dataSource = InMemoryAuthStoreDataSource()
        val registerRepository = repository(dataSource)
        val account = "mock-new@example.com"

        register(registerRepository, account = account)
        registerRepository.clearSession()

        val loginRepository = repository(dataSource)
        val result = LoginUseCase(loginRepository).execute(account, "password1")

        val success = assertIs<LoginResult.Success>(result)
        assertEquals(account, success.session.account)
    }

    @Test
    fun incorrectPasswordFails() {
        val repository = repository()
        register(repository, account = "wrong-password@example.com")
        repository.clearSession()

        val result = LoginUseCase(repository).execute("wrong-password@example.com", "bad-pass")

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals(MockError.PasswordIncorrect.code, failure.code)
    }

    @Test
    fun changePasswordRequiresCorrectOldPassword() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "change-password@example.com")

        val result = repository.changePassword(
            account = "change-password@example.com",
            oldPassword = "bad-pass",
            newPassword = "newpass1"
        )

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.PasswordIncorrect, failure.error)
    }

    @Test
    fun changedPasswordReplacesOldPassword() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "changed-password@example.com")

        val changeResult = repository.changePassword(
            account = "changed-password@example.com",
            oldPassword = "password1",
            newPassword = "newpass1"
        )
        assertIs<MockResult.Success<Unit>>(changeResult)
        repository.clearSession()

        val oldLogin = LoginUseCase(repository(dataSource)).execute("changed-password@example.com", "password1")
        val newLogin = LoginUseCase(repository(dataSource)).execute("changed-password@example.com", "newpass1")

        assertIs<LoginResult.Failure>(oldLogin)
        assertIs<LoginResult.Success>(newLogin)
    }

    @Test
    fun resetPasswordDoesNotRequireOldPassword() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "reset-password@example.com")

        val resetResult = repository.resetPassword(
            account = "reset-password@example.com",
            newPassword = "newpass1"
        )
        assertIs<MockResult.Success<Unit>>(resetResult)
        repository.clearSession()

        val oldLogin = LoginUseCase(repository(dataSource)).execute("reset-password@example.com", "password1")
        val newLogin = LoginUseCase(repository(dataSource)).execute("reset-password@example.com", "newpass1")

        assertIs<LoginResult.Failure>(oldLogin)
        assertIs<LoginResult.Success>(newLogin)
    }

    @Test
    fun deleteCurrentAccountRemovesAccountAndSession() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "delete-me@example.com")

        LoginUseCase(repository).execute("delete-me@example.com", "password1")

        val deleteResult = repository.deleteCurrentAccount()

        assertIs<MockResult.Success<Unit>>(deleteResult)
        assertEquals(null, repository.currentSession())
        val loginResult = LoginUseCase(repository(dataSource)).execute("delete-me@example.com", "password1")
        val failure = assertIs<LoginResult.Failure>(loginResult)
        assertEquals(MockError.AccountNotFound.code, failure.code)
    }

    @Test
    fun businessAccessRequiresLogin() {
        val repository = repository()

        val result = repository.verifyBusinessAccess()

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.AuthRequired, failure.error)
    }

    @Test
    fun businessAccessFailsAfterLogout() {
        val repository = repository()
        register(repository, account = "logout@example.com")

        repository.clearSession()
        val result = repository.verifyBusinessAccess()

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.AuthRequired, failure.error)
    }

    @Test
    fun businessAccessFailsAfterSessionExpired() {
        val repository = repository()
        register(repository, account = "expired@example.com")

        repository.markSessionExpired()
        val result = repository.verifyBusinessAccess()

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.AuthRequired, failure.error)
    }

    @Test
    fun localSessionCanBeRestoredAfterLogin() {
        val dataSource = InMemoryAuthStoreDataSource()
        val firstRepository = repository(dataSource)
        register(firstRepository, account = "restore@example.com")

        val loginResult = LoginUseCase(firstRepository).execute("restore@example.com", "password1")
        val session = assertIs<LoginResult.Success>(loginResult).session

        val restoredRepository = repository(dataSource)

        assertEquals(session, restoredRepository.currentSession())
        assertNotNull(restoredRepository.requireSession())
    }

    @Test
    fun mockStoreJsonPreservesProfileDisplayNameAndSession() {
        val store = MockAuthStore(
            accounts = listOf(
                MockAccount(
                    userId = "mock-user-json",
                    account = "json@example.com",
                    passwordHash = "mock:1drowssap:9",
                    displayName = "Json Runner",
                    region = "CN",
                    profile = UserProfile(
                        username = "Json Runner",
                        birthDate = "2001年01月01日",
                        heightCm = 180,
                        weightKg = 72.5,
                        gender = UserGender.Male
                    )
                )
            ),
            currentSession = MockAuthSession(
                userId = "mock-user-json",
                account = "json@example.com",
                displayName = "Json Runner",
                region = "CN",
                isValid = true,
                profile = UserProfile(
                    username = "Json Runner",
                    birthDate = "2001年01月01日",
                    heightCm = 180,
                    weightKg = 72.5,
                    gender = UserGender.Male
                )
            ),
            defaultAccountsInitialized = true
        )

        val encoded = MockAuthStoreJson.encode(store)
        val decoded = MockAuthStoreJson.decode(encoded)

        assertEquals(store, decoded)
        assertTrue(MockAuthStoreJson.isRoundTripStable(encoded))
    }

    @Test
    fun mockStoreJsonReadsLegacyAndroidSnakeCaseSnapshot() {
        val legacyJson = """
            {
              "accounts":[
                {
                  "user_id":"legacy-user",
                  "account":"legacy@example.com",
                  "password_hash":"mock:1drowssap:9",
                  "display_name":"Legacy Runner",
                  "region":"CN",
                  "profile":{
                    "avatar_uri":null,
                    "username":"Legacy Runner",
                    "birth_date":"2000年02月03日",
                    "height_cm":171,
                    "weight_kg":60.5,
                    "measurement_system":"Metric",
                    "phone":"13107012029",
                    "country_region":"中国",
                    "gender":"Female"
                  }
                }
              ],
              "current_session":{
                "user_id":"legacy-user",
                "account":"legacy@example.com",
                "display_name":"Legacy Runner",
                "region":"CN",
                "is_valid":true,
                "profile":null
              },
              "verify_codes":[
                {"account":"legacy@example.com","code":"1234","expire_at_epoch_ms":61000}
              ],
              "default_accounts_initialized":true
            }
        """.trimIndent()

        val decoded = MockAuthStoreJson.decode(legacyJson)

        assertEquals("Legacy Runner", decoded.accounts.first().displayName)
        assertEquals("Legacy Runner", decoded.accounts.first().profile?.username)
        assertEquals("Legacy Runner", decoded.currentSession?.displayName)
        assertEquals(61000L, decoded.verifyCodes.first().expireAtEpochMs)
        assertEquals(true, decoded.defaultAccountsInitialized)
    }

    @Test
    fun emptyStoreWithInitializedFlagReturnsNullSession() {
        val store = MockAuthStore(defaultAccountsInitialized = true)
        val dataSource = InMemoryAuthStoreDataSource(store)
        val repository = LocalMockAuthRepository(dataSource, nowEpochMs = { 1000L })

        assertEquals(null, repository.currentSession())
        val access = repository.verifyBusinessAccess()
        val failure = assertIs<MockResult.Failure>(access)
        assertEquals(MockError.AuthRequired, failure.error)
    }

    @Test
    fun corruptedSessionWithBlankUserIdReturnsNull() {
        val store = MockAuthStore(
            accounts = listOf(
                MockAccount(
                    userId = "",
                    account = "corrupted@example.com",
                    passwordHash = "",
                    displayName = "",
                    region = ""
                )
            ),
            currentSession = MockAuthSession(
                userId = "",
                account = "corrupted@example.com",
                displayName = "",
                region = "",
                isValid = false
            ),
            defaultAccountsInitialized = true
        )
        val dataSource = InMemoryAuthStoreDataSource(store)
        val repository = LocalMockAuthRepository(dataSource, nowEpochMs = { 1000L })

        assertEquals(null, repository.currentSession())
    }

    @Test
    fun persistFailedOnRegisterReturnsError() {
        var saveCallCount = 0
        var stored: MockAuthStore = MockAuthStore()
        val failingDataSource = object : AuthStoreDataSource {
            override fun load(): MockAuthStore = stored
            override fun save(store: MockAuthStore): Boolean {
                stored = store
                saveCallCount++
                return saveCallCount <= 1
            }
        }
        val repository = LocalMockAuthRepository(failingDataSource, nowEpochMs = { 1000L })
        repository.requestVerifyCode("persist-fail@example.com")

        val result = RegisterUseCase(repository).execute(
            account = "persist-fail@example.com",
            password = "password1",
            verifyCode = LocalMockAuthRepository.DefaultVerifyCode,
            region = "CN",
            displayName = "Persist Fail"
        )

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals(MockError.PersistFailed.code, failure.code)
    }

    private fun repository(
        dataSource: AuthStoreDataSource = InMemoryAuthStoreDataSource()
    ): LocalMockAuthRepository {
        return LocalMockAuthRepository(dataSource, nowEpochMs = { 1000L })
    }

    private fun register(
        repository: AuthRepository,
        account: String
    ): LoginResult {
        repository.requestVerifyCode(account)
        return RegisterUseCase(repository).execute(
            account = account,
            password = "password1",
            verifyCode = LocalMockAuthRepository.DefaultVerifyCode,
            region = "CN",
            displayName = "Mock User"
        )
    }
}
