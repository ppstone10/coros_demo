package com.example.demo.common.health

enum class HealthMockScenario { Normal, PartialMissing, AllEmpty, Abnormal, ReadFailure }

enum class HealthCardType {
    WeeklyPlan, TodayActivity, TrainingLoad, TrainingAssessment, Recovery,
    RunningAbility, CyclingAbility, HeartRate, Stress, Sleep, HrvAssessment,
    RestingHeartRate, HealthCheck, BodyManagement
}
enum class HealthCardStatus { Normal, Attention, Risk, Empty }

enum class HealthCardAction { ViewSleep, ViewActivity, ViewTrainingLoad, ViewRecovery, OpenCard }

data class DailySummary(val steps: Int?, val calories: Int?, val activeMinutes: Int?)
data class SleepSummary(val durationMinutes: Int?, val qualityScore: Int?)
data class TrainingLoad(val value: Int?, val recommendedMin: Int = 300, val recommendedMax: Int = 700)
data class Recovery(val score: Int?, val remainingHours: Int?)

data class HealthDashboardData(
    val dailySummary: DailySummary?,
    val sleepSummary: SleepSummary?,
    val trainingLoad: TrainingLoad?,
    val recovery: Recovery?
)

data class HealthCardUiModel(
    val type: HealthCardType,
    val title: String,
    val summary: String,
    val status: HealthCardStatus,
    val action: HealthCardAction,
    val priority: Int,
    val priorityReason: String
)

data class DashboardUiState(
    val greeting: String,
    val dateLabel: String,
    val dailySummary: DailySummary?,
    val cards: List<HealthCardUiModel>
)

/** 本地保存的健康首页状态；按认证 userId 隔离，避免跨账号复用。 */
data class HealthDashboardSnapshot(
    val userId: String,
    val scenario: HealthMockScenario = HealthMockScenario.Normal,
    val enabledCardTypes: List<HealthCardType> = DefaultHealthCardOrder
)

val DefaultHealthCardOrder = listOf(
    HealthCardType.WeeklyPlan, HealthCardType.TrainingLoad, HealthCardType.TrainingAssessment,
    HealthCardType.Recovery, HealthCardType.RunningAbility, HealthCardType.CyclingAbility,
    HealthCardType.HeartRate, HealthCardType.Stress, HealthCardType.Sleep,
    HealthCardType.HrvAssessment, HealthCardType.RestingHeartRate,
    HealthCardType.HealthCheck, HealthCardType.BodyManagement
)
