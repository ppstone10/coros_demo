package com.example.demo.harmony.bridge

import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthEffect
import com.example.demo.common.health.HealthFacade
import com.example.demo.common.health.HealthFacadeFactory
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.health.HealthState
import com.example.demo.common.health.InMemoryHealthDashboardStateDataSource
import com.example.demo.common.health.MockHealthDashboardStoreJson
import com.example.demo.common.health.PersistedDashboard
import com.example.demo.common.login.AuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.LoginFacade
import com.example.demo.common.login.LoginStore
import com.example.demo.common.login.MockAuthStore
import com.tencent.tmm.knoi.annotation.ServiceProvider
import kotlinx.cinterop.ExperimentalForeignApi
import platform.posix.time

@ServiceProvider
open class HarmonyLoginService {
    private val dataSource: MemoryAuthStoreDataSource = MemoryAuthStoreDataSource()
    private val healthDataSource = InMemoryHealthDashboardStateDataSource()
    private var facade: LoginFacade = createFacade(dataSource, healthDataSource)
    private var healthFacade: HealthFacade = createHealthFacade(dataSource, healthDataSource)

    fun stateSnapshot(): String {
        return HarmonyLoginJson.stateSnapshot(facade.state)
    }

    fun exportStoreSnapshot(): String {
        val store = dataSource.load()
        val json = HarmonyLoginJson.storeSnapshot(store)
        return json.dropLast(1) + ""","_s":{"accounts":${store.accounts.size},"session":${store.currentSession != null},"defaultInit":${store.defaultAccountsInitialized}}}"""
    }

    fun restoreStoreSnapshot(json: String): Boolean {
        if (json.isBlank()) return false
        return try {
            val store = HarmonyLoginJson.parseStoreSnapshot(json)
            dataSource.replaceStore(store)
            facade = createFacade(dataSource, healthDataSource)
            healthFacade = createHealthFacade(dataSource, healthDataSource)
            syncClock()
            facade.restoreSession()
            restoreLegacyHealthFromStoreJson(json)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun submit() {
        syncClock()
        facade.submit()
    }

    fun logout() {
        facade.logout()
    }

    fun clearSessionSilently() {
        facade.clearSessionSilently()
    }

    fun pauseSession() {
        syncClock()
        facade.pauseSession()
    }

    fun consumeEffectSnapshot(): String {
        return HarmonyLoginJson.effectSnapshot(facade.consumeEffect())
    }

    fun setLoginMode() {
        facade.setLoginMode()
    }

    fun setRegisterMode() {
        facade.setRegisterMode()
    }

    fun setUsername(value: String) {
        facade.setUsername(value)
    }

    fun setPassword(value: String) {
        facade.setPassword(value)
    }

    fun setVerifyCode(value: String) {
        facade.setVerifyCode(value)
    }

    fun setDisplayName(value: String) {
        facade.setDisplayName(value)
    }

    fun setRegion(value: String) {
        facade.setRegion(value)
    }

    fun validateLogin(account: String, password: String): Boolean {
        return facade.isLoginReady(account, password, isLoading = false)
    }

    fun validateLoginInput(account: String, password: String): String {
        return facade.validateLoginInput(account, password).orEmpty()
    }

    fun requestVerifyCode(account: String): String {
        syncClock()
        return facade.requestVerifyCode(account).orEmpty()
    }

    fun requestResentVerifyCode(account: String): String {
        syncClock()
        return facade.requestResentVerifyCode(account).orEmpty()
    }

    fun verifyCode(account: String, code: String): String {
        syncClock()
        return facade.verifyCode(account, code).orEmpty()
    }

    fun verifyCodeRemainingSeconds(account: String): Int {
        syncClock()
        return facade.verifyCodeRemainingSeconds(account)
    }

    fun normalizePhoneInput(value: String): String {
        return facade.normalizePhoneInput(value)
    }

    fun normalizeEmailInput(value: String): String {
        return facade.normalizeEmailInput(value)
    }

    fun normalizeVerifyCodeInput(value: String): String {
        return facade.normalizeVerifyCodeInput(value)
    }

    fun normalizePasswordInput(value: String): String {
        return facade.normalizePasswordInput(value)
    }

    fun isLoginReady(account: String, password: String, isLoading: Boolean): Boolean {
        return facade.isLoginReady(account, password, isLoading)
    }

    fun isPhoneAccountValid(account: String): Boolean {
        return facade.isPhoneAccountValid(account)
    }

    fun isEmailAccountValid(email: String): Boolean {
        return facade.isEmailAccountValid(email)
    }

    fun isRegisterPasswordReady(password: String, confirmPassword: String, isLoading: Boolean): Boolean {
        return facade.isRegisterPasswordReady(password, confirmPassword, isLoading)
    }

    fun isResetPasswordReady(newPassword: String, confirmPassword: String, isLoading: Boolean): Boolean {
        return facade.isResetPasswordReady(newPassword, confirmPassword, isLoading)
    }

    fun hasAccount(account: String): Boolean {
        return facade.hasAccount(account)
    }

    fun isProfileRequiredComplete(
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        gender: String,
        isLoading: Boolean
    ): Boolean {
        return facade.isProfileRequiredComplete(username, birthDate, heightCm, weightKg, gender, isLoading)
    }

    fun validatePhoneAccount(account: String): String {
        return facade.validatePhoneAccount(account).orEmpty()
    }

    fun validateEmailAccount(email: String): String {
        return facade.validateEmailAccount(email).orEmpty()
    }

    fun validateVerifyCode(code: String): String {
        return facade.validateVerifyCode(code).orEmpty()
    }

    fun validateRegisterPassword(password: String, confirmPassword: String): String {
        return facade.validateRegisterPassword(password, confirmPassword).orEmpty()
    }

    fun resetPassword(account: String, newPassword: String): String {
        return facade.resetPassword(account, newPassword).orEmpty()
    }

    fun changePassword(account: String, oldPassword: String, newPassword: String): String {
        return facade.changePassword(account, oldPassword, newPassword).orEmpty()
    }

    fun submitProfile(
        avatarUri: String,
        username: String,
        birthDate: String,
        heightCm: Int,
        weightKg: Double,
        measurementSystem: String,
        phone: String,
        countryRegion: String,
        gender: String
    ) {
        facade.submitProfile(
            avatarUri = avatarUri.takeIf { it.isNotBlank() },
            username = username,
            birthDate = birthDate,
            heightCm = heightCm,
            weightKg = weightKg,
            measurementSystem = measurementSystem,
            phone = phone,
            countryRegion = countryRegion,
            gender = gender
        )
    }

    fun deleteCurrentAccount(): String {
        return facade.deleteCurrentAccount().orEmpty()
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

    private fun restoreLegacyHealthFromStoreJson(json: String) {
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
                val scenario = body.substring(sStart, if (sEnd >= 0) sEnd else body.length)
                if (scenario.isNotBlank() && healthFacade.selectScenario(scenario)) {
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

    @OptIn(ExperimentalForeignApi::class)
    private fun createFacade(
        dataSource: MemoryAuthStoreDataSource,
        healthDataSource: InMemoryHealthDashboardStateDataSource
    ): LoginFacade {
        return LoginFacade(LoginStore.create(LocalMockAuthRepository(dataSource)))
    }

    private fun createHealthFacade(
        dataSource: MemoryAuthStoreDataSource,
        healthDataSource: InMemoryHealthDashboardStateDataSource
    ): HealthFacade {
        return HealthFacadeFactory().createPersistent(
            authRepository = LocalMockAuthRepository(dataSource),
            stateDataSource = healthDataSource
        )
    }

    @OptIn(ExperimentalForeignApi::class)
    private fun syncClock() {
        facade.setCurrentTimeEpochMs(time(null) * 1000L)
    }
}

private class MemoryAuthStoreDataSource(
    initialStore: MockAuthStore = MockAuthStore()
) : AuthStoreDataSource {
    private var store: MockAuthStore = initialStore

    override fun load(): MockAuthStore = store

    override fun save(store: MockAuthStore): Boolean {
        this.store = store
        return true
    }

    fun replaceStore(newStore: MockAuthStore) {
        this.store = newStore
    }
}

private fun healthSnapshotFromState(state: HealthState): String {
    val uiState = state.uiState ?: return "{}"
    val sb = StringBuilder()
    sb.append("{\"scenario\":\"")
    sb.append(state.currentScenario.name)
    sb.append("\",\"dateLabelKey\":\"")
    sb.append(uiState.dateLabel.key.esc())
    sb.append("\",\"steps\":")
    sb.append(uiState.dailySummary?.steps ?: 0)
    sb.append(",\"calories\":")
    sb.append(uiState.dailySummary?.calories ?: 0)
    sb.append(",\"activeMinutes\":")
    sb.append(uiState.dailySummary?.activeMinutes ?: 0)
    sb.append(",\"cards\":[")
    uiState.cards.forEachIndexed { index, card ->
        if (index > 0) sb.append(",")
        sb.append("{\"type\":\"")
        sb.append(card.type.name)
        sb.append("\",\"titleKey\":\"")
        sb.append(card.title.key.esc())
        sb.append("\",\"summaryKey\":\"")
        sb.append(card.summary.key.esc())
        sb.append("\",\"summaryArgs\":[")
        card.summary.arguments.forEachIndexed { argumentIndex, argument ->
            if (argumentIndex > 0) sb.append(",")
            sb.append("\"").append(argument.esc()).append("\"")
        }
        sb.append("]")
        sb.append(",\"status\":\"")
        sb.append(card.status.name)
        sb.append("\"")
        sb.append(",\"isRisk\":")
        sb.append(card.status.name == "Risk")
        sb.append(",\"visual\":{")
        sb.append("\"kind\":\"").append(card.visual.kind.name).append("\"")
        card.visual.primaryValue?.let { sb.append(",\"primaryValue\":\"").append(it.esc()).append("\"") }
        card.visual.primaryUnit?.let { sb.append(",\"primaryUnitKey\":\"").append(it.key.esc()).append("\"") }
        card.visual.secondaryValue?.let { sb.append(",\"secondaryValue\":\"").append(it.esc()).append("\"") }
        card.visual.secondaryUnit?.let { sb.append(",\"secondaryUnitKey\":\"").append(it.key.esc()).append("\"") }
        card.visual.caption?.let { spec ->
            sb.append(",\"captionKey\":\"").append(spec.key.esc()).append("\",\"captionArgs\":[")
            spec.arguments.forEachIndexed { i, arg -> if (i > 0) sb.append(","); sb.append("\"").append(arg.esc()).append("\"") }
            sb.append("]")
        }
        card.visual.detail?.let { spec ->
            sb.append(",\"detailKey\":\"").append(spec.key.esc()).append("\",\"detailArgs\":[")
            spec.arguments.forEachIndexed { i, arg -> if (i > 0) sb.append(","); sb.append("\"").append(arg.esc()).append("\"") }
            sb.append("]")
        }
        card.visual.progress?.let { sb.append(",\"progress\":").append(it) }
        card.visual.highlightedIndex?.let { sb.append(",\"highlightedIndex\":").append(it) }
        sb.append(",\"weeklyDayPlans\":[")
        card.visual.weeklyDayPlans.forEachIndexed { i, plan ->
            if (i > 0) sb.append(",")
            sb.append("{\"dayIndex\":").append(plan.dayIndex)
            plan.workoutName?.let { sb.append(",\"workoutNameKey\":\"").append(it.key.esc()).append("\"") }
            plan.workoutDurationMinutes?.let { sb.append(",\"workoutDurationMinutes\":").append(it) }
            plan.workoutTrainingLoad?.let { sb.append(",\"workoutTrainingLoad\":").append(it) }
            sb.append("}")
        }
        sb.append("]")
        sb.append(",\"chartPoints\":[")
        card.visual.chartPoints.forEachIndexed { i, point ->
            if (i > 0) sb.append(",")
            sb.append("{\"label\":\"").append(point.label.esc()).append("\",\"value\":").append(point.value)
                .append(",\"level\":\"").append(point.level.name).append("\"")
            point.minimum?.let { sb.append(",\"minimum\":").append(it) }
            point.maximum?.let { sb.append(",\"maximum\":").append(it) }
            point.average?.let { sb.append(",\"average\":").append(it) }
            sb.append("}")
        }
        sb.append("],\"metrics\":[")
        card.visual.metrics.forEachIndexed { i, metric ->
            if (i > 0) sb.append(",")
            sb.append("{\"labelKey\":\"").append(metric.label.key.esc()).append("\",\"value\":\"").append(metric.value.esc()).append("\"")
            metric.unit?.let { sb.append(",\"unitKey\":\"").append(it.key.esc()).append("\"") }
            sb.append("}")
        }
        sb.append("]")
        card.visual.range?.let { range ->
            sb.append(",\"range\":{\"minimum\":").append(range.minimum).append(",\"maximum\":").append(range.maximum)
                .append(",\"current\":").append(range.current)
            range.normalMin?.let { sb.append(",\"normalMin\":").append(it) }
            range.normalMax?.let { sb.append(",\"normalMax\":").append(it) }
            range.average?.let { sb.append(",\"average\":").append(it) }
            sb.append("}")
        }
        sb.append(",\"sleepStages\":[")
        card.visual.sleepStages.forEachIndexed { i, stage ->
            if (i > 0) sb.append(",")
            sb.append("{\"stage\":\"").append(stage.stage.name).append("\",\"startMinute\":").append(stage.startMinute)
                .append(",\"durationMinutes\":").append(stage.durationMinutes).append("}")
        }
        sb.append("]")
        card.visual.startTime?.let { sb.append(",\"startTime\":\"").append(it.esc()).append("\"") }
        card.visual.endTime?.let { sb.append(",\"endTime\":\"").append(it.esc()).append("\"") }
        card.visual.assetKey?.let { sb.append(",\"assetKey\":\"").append(it.esc()).append("\"") }
        sb.append("}")
        sb.append("}")
    }
    sb.append("],\"enabledTypes\":\"")
    sb.append(state.enabledCardTypes.joinToString(",") { it.name })
    sb.append("\"}")
    return sb.toString()
}

private fun String.esc(): String = replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
