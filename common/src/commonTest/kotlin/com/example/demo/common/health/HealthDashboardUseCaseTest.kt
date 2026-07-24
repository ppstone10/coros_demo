package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.InMemoryAuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.LocalMockAuthRepository.Companion.DefaultVerifyCode
import com.example.demo.common.login.LoginResult
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult
import com.example.demo.common.login.RegisterUseCase
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFails
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class HealthDashboardUseCaseTest {
    @Test fun normalScenarioShowsCompleteCardCatalog() = assertEquals(14, state(HealthMockScenario.Normal).cards.size)
    @Test fun normalScenarioPrioritizesRecoveryBeforeSleep() = assertEquals(HealthCardType.Recovery, state(HealthMockScenario.Normal).cards.first().type)
    @Test fun partialMissingShowsSleepEmptyCard() = assertEquals(HealthCardStatus.Empty, state(HealthMockScenario.PartialMissing).cards.first { it.type == HealthCardType.Sleep }.status)
    @Test fun partialMissingKeepsAvailableTodayActivity() = assertEquals(HealthCardStatus.Normal, state(HealthMockScenario.PartialMissing).cards.first { it.type == HealthCardType.TodayActivity }.status)
    @Test fun allEmptyKeepsConfigurableCards() = assertEquals(14, state(HealthMockScenario.AllEmpty).cards.size)
    @Test fun abnormalRecoveryIsFirst() = assertEquals(HealthCardType.Recovery, state(HealthMockScenario.Abnormal).cards.first().type)
    @Test fun abnormalSleepIsRisk() = assertEquals(HealthCardStatus.Risk, state(HealthMockScenario.Abnormal).cards.first { it.type == HealthCardType.Sleep }.status)
    @Test fun abnormalTrainingLoadIsRisk() = assertEquals(HealthCardStatus.Risk, state(HealthMockScenario.Abnormal).cards.first { it.type == HealthCardType.TrainingLoad }.status)
    @Test fun riskPriorityIsExplained() = assertTrue(state(HealthMockScenario.Abnormal).cards.first().priorityReason.isNotBlank())
    @Test fun healthUiModelsExposeLocalizationKeysAndTypedArguments() {
        val normal = state(HealthMockScenario.Normal)
        assertEquals("health_today", normal.greeting.key)
        assertEquals("health_demo_date", normal.dateLabel.key)
        normal.cards.forEach { card ->
            assertTrue(card.title.key.startsWith("health_card_"))
            assertTrue(card.summary.key.startsWith("health_summary_"))
            assertTrue(card.priorityReason.startsWith("health_reason_"))
        }
        val recovery = normal.cards.first { it.type == HealthCardType.Recovery }
        assertEquals("health_summary_recovery_normal", recovery.summary.key)
        assertEquals(listOf("95", "5"), recovery.summary.arguments)
    }
    @Test fun cardsUseStablePriorityOrder() { val cards = state(HealthMockScenario.Normal).cards; assertEquals(cards.map { it.priority }.sorted(), cards.map { it.priority }) }
    @Test fun readFailureIsReturned() = assertEquals(MockError.CorruptedData, assertIs<MockResult.Failure>(useCase().load(HealthMockScenario.ReadFailure)).error)
    @Test fun loggedOutUserIsBlocked() { val repository = repository(false); val result = HealthDashboardUseCase(LocalHealthDashboardDataSource(repository)).load(HealthMockScenario.Normal); assertEquals(MockError.AuthRequired, assertIs<MockResult.Failure>(result).error) }
    @Test fun selectedScenarioPersistsForTheSameUser() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        store.selectScenario(HealthMockScenario.Abnormal)
        store.refresh()
        assertEquals(HealthMockScenario.Abnormal, assertIs<MockResult.Success<PersistedDashboard>>(store.load()).data.scenario)
    }
    @Test fun dashboardSnapshotsAreIsolatedByUserId() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val first = repository(true)
        val second = LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L })
        second.requestVerifyCode("other@example.com", DefaultVerifyCode)
        assertIs<LoginResult.Success>(RegisterUseCase(second).execute("other@example.com", "password1", DefaultVerifyCode, "CN", "Other User"))
        HealthDashboardStore(first, persistence).apply {
            selectScenario(HealthMockScenario.AllEmpty)
            refresh()
        }
        assertEquals(HealthMockScenario.Normal, assertIs<MockResult.Success<PersistedDashboard>>(HealthDashboardStore(second, persistence).load()).data.scenario)
    }
    @Test fun cardSaveRejectsMinimumConfig() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        val twoCards = listOf(HealthCardType.Sleep, HealthCardType.Stress)
        val result = store.saveCardConfiguration(twoCards)
        val failure = assertIs<MockResult.Failure>(result)
        assertEquals(MockError.MinimumCardsRequired, failure.error)
    }
    @Test fun cardSaveAcceptsSufficientConfig() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        val threeCards = listOf(HealthCardType.Sleep, HealthCardType.Stress, HealthCardType.HeartRate)
        val result = store.saveCardConfiguration(threeCards)
        assertIs<MockResult.Success<PersistedDashboard>>(result)
    }
    @Test fun healthScenariosMatchMockEntries() {
        assertEquals(HealthMockScenario.entries.map { it.name }, HealthScenarios.names)
        assertEquals(HealthMockScenario.entries.size, HealthScenarios.displayKeys.size)
    }
    @Test fun normalScenarioProvidesFigmaVisualData() {
        val byType = state(HealthMockScenario.Normal).cards.associateBy { it.type }
        assertEquals(7, byType.getValue(HealthCardType.WeeklyPlan).visual.chartPoints.size)
        assertEquals(7, byType.getValue(HealthCardType.TrainingLoad).visual.chartPoints.size)
        assertTrue(byType.getValue(HealthCardType.HeartRate).visual.chartPoints.size >= 12)
        assertTrue(byType.getValue(HealthCardType.Stress).visual.chartPoints.size >= 12)
        assertTrue(byType.getValue(HealthCardType.Sleep).visual.sleepStages.isNotEmpty())
        assertEquals(5, byType.getValue(HealthCardType.HealthCheck).visual.metrics.size)
        assertEquals("68.2", byType.getValue(HealthCardType.BodyManagement).visual.primaryValue)
        assertEquals(52.0, byType.getValue(HealthCardType.HrvAssessment).visual.range?.normalMin)
        assertEquals(60.0, byType.getValue(HealthCardType.HrvAssessment).visual.range?.normalMax)
    }
    @Test fun heartRateVisualUsesFortyEightHalfHourMinMaxAverageIntervals() {
        val points = state(HealthMockScenario.Normal).cards
            .first { it.type == HealthCardType.HeartRate }
            .visual.chartPoints

        assertEquals(48, points.size)
        assertEquals("00:00", points.first().label)
        assertEquals("23:30", points.last().label)
        points.forEach { point ->
            val minimum = requireNotNull(point.minimum)
            val maximum = requireNotNull(point.maximum)
            val average = requireNotNull(point.average)
            assertTrue(minimum <= average)
            assertTrue(average <= maximum)
            assertEquals(average, point.value)
        }
    }
    @Test fun fiveMinuteHeartSamplesAggregateIntoHalfHourIntervals() {
        val intervals = aggregateFiveMinuteHeartSamples(
            listOf(
                50, 50, 53, 52, 50, 50,
                51, 52, 51, 53, 53, 56
            )
        )

        assertEquals(
            listOf(
                HeartRateInterval(startMinute = 0, minimum = 50, maximum = 53, average = 51),
                HeartRateInterval(startMinute = 30, minimum = 51, maximum = 56, average = 53)
            ),
            intervals
        )
    }
    @Test fun enabledHeartDataScenariosUseThreeProvidedFiveMinuteSamples() {
        val scenarios = listOf(
            HealthMockScenario.Normal,
            HealthMockScenario.PartialMissing,
            HealthMockScenario.Abnormal
        )

        scenarios.forEach { scenario ->
            val heartRate = requireNotNull(domain(scenario).heartRate)
            assertEquals(288, heartRate.fiveMinuteSamples.size)
            assertEquals(48, heartRate.intervals.size)
        }
        assertEquals(HeartRateInterval(0, 64, 66, 65), requireNotNull(domain(HealthMockScenario.Normal).heartRate).intervals.first())
        assertEquals(HeartRateInterval(0, 50, 55, 53), requireNotNull(domain(HealthMockScenario.PartialMissing).heartRate).intervals.first())
        assertEquals(HeartRateInterval(0, 67, 70, 69), requireNotNull(domain(HealthMockScenario.Abnormal).heartRate).intervals.first())
        assertEquals(
            listOf(
                HealthMockScenario.Normal,
                HealthMockScenario.PartialMissing,
                HealthMockScenario.AllEmpty,
                HealthMockScenario.Abnormal,
                HealthMockScenario.ReadFailure
            ),
            HealthMockScenario.entries
        )
        assertTrue(domain(HealthMockScenario.AllEmpty).heartRate == null)
    }
    @Test fun healthCheckWithoutMeasuredTimeDoesNotExposeHeaderPlaceholder() {
        val data = HealthDashboardData(
            dailySummary = null,
            sleepSummary = null,
            trainingLoad = null,
            recovery = null,
            healthCheck = HealthCheck(overallScore = 82, lastCheckDays = 0, measuredTime = null)
        )

        val card = useCase()
            .toUiState(data)
            .cards
            .first { it.type == HealthCardType.HealthCheck }

        assertNull(card.visual.caption)
    }
    @Test fun weeklyPlanProvidesSevenSelectableDayPlans() {
        val weeklyPlan = requireNotNull(domain(HealthMockScenario.Normal).weeklyPlan)

        assertEquals(7, weeklyPlan.dayPlans.size)
        assertEquals(weeklyPlan.currentDayIndex, weeklyPlan.dayPlans[weeklyPlan.currentDayIndex].dayIndex)
        assertTrue(weeklyPlan.dayPlans.any { it.workoutName != weeklyPlan.dayPlans[weeklyPlan.currentDayIndex].workoutName })
    }
    @Test fun legacyHeartRateSamplesDecodeAsDegenerateHalfHourIntervals() {
        val snapshot = MockHealthDashboardStoreJson.decode(
            """{"userId":"legacy-heart","dashboardData":{"heartRate":{"restingHr":55,"currentHr":68,"averageHr":65,"samples":[60,72]}}}"""
        )
        val intervals = requireNotNull(snapshot.dashboardData?.heartRate).intervals

        assertEquals(2, intervals.size)
        assertEquals(HeartRateInterval(0, 60, 60, 60), intervals[0])
        assertEquals(HeartRateInterval(30, 72, 72, 72), intervals[1])
    }
    @Test fun cardsExposeStableVisualKinds() {
        val kinds = state(HealthMockScenario.Normal).cards.associate { it.type to it.visual.kind }
        assertEquals(HealthCardVisualKind.TodayActivity, kinds[HealthCardType.TodayActivity])
        assertEquals(HealthCardVisualKind.WeeklyPlan, kinds[HealthCardType.WeeklyPlan])
        assertEquals(HealthCardVisualKind.TrainingLoad, kinds[HealthCardType.TrainingLoad])
        assertEquals(HealthCardVisualKind.TrainingAssessment, kinds[HealthCardType.TrainingAssessment])
        assertEquals(HealthCardVisualKind.RecoveryGauge, kinds[HealthCardType.Recovery])
        assertEquals(HealthCardVisualKind.AbilityGauge, kinds[HealthCardType.RunningAbility])
        assertEquals(HealthCardVisualKind.AbilityGauge, kinds[HealthCardType.CyclingAbility])
        assertEquals(HealthCardVisualKind.TrendBars, kinds[HealthCardType.HeartRate])
        assertEquals(HealthCardVisualKind.TrendBars, kinds[HealthCardType.Stress])
        assertEquals(HealthCardVisualKind.SleepStages, kinds[HealthCardType.Sleep])
        assertEquals(HealthCardVisualKind.RangeIndicator, kinds[HealthCardType.HrvAssessment])
        assertEquals(HealthCardVisualKind.RangeIndicator, kinds[HealthCardType.RestingHeartRate])
        assertEquals(HealthCardVisualKind.HealthCheckGrid, kinds[HealthCardType.HealthCheck])
        assertEquals(HealthCardVisualKind.BodyMap, kinds[HealthCardType.BodyManagement])
    }
    @Test fun defaultOrderIncludesTodayActivityBeforeWeeklyPlan() {
        assertTrue(HealthCardType.TodayActivity in DefaultHealthCardOrder)
        assertTrue(DefaultHealthCardOrder.indexOf(HealthCardType.TodayActivity) < DefaultHealthCardOrder.indexOf(HealthCardType.WeeklyPlan))
    }
    @Test fun cardSelectionAndOrderPersist() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val order = listOf(HealthCardType.Sleep, HealthCardType.Stress, HealthCardType.HeartRate)
        HealthDashboardStore(repository, persistence).saveCardConfiguration(order)
        val restored = assertIs<MockResult.Success<PersistedDashboard>>(HealthDashboardStore(repository, persistence).load()).data
        assertEquals(order, restored.enabledCardTypes)
        assertEquals(order, restored.uiState.cards.map { it.type })
    }

    @Test fun fullDashboardSnapshotRoundTripsAllModuleData() {
        val data = domain(HealthMockScenario.Normal)
        val snapshot = HealthDashboardSnapshot(
            userId = "health-user",
            sourceScenario = HealthMockScenario.Normal,
            enabledCardTypes = DefaultHealthCardOrder,
            dashboardData = data,
            schemaVersion = 2
        )

        assertEquals(snapshot, MockHealthDashboardStoreJson.decode(MockHealthDashboardStoreJson.encode(snapshot)))
    }

    @Test fun storedDashboardDataWinsOverScenarioTemplate() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val storedData = domain(HealthMockScenario.Abnormal).copy(
            bodyManagement = BodyManagement(61.3, 18.0, 21.1, "2026/7/22", listOf("chest"))
        )
        persistence.save(
            HealthDashboardSnapshot(
                userId = requireNotNull(repository.currentSession()).userId,
                sourceScenario = HealthMockScenario.Normal,
                dashboardData = storedData
            )
        )

        val loaded = assertIs<MockResult.Success<PersistedDashboard>>(
            HealthDashboardStore(repository, persistence).load()
        ).data

        assertEquals("61.3", loaded.uiState.cards.first { it.type == HealthCardType.BodyManagement }.visual.primaryValue)
    }

    @Test fun scenarioSelectionDoesNotChangeDashboardUntilRefresh() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        val before = assertIs<MockResult.Success<PersistedDashboard>>(store.load()).data
        val beforeSnapshot = persistence.load(requireNotNull(repository.currentSession()).userId)

        assertIs<MockResult.Success<Unit>>(store.selectScenario(HealthMockScenario.Abnormal))

        assertEquals(before, assertIs<MockResult.Success<PersistedDashboard>>(store.load()).data)
        assertEquals(beforeSnapshot, persistence.load(requireNotNull(repository.currentSession()).userId))
    }

    @Test fun refreshPersistsSelectedScenarioModuleData() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        assertIs<MockResult.Success<PersistedDashboard>>(store.load())
        assertIs<MockResult.Success<Unit>>(store.selectScenario(HealthMockScenario.Abnormal))

        val refreshed = assertIs<MockResult.Success<PersistedDashboard>>(store.refresh()).data
        val stored = requireNotNull(persistence.load(requireNotNull(repository.currentSession()).userId))

        assertEquals(HealthMockScenario.Abnormal, refreshed.scenario)
        assertEquals(HealthMockScenario.Abnormal, stored.sourceScenario)
        assertEquals(domain(HealthMockScenario.Abnormal), stored.dashboardData)
    }

    @Test fun failedRefreshPreservesLastDashboardSnapshot() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        val before = assertIs<MockResult.Success<PersistedDashboard>>(store.load()).data
        val beforeSnapshot = persistence.load(requireNotNull(repository.currentSession()).userId)
        assertIs<MockResult.Success<Unit>>(store.selectScenario(HealthMockScenario.ReadFailure))

        assertEquals(MockError.CorruptedData, assertIs<MockResult.Failure>(store.refresh()).error)
        assertEquals(before, assertIs<MockResult.Success<PersistedDashboard>>(store.load()).data)
        assertEquals(beforeSnapshot, persistence.load(requireNotNull(repository.currentSession()).userId))
    }

    @Test fun cardConfigurationUpdatePreservesDashboardData() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val store = HealthDashboardStore(repository, persistence)
        assertIs<MockResult.Success<Unit>>(store.selectScenario(HealthMockScenario.Abnormal))
        assertIs<MockResult.Success<PersistedDashboard>>(store.refresh())
        val before = requireNotNull(persistence.load(requireNotNull(repository.currentSession()).userId)).dashboardData

        assertIs<MockResult.Success<PersistedDashboard>>(
            store.saveCardConfiguration(listOf(HealthCardType.Sleep, HealthCardType.Stress, HealthCardType.HeartRate))
        )

        assertEquals(before, persistence.load(requireNotNull(repository.currentSession()).userId)?.dashboardData)
    }

    @Test fun legacyScenarioSnapshotMigratesToFullData() {
        val repository = repository(true)
        val userId = requireNotNull(repository.currentSession()).userId
        var raw = "{\"userId\":\"$userId\",\"scenario\":\"Abnormal\",\"enabledCardTypes\":[\"Sleep\",\"Stress\",\"HeartRate\"]}"
        val persistence = JsonHealthDashboardStateDataSource(
            readString = { raw },
            writeString = { _, json -> raw = json; true }
        )

        val restored = assertIs<MockResult.Success<PersistedDashboard>>(
            HealthDashboardStore(repository, persistence).load()
        ).data

        assertEquals("3", restored.uiState.cards.first { it.type == HealthCardType.Sleep }.visual.primaryValue)
        assertEquals(domain(HealthMockScenario.Abnormal), requireNotNull(persistence.load(userId)).dashboardData)
        assertTrue(raw.contains("\"dashboardData\""))
    }

    @Test fun fullDashboardSnapshotsAreIsolatedByUserId() {
        val snapshots = listOf(
            HealthDashboardSnapshot("first", HealthMockScenario.Normal, dashboardData = domain(HealthMockScenario.Normal)),
            HealthDashboardSnapshot("second", HealthMockScenario.Abnormal, dashboardData = domain(HealthMockScenario.Abnormal))
        )

        assertEquals(
            snapshots,
            MockHealthDashboardStoreJson.decodeCollection(MockHealthDashboardStoreJson.encodeCollection(snapshots))
        )
    }

    @Test fun twentyFullDashboardSnapshotsRoundTripWithinPreferencesBudget() {
        val snapshots = (1..20).map { index ->
            HealthDashboardSnapshot(
                userId = "demo-user-$index",
                sourceScenario = if (index % 2 == 0) HealthMockScenario.Normal else HealthMockScenario.Abnormal,
                dashboardData = domain(if (index % 2 == 0) HealthMockScenario.Normal else HealthMockScenario.Abnormal)
            )
        }
        val json = MockHealthDashboardStoreJson.encodeCollection(snapshots)

        assertTrue(json.length < 1_000_000, "20-user health snapshot collection should stay below 1 MB")
        assertEquals(snapshots, MockHealthDashboardStoreJson.decodeCollection(json))
    }

    @Test fun corruptedDashboardSnapshotIsIgnoredWithoutCrash() {
        val persistence = JsonHealthDashboardStateDataSource(
            readString = { "{not-json" },
            writeString = { _, _ -> true }
        )

        assertNull(persistence.load("health-user"))
        assertFails { MockHealthDashboardStoreJson.decodeCollection("{\"scenario\":\"Normal\"}") }
    }

    @Test fun deletingAccountClearsOnlyItsHealthSnapshot() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        val userId = requireNotNull(repository.currentSession()).userId
        val healthStore = HealthDashboardStore(repository, persistence)
        assertIs<MockResult.Success<PersistedDashboard>>(healthStore.load())
        healthStore.clear(userId)
        assertNull(persistence.load(userId))
    }

    private fun state(scenario: HealthMockScenario) = assertIs<MockResult.Success<DashboardUiState>>(useCase().load(scenario)).data
    private fun domain(scenario: HealthMockScenario) = assertIs<MockResult.Success<HealthDashboardData>>(
        LocalHealthDashboardDataSource(repository(true)).load(scenario)
    ).data
    private fun useCase() = HealthDashboardUseCase(LocalHealthDashboardDataSource(repository(true)))
    private fun repository(register: Boolean): AuthRepository = LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L }).also { repo ->
        if (register) {
            repo.requestVerifyCode("health@example.com", DefaultVerifyCode)
            assertIs<LoginResult.Success>(RegisterUseCase(repo).execute("health@example.com", "password1", DefaultVerifyCode, "CN", "Health User"))
        }
    }
}
