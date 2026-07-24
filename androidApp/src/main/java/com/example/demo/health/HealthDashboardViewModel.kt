package com.example.demo.health

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.example.demo.common.health.HealthAction
import com.example.demo.common.health.HealthCardType
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

    fun onEffectConsumed() {
        effect = null
    }

    private fun dispatch(action: HealthAction) {
        store.dispatch(action)
        state = store.state
        effect = store.consumeEffect()
    }
}
