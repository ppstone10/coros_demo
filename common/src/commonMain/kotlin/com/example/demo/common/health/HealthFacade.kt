package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.InMemoryAuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository

@Suppress("unused")
class HealthFacade(
    private val store: HealthStore
) {
    constructor() : this(
        HealthStore(
            LocalMockAuthRepository(InMemoryAuthStoreDataSource()),
            InMemoryHealthDashboardStateDataSource()
        )
    )

    val state: HealthState
        get() = store.state

    fun scenarioDescriptors(): List<HealthScenarioDescriptor> = HealthScenarios.entries

    fun editableSectionNames(): List<String> = HealthEditableSection.entries.map { it.name }

    fun load() {
        store.dispatch(HealthAction.Load)
    }

    fun selectScenario(name: String): Boolean {
        val scenario = HealthMockScenario.entries.firstOrNull { it.name == name } ?: return false
        store.dispatch(HealthAction.ScenarioSelected(scenario))
        return true
    }

    fun refresh() {
        store.dispatch(HealthAction.Refresh)
    }

    fun saveCardConfiguration(typeNames: List<String>): String? {
        val types = typeNames.mapNotNull { n -> HealthCardType.entries.firstOrNull { it.name == n } }
        store.dispatch(HealthAction.CardConfigurationChanged(types))
        val effect = store.consumeEffect()
        return if (effect is HealthEffect.ShowMessage) effect.message else null
    }

    fun saveBodyWeight(weightKg: Double): String? {
        store.dispatch(HealthAction.BodyWeightChanged(weightKg))
        val effect = store.consumeEffect()
        return if (effect is HealthEffect.ShowMessage) effect.message else null
    }

    fun normalEditableDataJson(): String =
        MockHealthDashboardStoreJson.encodeEditable(store.normalDraftForEditing())

    fun saveNormalEditableDataJson(json: String, sectionName: String): Boolean {
        val section = HealthEditableSection.entries.firstOrNull { it.name == sectionName }
            ?: return false
        val data = runCatching { MockHealthDashboardStoreJson.decodeEditable(json) }
            .getOrNull() ?: return false
        store.dispatch(HealthAction.NormalDraftSaved(data, section))
        return store.state.error == null
    }

    fun normalEditFormJson(sectionName: String): String? {
        val section = HealthEditableSection.entries.firstOrNull { it.name == sectionName }
            ?: return null
        val data = store.normalDraftForEditing()
        return HealthEditableForms.formJson(
            HealthEditableForms.form(data, section, store.state.editSourceKind)
        )
    }

    fun defaultNormalEditFormJson(sectionName: String): String? {
        val section = HealthEditableSection.entries.firstOrNull { it.name == sectionName }
            ?: return null
        return HealthEditableForms.formJson(DefaultEditableHealthData.value, section)
    }

    fun mutateNormalEditFormJson(
        sectionName: String,
        valuesSpec: String,
        groupId: String,
        operationName: String,
        rowIndex: Int
    ): String? {
        val section = HealthEditableSection.entries.firstOrNull { it.name == sectionName }
            ?: return null
        val operation = HealthEditRepeatOperation.entries.firstOrNull {
            it.name == operationName
        } ?: return null
        val values = runCatching { HealthEditableForms.decodeValues(valuesSpec) }
            .getOrNull() ?: return null
        val form = HealthEditableForms.mutate(
            source = store.normalDraftForEditing(),
            section = section,
            values = values,
            groupId = groupId,
            operation = operation,
            rowIndex = rowIndex.takeIf { it >= 0 }
        ) ?: return null
        return HealthEditableForms.formJson(
            form.copy(
                sourceKind = store.state.editSourceKind,
                sourceMessageKey = store.state.editSourceKind.messageKey
            )
        )
    }

    fun saveNormalEditForm(sectionName: String, valuesSpec: String): Boolean {
        val result = saveNormalEditFormResult(sectionName, valuesSpec)
        return result.isSuccess
    }

    fun saveNormalEditFormResultJson(sectionName: String, valuesSpec: String): String =
        HealthEditableForms.applyResultJson(saveNormalEditFormResult(sectionName, valuesSpec))

    private fun saveNormalEditFormResult(
        sectionName: String,
        valuesSpec: String
    ): HealthEditApplyResult {
        val section = HealthEditableSection.entries.firstOrNull { it.name == sectionName }
            ?: return HealthEditApplyResult(
                issue = HealthEditValidationIssue(
                    sectionName,
                    "health_edit_normal_data",
                    reason = HealthEditValidationReason.Inconsistent
                )
            )
        val current = store.normalDraftForEditing()
        val values = runCatching { HealthEditableForms.decodeValues(valuesSpec) }
            .getOrNull() ?: return HealthEditApplyResult(
                issue = HealthEditValidationIssue(
                    section.name,
                    "health_edit_title_${section.name.replaceFirstChar { it.lowercase() }}",
                    reason = HealthEditValidationReason.Inconsistent
                )
            )
        val result = HealthEditableForms.applyDetailed(current, section, values)
        val updated = result.data ?: return result
        store.dispatch(HealthAction.NormalDraftSaved(updated, section))
        return if (store.state.error == null) result else HealthEditApplyResult(
            issue = HealthEditValidationIssue(
                section.name,
                "health_edit_title_${section.name.replaceFirstChar { it.lowercase() }}",
                reason = HealthEditValidationReason.Inconsistent
            )
        )
    }

    fun saveDailySummary(steps: Int, calories: Int, activeMinutes: Int): Boolean =
        edit(HealthEditableSection.DailySummary) {
            it.copy(dailySummary = DailySummaryInput(steps, calories, activeMinutes))
        }

    fun saveTodayActivity(distanceKm: Double, paceSecondsPerKm: Int): Boolean =
        edit(HealthEditableSection.TodayActivity) {
            it.copy(todayActivity = TodayActivityInput(distanceKm, paceSecondsPerKm))
        }

    fun saveWeeklyPlan(typesCsv: String, distancesCsv: String): Boolean {
        val types = typesCsv.csvStrings().mapNotNull { value ->
            WorkoutType.entries.firstOrNull { it.name == value }
        }
        val distances = distancesCsv.csvDoubles()
        if (types.size != 7 || distances.size != 7) return false
        return edit(HealthEditableSection.WeeklyPlan) {
            it.copy(
                weeklyPlan = WeeklyPlanInput(
                    types.zip(distances).map { (type, distance) ->
                        WeeklyWorkoutInput(type, distance)
                    }
                )
            )
        }
    }

    fun saveTrainingLoad(dailyLoadsCsv: String): Boolean {
        val values = dailyLoadsCsv.csvInts()
        if (values.size != 7) return false
        return edit(HealthEditableSection.TrainingLoad) {
            it.copy(trainingLoad = TrainingLoadInput(values))
        }
    }

    fun saveTrainingAssessment(shortTermLoad: Int, longTermLoad: Int): Boolean =
        edit(HealthEditableSection.TrainingAssessment) {
            it.copy(assessment = TrainingAssessmentInput(shortTermLoad, longTermLoad))
        }

    fun saveRecovery(score: Int): Boolean = edit(HealthEditableSection.Recovery) {
        it.copy(recovery = RecoveryInput(score))
    }

    fun saveRunningAbility(score: Int): Boolean = edit(HealthEditableSection.RunningAbility) {
        it.copy(runningAbility = RunningAbilityInput(score))
    }

    fun saveCyclingAbility(score: Int): Boolean = edit(HealthEditableSection.CyclingAbility) {
        it.copy(cyclingAbility = CyclingAbilityInput(score))
    }

    fun generateAndSaveHeartRate(average: Int, patternName: String): Boolean {
        val pattern = HeartRatePattern.entries.firstOrNull { it.name == patternName } ?: return false
        val samples = runCatching {
            HealthEditableRules.generateHeartRateSamples(average, pattern)
        }.getOrNull() ?: return false
        return edit(HealthEditableSection.HeartRate) {
            it.copy(heartRate = HeartRateInput(samples))
        }
    }

    fun generateAndSaveStress(average: Int, patternName: String): Boolean {
        val pattern = StressPattern.entries.firstOrNull { it.name == patternName } ?: return false
        val samples = runCatching {
            HealthEditableRules.generateStressSamples(average, pattern)
        }.getOrNull() ?: return false
        return edit(HealthEditableSection.Stress) {
            it.copy(stress = StressInput(samples))
        }
    }

    fun saveSleep(startMinuteOfDay: Int, stagesSpec: String): Boolean {
        val stages = stagesSpec.split(';').filter(String::isNotBlank).mapNotNull { entry ->
            val fields = entry.split(':')
            if (fields.size != 3) return@mapNotNull null
            val stage = SleepStage.entries.firstOrNull { it.name == fields[0] }
                ?: return@mapNotNull null
            val start = fields[1].toIntOrNull() ?: return@mapNotNull null
            val duration = fields[2].toIntOrNull() ?: return@mapNotNull null
            SleepStageInput(stage, start, duration)
        }
        if (stages.isEmpty()) return false
        return edit(HealthEditableSection.Sleep) {
            it.copy(sleep = SleepInput(startMinuteOfDay, stages))
        }
    }

    fun saveHrvAssessment(averageMs: Int): Boolean =
        edit(HealthEditableSection.HrvAssessment) {
            it.copy(hrvAssessment = HrvAssessmentInput(averageMs))
        }

    fun saveRestingHeartRate(value: Int, measuredTime: String, thirtyDayAverage: Int): Boolean =
        edit(HealthEditableSection.RestingHeartRate) {
            it.copy(
                restingHeartRate = RestingHeartRateInput(
                    value,
                    measuredTime,
                    thirtyDayAverage
                )
            )
        }

    fun saveHealthCheck(
        heartRate: Int,
        hrvMs: Int,
        stress: Int,
        respiratoryRate: Int,
        bloodOxygen: Int,
        measuredTime: String
    ): Boolean = edit(HealthEditableSection.HealthCheck) {
        it.copy(
            healthCheck = HealthCheckInput(
                heartRate,
                hrvMs,
                stress,
                respiratoryRate,
                bloodOxygen,
                measuredTime
            )
        )
    }

    fun saveBodyManagement(weightKg: Double, muscleGroupsCsv: String): Boolean =
        edit(HealthEditableSection.BodyManagement) { data ->
            val previous = data.bodyManagement
            val rounded = kotlin.math.round(weightKg * 10.0) / 10.0
            data.copy(
                bodyManagement = previous.copy(
                    weightKg = rounded,
                    trainedMuscleGroups = muscleGroupsCsv.csvStrings().distinct(),
                    weightHistoryKg = previous.weightHistoryKg + rounded
                )
            )
        }

    fun restoreNormalSection(sectionName: String): Boolean {
        val section = HealthEditableSection.entries.firstOrNull { it.name == sectionName }
            ?: return false
        store.dispatch(HealthAction.NormalDraftSectionRestored(section))
        return store.state.error == null
    }

    fun restoreAllNormalDefaults(): Boolean {
        store.dispatch(HealthAction.NormalDraftDefaultsRestored)
        return store.state.error == null
    }

    fun consumeEffect(): HealthEffect? = store.consumeEffect()

    fun staleForNewAccount() {
        store.staleForNewAccount()
    }

    fun clearUserData(userId: String): Boolean = store.clear(userId)

    fun healthError(): HealthError? = store.state.error

    private fun edit(
        section: HealthEditableSection,
        transform: (EditableHealthData) -> EditableHealthData
    ): Boolean {
        val current = store.normalDraftForEditing()
        val updated = runCatching { transform(current) }.getOrNull() ?: return false
        if (!HealthEditableRules.validate(updated)) return false
        store.dispatch(HealthAction.NormalDraftSaved(updated, section))
        return store.state.error == null
    }

    private fun String.csvStrings(): List<String> =
        split(',').map(String::trim).filter(String::isNotEmpty)

    private fun String.csvInts(): List<Int> = csvStrings().mapNotNull(String::toIntOrNull)

    private fun String.csvDoubles(): List<Double> = csvStrings().mapNotNull(String::toDoubleOrNull)
}

@Suppress("unused")
class HealthFacadeFactory {
    fun createPersistent(
        authRepository: AuthRepository,
        stateDataSource: HealthDashboardStateDataSource
    ): HealthFacade {
        return HealthFacade(HealthStore(authRepository, stateDataSource))
    }
}
