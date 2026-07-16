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
            dailySummary = DailySummary(8769, 769, 69),
            sleepSummary = SleepSummary(438, 86),
            trainingLoad = TrainingLoad(526),
            recovery = Recovery(78, 14),
            weeklyPlan = WeeklyPlan(true, 300, "5 次跑步 · 3 次力量"),
            trainingAssessment = TrainingAssessment(78, "increasing"),
            runningAbility = RunningAbility(52, 85),
            cyclingAbility = CyclingAbility(220, 72),
            heartRate = HeartRate(55, 68),
            stress = Stress(35, "normal"),
            hrvAssessment = HrvAssessment(62, "balanced"),
            restingHeartRate = RestingHeartRate(55),
            healthCheck = HealthCheck(82, 3),
            bodyManagement = BodyManagement(68.2, 15.5, 22.3)
        )
        HealthMockScenario.PartialMissing -> HealthDashboardData(
            dailySummary = DailySummary(null, 310, 32),
            sleepSummary = null,
            trainingLoad = TrainingLoad(526),
            recovery = Recovery(78, 14),
            weeklyPlan = null,
            trainingAssessment = null,
            runningAbility = RunningAbility(52, 85),
            cyclingAbility = null,
            heartRate = HeartRate(55, 68),
            stress = null,
            hrvAssessment = null,
            restingHeartRate = RestingHeartRate(55),
            healthCheck = null,
            bodyManagement = BodyManagement(68.2, 15.5, 22.3)
        )
        HealthMockScenario.AllEmpty -> HealthDashboardData(null, null, null, null)
        HealthMockScenario.Abnormal -> HealthDashboardData(
            dailySummary = DailySummary(12_000, 900, 85),
            sleepSummary = SleepSummary(180, 34),
            trainingLoad = TrainingLoad(1_120),
            recovery = Recovery(22, 36),
            weeklyPlan = WeeklyPlan(false, null, null),
            trainingAssessment = TrainingAssessment(25, "declining"),
            runningAbility = RunningAbility(38, 28),
            cyclingAbility = CyclingAbility(150, 25),
            heartRate = HeartRate(92, 138),
            stress = Stress(85, "high"),
            hrvAssessment = HrvAssessment(32, "low"),
            restingHeartRate = RestingHeartRate(108),
            healthCheck = HealthCheck(35, 30),
            bodyManagement = BodyManagement(75.0, 25.0, 27.8)
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
            weeklyPlanCard(data.weeklyPlan), activityCard(data.dailySummary), trainingCard(data.trainingLoad),
            trainingAssessmentCard(data.trainingAssessment), recoveryCard(data.recovery),
            runningAbilityCard(data.runningAbility), cyclingAbilityCard(data.cyclingAbility),
            heartRateCard(data.heartRate), stressCard(data.stress), sleepCard(data.sleepSummary),
            hrvAssessmentCard(data.hrvAssessment), restingHeartRateCard(data.restingHeartRate),
            healthCheckCard(data.healthCheck), bodyManagementCard(data.bodyManagement)
        ).sortedWith(compareBy<HealthCardUiModel> { it.priority }.thenBy { it.type.ordinal })
        return DashboardUiState("今天", "7月15日 星期三", data.dailySummary, cards)
    }

    private fun weeklyPlanCard(value: WeeklyPlan?): HealthCardUiModel = when {
        value == null -> empty(HealthCardType.WeeklyPlan, "本周计划", "本周无计划", HealthCardAction.ViewWeeklyPlan)
        value.hasPlan -> HealthCardUiModel(HealthCardType.WeeklyPlan, "本周计划", value.description ?: "本周训练计划已就绪", HealthCardStatus.Normal, HealthCardAction.ViewWeeklyPlan, 25, "本周训练计划")
        else -> HealthCardUiModel(HealthCardType.WeeklyPlan, "本周计划", value.description ?: "本周无计划", HealthCardStatus.Empty, HealthCardAction.ViewWeeklyPlan, 40, "未知训练计划状态")
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

    private fun trainingAssessmentCard(value: TrainingAssessment?): HealthCardUiModel = when {
        value == null || value.volumeScore == null -> empty(HealthCardType.TrainingAssessment, "训练量评估", "将在第一次运动后 7 天评估您的训练量", HealthCardAction.ViewTrainingAssessment)
        value.volumeScore < 30 -> HealthCardUiModel(HealthCardType.TrainingAssessment, "训练量评估", "训练量偏低，评分 ${value.volumeScore}，趋势 ${value.trend}", HealthCardStatus.Risk, HealthCardAction.ViewTrainingAssessment, 3, "训练量不足")
        else -> HealthCardUiModel(HealthCardType.TrainingAssessment, "训练量评估", "评分 ${value.volumeScore} · 趋势 ${value.trend}", HealthCardStatus.Normal, HealthCardAction.ViewTrainingAssessment, 23, "训练量评估数据")
    }

    private fun runningAbilityCard(value: RunningAbility?): HealthCardUiModel = when {
        value == null || value.vo2max == null -> empty(HealthCardType.RunningAbility, "跑步能力", "记录一笔 25min 以上的户外跑步运动", HealthCardAction.ViewRunningAbility)
        value.score != null && value.score < 30 -> HealthCardUiModel(HealthCardType.RunningAbility, "跑步能力", "VO2Max ${value.vo2max} · 评分 ${value.score}，建议增加有氧训练", HealthCardStatus.Risk, HealthCardAction.ViewRunningAbility, 4, "跑步能力偏低")
        else -> HealthCardUiModel(HealthCardType.RunningAbility, "跑步能力", "VO2Max ${value.vo2max} · 评分 ${value.score ?: "---"}", HealthCardStatus.Normal, HealthCardAction.ViewRunningAbility, 24, "跑步能力数据")
    }

    private fun cyclingAbilityCard(value: CyclingAbility?): HealthCardUiModel = when {
        value == null || value.ftp == null -> empty(HealthCardType.CyclingAbility, "骑行能力", "连接功率计，完成一次 20min 以上稳定骑行", HealthCardAction.ViewCyclingAbility)
        value.score != null && value.score < 30 -> HealthCardUiModel(HealthCardType.CyclingAbility, "骑行能力", "FTP ${value.ftp}W · 评分 ${value.score}，建议加强骑行训练", HealthCardStatus.Risk, HealthCardAction.ViewCyclingAbility, 5, "骑行能力偏低")
        else -> HealthCardUiModel(HealthCardType.CyclingAbility, "骑行能力", "FTP ${value.ftp}W · 评分 ${value.score ?: "---"}", HealthCardStatus.Normal, HealthCardAction.ViewCyclingAbility, 25, "骑行能力数据")
    }

    private fun heartRateCard(value: HeartRate?): HealthCardUiModel = when {
        value == null || value.restingHr == null -> empty(HealthCardType.HeartRate, "心率", "佩戴手表记录心率数据", HealthCardAction.ViewHeartRate)
        value.restingHr > 90 || value.currentHr != null && value.currentHr > 160 -> HealthCardUiModel(HealthCardType.HeartRate, "心率", "静息 ${value.restingHr} bpm · 当前 ${value.currentHr ?: "---"} bpm，心率偏高", HealthCardStatus.Risk, HealthCardAction.ViewHeartRate, 6, "心率异常")
        else -> HealthCardUiModel(HealthCardType.HeartRate, "心率", "静息 ${value.restingHr} bpm · 当前 ${value.currentHr ?: "---"} bpm", HealthCardStatus.Normal, HealthCardAction.ViewHeartRate, 26, "心率数据")
    }

    private fun stressCard(value: Stress?): HealthCardUiModel = when {
        value == null || value.stressLevel == null -> empty(HealthCardType.Stress, "压力", "佩戴手表或进行健康快测获取压力", HealthCardAction.ViewStress)
        value.stressLevel > 80 -> HealthCardUiModel(HealthCardType.Stress, "压力", "压力水平 ${value.stressLevel} · 状态 ${value.status}，建议放松休息", HealthCardStatus.Risk, HealthCardAction.ViewStress, 7, "压力过高")
        else -> HealthCardUiModel(HealthCardType.Stress, "压力", "压力水平 ${value.stressLevel} · 状态 ${value.status}", HealthCardStatus.Normal, HealthCardAction.ViewStress, 27, "压力数据")
    }

    private fun hrvAssessmentCard(value: HrvAssessment?): HealthCardUiModel = when {
        value == null || value.hrvScore == null -> empty(HealthCardType.HrvAssessment, "HRV 评估", "睡觉时佩戴手表获取数据", HealthCardAction.ViewHrvAssessment)
        value.hrvScore < 40 -> HealthCardUiModel(HealthCardType.HrvAssessment, "HRV 评估", "HRV ${value.hrvScore} ms · 状态 ${value.status}，建议关注恢复", HealthCardStatus.Risk, HealthCardAction.ViewHrvAssessment, 8, "HRV 偏低")
        else -> HealthCardUiModel(HealthCardType.HrvAssessment, "HRV 评估", "HRV ${value.hrvScore} ms · 状态 ${value.status}", HealthCardStatus.Normal, HealthCardAction.ViewHrvAssessment, 28, "HRV 数据")
    }

    private fun restingHeartRateCard(value: RestingHeartRate?): HealthCardUiModel = when {
        value == null || value.value == null -> empty(HealthCardType.RestingHeartRate, "静息心率", "睡觉时佩戴手表或进行静息心率测试", HealthCardAction.ViewRestingHeartRate)
        value.value > 100 -> HealthCardUiModel(HealthCardType.RestingHeartRate, "静息心率", "${value.value} bpm，偏高于正常范围", HealthCardStatus.Risk, HealthCardAction.ViewRestingHeartRate, 9, "静息心率偏高")
        else -> HealthCardUiModel(HealthCardType.RestingHeartRate, "静息心率", "${value.value} bpm", HealthCardStatus.Normal, HealthCardAction.ViewRestingHeartRate, 29, "静息心率数据")
    }

    private fun healthCheckCard(value: HealthCheck?): HealthCardUiModel = when {
        value == null || value.overallScore == null -> empty(HealthCardType.HealthCheck, "健康快测", "使用手表\"健康快测\"获取数据", HealthCardAction.ViewHealthCheck)
        value.overallScore < 40 -> HealthCardUiModel(HealthCardType.HealthCheck, "健康快测", "综合评分 ${value.overallScore}，${value.lastCheckDays} 天前测量，建议重新测量", HealthCardStatus.Risk, HealthCardAction.ViewHealthCheck, 10, "健康评分偏低")
        else -> HealthCardUiModel(HealthCardType.HealthCheck, "健康快测", "综合评分 ${value.overallScore} · ${value.lastCheckDays} 天前测量", HealthCardStatus.Normal, HealthCardAction.ViewHealthCheck, 31, "健康快测数据")
    }

    private fun bodyManagementCard(value: BodyManagement?): HealthCardUiModel = when {
        value == null || value.weightKg == null -> empty(HealthCardType.BodyManagement, "体型管理", "体重 --- kg · 本周主要锻炼部位", HealthCardAction.ViewBodyManagement)
        value.bmi != null && (value.bmi > 28 || value.bmi < 16) -> HealthCardUiModel(HealthCardType.BodyManagement, "体型管理", "体重 ${value.weightKg} kg · BMI ${value.bmi.f1()}，关注体型健康", HealthCardStatus.Risk, HealthCardAction.ViewBodyManagement, 11, "BMI 异常")
        else -> HealthCardUiModel(HealthCardType.BodyManagement, "体型管理", "体重 ${value.weightKg} kg · BMI ${value.bmi?.f1() ?: "---"}", HealthCardStatus.Normal, HealthCardAction.ViewBodyManagement, 32, "体型数据")
    }

    private fun empty(type: HealthCardType, title: String, summary: String, action: HealthCardAction) =
        HealthCardUiModel(type, title, summary, HealthCardStatus.Empty, action, 80 + type.ordinal, "模块数据缺失")
}

private fun Double.f1(): String {
    val v = (this * 10).toLong()
    return "${v / 10}.${v % 10}"
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
