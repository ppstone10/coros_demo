package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult
import kotlin.math.round

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
    private var transientNormalDraft: EditableHealthData? = null

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
                    if (scenario == HealthMockScenario.Normal) {
                        val baseSource = transientNormalDraft ?: DefaultEditableHealthData.value
                        val previousBody = resolved.data.editableData?.bodyManagement
                            ?: resolved.data.dashboardData?.bodyManagement?.let { body ->
                                val weight = body.weightKg ?: return@let null
                                BodyManagementInput(
                                    weightKg = weight,
                                    trainedMuscleGroups = body.trainedMuscleGroups,
                                    weightHistoryKg = body.weightHistoryKg.ifEmpty { listOf(weight) }
                                )
                            }
                        val source = if ((previousBody?.weightHistoryKg?.size ?: 0) > 1) {
                            val retainedBody = requireNotNull(previousBody)
                            baseSource.copy(
                                bodyManagement = baseSource.bodyManagement.copy(
                                    weightKg = retainedBody.weightHistoryKg.last(),
                                    weightHistoryKg = retainedBody.weightHistoryKg
                                )
                            )
                        } else {
                            baseSource
                        }
                        val updated = resolved.data.copy(
                            sourceScenario = scenario,
                            dashboardData = null,
                            editableData = source,
                            schemaVersion = CurrentHealthDashboardSchemaVersion
                        )
                        if (!stateDataSource.save(updated)) MockResult.Failure(MockError.PersistFailed)
                        else {
                            pendingScenarios.remove(userId)
                            updated.toPersistedDashboard()
                        }
                    } else {
                    when (val generated = dashboardDataSource.load(scenario)) {
                        is MockResult.Failure -> MockResult.Failure(generated.error)
                        is MockResult.Success -> {
                            val preservedBody = resolved.data.editableData?.let {
                                HealthEditableRules.derive(it).bodyManagement
                            } ?: resolved.data.dashboardData?.bodyManagement
                            val generatedBody = generated.data.bodyManagement
                            val mergedBody = if (
                                (preservedBody?.weightHistoryKg?.size ?: 0) > 1 &&
                                generatedBody != null
                            ) {
                                val retainedBody = requireNotNull(preservedBody)
                                generatedBody.copy(
                                    weightKg = retainedBody.weightHistoryKg.last(),
                                    weightHistoryKg = retainedBody.weightHistoryKg
                                )
                            } else {
                                generatedBody
                            }
                            val updated = resolved.data.copy(
                                sourceScenario = scenario,
                                dashboardData = generated.data.copy(bodyManagement = mergedBody),
                                editableData = null,
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
    }

    fun clear(userId: String): Boolean {
        pendingScenarios.remove(userId)
        transientNormalDraft = null
        return stateDataSource.clear(userId)
    }

    fun normalDraft(): EditableHealthData? = transientNormalDraft

    fun saveNormalDraft(data: EditableHealthData): Boolean {
        if (!HealthEditableRules.validate(data)) return false
        transientNormalDraft = data
        return true
    }

    fun restoreNormalDraftSection(section: HealthEditableSection): EditableHealthData {
        val current = transientNormalDraft ?: initialNormalDraft()
        return HealthEditableRules.restoreSection(current, section).also {
            transientNormalDraft = it
        }
    }

    fun restoreNormalDefaults(): EditableHealthData =
        DefaultEditableHealthData.value.also { transientNormalDraft = it }

    fun initialNormalDraft(): EditableHealthData {
        transientNormalDraft?.let { return it }
        val access = authRepository.verifyBusinessAccess()
        val userId = (access as? MockResult.Success)?.data?.userId
        val stored = userId?.let(stateDataSource::load)
        return if (stored?.sourceScenario == HealthMockScenario.Normal) {
            stored.editableData
                ?: stored.dashboardData?.let(HealthEditableRules::fromDashboard)
                ?: DefaultEditableHealthData.value
        } else {
            DefaultEditableHealthData.value
        }
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

    fun saveBodyWeight(weightKg: Double): MockResult<PersistedDashboard> {
        val access = authRepository.verifyBusinessAccess()
        return when (access) {
            is MockResult.Failure -> MockResult.Failure(access.error)
            is MockResult.Success -> {
                val normalized = round(weightKg * 10.0) / 10.0
                if (!normalized.isFinite() || normalized !in 30.0..200.0) {
                    return MockResult.Failure(MockError.CorruptedData)
                }
                when (val resolved = resolveSnapshot(access.data.userId)) {
                    is MockResult.Failure -> MockResult.Failure(resolved.error)
                    is MockResult.Success -> {
                        val editable = resolved.data.editableData
                        val updated = if (editable != null) {
                            val body = editable.bodyManagement
                            val history = body.weightHistoryKg.ifEmpty { listOf(body.weightKg) } + normalized
                            resolved.data.copy(
                                editableData = editable.copy(
                                    bodyManagement = body.copy(
                                        weightKg = normalized,
                                        weightHistoryKg = history
                                    )
                                ),
                                schemaVersion = CurrentHealthDashboardSchemaVersion
                            )
                        } else {
                            val data = resolved.data.dashboardData
                                ?: return MockResult.Failure(MockError.CorruptedData)
                            val body = data.bodyManagement
                                ?: BodyManagement(weightKg = normalized, bodyFat = null, bmi = null)
                            val history = body.weightHistoryKg.ifEmpty {
                                body.weightKg?.let(::listOf).orEmpty()
                            } + normalized
                            resolved.data.copy(
                                dashboardData = data.copy(
                                    bodyManagement = body.copy(
                                        weightKg = normalized,
                                        weightHistoryKg = history
                                    )
                                ),
                                schemaVersion = CurrentHealthDashboardSchemaVersion
                            )
                        }
                        if (!stateDataSource.save(updated)) MockResult.Failure(MockError.PersistFailed)
                        else updated.toPersistedDashboard()
                    }
                }
            }
        }
    }

    private fun resolveSnapshot(userId: String): MockResult<HealthDashboardSnapshot> {
        val stored = stateDataSource.load(userId)
        if (stored?.editableData != null || stored?.dashboardData != null) {
            if (stored.sourceScenario == HealthMockScenario.Normal && stored.editableData == null) {
                val migratedSource = stored.dashboardData?.let(HealthEditableRules::fromDashboard)
                if (migratedSource != null) {
                    val migrated = stored.copy(
                        dashboardData = null,
                        editableData = migratedSource,
                        schemaVersion = CurrentHealthDashboardSchemaVersion
                    )
                    return if (stateDataSource.save(migrated)) MockResult.Success(migrated)
                    else MockResult.Failure(MockError.PersistFailed)
                }
            }
            return MockResult.Success(stored)
        }
        val sourceScenario = stored?.sourceScenario ?: HealthMockScenario.Normal
        if (sourceScenario == HealthMockScenario.Normal) {
            val created = (stored ?: HealthDashboardSnapshot(userId)).copy(
                sourceScenario = HealthMockScenario.Normal,
                dashboardData = null,
                editableData = DefaultEditableHealthData.value,
                schemaVersion = CurrentHealthDashboardSchemaVersion
            )
            return if (!stateDataSource.save(created)) MockResult.Failure(MockError.PersistFailed)
            else MockResult.Success(created)
        }
        return when (val generated = dashboardDataSource.load(sourceScenario)) {
            is MockResult.Failure -> MockResult.Failure(generated.error)
            is MockResult.Success -> {
                val migrated = (stored ?: HealthDashboardSnapshot(userId)).copy(
                    sourceScenario = sourceScenario,
                    dashboardData = generated.data,
                    editableData = null,
                    schemaVersion = CurrentHealthDashboardSchemaVersion
                )
                if (!stateDataSource.save(migrated)) MockResult.Failure(MockError.PersistFailed)
                else MockResult.Success(migrated)
            }
        }
    }

    private fun HealthDashboardSnapshot.toPersistedDashboard(): MockResult<PersistedDashboard> {
        val data = editableData?.let {
            runCatching { HealthEditableRules.derive(it) }.getOrNull()
        } ?: dashboardData ?: return MockResult.Failure(MockError.CorruptedData)
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
