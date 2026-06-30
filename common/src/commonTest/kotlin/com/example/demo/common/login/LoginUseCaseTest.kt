package com.example.demo.common.login

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs

class LoginUseCaseTest {
    private val useCase = LoginUseCase(FakeAuthRepository())

    @Test
    fun loginWithDemoAccountSucceeds() {
        val result = useCase.execute(username = "demo", password = "demo123")

        val success = assertIs<LoginResult.Success>(result)
        assertEquals("Demo User", success.user.displayName)
    }

    @Test
    fun loginWithInvalidPasswordFails() {
        val result = useCase.execute(username = "demo", password = "wrong")

        val failure = assertIs<LoginResult.Failure>(result)
        assertEquals("AUTH_INVALID_CREDENTIALS", failure.code)
    }
}
