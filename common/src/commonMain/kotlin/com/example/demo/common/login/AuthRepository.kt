package com.example.demo.common.login

interface AuthRepository {
    fun login(request: LoginRequestDto): LoginResult
}

class FakeAuthRepository : AuthRepository {
    override fun login(request: LoginRequestDto): LoginResult {
        val username = request.username.trim()
        val password = request.password

        return if (username == "demo" && password == "demo123") {
            LoginResult.Success(
                UserDto(
                    id = "user-demo",
                    displayName = "Demo User",
                    accessToken = "fake-token-demo"
                )
            )
        } else {
            LoginResult.Failure(
                code = "AUTH_INVALID_CREDENTIALS",
                message = "用户名或密码不正确"
            )
        }
    }
}
