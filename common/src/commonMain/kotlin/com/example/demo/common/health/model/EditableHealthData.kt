package com.example.demo.common.health.model

enum class HealthEditableSection {
    DailySummary,
    TodayActivity,
    WeeklyPlan,
    TrainingLoad,
    TrainingAssessment,
    Recovery,
    RunningAbility,
    CyclingAbility,
    HeartRate,
    Stress,
    Sleep,
    HrvAssessment,
    RestingHeartRate,
    HealthCheck,
    BodyManagement
}

enum class WorkoutType { Rest, Easy, Tempo, Endurance }
enum class HeartRatePattern { Normal, High, Low }
enum class StressPattern { Normal, High }

data class DailySummaryInput(val steps: Int, val calories: Int, val activeMinutes: Int)
data class TodayActivityInput(val distanceKm: Double, val paceSecondsPerKm: Int)
data class WeeklyWorkoutInput(val type: WorkoutType, val distanceKm: Double)
data class WeeklyPlanInput(val days: List<WeeklyWorkoutInput>)
data class TrainingLoadInput(val dailyLoads: List<Int>)
data class TrainingAssessmentInput(val shortTermLoad: Int, val longTermLoad: Int)
data class RecoveryInput(val score: Int)
data class RunningAbilityInput(val score: Int)
data class CyclingAbilityInput(val score: Int)
data class HeartRateInput(val fiveMinuteSamples: List<Int>)
data class StressInput(val halfHourSamples: List<Int>)
data class SleepStageInput(val stage: SleepStage, val startMinute: Int, val durationMinutes: Int)
data class SleepInput(val startMinuteOfDay: Int, val stages: List<SleepStageInput>)
data class HrvAssessmentInput(val averageMs: Int)
data class RestingHeartRateInput(val value: Int, val measuredTime: String, val thirtyDayAverage: Int)
data class HealthCheckInput(
    val heartRate: Int,
    val hrvMs: Int,
    val stress: Int,
    val respiratoryRate: Int,
    val bloodOxygen: Int,
    val measuredTime: String
)
data class BodyManagementInput(
    val weightKg: Double,
    val trainedMuscleGroups: List<String>,
    val weightHistoryKg: List<Double> = listOf(weightKg)
)

/**
 * 可编辑正常场景、默认 fixture 与新快照共用的唯一源字段契约。
 * 任何能够从这些字段确定性计算的展示值都不得加入该类型。
 */
data class EditableHealthData(
    val dailySummary: DailySummaryInput,
    val todayActivity: TodayActivityInput,
    val weeklyPlan: WeeklyPlanInput,
    val trainingLoad: TrainingLoadInput,
    val assessment: TrainingAssessmentInput,
    val recovery: RecoveryInput,
    val runningAbility: RunningAbilityInput,
    val cyclingAbility: CyclingAbilityInput,
    val heartRate: HeartRateInput,
    val stress: StressInput,
    val sleep: SleepInput,
    val hrvAssessment: HrvAssessmentInput,
    val restingHeartRate: RestingHeartRateInput,
    val healthCheck: HealthCheckInput,
    val bodyManagement: BodyManagementInput
)

enum class HealthEditSourceKind(val messageKey: String) {
    Available(""),
    Partial("health_edit_source_partial"),
    Empty("health_edit_source_empty"),
    Corrupted("health_edit_source_corrupted")
}

data class HealthEditableProjection(
    val data: EditableHealthData,
    val sourceKind: HealthEditSourceKind
)
