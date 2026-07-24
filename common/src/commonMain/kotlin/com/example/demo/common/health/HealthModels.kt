package com.example.demo.common.health

import com.example.demo.common.login.MockError

sealed interface HealthAction {
    data object Load : HealthAction
    data class ScenarioSelected(val scenario: HealthMockScenario) : HealthAction
    data object Refresh : HealthAction
    data class CardConfigurationChanged(val types: List<HealthCardType>) : HealthAction
    data object EffectConsumed : HealthAction
    data object AuthSessionExpired : HealthAction
}

data class HealthState(
    val uiState: DashboardUiState? = null,
    val isRefreshing: Boolean = false,
    val currentScenario: HealthMockScenario = HealthMockScenario.Normal,
    val enabledCardTypes: List<HealthCardType> = DefaultHealthCardOrder,
    val error: HealthError? = null
)

sealed interface HealthEffect {
    data class ShowMessage(val message: String) : HealthEffect
    data object ScenarioChanged : HealthEffect
    data class ConfigSaved(val types: List<HealthCardType>) : HealthEffect
}

enum class HealthError {
    AuthRequired,
    CorruptedData,
    PersistFailed,
    MinimumCardsRequired;

    companion object {
        fun fromMockError(error: MockError): HealthError = when (error) {
            MockError.AuthRequired -> AuthRequired
            MockError.CorruptedData -> CorruptedData
            MockError.PersistFailed -> PersistFailed
            MockError.MinimumCardsRequired -> MinimumCardsRequired
            else -> PersistFailed
        }
    }
}
