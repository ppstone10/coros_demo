package com.example.demo.common.health

enum class HealthMockScenario { Normal, PartialMissing, AllEmpty, Abnormal, ReadFailure }

enum class HealthCardType {
    WeeklyPlan, TodayActivity, TrainingLoad, TrainingAssessment, Recovery,
    RunningAbility, CyclingAbility, HeartRate, Stress, Sleep, HrvAssessment,
    RestingHeartRate, HealthCheck, BodyManagement
}
enum class HealthCardStatus { Normal, Attention, Risk, Empty }

enum class HealthCardAction {
    ViewSleep, ViewActivity, ViewTrainingLoad, ViewRecovery,
    ViewWeeklyPlan, ViewTrainingAssessment, ViewRunningAbility, ViewCyclingAbility,
    ViewHeartRate, ViewStress, ViewHrvAssessment, ViewRestingHeartRate,
    ViewHealthCheck, ViewBodyManagement, OpenCard
}

data class DailySummary(val steps: Int?, val calories: Int?, val activeMinutes: Int?)
data class SleepSummary(val durationMinutes: Int?, val qualityScore: Int?)
data class TrainingLoad(val value: Int?, val recommendedMin: Int = 300, val recommendedMax: Int = 700)
data class Recovery(val score: Int?, val remainingHours: Int?)
data class WeeklyPlan(val hasPlan: Boolean, val plannedMinutes: Int?, val description: String?)
data class TrainingAssessment(val volumeScore: Int?, val trend: String?)
data class RunningAbility(val vo2max: Int?, val score: Int?)
data class CyclingAbility(val ftp: Int?, val score: Int?)
data class HeartRate(val restingHr: Int?, val currentHr: Int?)
data class Stress(val stressLevel: Int?, val status: String?)
data class HrvAssessment(val hrvScore: Int?, val status: String?)
data class RestingHeartRate(val value: Int?)
data class HealthCheck(val overallScore: Int?, val lastCheckDays: Int?)
data class BodyManagement(val weightKg: Double?, val bodyFat: Double?, val bmi: Double?)

/** 平台无关的本地化内容契约；最终句子由各端原生资源系统生成。 */
data class LocalizedTextSpec(
    val key: String,
    val arguments: List<String> = emptyList()
)

data class HealthDashboardData(
    val dailySummary: DailySummary?,
    val sleepSummary: SleepSummary?,
    val trainingLoad: TrainingLoad?,
    val recovery: Recovery?,
    val weeklyPlan: WeeklyPlan? = null,
    val trainingAssessment: TrainingAssessment? = null,
    val runningAbility: RunningAbility? = null,
    val cyclingAbility: CyclingAbility? = null,
    val heartRate: HeartRate? = null,
    val stress: Stress? = null,
    val hrvAssessment: HrvAssessment? = null,
    val restingHeartRate: RestingHeartRate? = null,
    val healthCheck: HealthCheck? = null,
    val bodyManagement: BodyManagement? = null
)

data class HealthCardUiModel(
    val type: HealthCardType,
    val title: LocalizedTextSpec,
    val summary: LocalizedTextSpec,
    val status: HealthCardStatus,
    val action: HealthCardAction,
    val priority: Int,
    val priorityReason: String
)

data class DashboardUiState(
    val greeting: LocalizedTextSpec,
    val dateLabel: LocalizedTextSpec,
    val dailySummary: DailySummary?,
    val cards: List<HealthCardUiModel>
)

/** 本地保存的健康首页状态；按认证 userId 隔离，避免跨账号复用。 */
data class HealthDashboardSnapshot(
    val userId: String,
    val scenario: HealthMockScenario = HealthMockScenario.Normal,
    val enabledCardTypes: List<HealthCardType> = DefaultHealthCardOrder
)

object HealthScenarios {
    val names: List<String> = HealthMockScenario.entries.map { it.name }
    val displayKeys: List<String> = listOf(
        "health_scenario_normal", "health_scenario_partial_missing",
        "health_scenario_all_empty", "health_scenario_abnormal",
        "health_scenario_read_failure"
    )
}

val DefaultHealthCardOrder = listOf(
    HealthCardType.WeeklyPlan, HealthCardType.TrainingLoad, HealthCardType.TrainingAssessment,
    HealthCardType.Recovery, HealthCardType.RunningAbility, HealthCardType.CyclingAbility,
    HealthCardType.HeartRate, HealthCardType.Stress, HealthCardType.Sleep,
    HealthCardType.HrvAssessment, HealthCardType.RestingHeartRate,
    HealthCardType.HealthCheck, HealthCardType.BodyManagement
)
