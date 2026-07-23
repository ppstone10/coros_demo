package com.example.demo.common.health

enum class HealthMockScenario { Normal, PartialMissing, AllEmpty, Abnormal, ReadFailure }

enum class HealthCardType {
    WeeklyPlan, TodayActivity, TrainingLoad, TrainingAssessment, Recovery,
    RunningAbility, CyclingAbility, HeartRate, Stress, Sleep, HrvAssessment,
    RestingHeartRate, HealthCheck, BodyManagement
}
enum class HealthCardStatus { Normal, Attention, Risk, Empty }

enum class HealthVisualLevel { Neutral, Low, Good, Elevated, High }
enum class HealthCardVisualKind {
    TodayActivity, WeeklyPlan, TrainingLoad, TrainingAssessment, RecoveryGauge,
    AbilityGauge, TrendBars, RangeIndicator, SleepStages, HealthCheckGrid, BodyMap
}
enum class SleepStage { Awake, Rem, Light, Deep }

enum class HealthCardAction {
    ViewSleep, ViewActivity, ViewTrainingLoad, ViewRecovery,
    ViewWeeklyPlan, ViewTrainingAssessment, ViewRunningAbility, ViewCyclingAbility,
    ViewHeartRate, ViewStress, ViewHrvAssessment, ViewRestingHeartRate,
    ViewHealthCheck, ViewBodyManagement, OpenCard
}

/** 平台无关的本地化内容契约；最终句子由各端原生资源系统生成。 */
data class LocalizedTextSpec(
    val key: String,
    val arguments: List<String> = emptyList()
)

data class HealthChartPoint(
    val label: String,
    val value: Double,
    val level: HealthVisualLevel = HealthVisualLevel.Neutral,
    val minimum: Double? = null,
    val maximum: Double? = null,
    val average: Double? = null
)
data class HealthRange(
    val minimum: Double, val maximum: Double, val current: Double,
    val normalMin: Double? = null, val normalMax: Double? = null, val average: Double? = null
)
data class HealthMetric(val label: LocalizedTextSpec, val value: String, val unit: LocalizedTextSpec? = null)
data class SleepStageSegment(val stage: SleepStage, val startMinute: Int, val durationMinutes: Int)

data class DailySummary(val steps: Int?, val calories: Int?, val activeMinutes: Int?)
data class TodayActivity(
    val distanceKm: Double?, val paceSecondsPerKm: Int?,
    val activityName: LocalizedTextSpec?, val trainingLoad: Int?
)
data class SleepSummary(
    val durationMinutes: Int?, val qualityScore: Int?,
    val startTime: String? = null, val endTime: String? = null,
    val stages: List<SleepStageSegment> = emptyList()
)
data class TrainingLoad(
    val value: Int?, val recommendedMin: Int = 300, val recommendedMax: Int = 700,
    val dailyLoads: List<Int> = emptyList()
)
data class Recovery(val score: Int?, val remainingHours: Int?)
data class WeeklyDayPlan(
    val dayIndex: Int,
    val workoutName: LocalizedTextSpec? = null,
    val workoutDurationMinutes: Int? = null,
    val workoutTrainingLoad: Int? = null
)
data class WeeklyPlan(
    val hasPlan: Boolean, val plannedMinutes: Int?, val description: String?,
    val currentDayIndex: Int = 0, val dailyLoads: List<Int> = emptyList(),
    val workoutName: LocalizedTextSpec? = null, val workoutDurationMinutes: Int? = null,
    val workoutTrainingLoad: Int? = null,
    val dayPlans: List<WeeklyDayPlan> = emptyList()
)
data class TrainingAssessment(
    val volumeScore: Int?, val trend: String?,
    val shortTermLoad: Int? = null, val longTermLoad: Int? = null, val loadRatio: Double? = null,
    val assessment: LocalizedTextSpec? = null, val explanation: LocalizedTextSpec? = null
)
data class RunningAbility(
    val vo2max: Int?, val score: Int?, val displayScore: Double? = null, val marathonSeconds: Int? = null
)
data class CyclingAbility(
    val ftp: Int?, val score: Int?, val displayScore: Double? = null, val abilityLabel: LocalizedTextSpec? = null
)
data class HeartRateInterval(
    val startMinute: Int,
    val minimum: Int,
    val maximum: Int,
    val average: Int
)
data class HeartRate(
    val restingHr: Int?,
    val currentHr: Int?,
    val averageHr: Int? = null,
    val samples: List<Int> = emptyList(),
    val intervals: List<HeartRateInterval> = emptyList(),
    val fiveMinuteSamples: List<Int> = emptyList()
)
data class Stress(
    val stressLevel: Int?, val status: String?, val averageStress: Int? = null, val samples: List<Int> = emptyList()
)
data class HrvAssessment(
    val hrvScore: Int?, val status: String?, val averageMs: Int? = null,
    val normalMin: Int? = null, val normalMax: Int? = null
)
data class RestingHeartRate(
    val value: Int?, val measuredTime: String? = null, val thirtyDayAverage: Int? = null,
    val rangeMin: Int = 30, val rangeMax: Int = 80
)
data class HealthCheck(
    val overallScore: Int?, val lastCheckDays: Int?, val measuredTime: String? = null,
    val heartRate: Int? = null, val hrvMs: Int? = null, val stress: Int? = null,
    val respiratoryRate: Int? = null, val bloodOxygen: Int? = null
)
data class BodyManagement(
    val weightKg: Double?, val bodyFat: Double?, val bmi: Double?,
    val measuredDate: String? = null, val trainedMuscleGroups: List<String> = emptyList()
)

data class HealthDashboardData(
    val dailySummary: DailySummary?,
    val sleepSummary: SleepSummary?,
    val trainingLoad: TrainingLoad?,
    val recovery: Recovery?,
    val todayActivity: TodayActivity? = null,
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
    val priorityReason: String,
    val visual: HealthCardVisualData
)

data class HealthCardVisualData(
    val kind: HealthCardVisualKind,
    val primaryValue: String? = null,
    val primaryUnit: LocalizedTextSpec? = null,
    val secondaryValue: String? = null,
    val secondaryUnit: LocalizedTextSpec? = null,
    val caption: LocalizedTextSpec? = null,
    val detail: LocalizedTextSpec? = null,
    val progress: Double? = null,
    val chartPoints: List<HealthChartPoint> = emptyList(),
    val range: HealthRange? = null,
    val metrics: List<HealthMetric> = emptyList(),
    val sleepStages: List<SleepStageSegment> = emptyList(),
    val startTime: String? = null,
    val endTime: String? = null,
    val highlightedIndex: Int? = null,
    val assetKey: String? = null,
    val weeklyDayPlans: List<WeeklyDayPlan> = emptyList()
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
    val sourceScenario: HealthMockScenario = HealthMockScenario.Normal,
    val enabledCardTypes: List<HealthCardType> = DefaultHealthCardOrder,
    val dashboardData: HealthDashboardData? = null,
    val schemaVersion: Int = CurrentHealthDashboardSchemaVersion
)

const val CurrentHealthDashboardSchemaVersion = 4

object HealthScenarios {
    val names: List<String> = HealthMockScenario.entries.map { it.name }
    val displayKeys: List<String> = listOf(
        "health_scenario_normal", "health_scenario_partial_missing",
        "health_scenario_all_empty", "health_scenario_abnormal",
        "health_scenario_read_failure"
    )
}

val DefaultHealthCardOrder = listOf(
    HealthCardType.TodayActivity, HealthCardType.WeeklyPlan, HealthCardType.TrainingLoad, HealthCardType.TrainingAssessment,
    HealthCardType.Recovery, HealthCardType.RunningAbility, HealthCardType.CyclingAbility,
    HealthCardType.HeartRate, HealthCardType.Stress, HealthCardType.Sleep,
    HealthCardType.HrvAssessment, HealthCardType.RestingHeartRate,
    HealthCardType.HealthCheck, HealthCardType.BodyManagement
)
