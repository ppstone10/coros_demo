package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.MockResult

class HealthStore(
    private val authRepository: AuthRepository,
    private val stateDataSource: HealthDashboardStateDataSource
) {
    private val dashboardStore = HealthDashboardStore(authRepository, stateDataSource)

    var state: HealthState = HealthState()
        private set

    private var pendingEffect: HealthEffect? = null

    fun dispatch(action: HealthAction) {
        when (action) {
            HealthAction.Load -> load()
            is HealthAction.ScenarioSelected -> selectScenario(action.scenario)
            HealthAction.Refresh -> refresh()
            is HealthAction.CardConfigurationChanged -> saveCardConfiguration(action.types)
            HealthAction.EffectConsumed -> pendingEffect = null
            HealthAction.AuthSessionExpired -> handleSessionExpired()
        }
    }

    fun consumeEffect(): HealthEffect? {
        val e = pendingEffect
        pendingEffect = null
        return e
    }

    private fun load() {
        when (val result = dashboardStore.load()) {
            is MockResult.Failure -> {
                state = HealthState(error = HealthError.fromMockError(result.error))
                pendingEffect = HealthEffect.ShowMessage(result.error.message)
            }
            is MockResult.Success -> apply(result.data)
        }
    }

    private fun selectScenario(scenario: HealthMockScenario) {
        dashboardStore.selectScenario(scenario)
        state = state.copy(currentScenario = scenario)
    }

    private fun refresh() {
        state = state.copy(isRefreshing = true)
        when (val result = dashboardStore.refresh()) {
            is MockResult.Failure -> {
                state = state.copy(isRefreshing = false, error = HealthError.fromMockError(result.error))
                pendingEffect = HealthEffect.ShowMessage(result.error.message)
            }
            is MockResult.Success -> {
                apply(result.data)
                pendingEffect = HealthEffect.ScenarioChanged
            }
        }
    }

    private fun saveCardConfiguration(types: List<HealthCardType>) {
        val clean = types.distinct()
        if (!HealthRules.validateMinimumCards(clean)) {
            state = state.copy(error = HealthError.MinimumCardsRequired)
            pendingEffect = HealthEffect.ShowMessage(HealthMessageKeys.ErrorMinimumCardsRequired)
            return
        }
        when (val result = dashboardStore.saveCardConfiguration(clean)) {
            is MockResult.Failure -> {
                state = state.copy(error = HealthError.fromMockError(result.error))
                pendingEffect = HealthEffect.ShowMessage(result.error.message)
            }
            is MockResult.Success -> {
                apply(result.data)
                pendingEffect = HealthEffect.ConfigSaved(clean)
            }
        }
    }

    private fun handleSessionExpired() {
        state = HealthState(error = HealthError.AuthRequired)
        pendingEffect = HealthEffect.ShowMessage(HealthMessageKeys.ErrorHealthDataUnavailable)
    }

    private fun apply(dashboard: PersistedDashboard) {
        state = HealthState(
            uiState = dashboard.uiState,
            currentScenario = dashboard.scenario,
            enabledCardTypes = dashboard.enabledCardTypes,
            isRefreshing = false,
            error = null
        )
    }

    fun clear(userId: String): Boolean = dashboardStore.clear(userId)
}
