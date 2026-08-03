package com.example.demo.common.health

/**
 * Deterministic, side-effect-free data used by native UI tooling previews.
 *
 * The fixture stays in commonMain so Compose, SwiftUI and ArkUI render the same
 * domain scenario. Platform adapters remain responsible for localization and UI types.
 */
object HealthPreviewFixtures {
    fun normalState(): HealthState {
        val editable = DefaultEditableHealthData.value
        val dashboard = HealthEditableRules.derive(editable)
        val uiState = HealthDashboardUseCase(PreviewDataSource(dashboard)).toUiState(dashboard)
        return HealthState(
            uiState = uiState,
            currentScenario = HealthMockScenario.Normal,
            enabledCardTypes = DefaultHealthCardOrder,
            normalDraft = editable,
            editSourceKind = HealthEditSourceKind.Available
        )
    }

    private class PreviewDataSource(
        private val data: HealthDashboardData
    ) : HealthDashboardDataSource {
        override fun load(scenario: HealthMockScenario) =
            com.example.demo.common.login.MockResult.Success(data)
    }
}
