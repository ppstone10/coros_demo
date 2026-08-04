package com.example.demo.common.login

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
    fun restoreSessionOnColdStart(): SessionResumeResult
    fun resumeSessionInSameProcess(): SessionResumeResult
    fun resumeSession(): SessionResumeResult
    fun changePassword(account: String, oldPassword: String, newPassword: String): MockResult<Unit>
    fun resetPassword(account: String, newPassword: String): MockResult<Unit>
    fun deleteCurrentAccount(): MockResult<Unit>
    fun register(request: RegisterRequestDto): LoginResult
    fun login(request: LoginRequestDto): LoginResult
    fun verifyBusinessAccess(): MockResult<AuthSession>
}
