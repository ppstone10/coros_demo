package com.example.demo.health

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.example.demo.common.health.HealthAction
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.EditableHealthData
import com.example.demo.common.health.HealthEditableSection
import com.example.demo.common.health.HealthEditForm
import com.example.demo.common.health.HealthEditApplyResult
import com.example.demo.common.health.HealthEditRepeatOperation
import com.example.demo.common.health.HealthEditableForms
import com.example.demo.common.health.DefaultEditableHealthData
import com.example.demo.common.health.HealthEffect
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.health.HealthState
import com.example.demo.common.health.HealthStore

class HealthDashboardViewModel(
    private val store: HealthStore
) {
    var state: HealthState by mutableStateOf(store.state)
        private set

    var effect: HealthEffect? by mutableStateOf(null)
        private set

    fun load() {
        dispatch(HealthAction.Load)
    }

    fun refresh() {
        dispatch(HealthAction.Refresh)
    }

    fun selectScenario(scenario: HealthMockScenario) {
        dispatch(HealthAction.ScenarioSelected(scenario))
    }

    fun saveCardConfiguration(types: List<HealthCardType>) {
        dispatch(HealthAction.CardConfigurationChanged(types))
    }

    fun saveBodyWeight(weightKg: Double) {
        dispatch(HealthAction.BodyWeightChanged(weightKg))
    }

    fun beginNormalDataEditing(): EditableHealthData {
        val data = store.normalDraftForEditing()
        state = store.state
        return data
    }

    fun saveNormalDraft(data: EditableHealthData, section: HealthEditableSection) {
        dispatch(HealthAction.NormalDraftSaved(data, section))
    }

    fun restoreNormalSection(section: HealthEditableSection) {
        dispatch(HealthAction.NormalDraftSectionRestored(section))
    }

    fun restoreAllNormalDefaults() {
        dispatch(HealthAction.NormalDraftDefaultsRestored)
    }

    fun normalEditForm(section: HealthEditableSection): HealthEditForm =
        HealthEditableForms.form(beginNormalDataEditing(), section, state.editSourceKind)

    fun defaultNormalEditForm(section: HealthEditableSection): HealthEditForm =
        HealthEditableForms.form(DefaultEditableHealthData.value, section)

    fun mutateNormalEditForm(
        section: HealthEditableSection,
        values: Map<String, String>,
        groupId: String,
        operation: HealthEditRepeatOperation,
        rowIndex: Int? = null
    ): HealthEditForm? = HealthEditableForms.mutate(
        beginNormalDataEditing(),
        section,
        values,
        groupId,
        operation,
        rowIndex
    )?.copy(
        sourceKind = state.editSourceKind,
        sourceMessageKey = state.editSourceKind.messageKey
    )

    fun saveNormalEditForm(
        section: HealthEditableSection,
        values: Map<String, String>
    ): HealthEditApplyResult {
        val result = HealthEditableForms.applyDetailed(beginNormalDataEditing(), section, values)
        val updated = result.data ?: return result
        saveNormalDraft(updated, section)
        return if (state.error == null) result else HealthEditApplyResult(
            issue = com.example.demo.common.health.HealthEditValidationIssue(
                fieldId = section.name,
                labelKey = "health_edit_title_${section.name.replaceFirstChar { it.lowercase() }}",
                reason = com.example.demo.common.health.HealthEditValidationReason.Inconsistent
            )
        )
    }

    fun onEffectConsumed() {
        effect = null
    }

    fun staleForNewAccount() {
        store.staleForNewAccount()
        state = store.state
    }

    private fun dispatch(action: HealthAction) {
        store.dispatch(action)
        state = store.state
        effect = store.consumeEffect()
    }
}
