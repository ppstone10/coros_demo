package com.example.demo.common.auth

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import com.example.demo.common.auth.mock.LocalMockAuthRepository
import com.example.demo.common.auth.mock.MockAuthStoreJson
import com.example.demo.common.auth.model.ActiveDeviceInfo
import com.example.demo.common.auth.model.AuthRegion
import com.example.demo.common.auth.model.AuthSession
import com.example.demo.common.auth.model.LoginAction
import com.example.demo.common.auth.model.LoginEffect
import com.example.demo.common.auth.model.LoginRequestDto
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.MockAccount
import com.example.demo.common.auth.model.MockAuthSession
import com.example.demo.common.auth.model.MockAuthStore
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.auth.model.MockVerifyCodeState
import com.example.demo.common.auth.model.PostLoginRoute
import com.example.demo.common.auth.model.RegisterRequestDto
import com.example.demo.common.auth.model.SessionResumeResult
import com.example.demo.common.auth.model.UserGender
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.repository.AuthRepository
import com.example.demo.common.auth.repository.AuthStoreDataSource
import com.example.demo.common.auth.repository.InMemoryAuthStoreDataSource
import com.example.demo.common.auth.rules.LoginRules
import com.example.demo.common.auth.rules.ProfileAccountDefaults
import com.example.demo.common.auth.store.LoginStore
import com.example.demo.common.auth.usecase.LoginUseCase
import com.example.demo.common.auth.usecase.RegisterUseCase

class LoginUseCaseTest {
    @Test
    fun registerSuccessSavesSessionAndCanBeRestored() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)

        val result = register(repository, account = "new.user@example.com")

        val success = assertIs<LoginResult.Success>(result)
        assertEquals("new.user@example.com", success.session.account)
        assertTrue(repository.hasAccount("new.user@example.com"))
        assertEquals(success.session, repository.currentSession())
        assertEquals(success.session, repository(dataSource).currentSession())
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
    fun missingRegionFailsWithExplicitMessage() {
        val repository = repository()
        repository.requestVerifyCode("missing-region@example.com")

        val result = RegisterUseCase(repository).execute(
            account = "missing-region@example.com",
            password = "password1",
            verifyCode = LocalMockAuthRepository.DefaultVerifyCode,
            region = "",
            displayName = "Missing Region"
        )

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals(MockError.RegionRequired.code, failure.code)
        assertEquals(MockError.RegionRequired.message, failure.message)
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

        val businessAccess = repository.verifyBusinessAccess()
        val failure = assertIs<MockResult.Failure>(businessAccess)
        assertEquals(MockError.AuthRequired, failure.error)
    }

    @Test
    fun warmResumeKeepsSessionActiveAfterBackgroundTtlAndClearsDeadline() {
        var now = 1_000L
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = LocalMockAuthRepository(dataSource, nowEpochMs = { now })

        register(repository, account = "warm-resume@example.com")
        assertIs<MockResult.Success<Unit>>(repository.pauseSession())
        now += LocalMockAuthRepository.SessionTtlMs * 2

        val resumed = assertIs<SessionResumeResult.Active>(repository.resumeSessionInSameProcess())

        assertEquals(0L, resumed.session.expireAtEpochMs)
        assertEquals(0L, repository.currentSession()?.expireAtEpochMs)
    }

    @Test
    fun warmResumePreventsStaleDeadlineFromExpiringNextColdStart() {
        var now = 1_000L
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = LocalMockAuthRepository(dataSource, nowEpochMs = { now })

        register(repository, account = "warm-then-cold@example.com")
        assertIs<MockResult.Success<Unit>>(repository.pauseSession())
        now += LocalMockAuthRepository.SessionTtlMs * 2
        assertIs<SessionResumeResult.Active>(repository.resumeSessionInSameProcess())
        now += LocalMockAuthRepository.SessionTtlMs * 2

        assertIs<SessionResumeResult.Active>(
            LocalMockAuthRepository(dataSource, nowEpochMs = { now }).restoreSessionOnColdStart()
        )
    }

    @Test
    fun coldStartRestoreExpiresSessionAfterPersistedDeadline() {
        var now = 1_000L
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = LocalMockAuthRepository(dataSource, nowEpochMs = { now })

        register(repository, account = "cold-restore@example.com")
        assertIs<MockResult.Success<Unit>>(repository.pauseSession())
        now += LocalMockAuthRepository.SessionTtlMs

        assertEquals(
            SessionResumeResult.Expired,
            LocalMockAuthRepository(dataSource, nowEpochMs = { now }).restoreSessionOnColdStart()
        )
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
    fun loginSuccessCarriesSignedInRouteWhenProfileComplete() {
        val repository = repository()
        register(repository, account = "complete-profile@example.com")
        repository.saveProfile(
            UserProfile(
                username = "Complete User",
                birthDate = "2000年01月01日",
                heightCm = 175,
                weightKg = 70.0,
                gender = UserGender.Male
            )
        )

        val store = LoginStore.create(repository)
        store.dispatch(LoginAction.UsernameChanged("complete-profile@example.com"))
        store.dispatch(LoginAction.PasswordChanged("password1"))
        store.dispatch(LoginAction.SubmitClicked)

        val effect = store.consumeEffect()
        val authSucceeded = assertIs<LoginEffect.AuthSucceeded>(effect)
        assertEquals(PostLoginRoute.SignedIn, authSucceeded.nextRoute)
    }

    @Test
    fun loginSuccessCarriesProfileCompletionRouteWhenProfileIncomplete() {
        val repository = repository()
        repository.requestVerifyCode("no-profile@example.com")
        RegisterUseCase(repository).execute(
            account = "no-profile@example.com",
            password = "password1",
            verifyCode = LocalMockAuthRepository.DefaultVerifyCode,
            region = "CN",
            displayName = null
        )

        val store = LoginStore.create(repository)
        store.dispatch(LoginAction.UsernameChanged("no-profile@example.com"))
        store.dispatch(LoginAction.PasswordChanged("password1"))
        store.dispatch(LoginAction.SubmitClicked)

        val effect = store.consumeEffect()
        val authSucceeded = assertIs<LoginEffect.AuthSucceeded>(effect)
        assertEquals(PostLoginRoute.ProfileCompletion, authSucceeded.nextRoute)
    }

    @Test
    fun businessAccessSucceedsAfterLogin() {
        val repository = repository()
        register(repository, account = "business-access@example.com")

        val login = LoginUseCase(repository).execute("business-access@example.com", "password1")
        val session = assertIs<LoginResult.Success>(login).session

        val access = assertIs<MockResult.Success<AuthSession>>(repository.verifyBusinessAccess())
        assertEquals(session, access.data)
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
                email = "profile@example.com",
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
        assertEquals("profile@example.com", loginSession.profile?.email)
    }

    @Test
    fun profileDefaultsUseAccountTypeAndCorosUserName() {
        assertEquals(
            ProfileAccountDefaults(username = "COROS user", phone = "13800138000", email = ""),
            LoginRules.profileDefaults("13800138000")
        )
        assertEquals(
            ProfileAccountDefaults(username = "COROS user", phone = "", email = "runner@example.com"),
            LoginRules.profileDefaults("runner@example.com")
        )
    }

    @Test
    fun editingProfilePersistsWithoutProducingNavigationEffect() {
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "profile-edit@example.com")
        val store = LoginStore(repository)
        val updated = UserProfile(
            username = "Updated Runner",
            birthDate = "1998年7月14日",
            heightCm = 178,
            weightKg = 63.5,
            countryRegion = "CN",
            gender = UserGender.Male
        )

        assertIs<MockResult.Success<AuthSession>>(store.updateProfile(updated))

        assertEquals(updated, store.state.currentSession?.profile)
        assertEquals(null, store.consumeEffect())
        assertEquals(updated, repository(dataSource).currentSession()?.profile)
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
    fun loginWithNonExistentAccountFails() {
        val repository = repository()

        val result = LoginUseCase(repository).execute("never-registered@example.com", "password1")

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals(MockError.AccountNotFound.code, failure.code)
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
        val dataSource = InMemoryAuthStoreDataSource()
        val repository = repository(dataSource)
        register(repository, account = "expired@example.com")

        repository.markSessionExpired()
        assertEquals(false, dataSource.load().currentSession?.isValid)
        val result = repository.verifyBusinessAccess()

        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.AuthRequired, failure.error)
        assertEquals(SessionResumeResult.Expired, repository(dataSource).resumeSession())
        assertEquals(null, dataSource.load().currentSession)
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
        assertEquals(SessionResumeResult.Active(session), restoredRepository.resumeSession())
        val businessAccess = assertIs<MockResult.Success<AuthSession>>(
            restoredRepository.verifyBusinessAccess()
        )
        assertEquals(session, businessAccess.data)
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

        assertTrue(encoded.startsWith("{"))
        assertTrue(encoded.contains("\"currentSession\""))
        assertTrue(encoded.contains("\"measurementSystem\":\"METRIC\""))
        assertTrue(encoded.contains("\"issuedAtEpochMs\":\""))
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
        assertEquals("CN", decoded.accounts.first().profile?.countryRegion)
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
        var stored = MockAuthStore()
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

    // ---- MSRV-016：二次确认（SessionActiveElsewhere → force 重登） ----

    @Test
    fun loginConflictSetsConfirmFlagAndEffect() {
        val store = LoginStore(FakeConflictRepository())
        store.dispatch(LoginAction.UsernameChanged("13107012029"))
        store.dispatch(LoginAction.PasswordChanged("123456"))
        store.dispatch(LoginAction.SubmitClicked)

        assertTrue(store.state.confirmForceLogin)
        assertEquals("13107012029", store.state.username)
        val effect = store.consumeEffect()
        val dialog = assertIs<LoginEffect.ShowForceLoginDialog>(effect)
        assertEquals("dev-a", dialog.activeDevice?.deviceId)
        assertEquals("Device A", dialog.activeDevice?.deviceName)
    }

    @Test
    fun confirmForceLoginSucceedsAndClearsConfirmFlag() {
        val store = LoginStore(FakeConflictRepository())
        store.dispatch(LoginAction.UsernameChanged("13107012029"))
        store.dispatch(LoginAction.PasswordChanged("123456"))
        store.dispatch(LoginAction.SubmitClicked)
        assertTrue(store.state.confirmForceLogin)
        store.consumeEffect()

        store.dispatch(LoginAction.ConfirmForceLogin)

        assertTrue(store.state.isLoggedIn)
        assertFalse(store.state.confirmForceLogin)
        val effect = store.consumeEffect()
        assertIs<LoginEffect.AuthSucceeded>(effect)
    }

    @Test
    fun cancelForceLoginClearsConfirmFlag() {
        val store = LoginStore(FakeConflictRepository())
        store.dispatch(LoginAction.UsernameChanged("13107012029"))
        store.dispatch(LoginAction.PasswordChanged("123456"))
        store.dispatch(LoginAction.SubmitClicked)
        store.consumeEffect()
        assertTrue(store.state.confirmForceLogin)

        store.dispatch(LoginAction.CancelForceLogin)
        assertFalse(store.state.confirmForceLogin)
        assertFalse(store.state.isLoggedIn)
    }

    @Test
    fun kickedElsewhereOnRestoreShowsDialogThenConfirmNavigates() {
        val store = LoginStore(FakeKickedRepository())
        store.restoreSessionOnColdStart()
        // 弹窗：会话未清、无 effect、错误文案不落到登录页
        assertTrue(store.state.kickedDialogShown)
        assertTrue(store.state.isLoggedIn)
        assertNull(store.state.errorMessage)
        assertNull(store.consumeEffect())

        store.dispatch(LoginAction.KickedDialogConfirmed)
        assertFalse(store.state.kickedDialogShown)
        assertFalse(store.state.isLoggedIn)
        assertNull(store.state.errorMessage)
        assertIs<LoginEffect.SessionKicked>(store.consumeEffect())
    }

    @Test
    fun updateProfileKickedElsewhereShowsDialogThenConfirmClearsSession() {
        val store = LoginStore(FakeKickedWriteRepository())
        val result = store.updateProfile(
            UserProfile(
                username = "X",
                birthDate = "2000-01-01",
                heightCm = 178,
                weightKg = 70.0,
                gender = UserGender.Male
            )
        )
        assertTrue(result is MockResult.Failure)
        assertEquals(MockError.SessionExpiredElsewhere, result.error)
        // 弹窗：会话暂未清
        assertTrue(store.state.kickedDialogShown)
        assertNull(store.state.errorMessage)
        assertNull(store.consumeEffect())

        store.dispatch(LoginAction.KickedDialogConfirmed)
        assertFalse(store.state.kickedDialogShown)
        assertFalse(store.state.isLoggedIn)
        assertNull(store.state.currentSession)
        assertIs<LoginEffect.SessionKicked>(store.consumeEffect())
    }

    @Test
    fun successfulLoginClearsStaleKickedDialogState() {
        val store = LoginStore(repository())
        store.dispatch(LoginAction.UsernameChanged("13107012029"))
        store.dispatch(LoginAction.PasswordChanged("123456"))
        // 被顶弹窗状态残留（如登录前一次失效健康同步触发的 kickedDialogShown）
        store.onSessionKicked()
        assertTrue(store.state.kickedDialogShown)

        store.dispatch(LoginAction.SubmitClicked)
        assertTrue(store.state.isLoggedIn)
        // 新的成功登录必须清除残留的被顶弹窗状态，否则登录成功后首页仍弹"已在其他设备登录"
        assertFalse(store.state.kickedDialogShown)
    }

    /** 普通登录返回异地会话冲突，force 登录成功（MSRV-016）。 */
    private open class FakeConflictRepository : AuthRepository {
        override fun login(request: LoginRequestDto): LoginResult {
            return if (request.force) {
                LoginResult.Success(session("mock-user-default"))
            } else {
                LoginResult.SessionActiveElsewhere(ActiveDeviceInfo("dev-a", "Device A"))
            }
        }

        override fun availableRegions(): List<AuthRegion> = emptyList()
        override fun hasAccount(account: String): Boolean = true
        override fun requestVerifyCode(account: String, code: String): MockResult<MockVerifyCodeState> =
            MockResult.Success(MockVerifyCodeState(account, code, 0L))
        override fun verifyCode(account: String, code: String): MockResult<Unit> = MockResult.Success(Unit)
        override fun verifyCodeRemainingSeconds(account: String): Int = 0
        override fun setCurrentTimeEpochMs(value: Long) = Unit
        override fun currentSession(): AuthSession? = null
        override fun requireSession(): AuthSession = session("mock-user-default")
        override fun saveSession(session: AuthSession): MockResult<AuthSession> = MockResult.Success(session)
        override fun saveProfile(profile: UserProfile): MockResult<AuthSession> = MockResult.Success(session("mock-user-default"))
        override fun clearSession(): MockResult<Unit> = MockResult.Success(Unit)
        override fun markSessionExpired(): MockResult<Unit> = MockResult.Success(Unit)
        override fun pauseSession(): MockResult<Unit> = MockResult.Success(Unit)
        override fun restoreSessionOnColdStart(): SessionResumeResult = SessionResumeResult.NoSession
        override fun resumeSessionInSameProcess(): SessionResumeResult = SessionResumeResult.NoSession
        override fun resumeSession(): SessionResumeResult = SessionResumeResult.NoSession
        override fun changePassword(account: String, oldPassword: String, newPassword: String): MockResult<Unit> =
            MockResult.Success(Unit)
        override fun resetPassword(account: String, newPassword: String): MockResult<Unit> =
            MockResult.Success(Unit)
        override fun deleteCurrentAccount(): MockResult<Unit> = MockResult.Success(Unit)
        override fun register(request: RegisterRequestDto): LoginResult =
            LoginResult.Success(session("mock-user-new"))
        override fun verifyBusinessAccess(): MockResult<AuthSession> =
            MockResult.Failure(MockError.AuthRequired)

        private fun session(userId: String) = AuthSession(
            userId = userId,
            account = "13107012029",
            displayName = null,
            region = "CN",
            isValid = true
        )
    }

    /** 冷启动恢复时发现被顶（MSRV-019）。 */
    private class FakeKickedRepository : FakeConflictRepository() {
        override fun currentSession(): AuthSession? = AuthSession(
            userId = "mock-user-default",
            account = "13107012029",
            displayName = null,
            region = "CN",
            isValid = true
        )

        override fun restoreSessionOnColdStart(): SessionResumeResult = SessionResumeResult.KickedElsewhere
        override fun resumeSession(): SessionResumeResult = SessionResumeResult.KickedElsewhere
    }

    /** 写操作被顶：saveProfile 返回 SESSION_EXPIRED_ELSEWHERE（MSRV-019）。 */
    private class FakeKickedWriteRepository : FakeConflictRepository() {
        override fun saveProfile(profile: UserProfile): MockResult<AuthSession> =
            MockResult.Failure(MockError.SessionExpiredElsewhere)
    }
}
