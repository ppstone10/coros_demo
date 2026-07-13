package com.example.demo.common.login

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class BusinessMockDataSourceTest {
    @Test
    fun loggedInUserCanReadBusinessMockData() {
        val repository = repository()
        val session = register(repository, "business@example.com")

        val result = LocalBusinessMockDataSource(repository).loadSummary()

        val summary = assertIs<MockResult.Success<MockBusinessSummary>>(result).data
        assertEquals(session.userId, summary.userId)
        assertEquals(session.resolvedDisplayName, summary.displayName)
    }

    @Test
    fun loggedOutUserCannotReadBusinessMockData() {
        val repository = repository()
        register(repository, "logout-business@example.com")
        repository.clearSession()

        val result = LocalBusinessMockDataSource(repository).loadSummary()

        assertEquals(MockError.AuthRequired, assertIs<MockResult.Failure>(result).error)
    }

    @Test
    fun expiredSessionCannotReadBusinessMockData() {
        val repository = repository()
        register(repository, "expired-business@example.com")
        repository.markSessionExpired()

        val result = LocalBusinessMockDataSource(repository).loadSummary()

        assertEquals(MockError.AuthRequired, assertIs<MockResult.Failure>(result).error)
    }

    @Test
    fun anonymousUserCannotReadBusinessMockData() {
        val result = LocalBusinessMockDataSource(repository()).loadSummary()

        assertEquals(MockError.AuthRequired, assertIs<MockResult.Failure>(result).error)
    }

    private fun repository(): LocalMockAuthRepository {
        return LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L })
    }

    private fun register(repository: AuthRepository, account: String): AuthSession {
        repository.requestVerifyCode(account)
        val result = RegisterUseCase(repository).execute(
            account = account,
            password = "password1",
            verifyCode = LocalMockAuthRepository.DefaultVerifyCode,
            region = "CN",
            displayName = "Business User"
        )
        return assertIs<LoginResult.Success>(result).session
    }
}
