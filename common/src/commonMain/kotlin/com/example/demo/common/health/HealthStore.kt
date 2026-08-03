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
    private var effectSequence: Long = 0

    fun dispatch(action: HealthAction) {
        when (action) {
            HealthAction.Load -> load()
            is HealthAction.ScenarioSelected -> selectScenario(action.scenario)
            HealthAction.Refresh -> refresh()
            is HealthAction.CardConfigurationChanged -> saveCardConfiguration(action.types)
            is HealthAction.BodyWeightChanged -> saveBodyWeight(action.weightKg)
            is HealthAction.NormalDraftSaved -> saveNormalDraft(action.data, action.section)
            is HealthAction.NormalDraftSectionRestored -> restoreNormalDraftSection(action.section)
            HealthAction.NormalDraftDefaultsRestored -> restoreNormalDefaults()
            HealthAction.EffectConsumed -> pendingEffect = null
            HealthAction.AuthSessionExpired -> handleSessionExpired()
        }
    }

    fun consumeEffect(): HealthEffect? {
        val e = pendingEffect
        pendingEffect = null
        return e
    }

    fun normalDraftForEditing(): EditableHealthData {
        state.normalDraft?.let { return it }
        val projection = dashboardStore.resolveBaseDraft(state.currentScenario)
        state = state.copy(
            normalDraft = projection.data,
            editSourceKind = projection.sourceKind
        )
        return projection.data
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
        state = state.copy(
            currentScenario = scenario,
            normalDraft = null,
            editSourceKind = when (scenario) {
                HealthMockScenario.ReadFailure -> HealthEditSourceKind.Corrupted
                HealthMockScenario.AllEmpty -> HealthEditSourceKind.Empty
                HealthMockScenario.PartialMissing -> HealthEditSourceKind.Partial
                else -> HealthEditSourceKind.Available
            }
        )
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

    private fun saveBodyWeight(weightKg: Double) {
        when (val result = dashboardStore.saveBodyWeight(weightKg)) {
            is MockResult.Failure -> {
                state = state.copy(error = HealthError.fromMockError(result.error))
                pendingEffect = HealthEffect.ShowMessage(result.error.message)
            }
            is MockResult.Success -> {
                apply(result.data)
                pendingEffect = HealthEffect.BodyWeightSaved(weightKg)
            }
        }
    }

    private fun saveNormalDraft(data: EditableHealthData, section: HealthEditableSection) {
        if (!HealthEditableRules.validateSection(data, section)) {
            state = state.copy(error = HealthError.CorruptedData)
            pendingEffect = HealthEffect.ShowMessage(HealthMessageKeys.ErrorHealthDataUnavailable)
            return
        }
        if (!dashboardStore.saveNormalDraft(data, section)) {
            state = state.copy(error = HealthError.CorruptedData)
            pendingEffect = HealthEffect.ShowMessage(HealthMessageKeys.ErrorHealthDataUnavailable)
            return
        }
        state = state.copy(normalDraft = data, error = null)
        pendingEffect = HealthEffect.NormalDraftSaved(section, ++effectSequence)
    }

    private fun restoreNormalDraftSection(section: HealthEditableSection) {
        val restored = dashboardStore.restoreNormalDraftSection(section)
        state = state.copy(normalDraft = restored, error = null)
        pendingEffect = HealthEffect.NormalDraftSaved(section, ++effectSequence)
    }

    private fun restoreNormalDefaults() {
        val restored = dashboardStore.restoreNormalDefaults()
        state = state.copy(normalDraft = restored, error = null)
        pendingEffect = HealthEffect.NormalDefaultsRestored(++effectSequence)
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
            normalDraft = null,
            isRefreshing = false,
            error = null
        )
    }

    fun clear(userId: String): Boolean {
        val cleared = dashboardStore.clear(userId)
        if (cleared) {
            state = HealthState(uiState = dashboardStore.emptyUiState())
            pendingEffect = null
        }
        return cleared
    }

    fun staleForNewAccount() {
        dashboardStore.clearTransientState()
        state = HealthState(uiState = dashboardStore.emptyUiState(), isRefreshing = true)
        pendingEffect = null
    }
}
