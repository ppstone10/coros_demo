package com.example.demo.common.health

import com.example.demo.common.login.MockError

sealed interface HealthAction {
    data object Load : HealthAction
    data class ScenarioSelected(val scenario: HealthMockScenario) : HealthAction
    data object Refresh : HealthAction
    data class CardConfigurationChanged(val types: List<HealthCardType>) : HealthAction
    data class BodyWeightChanged(val weightKg: Double) : HealthAction
    data class NormalDraftSaved(
        val data: EditableHealthData,
        val section: HealthEditableSection
    ) : HealthAction
    data class NormalDraftSectionRestored(val section: HealthEditableSection) : HealthAction
    data object NormalDraftDefaultsRestored : HealthAction
    data object EffectConsumed : HealthAction
    data object AuthSessionExpired : HealthAction
}

data class HealthState(
    val uiState: DashboardUiState? = null,
    val isRefreshing: Boolean = false,
    val currentScenario: HealthMockScenario = HealthMockScenario.Normal,
    val enabledCardTypes: List<HealthCardType> = DefaultHealthCardOrder,
    val normalDraft: EditableHealthData? = null,
    val editSourceKind: HealthEditSourceKind = HealthEditSourceKind.Available,
    val error: HealthError? = null
)

sealed interface HealthEffect {
    data class ShowMessage(val message: String) : HealthEffect
    data object ScenarioChanged : HealthEffect
    data class ConfigSaved(val types: List<HealthCardType>) : HealthEffect
    data class BodyWeightSaved(val weightKg: Double) : HealthEffect
    data class NormalDraftSaved(val section: HealthEditableSection, val eventId: Long) : HealthEffect
    data class NormalDefaultsRestored(val eventId: Long) : HealthEffect
}

enum class HealthError {
    AuthRequired,
    EmptyData,
    CorruptedData,
    ReadFailed,
    PersistFailed,
    MinimumCardsRequired;

    companion object {
        fun fromMockError(error: MockError): HealthError = when (error) {
            MockError.AuthRequired -> AuthRequired
            MockError.EmptyData -> EmptyData
            MockError.CorruptedData -> CorruptedData
            MockError.PersistFailed -> PersistFailed
            MockError.MinimumCardsRequired -> MinimumCardsRequired
            else -> PersistFailed
        }
    }
}
