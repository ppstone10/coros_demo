package com.example.demo.common.health.mock
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.health.model.HealthDashboardData
import com.example.demo.common.health.model.HealthEditSourceKind
import com.example.demo.common.health.model.HealthMockScenario
import com.example.demo.common.health.model.HealthState
import com.example.demo.common.health.repository.HealthDashboardDataSource
import com.example.demo.common.health.rules.HealthEditableRules
import com.example.demo.common.health.usecase.HealthDashboardUseCase
import com.example.demo.common.health.model.DefaultHealthCardOrder

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
            MockResult.Success(data)
    }
}
