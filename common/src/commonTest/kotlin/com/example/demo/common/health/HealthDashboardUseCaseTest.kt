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
import kotlin.test.assertIs
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
    @Test fun cardsUseStablePriorityOrder() { val cards = state(HealthMockScenario.Normal).cards; assertEquals(cards.map { it.priority }.sorted(), cards.map { it.priority }) }
    @Test fun readFailureIsReturned() = assertEquals(MockError.CorruptedData, assertIs<MockResult.Failure>(useCase().load(HealthMockScenario.ReadFailure)).error)
    @Test fun loggedOutUserIsBlocked() { val repository = repository(false); val result = HealthDashboardUseCase(LocalHealthDashboardDataSource(repository)).load(HealthMockScenario.Normal); assertEquals(MockError.AuthRequired, assertIs<MockResult.Failure>(result).error) }
    @Test fun selectedScenarioPersistsForTheSameUser() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val repository = repository(true)
        HealthDashboardStore(repository, persistence).selectScenario(HealthMockScenario.Abnormal)
        assertEquals(HealthMockScenario.Abnormal, assertIs<MockResult.Success<PersistedDashboard>>(HealthDashboardStore(repository, persistence).load()).data.scenario)
    }
    @Test fun dashboardSnapshotsAreIsolatedByUserId() {
        val persistence = InMemoryHealthDashboardStateDataSource()
        val first = repository(true)
        val second = LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L })
        second.requestVerifyCode("other@example.com", DefaultVerifyCode)
        assertIs<LoginResult.Success>(RegisterUseCase(second).execute("other@example.com", "password1", DefaultVerifyCode, "CN", "Other User"))
        HealthDashboardStore(first, persistence).selectScenario(HealthMockScenario.AllEmpty)
        assertEquals(HealthMockScenario.Normal, assertIs<MockResult.Success<PersistedDashboard>>(HealthDashboardStore(second, persistence).load()).data.scenario)
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

    private fun state(scenario: HealthMockScenario) = assertIs<MockResult.Success<DashboardUiState>>(useCase().load(scenario)).data
    private fun useCase() = HealthDashboardUseCase(LocalHealthDashboardDataSource(repository(true)))
    private fun repository(register: Boolean): AuthRepository = LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L }).also { repo ->
        if (register) {
            repo.requestVerifyCode("health@example.com", DefaultVerifyCode)
            assertIs<LoginResult.Success>(RegisterUseCase(repo).execute("health@example.com", "password1", DefaultVerifyCode, "CN", "Health User"))
        }
    }
}
