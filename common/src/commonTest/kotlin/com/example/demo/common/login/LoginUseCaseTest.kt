package com.example.demo.common.login

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull

class LoginUseCaseTest {
    @Test
    fun registerSuccessSavesSession() {
        val repository = repository()

        val result = register(repository, account = "new.user@example.com")

        val success = assertIs<LoginResult.Success>(result)
        assertEquals("new.user@example.com", success.session.account)
        assertEquals(success.session, repository.currentSession())
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
    fun localSessionCanBeRestored() {
        val dataSource = InMemoryAuthStoreDataSource()
        val firstRepository = repository(dataSource)
        val registerResult = register(firstRepository, account = "restore@example.com")
        val session = assertIs<LoginResult.Success>(registerResult).session

        val restoredRepository = repository(dataSource)

        assertEquals(session, restoredRepository.currentSession())
        assertNotNull(restoredRepository.requireSession())
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
