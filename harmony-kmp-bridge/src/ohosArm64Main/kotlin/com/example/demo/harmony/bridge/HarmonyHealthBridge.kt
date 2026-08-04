package com.example.demo.harmony.bridge

import com.example.demo.common.health.facade.HealthFacade
import com.example.demo.common.health.mock.HealthPreviewFixtures
import com.example.demo.common.health.model.HealthState
import com.example.demo.common.health.store.InMemoryHealthDashboardStateDataSource
import com.example.demo.common.health.mock.MockHealthDashboardStoreJson
import com.example.demo.common.health.model.healthScenarioFromPersistedCode

/**
 * 健康域 KNOI 转发桥：承载全部 health 快照/编辑/持久化方法。
 * 由 [HarmonyLoginService] 持有并委托，保持 KNOI @ServiceProvider 契约不变。
 */
internal class HarmonyHealthBridge(
    private val healthDataSource: InMemoryHealthDashboardStateDataSource,
    healthFacade: HealthFacade
) {
    var healthFacade: HealthFacade = healthFacade
        private set

    fun updateFacade(facade: HealthFacade) {
        healthFacade = facade
    }

    fun healthScenarioDescriptorsJson(): String {
        return healthFacade.scenarioDescriptors().joinToString(prefix = "[", postfix = "]") {
            """{"code":"${it.code.esc()}","displayKey":"${it.displayKey.esc()}"}"""
        }
    }

    fun healthEditableSectionsJson(): String =
        healthFacade.editableSectionNames().joinToString(prefix = "[", postfix = "]") {
            "\"${it.esc()}\""
        }

    fun normalHealthEditFormJson(sectionName: String): String =
        healthFacade.normalEditFormJson(sectionName).orEmpty()

    fun defaultNormalHealthEditFormJson(sectionName: String): String =
        healthFacade.defaultNormalEditFormJson(sectionName).orEmpty()

    fun mutateNormalHealthEditFormJson(
        sectionName: String,
        valuesSpec: String,
        groupId: String,
        operationName: String,
        rowIndex: Int
    ): String = healthFacade.mutateNormalEditFormJson(
        sectionName,
        valuesSpec,
        groupId,
        operationName,
        rowIndex
    ).orEmpty()

    fun saveNormalHealthEditForm(sectionName: String, valuesSpec: String): Boolean =
        healthFacade.saveNormalEditForm(sectionName, valuesSpec)

    fun saveNormalHealthEditFormResultJson(sectionName: String, valuesSpec: String): String =
        healthFacade.saveNormalEditFormResultJson(sectionName, valuesSpec)

    fun restoreAllNormalHealthDefaults(): String =
        healthFacade.restoreAllNormalDefaults().toString()

    fun staleHealthForNewAccount() {
        healthFacade.staleForNewAccount()
    }

    fun loadHealthSnapshot(): String {
        healthFacade.load()
        val state = healthFacade.state
        return if (state.error != null) {
            "{\"error\":\"${state.error.name}\"}"
        } else {
            healthSnapshotFromState(state)
        }
    }

    /** Side-effect-free common fixture for ArkUI Preview and screenshot tooling. */
    fun previewHealthSnapshot(): String =
        healthSnapshotFromState(HealthPreviewFixtures.normalState())

    fun selectHealthScene(name: String): String {
        return healthFacade.selectScenario(name).toString()
    }

    fun refreshHealthSnapshot(): String {
        healthFacade.refresh()
        val state = healthFacade.state
        return if (state.error != null) {
            "{\"error\":\"${state.error.name}\"}"
        } else {
            healthSnapshotFromState(state)
        }
    }

    fun saveCardConfig(typeNamesCsv: String): String {
        val names = typeNamesCsv.split(",").map { it.trim() }.filter { it.isNotBlank() }
        val error = healthFacade.saveCardConfiguration(names)
        return if (error != null) {
            "{\"error\":\"$error\"}"
        } else {
            healthSnapshotFromState(healthFacade.state)
        }
    }

    fun saveHealthBodyWeight(weightKg: Double): String {
        val error = healthFacade.saveBodyWeight(weightKg)
        return if (error != null) {
            "{\"error\":\"${error.esc()}\"}"
        } else {
            healthSnapshotFromState(healthFacade.state)
        }
    }

    fun exportHealthSnapshot(): String {
        return MockHealthDashboardStoreJson.encodeCollection(healthDataSource.allSnapshots())
    }

    fun restoreHealthSnapshot(json: String): Boolean {
        return try {
            if (json.isBlank() || json == "{}") return false
            healthDataSource.replaceAll(MockHealthDashboardStoreJson.decodeCollection(json))
            true
        } catch (_: Exception) { false }
    }

    fun restoreLegacyHealthFromStoreJson(json: String) {
        try {
            if (healthDataSource.allSnapshots().isNotEmpty()) return
            val healthIdx = json.indexOf("\"_health\":{")
            if (healthIdx < 0) return
            val start = json.indexOf('{', healthIdx) + 1
            val end = json.indexOf('}', start)
            if (end < 0) return
            val body = json.substring(start, end)
            val scenarioKey = "\"scenario\":\""
            val scenarioIdx = body.indexOf(scenarioKey)
            if (scenarioIdx >= 0) {
                val sStart = scenarioIdx + scenarioKey.length
                val sEnd = body.indexOf('"', sStart)
                val scenario = healthScenarioFromPersistedCode(
                    body.substring(sStart, if (sEnd >= 0) sEnd else body.length)
                ).name
                if (healthFacade.selectScenario(scenario)) {
                    healthFacade.refresh()
                }
            }
            val typesKey = "\"enabledTypes\":\""
            val typesIdx = body.indexOf(typesKey)
            if (typesIdx >= 0) {
                val tStart = typesIdx + typesKey.length
                val tEnd = body.indexOf('"', tStart)
                val typesStr = body.substring(tStart, if (tEnd >= 0) tEnd else body.length)
                if (typesStr.isNotBlank()) {
                    val names = typesStr.split(",").map { it.trim() }.filter { it.isNotBlank() }
                    healthFacade.saveCardConfiguration(names)
                }
            }
        } catch (_: Exception) { }
    }
}
