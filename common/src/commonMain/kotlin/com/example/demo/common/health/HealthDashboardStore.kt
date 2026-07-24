package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult

interface HealthDashboardStateDataSource {
    fun load(userId: String): HealthDashboardSnapshot?
    fun save(snapshot: HealthDashboardSnapshot): Boolean
    fun clear(userId: String): Boolean
}

class InMemoryHealthDashboardStateDataSource : HealthDashboardStateDataSource {
    private val snapshots = mutableMapOf<String, HealthDashboardSnapshot>()
    override fun load(userId: String): HealthDashboardSnapshot? = snapshots[userId]
    override fun save(snapshot: HealthDashboardSnapshot): Boolean { snapshots[snapshot.userId] = snapshot; return true }
    override fun clear(userId: String): Boolean { snapshots.remove(userId); return true }

    fun allSnapshots(): List<HealthDashboardSnapshot> = snapshots.values.sortedBy { it.userId }

    fun replaceAll(values: List<HealthDashboardSnapshot>) {
        snapshots.clear()
        values.forEach { snapshots[it.userId] = it }
    }
}

data class PersistedDashboard(val scenario: HealthMockScenario, val uiState: DashboardUiState, val enabledCardTypes: List<HealthCardType>)

class HealthDashboardStore(
    private val authRepository: AuthRepository,
    private val stateDataSource: HealthDashboardStateDataSource
) {
    private val dashboardDataSource = LocalHealthDashboardDataSource(authRepository)
    private val useCase = HealthDashboardUseCase(dashboardDataSource)
    private val pendingScenarios = mutableMapOf<String, HealthMockScenario>()

    fun load(): MockResult<PersistedDashboard> = when (val access = authRepository.verifyBusinessAccess()) {
        is MockResult.Failure -> MockResult.Failure(access.error)
        is MockResult.Success -> {
            when (val resolved = resolveSnapshot(access.data.userId)) {
                is MockResult.Failure -> MockResult.Failure(resolved.error)
                is MockResult.Success -> resolved.data.toPersistedDashboard()
            }
        }
    }

    fun selectScenario(scenario: HealthMockScenario): MockResult<Unit> = when (val access = authRepository.verifyBusinessAccess()) {
        is MockResult.Failure -> MockResult.Failure(access.error)
        is MockResult.Success -> {
            pendingScenarios[access.data.userId] = scenario
            MockResult.Success(Unit)
        }
    }

    fun refresh(): MockResult<PersistedDashboard> = when (val access = authRepository.verifyBusinessAccess()) {
        is MockResult.Failure -> MockResult.Failure(access.error)
        is MockResult.Success -> {
            val userId = access.data.userId
            when (val resolved = resolveSnapshot(userId)) {
                is MockResult.Failure -> MockResult.Failure(resolved.error)
                is MockResult.Success -> {
                    val scenario = pendingScenarios[userId] ?: resolved.data.sourceScenario
                    when (val generated = dashboardDataSource.load(scenario)) {
                        is MockResult.Failure -> MockResult.Failure(generated.error)
                        is MockResult.Success -> {
                            val updated = resolved.data.copy(
                                sourceScenario = scenario,
                                dashboardData = generated.data,
                                schemaVersion = CurrentHealthDashboardSchemaVersion
                            )
                            if (!stateDataSource.save(updated)) MockResult.Failure(MockError.PersistFailed)
                            else {
                                pendingScenarios.remove(userId)
                                updated.toPersistedDashboard()
                            }
                        }
                    }
                }
            }
        }
    }

    fun clear(userId: String): Boolean {
        pendingScenarios.remove(userId)
        return stateDataSource.clear(userId)
    }

    fun saveCardConfiguration(types: List<HealthCardType>): MockResult<PersistedDashboard> {
        val access = authRepository.verifyBusinessAccess()
        return when (access) {
            is MockResult.Failure -> MockResult.Failure(access.error)
            is MockResult.Success -> {
                val clean = types.distinct()
                if (clean.size < 3) return MockResult.Failure(MockError.MinimumCardsRequired)
                when (val resolved = resolveSnapshot(access.data.userId)) {
                    is MockResult.Failure -> MockResult.Failure(resolved.error)
                    is MockResult.Success -> {
                        val updated = resolved.data.copy(enabledCardTypes = clean)
                        if (!stateDataSource.save(updated)) MockResult.Failure(MockError.PersistFailed)
                        else updated.toPersistedDashboard()
                    }
                }
            }
        }
    }

    private fun resolveSnapshot(userId: String): MockResult<HealthDashboardSnapshot> {
        val stored = stateDataSource.load(userId)
        if (stored?.dashboardData != null) return MockResult.Success(stored)
        val sourceScenario = stored?.sourceScenario ?: HealthMockScenario.Normal
        return when (val generated = dashboardDataSource.load(sourceScenario)) {
            is MockResult.Failure -> MockResult.Failure(generated.error)
            is MockResult.Success -> {
                val migrated = (stored ?: HealthDashboardSnapshot(userId)).copy(
                    sourceScenario = sourceScenario,
                    dashboardData = generated.data,
                    schemaVersion = CurrentHealthDashboardSchemaVersion
                )
                if (!stateDataSource.save(migrated)) MockResult.Failure(MockError.PersistFailed)
                else MockResult.Success(migrated)
            }
        }
    }

    private fun HealthDashboardSnapshot.toPersistedDashboard(): MockResult<PersistedDashboard> {
        val data = dashboardData ?: return MockResult.Failure(MockError.CorruptedData)
        val uiState = useCase.toUiState(data)
        return MockResult.Success(
            PersistedDashboard(
                sourceScenario,
                uiState.copy(cards = ordered(uiState.cards, enabledCardTypes)),
                enabledCardTypes
            )
        )
    }

    private fun ordered(cards: List<HealthCardUiModel>, types: List<HealthCardType>): List<HealthCardUiModel> {
        val byType = cards.associateBy { it.type }
        return types.mapNotNull(byType::get)
    }
}
