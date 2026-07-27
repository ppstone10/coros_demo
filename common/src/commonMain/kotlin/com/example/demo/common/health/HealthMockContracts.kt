package com.example.demo.common.health

enum class HealthMockScenarioCode {
    HEALTH_MOCK_SCENARIO_UNSPECIFIED,
    HEALTH_MOCK_SCENARIO_NORMAL,
    HEALTH_MOCK_SCENARIO_PARTIAL_MISSING,
    HEALTH_MOCK_SCENARIO_ALL_EMPTY,
    HEALTH_MOCK_SCENARIO_ABNORMAL,
    HEALTH_MOCK_SCENARIO_READ_FAILURE
}

enum class HealthMockErrorCode {
    HEALTH_MOCK_ERROR_UNSPECIFIED,
    HEALTH_MOCK_ERROR_AUTH_REQUIRED,
    HEALTH_MOCK_ERROR_EMPTY_DATA,
    HEALTH_MOCK_ERROR_CORRUPTED_DATA,
    HEALTH_MOCK_ERROR_READ_FAILED,
    HEALTH_MOCK_ERROR_PERSIST_FAILED,
    HEALTH_MOCK_ERROR_MINIMUM_CARDS_REQUIRED
}

data class HealthMockErrorMessage(
    val code: HealthMockErrorCode,
    val messageKey: String
)

fun HealthMockScenario.toProtoCode(): HealthMockScenarioCode = when (this) {
    HealthMockScenario.Normal -> HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_NORMAL
    HealthMockScenario.PartialMissing -> HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_PARTIAL_MISSING
    HealthMockScenario.AllEmpty -> HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_ALL_EMPTY
    HealthMockScenario.Abnormal -> HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_ABNORMAL
    HealthMockScenario.ReadFailure -> HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_READ_FAILURE
}

fun HealthMockScenarioCode.toDomain(): HealthMockScenario = when (this) {
    HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_PARTIAL_MISSING -> HealthMockScenario.PartialMissing
    HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_ALL_EMPTY -> HealthMockScenario.AllEmpty
    HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_ABNORMAL -> HealthMockScenario.Abnormal
    HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_READ_FAILURE -> HealthMockScenario.ReadFailure
    HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_UNSPECIFIED,
    HealthMockScenarioCode.HEALTH_MOCK_SCENARIO_NORMAL -> HealthMockScenario.Normal
}

fun healthScenarioFromPersistedCode(value: String?): HealthMockScenario {
    if (value.isNullOrBlank()) return HealthMockScenario.Normal
    return HealthMockScenarioCode.entries.firstOrNull { it.name == value }?.toDomain()
        ?: HealthMockScenario.entries.firstOrNull { it.name == value }
        ?: HealthMockScenario.Normal
}

fun HealthError.toProtoMessage(): HealthMockErrorMessage = when (this) {
    HealthError.AuthRequired -> HealthMockErrorMessage(
        HealthMockErrorCode.HEALTH_MOCK_ERROR_AUTH_REQUIRED,
        "auth_error_auth_required"
    )
    HealthError.EmptyData -> HealthMockErrorMessage(
        HealthMockErrorCode.HEALTH_MOCK_ERROR_EMPTY_DATA,
        "auth_error_empty_data"
    )
    HealthError.CorruptedData -> HealthMockErrorMessage(
        HealthMockErrorCode.HEALTH_MOCK_ERROR_CORRUPTED_DATA,
        "auth_error_corrupted_data"
    )
    HealthError.ReadFailed -> HealthMockErrorMessage(
        HealthMockErrorCode.HEALTH_MOCK_ERROR_READ_FAILED,
        "health_data_corrupted"
    )
    HealthError.PersistFailed -> HealthMockErrorMessage(
        HealthMockErrorCode.HEALTH_MOCK_ERROR_PERSIST_FAILED,
        "auth_error_persist_failed"
    )
    HealthError.MinimumCardsRequired -> HealthMockErrorMessage(
        HealthMockErrorCode.HEALTH_MOCK_ERROR_MINIMUM_CARDS_REQUIRED,
        HealthMessageKeys.ErrorMinimumCardsRequired
    )
}

fun HealthMockErrorMessage.toDomain(): HealthError = when (code) {
    HealthMockErrorCode.HEALTH_MOCK_ERROR_AUTH_REQUIRED -> HealthError.AuthRequired
    HealthMockErrorCode.HEALTH_MOCK_ERROR_EMPTY_DATA -> HealthError.EmptyData
    HealthMockErrorCode.HEALTH_MOCK_ERROR_CORRUPTED_DATA -> HealthError.CorruptedData
    HealthMockErrorCode.HEALTH_MOCK_ERROR_READ_FAILED -> HealthError.ReadFailed
    HealthMockErrorCode.HEALTH_MOCK_ERROR_MINIMUM_CARDS_REQUIRED -> HealthError.MinimumCardsRequired
    HealthMockErrorCode.HEALTH_MOCK_ERROR_UNSPECIFIED,
    HealthMockErrorCode.HEALTH_MOCK_ERROR_PERSIST_FAILED -> HealthError.PersistFailed
}
