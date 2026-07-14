package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult

interface HealthDashboardDataSource {
    fun load(scenario: HealthMockScenario): MockResult<HealthDashboardData>
}

class LocalHealthDashboardDataSource(
    private val authRepository: AuthRepository
) : HealthDashboardDataSource {
    override fun load(scenario: HealthMockScenario): MockResult<HealthDashboardData> {
        if (authRepository.verifyBusinessAccess() is MockResult.Failure) {
            return MockResult.Failure(MockError.AuthRequired)
        }
        if (scenario == HealthMockScenario.ReadFailure) return MockResult.Failure(MockError.CorruptedData)
        return MockResult.Success(sample(scenario))
    }

    private fun sample(scenario: HealthMockScenario): HealthDashboardData = when (scenario) {
        HealthMockScenario.Normal -> HealthDashboardData(
            DailySummary(8769, 769, 69), SleepSummary(438, 86), TrainingLoad(526), Recovery(78, 14)
        )
        HealthMockScenario.PartialMissing -> HealthDashboardData(
            DailySummary(null, 310, 32), null, TrainingLoad(526), Recovery(78, 14)
        )
        HealthMockScenario.AllEmpty -> HealthDashboardData(null, null, null, null)
        HealthMockScenario.Abnormal -> HealthDashboardData(
            DailySummary(12_000, 900, 85), SleepSummary(180, 34), TrainingLoad(1_120), Recovery(22, 36)
        )
        HealthMockScenario.ReadFailure -> error("handled above")
    }
}

class HealthDashboardUseCase(private val dataSource: HealthDashboardDataSource) {
    fun load(scenario: HealthMockScenario): MockResult<DashboardUiState> = when (val result = dataSource.load(scenario)) {
        is MockResult.Failure -> MockResult.Failure(result.error)
        is MockResult.Success -> MockResult.Success(toUiState(result.data))
    }

    fun toUiState(data: HealthDashboardData): DashboardUiState {
        val cards = listOf(
            generic(HealthCardType.WeeklyPlan, "本周计划", "本周无计划", 40),
            activityCard(data.dailySummary), trainingCard(data.trainingLoad),
            generic(HealthCardType.TrainingAssessment, "训练量评估", "将在第一次运动后 7 天评估您的训练量", 41),
            recoveryCard(data.recovery), generic(HealthCardType.RunningAbility, "跑步能力", "记录一笔 25min 以上的户外跑步运动", 42),
            generic(HealthCardType.CyclingAbility, "骑行能力", "连接功率计，完成一次 20min 以上稳定骑行", 43),
            generic(HealthCardType.HeartRate, "心率", "佩戴手表记录心率数据", 44),
            generic(HealthCardType.Stress, "压力", "佩戴手表或进行健康快测获取压力", 45), sleepCard(data.sleepSummary),
            generic(HealthCardType.HrvAssessment, "HRV 评估", "睡觉时佩戴手表获取数据", 46),
            generic(HealthCardType.RestingHeartRate, "静息心率", "睡觉时佩戴手表或进行静息心率测试", 47),
            generic(HealthCardType.HealthCheck, "健康快测", "使用手表“健康快测”获取数据", 48),
            generic(HealthCardType.BodyManagement, "体型管理", "体重 68.2 kg · 本周主要锻炼部位", 49)
        ).sortedWith(compareBy<HealthCardUiModel> { it.priority }.thenBy { it.type.ordinal })
        return DashboardUiState("今天", "7月14日 星期二", data.dailySummary, cards)
    }

    private fun recoveryCard(value: Recovery?): HealthCardUiModel {
        val score = value?.score
        return when {
            score == null -> empty(HealthCardType.Recovery, "体力恢复", "佩戴手表记录一次运动以评估实时体力", HealthCardAction.ViewRecovery)
            score !in 0..100 || score < 40 -> HealthCardUiModel(HealthCardType.Recovery, "体力恢复", "恢复不足，建议降低训练强度", HealthCardStatus.Risk, HealthCardAction.ViewRecovery, 0, "恢复状态异常")
            else -> HealthCardUiModel(HealthCardType.Recovery, "体力恢复", "恢复评分 $score，预计 ${value.remainingHours ?: 0} 小时后恢复", HealthCardStatus.Normal, HealthCardAction.ViewRecovery, 20, "今日恢复数据")
        }
    }

    private fun sleepCard(value: SleepSummary?): HealthCardUiModel {
        val minutes = value?.durationMinutes
        return when {
            minutes == null -> empty(HealthCardType.Sleep, "睡眠", "暂无昨夜睡眠数据", HealthCardAction.ViewSleep)
            minutes !in 60..900 || (value.qualityScore ?: 100) < 40 -> HealthCardUiModel(HealthCardType.Sleep, "睡眠", "睡眠质量偏低，今天注意安排休息", HealthCardStatus.Risk, HealthCardAction.ViewSleep, 1, "睡眠异常")
            else -> HealthCardUiModel(HealthCardType.Sleep, "睡眠", "昨夜睡眠 ${minutes / 60}小时${minutes % 60}分，质量 ${value.qualityScore}", HealthCardStatus.Normal, HealthCardAction.ViewSleep, 21, "今日睡眠数据")
        }
    }

    private fun activityCard(value: DailySummary?): HealthCardUiModel = when {
        value == null || (value.steps == null && value.calories == null && value.activeMinutes == null) -> empty(HealthCardType.TodayActivity, "今日运动", "今天还没有运动数据", HealthCardAction.ViewActivity)
        else -> HealthCardUiModel(HealthCardType.TodayActivity, "今日运动", "${value.steps ?: 0} 步 · ${value.calories ?: 0} Kcal · ${value.activeMinutes ?: 0} 分钟", HealthCardStatus.Normal, HealthCardAction.ViewActivity, 22, "今日运动数据")
    }

    private fun trainingCard(value: TrainingLoad?): HealthCardUiModel {
        val load = value?.value
        return when {
            load == null -> empty(HealthCardType.TrainingLoad, "训练负荷", "暂无训练负荷数据", HealthCardAction.ViewTrainingLoad)
            load < 0 || load > value.recommendedMax -> HealthCardUiModel(HealthCardType.TrainingLoad, "训练负荷", "负荷 $load，超过建议范围，建议安排恢复", HealthCardStatus.Risk, HealthCardAction.ViewTrainingLoad, 2, "训练负荷风险")
            else -> HealthCardUiModel(HealthCardType.TrainingLoad, "训练负荷", "本周负荷 $load，建议范围 ${value.recommendedMin}-${value.recommendedMax}", HealthCardStatus.Normal, HealthCardAction.ViewTrainingLoad, 30, "常规趋势数据")
        }
    }

    private fun empty(type: HealthCardType, title: String, summary: String, action: HealthCardAction) =
        HealthCardUiModel(type, title, summary, HealthCardStatus.Empty, action, 80 + type.ordinal, "模块数据缺失")
    private fun generic(type: HealthCardType, title: String, summary: String, priority: Int) =
        HealthCardUiModel(type, title, summary, HealthCardStatus.Empty, HealthCardAction.OpenCard, priority, "常规健康卡片")
}

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
}

data class PersistedDashboard(val scenario: HealthMockScenario, val uiState: DashboardUiState, val enabledCardTypes: List<HealthCardType>)

class HealthDashboardStore(
    private val authRepository: AuthRepository,
    private val stateDataSource: HealthDashboardStateDataSource
) {
    private val useCase = HealthDashboardUseCase(LocalHealthDashboardDataSource(authRepository))

    fun load(): MockResult<PersistedDashboard> = when (val access = authRepository.verifyBusinessAccess()) {
        is MockResult.Failure -> MockResult.Failure(access.error)
        is MockResult.Success -> {
            val snapshot = stateDataSource.load(access.data.userId) ?: HealthDashboardSnapshot(access.data.userId)
            val scenario = snapshot.scenario
            when (val dashboard = useCase.load(scenario)) {
                is MockResult.Success -> MockResult.Success(PersistedDashboard(scenario, dashboard.data.copy(cards = ordered(dashboard.data.cards, snapshot.enabledCardTypes)), snapshot.enabledCardTypes))
                is MockResult.Failure -> MockResult.Failure(dashboard.error)
            }
        }
    }

    fun selectScenario(scenario: HealthMockScenario): MockResult<PersistedDashboard> = when (val access = authRepository.verifyBusinessAccess()) {
        is MockResult.Failure -> MockResult.Failure(access.error)
        is MockResult.Success -> {
            val old = stateDataSource.load(access.data.userId) ?: HealthDashboardSnapshot(access.data.userId)
            if (!stateDataSource.save(old.copy(scenario = scenario))) {
                MockResult.Failure(MockError.PersistFailed)
            } else {
                when (val dashboard = useCase.load(scenario)) {
                    is MockResult.Success -> MockResult.Success(PersistedDashboard(scenario, dashboard.data.copy(cards = ordered(dashboard.data.cards, old.enabledCardTypes)), old.enabledCardTypes))
                    is MockResult.Failure -> MockResult.Failure(dashboard.error)
                }
            }
        }
    }

    fun saveCardConfiguration(types: List<HealthCardType>): MockResult<PersistedDashboard> = when (val access = authRepository.verifyBusinessAccess()) {
        is MockResult.Failure -> MockResult.Failure(access.error)
        is MockResult.Success -> {
            val old = stateDataSource.load(access.data.userId) ?: HealthDashboardSnapshot(access.data.userId)
            val clean = types.distinct().takeIf { it.size >= 3 } ?: old.enabledCardTypes
            if (!stateDataSource.save(old.copy(enabledCardTypes = clean))) MockResult.Failure(MockError.PersistFailed)
            else when (val dashboard = useCase.load(old.scenario)) {
                is MockResult.Failure -> MockResult.Failure(dashboard.error)
                is MockResult.Success -> MockResult.Success(PersistedDashboard(old.scenario, dashboard.data.copy(cards = ordered(dashboard.data.cards, clean)), clean))
            }
        }
    }

    private fun ordered(cards: List<HealthCardUiModel>, types: List<HealthCardType>): List<HealthCardUiModel> {
        val byType = cards.associateBy { it.type }
        return types.mapNotNull(byType::get)
    }
}
