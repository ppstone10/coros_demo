package com.example.demo.common.login

/**
 * 后续业务模块应通过此类模式读取本地 mock 数据，而不是在页面中自行判断登录状态。
 */
data class MockBusinessSummary(
    val userId: String,
    val displayName: String,
    val greetingKey: String,
    val greetingArguments: List<String>,
    val weeklyTrainingMinutes: Int
)

interface BusinessMockDataSource {
    fun loadSummary(): MockResult<MockBusinessSummary>
}

class LocalBusinessMockDataSource(
    private val authRepository: AuthRepository
) : BusinessMockDataSource {
    override fun loadSummary(): MockResult<MockBusinessSummary> {
        return when (val access = authRepository.verifyBusinessAccess()) {
            is MockResult.Success -> {
                val session = access.data
                MockResult.Success(
                    MockBusinessSummary(
                        userId = session.userId,
                        displayName = session.resolvedDisplayName,
                        greetingKey = "business_welcome_back",
                        greetingArguments = listOf(session.resolvedDisplayName),
                        weeklyTrainingMinutes = 0
                    )
                )
            }
            is MockResult.Failure -> MockResult.Failure(access.error)
        }
    }
}
