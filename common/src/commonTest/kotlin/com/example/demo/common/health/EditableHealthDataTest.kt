package com.example.demo.common.health

import com.example.demo.common.auth.repository.InMemoryAuthStoreDataSource
import com.example.demo.common.auth.mock.LocalMockAuthRepository
import com.example.demo.common.auth.mock.LocalMockAuthRepository.Companion.DefaultVerifyCode
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.auth.usecase.RegisterUseCase
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import com.example.demo.common.health.mock.DefaultEditableHealthData
import com.example.demo.common.health.mock.MockHealthDashboardStoreJson
import com.example.demo.common.health.model.BodyManagement
import com.example.demo.common.health.model.BodyMuscleGroup
import com.example.demo.common.health.model.DailySummaryInput
import com.example.demo.common.health.model.HealthAction
import com.example.demo.common.health.model.HealthCardType
import com.example.demo.common.health.model.HealthDashboardSnapshot
import com.example.demo.common.health.model.HealthEditFieldType
import com.example.demo.common.health.model.HealthEditRepeatOperation
import com.example.demo.common.health.model.HealthEditSourceKind
import com.example.demo.common.health.model.HealthEditValidationReason
import com.example.demo.common.health.model.HealthEditableSection
import com.example.demo.common.health.model.HealthMockScenario
import com.example.demo.common.health.model.HeartRatePattern
import com.example.demo.common.health.model.RecoveryInput
import com.example.demo.common.health.model.SleepInput
import com.example.demo.common.health.model.SleepStage
import com.example.demo.common.health.model.SleepStageInput
import com.example.demo.common.health.model.StressPattern
import com.example.demo.common.health.model.TodayActivityInput
import com.example.demo.common.health.model.TrainingAssessmentInput
import com.example.demo.common.health.model.WeeklyPlanInput
import com.example.demo.common.health.model.WeeklyWorkoutInput
import com.example.demo.common.health.model.WorkoutType
import com.example.demo.common.health.model.bodyVisual
import com.example.demo.common.health.rules.HealthEditableForms
import com.example.demo.common.health.rules.HealthEditableRules
import com.example.demo.common.health.store.HealthStore
import com.example.demo.common.health.store.InMemoryHealthDashboardStateDataSource

class EditableHealthDataTest {

    @Test
    fun editableSourcePersistsOnlyCanonicalInputsAndRebuildsDerivedData() {
        val source = DefaultEditableHealthData.value.copy(
            todayActivity = TodayActivityInput(distanceKm = 10.0, paceSecondsPerKm = 4 * 60 + 30),
            assessment = TrainingAssessmentInput(shortTermLoad = 180, longTermLoad = 120),
            recovery = RecoveryInput(score = 18)
        )

        val derived = HealthEditableRules.derive(source)

        assertEquals("health_visual_activity_endurance_run", derived.todayActivity?.activityName?.key)
        assertEquals(1.5, derived.trainingAssessment?.loadRatio)
        assertEquals("health_visual_assessment_efficient", derived.trainingAssessment?.assessment?.key)
        assertEquals(18, derived.recovery?.score)
        assertTrue(requireNotNull(derived.recovery?.remainingHours) > 0)
        assertFalse(source.toString().contains("activityName"))
        assertFalse(source.toString().contains("loadRatio"))
        assertFalse(source.toString().contains("remainingHours"))

        val encoded = MockHealthDashboardStoreJson.encode(
            HealthDashboardSnapshot(
                userId = "canonical",
                sourceScenario = HealthMockScenario.Normal,
                editableData = source
            )
        )
        val decoded = MockHealthDashboardStoreJson.decode(encoded)
        assertEquals(source, decoded.editableData)
        assertNull(decoded.dashboardData)
        assertFalse(encoded.contains("activityNameKey"))
        assertFalse(encoded.contains("loadRatio"))
        assertFalse(encoded.contains("remainingHours"))
    }

    @Test
    fun normalDraftDoesNotChangeSnapshotUntilRefreshAndIsNotRestored() {
        val repository = signedInRepository()
        val persistence = InMemoryHealthDashboardStateDataSource()
        val store = HealthStore(repository, persistence)
        store.dispatch(HealthAction.Load)
        val originalSummary = store.state.uiState?.dailySummary
        val edited = DefaultEditableHealthData.value.copy(
            dailySummary = DailySummaryInput(steps = 12_345, calories = 888, activeMinutes = 77)
        )
        val userId = assertIs<MockResult.Success<com.example.demo.common.auth.model.AuthSession>>(
            repository.verifyBusinessAccess()
        ).data.userId
        val snapshotBefore = persistence.load(userId)

        store.dispatch(HealthAction.NormalDraftSaved(edited, HealthEditableSection.DailySummary))

        assertEquals(originalSummary, store.state.uiState?.dailySummary)
        assertEquals(snapshotBefore, persistence.load(userId))
        assertEquals(edited, store.state.normalDraft)

        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Normal))
        store.dispatch(HealthAction.Refresh)

        assertEquals(12_345, store.state.uiState?.dailySummary?.steps)
        val persistedDashboard = persistence.load(userId)?.dashboardData
        assertNotNull(persistedDashboard)
        assertEquals(12_345, persistedDashboard.dailySummary?.steps)
        assertEquals(888, persistedDashboard.dailySummary?.calories)

        val recreated = HealthStore(repository, persistence)
        recreated.dispatch(HealthAction.Load)
        assertNull(recreated.state.normalDraft)
        assertEquals(12_345, recreated.state.uiState?.dailySummary?.steps)
    }

    @Test
    fun bodyMuscleDraftReplacesOldMusclesOnRefreshWhileWeightHistoryIsPreserved() {
        val repository = signedInRepository()
        val persistence = InMemoryHealthDashboardStateDataSource()
        val store = HealthStore(repository, persistence)
        store.dispatch(HealthAction.Load)
        store.dispatch(HealthAction.BodyWeightChanged(65.0))
        store.dispatch(HealthAction.BodyWeightChanged(66.0))

        val initialBodyVisual = requireNotNull(
            store.state.uiState?.cards
                ?.first { it.type == HealthCardType.BodyManagement }
                ?.visual
        )
        val currentDraft = store.normalDraftForEditing()
        val editedDraft = currentDraft.copy(
            bodyManagement = currentDraft.bodyManagement.copy(
                trainedMuscleGroups = listOf(BodyMuscleGroup.Back.id)
            )
        )

        store.dispatch(
            HealthAction.NormalDraftSaved(
                editedDraft,
                HealthEditableSection.BodyManagement
            )
        )

        assertEquals(
            initialBodyVisual.highlightedBodyRegions,
            store.state.uiState?.cards
                ?.first { it.type == HealthCardType.BodyManagement }
                ?.visual
                ?.highlightedBodyRegions
        )

        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Normal))
        store.dispatch(HealthAction.Refresh)

        val expectedBackRegions = listOf(
            "trapezius_back",
            "latissimus_back",
            "erector_spinae_back"
        )
        val refreshedBodyVisual = requireNotNull(
            store.state.uiState?.cards
                ?.first { it.type == HealthCardType.BodyManagement }
                ?.visual
        )
        val userId = assertIs<MockResult.Success<com.example.demo.common.auth.model.AuthSession>>(
            repository.verifyBusinessAccess()
        ).data.userId
        val persistedBody = requireNotNull(persistence.load(userId)?.dashboardData?.bodyManagement)

        assertEquals(expectedBackRegions, refreshedBodyVisual.highlightedBodyRegions)
        assertEquals(listOf(BodyMuscleGroup.Back.id), persistedBody.trainedMuscleGroups)
        assertEquals(listOf(68.2, 65.0, 66.0), persistedBody.weightHistoryKg)
        assertEquals(66.0, persistedBody.weightKg)

        val recreated = HealthStore(repository, persistence)
        recreated.dispatch(HealthAction.Load)
        assertEquals(
            expectedBackRegions,
            recreated.state.uiState?.cards
                ?.first { it.type == HealthCardType.BodyManagement }
                ?.visual
                ?.highlightedBodyRegions
        )
    }

    @Test
    fun singleModuleAndWholeDraftRestoreUseCommonDefaults() {
        val custom = DefaultEditableHealthData.value.copy(
            dailySummary = DailySummaryInput(1, 2, 3),
            todayActivity = TodayActivityInput(42.0, 240)
        )

        val singleRestored = HealthEditableRules.restoreSection(
            custom,
            HealthEditableSection.TodayActivity
        )
        assertEquals(DefaultEditableHealthData.value.todayActivity, singleRestored.todayActivity)
        assertEquals(custom.dailySummary, singleRestored.dailySummary)
        assertEquals(DefaultEditableHealthData.value, HealthEditableRules.restoreAll(custom))
    }

    @Test
    fun heartAndStressGeneratorsProduceDeterministicFullSequences() {
        HeartRatePattern.entries.forEach { pattern ->
            val first = HealthEditableRules.generateHeartRateSamples(average = 72, pattern = pattern)
            val second = HealthEditableRules.generateHeartRateSamples(average = 72, pattern = pattern)
            assertEquals(288, first.size)
            assertEquals(first, second)
            assertTrue(first.all { it in 35..220 })
        }
        StressPattern.entries.forEach { pattern ->
            val first = HealthEditableRules.generateStressSamples(average = 45, pattern = pattern)
            val second = HealthEditableRules.generateStressSamples(average = 45, pattern = pattern)
            assertEquals(48, first.size)
            assertEquals(first, second)
            assertTrue(first.all { it in 0..100 })
        }
        assertNotEquals(
            HealthEditableRules.generateHeartRateSamples(72, HeartRatePattern.Normal),
            HealthEditableRules.generateHeartRateSamples(72, HeartRatePattern.High)
        )
    }

    @Test
    fun commonFormSchemaAppliesRawPlatformInputsAndGeneratesCanonicalSequences() {
        val source = DefaultEditableHealthData.value
        val activityForm = HealthEditableForms.form(source, HealthEditableSection.TodayActivity)
        assertEquals(
            listOf("distanceKm", "paceSecondsPerKm"),
            activityForm.fields.map { it.id }
        )
        val activity = requireNotNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.TodayActivity,
                mapOf("distanceKm" to "12.5", "paceSecondsPerKm" to "300")
            )
        )
        assertEquals(TodayActivityInput(12.5, 300), activity.todayActivity)

        val heart = requireNotNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.HeartRate,
                mapOf("average" to "80", "pattern" to HeartRatePattern.High.name)
            )
        )
        assertEquals(288, heart.heartRate.fiveMinuteSamples.size)
        assertNotEquals(source.heartRate, heart.heartRate)

        assertNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.TodayActivity,
                mapOf("distanceKm" to "-1", "paceSecondsPerKm" to "300")
            )
        )
    }

    @Test
    fun derivedWeeklyPlanUsesOnlyWorkoutTypeAndDistance() {
        val source = DefaultEditableHealthData.value.copy(
            weeklyPlan = WeeklyPlanInput(
                listOf(
                    WeeklyWorkoutInput(WorkoutType.Easy, 10.0),
                    WeeklyWorkoutInput(WorkoutType.Tempo, 6.0),
                    WeeklyWorkoutInput(WorkoutType.Endurance, 4.0),
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0)
                )
            )
        )

        val weekly = requireNotNull(HealthEditableRules.derive(source).weeklyPlan)
        assertEquals(listOf(100, 36, 16), weekly.dayPlans.take(3).map { it.workoutDurationMinutes })
        assertEquals(7, weekly.dayPlans.size)
        assertEquals(weekly.dayPlans.map { it.workoutTrainingLoad ?: 0 }, weekly.dailyLoads)
    }

    @Test
    fun sleepStagesMustBeContinuousAndEndTimeIsDerived() {
        val input = SleepInput(
            startMinuteOfDay = 23 * 60,
            stages = listOf(
                SleepStageInput(SleepStage.Light, startMinute = 0, durationMinutes = 120),
                SleepStageInput(SleepStage.Deep, startMinute = 120, durationMinutes = 90),
                SleepStageInput(SleepStage.Rem, startMinute = 210, durationMinutes = 60)
            )
        )

        assertTrue(HealthEditableRules.validateSleep(input))
        val sleep = requireNotNull(
            HealthEditableRules.derive(DefaultEditableHealthData.value.copy(sleep = input)).sleepSummary
        )
        assertEquals(270, sleep.durationMinutes)
        assertEquals("23:00", sleep.startTime)
        assertEquals("03:30", sleep.endTime)

        assertFalse(
            HealthEditableRules.validateSleep(
                input.copy(stages = input.stages.dropLast(1) + SleepStageInput(SleepStage.Rem, 211, 60))
            )
        )
    }

    @Test
    fun dynamicSleepStagesAreMutatedAndAppliedByCommon() {
        val source = DefaultEditableHealthData.value
        val initial = HealthEditableForms.form(source, HealthEditableSection.Sleep)
        val initialValues = initial.fields.associate { it.id to it.value }
        val added = requireNotNull(
            HealthEditableForms.mutate(
                source = source,
                section = HealthEditableSection.Sleep,
                values = initialValues,
                groupId = "sleepStages",
                operation = HealthEditRepeatOperation.Add
            )
        )
        val addedStageCount = added.fields.count { it.groupId == "sleepStages" } / 2
        assertEquals(source.sleep.stages.size + 1, addedStageCount)
        assertEquals(
            (0 until addedStageCount).toList(),
            added.fields.filter { it.id.endsWith("Type") }.mapNotNull { it.rowIndex }
        )

        val removed = requireNotNull(
            HealthEditableForms.mutate(
                source = source,
                section = HealthEditableSection.Sleep,
                values = added.fields.associate { it.id to it.value },
                groupId = "sleepStages",
                operation = HealthEditRepeatOperation.Remove,
                rowIndex = 1
            )
        )
        val updated = requireNotNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.Sleep,
                removed.fields.associate { it.id to it.value }
            )
        )
        assertEquals(source.sleep.stages.size, updated.sleep.stages.size)
        assertEquals(
            updated.sleep.stages.mapIndexed { index, stage -> index to stage.startMinute },
            updated.sleep.stages.mapIndexed { index, stage ->
                index to updated.sleep.stages.take(index).sumOf { it.durationMinutes }
            }
        )

        val oneStageValues = mapOf(
            "startTime" to "23:00",
            "stage0Type" to SleepStage.Light.name,
            "stage0Duration" to "60"
        )
        assertNull(
            HealthEditableForms.mutate(
                source,
                HealthEditableSection.Sleep,
                oneStageValues,
                "sleepStages",
                HealthEditRepeatOperation.Remove,
                rowIndex = 0
            )
        )
    }

    @Test
    fun dynamicMuscleGroupsUseSharedSelectableOptions() {
        val source = DefaultEditableHealthData.value
        val form = HealthEditableForms.form(source, HealthEditableSection.BodyManagement)
        val muscleFields = form.fields.filter { it.groupId == "muscleGroups" }
        assertEquals(source.bodyManagement.trainedMuscleGroups.size, muscleFields.size)
        assertEquals(BodyMuscleGroup.entries.map { it.id }, muscleFields.first().options.map { it.value })
        assertTrue(muscleFields.all { it.type == HealthEditFieldType.Choice })

        val added = requireNotNull(
            HealthEditableForms.mutate(
                source,
                HealthEditableSection.BodyManagement,
                form.fields.associate { it.id to it.value },
                "muscleGroups",
                HealthEditRepeatOperation.Add
            )
        )
        val addedMuscles = added.fields.filter { it.groupId == "muscleGroups" }
        assertEquals(muscleFields.size + 1, addedMuscles.size)
        assertEquals(addedMuscles.size, addedMuscles.map { it.value }.distinct().size)

        val removedAll = addedMuscles.indices.reversed().fold(added) { current, index ->
            requireNotNull(
                HealthEditableForms.mutate(
                    source,
                    HealthEditableSection.BodyManagement,
                    current.fields.associate { it.id to it.value },
                    "muscleGroups",
                    HealthEditRepeatOperation.Remove,
                    rowIndex = index
                )
            )
        }
        val noMuscleData = requireNotNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.BodyManagement,
                removedAll.fields.associate { it.id to it.value }
            )
        )
        assertTrue(noMuscleData.bodyManagement.trainedMuscleGroups.isEmpty())

        assertNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.BodyManagement,
                mapOf("muscle0" to "unknown")
            )
        )
    }

    @Test
    fun bodyManagementFormEditsOnlyMusclesAndPreservesWeightHistory() {
        val source = DefaultEditableHealthData.value.copy(
            bodyManagement = DefaultEditableHealthData.value.bodyManagement.copy(
                weightKg = 71.4,
                weightHistoryKg = listOf(69.8, 70.2, 71.4)
            )
        )
        val form = HealthEditableForms.form(source, HealthEditableSection.BodyManagement)

        assertTrue(form.fields.none { it.id == "weightKg" })
        val updated = requireNotNull(
            HealthEditableForms.apply(
                source,
                HealthEditableSection.BodyManagement,
                mapOf("muscle0" to BodyMuscleGroup.Back.id)
            )
        )

        assertEquals(71.4, updated.bodyManagement.weightKg)
        assertEquals(listOf(69.8, 70.2, 71.4), updated.bodyManagement.weightHistoryKg)
        assertEquals(listOf(BodyMuscleGroup.Back.id), updated.bodyManagement.trainedMuscleGroups)
    }

    @Test
    fun abnormalScenarioProjectsCurrentMemoryAndPersistedValuesIntoEditor() {
        val repository = signedInRepository()
        val persistence = InMemoryHealthDashboardStateDataSource()
        val store = HealthStore(repository, persistence)
        store.dispatch(HealthAction.Load)
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Abnormal))
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Normal))

        val inMemory = store.normalDraftForEditing()

        assertEquals(HealthEditSourceKind.Available, store.state.editSourceKind)
        assertEquals(12_000, inMemory.dailySummary.steps)
        assertEquals(22, inMemory.recovery.score)
        assertEquals(108, inMemory.restingHeartRate.value)
        assertEquals(75.0, inMemory.bodyManagement.weightKg)
        assertTrue(HealthEditableRules.validate(inMemory))

        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Abnormal))
        store.dispatch(HealthAction.Refresh)
        val recreated = HealthStore(repository, persistence)
        recreated.dispatch(HealthAction.Load)
        recreated.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Normal))
        val persisted = recreated.normalDraftForEditing()

        assertEquals(HealthEditSourceKind.Available, recreated.state.editSourceKind)
        assertEquals(inMemory.dailySummary, persisted.dailySummary)
        assertEquals(inMemory.recovery, persisted.recovery)
        assertEquals(inMemory.restingHeartRate, persisted.restingHeartRate)
    }

    @Test
    fun emptyAndCorruptedScenariosShareZeroProjectionButKeepDifferentSourceMeaning() {
        val store = HealthStore(signedInRepository(), InMemoryHealthDashboardStateDataSource())
        store.dispatch(HealthAction.Load)
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.AllEmpty))

        assertEquals(DefaultEditableHealthData.allEmpty(), store.normalDraftForEditing())
        assertEquals(HealthEditSourceKind.Empty, store.state.editSourceKind)

        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.ReadFailure))
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Normal))

        assertEquals(DefaultEditableHealthData.allEmpty(), store.normalDraftForEditing())
        assertEquals(HealthEditSourceKind.Corrupted, store.state.editSourceKind)
        val formJson = HealthEditableForms.formJson(
            HealthEditableForms.form(
                store.state.normalDraft ?: error("missing draft"),
                HealthEditableSection.TodayActivity,
                store.state.editSourceKind
            )
        )
        assertTrue(formJson.contains("\"sourceKind\":\"Corrupted\""))
        assertTrue(formJson.contains("health_edit_source_corrupted"))
    }

    @Test
    fun partialScenarioCanSaveOneValidModuleWithoutAuditingMissingModules() {
        val repository = signedInRepository()
        val persistence = InMemoryHealthDashboardStateDataSource()
        val store = HealthStore(repository, persistence)
        store.dispatch(HealthAction.Load)
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.PartialMissing))
        val source = store.normalDraftForEditing()
        assertEquals(HealthEditSourceKind.Partial, store.state.editSourceKind)

        val result = HealthEditableForms.applyDetailed(
            source,
            HealthEditableSection.DailySummary,
            mapOf("steps" to "1234", "calories" to "310", "activeMinutes" to "32")
        )
        assertTrue(result.isSuccess)

        store.dispatch(
            HealthAction.NormalDraftSaved(
                requireNotNull(result.data),
                HealthEditableSection.DailySummary
            )
        )

        assertNull(store.state.error)
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Normal))
        store.dispatch(HealthAction.Refresh)
        val userId = assertIs<MockResult.Success<com.example.demo.common.auth.model.AuthSession>>(
            repository.verifyBusinessAccess()
        ).data.userId
        assertEquals(1_234, persistence.load(userId)?.dashboardData?.dailySummary?.steps)
        assertNull(persistence.load(userId)?.dashboardData?.sleepSummary)
    }

    @Test
    fun detailedFormAuditNamesTheFieldAndReasonInsteadOfReturningOnlyFalse() {
        val source = DefaultEditableHealthData.value
        val notNumber = HealthEditableForms.applyDetailed(
            source,
            HealthEditableSection.TodayActivity,
            mapOf("distanceKm" to "abc", "paceSecondsPerKm" to "300")
        )
        assertFalse(notNumber.isSuccess)
        assertEquals("distanceKm", notNumber.issue?.fieldId)
        assertEquals("health_edit_distance", notNumber.issue?.labelKey)
        assertEquals(HealthEditValidationReason.InvalidNumber, notNumber.issue?.reason)

        val outOfRange = HealthEditableForms.applyDetailed(
            source,
            HealthEditableSection.TodayActivity,
            mapOf("distanceKm" to "12.4", "paceSecondsPerKm" to "99")
        )
        assertFalse(outOfRange.isSuccess)
        assertEquals("paceSecondsPerKm", outOfRange.issue?.fieldId)
        assertEquals(HealthEditValidationReason.OutOfRange, outOfRange.issue?.reason)
        assertEquals(listOf("120", "1800"), outOfRange.issue?.reasonArguments)
    }

    @Test
    fun bodyVisualDerivesAlignedHighlightRegions() {
        val body = BodyManagement(
            weightKg = 68.2,
            bodyFat = 15.5,
            bmi = 22.3,
            measuredDate = "2022/8/7",
            trainedMuscleGroups = BodyMuscleGroup.entries.map { it.id }
        )
        val visual = bodyVisual(body)

        assertEquals(
            listOf(
                "chest_front",
                "shoulders_front",
                "shoulders_back",
                "trapezius_back",
                "latissimus_back",
                "erector_spinae_back",
                "biceps_front",
                "triceps_back",
                "abdominals_front",
                "glutes_back",
                "quadriceps_front",
                "hamstrings_back",
                "calves_front",
                "calves_back"
            ),
            visual.highlightedBodyRegions
        )
        assertEquals("health_visual_weekly_primary_muscles", visual.footer?.key)
        assertTrue(visual.metrics.isEmpty())
    }

    private fun signedInRepository(): LocalMockAuthRepository =
        LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L }).also { repo ->
            repo.requestVerifyCode("editable@example.com", DefaultVerifyCode)
            assertIs<LoginResult.Success>(
                RegisterUseCase(repo).execute(
                    "editable@example.com",
                    "password1",
                    DefaultVerifyCode,
                    "CN",
                    "Editable"
                )
            )
        }
}
