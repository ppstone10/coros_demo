package com.example.demo.common.health

data class DailySummaryMock(val steps: Int? = null, val calories: Int? = null, val activeMinutes: Int? = null)
data class TodayActivityMock(val distanceKm: Double? = null, val paceSecondsPerKm: Int? = null, val activityNameKey: String? = null, val trainingLoad: Int? = null)
data class SleepStageSegmentMock(val stage: String, val startMinute: Int, val durationMinutes: Int)
data class SleepSummaryMock(
    val durationMinutes: Int? = null, val qualityScore: Int? = null,
    val startTime: String? = null, val endTime: String? = null,
    val stages: List<SleepStageSegmentMock> = emptyList()
)
data class TrainingLoadMock(
    val value: Int? = null, val recommendedMin: Int = 300, val recommendedMax: Int = 700,
    val dailyLoads: List<Int> = emptyList()
)
data class RecoveryMock(val score: Int? = null, val remainingHours: Int? = null)
data class WeeklyPlanMock(
    val hasPlan: Boolean = false, val plannedMinutes: Int? = null, val description: String? = null,
    val currentDayIndex: Int = 0, val dailyLoads: List<Int> = emptyList(), val workoutNameKey: String? = null,
    val workoutDurationMinutes: Int? = null, val workoutTrainingLoad: Int? = null
)
data class TrainingAssessmentMock(
    val volumeScore: Int? = null, val trend: String? = null, val shortTermLoad: Int? = null,
    val longTermLoad: Int? = null, val loadRatio: Double? = null, val assessmentKey: String? = null,
    val explanationKey: String? = null
)
data class RunningAbilityMock(val vo2max: Int? = null, val score: Int? = null, val displayScore: Double? = null, val marathonSeconds: Int? = null)
data class CyclingAbilityMock(val ftp: Int? = null, val score: Int? = null, val displayScore: Double? = null, val abilityLabelKey: String? = null)
data class HeartRateMock(val restingHr: Int? = null, val currentHr: Int? = null, val averageHr: Int? = null, val samples: List<Int> = emptyList())
data class StressMock(val stressLevel: Int? = null, val status: String? = null, val averageStress: Int? = null, val samples: List<Int> = emptyList())
data class HrvAssessmentMock(val hrvScore: Int? = null, val status: String? = null, val averageMs: Int? = null, val normalMin: Int? = null, val normalMax: Int? = null)
data class RestingHeartRateMock(val value: Int? = null, val measuredTime: String? = null, val thirtyDayAverage: Int? = null, val rangeMin: Int = 30, val rangeMax: Int = 80)
data class HealthCheckMock(
    val overallScore: Int? = null, val lastCheckDays: Int? = null, val measuredTime: String? = null,
    val heartRate: Int? = null, val hrvMs: Int? = null, val stress: Int? = null,
    val respiratoryRate: Int? = null, val bloodOxygen: Int? = null
)
data class BodyManagementMock(
    val weightKg: Double? = null, val bodyFat: Double? = null, val bmi: Double? = null,
    val measuredDate: String? = null, val trainedMuscleGroups: List<String> = emptyList()
)

data class HealthDashboardMockData(
    val daily: DailySummaryMock? = null, val sleep: SleepSummaryMock? = null,
    val todayActivity: TodayActivityMock? = null,
    val trainingLoad: TrainingLoadMock? = null, val recovery: RecoveryMock? = null,
    val weeklyPlan: WeeklyPlanMock? = null, val trainingAssessment: TrainingAssessmentMock? = null,
    val runningAbility: RunningAbilityMock? = null, val cyclingAbility: CyclingAbilityMock? = null,
    val heartRate: HeartRateMock? = null, val stress: StressMock? = null,
    val hrvAssessment: HrvAssessmentMock? = null, val restingHeartRate: RestingHeartRateMock? = null,
    val healthCheck: HealthCheckMock? = null, val bodyManagement: BodyManagementMock? = null
)

data class HealthDashboardSnapshotMock(
    val user_id: String,
    val scenario: String,
    val enabled_card_types: List<String>,
    val dashboard_data: HealthDashboardMockData? = null,
    val schema_version: Int = CurrentHealthDashboardSchemaVersion
)

// ---- Domain → Proto Mock ----

fun DailySummary.toMock() = DailySummaryMock(steps, calories, activeMinutes)
fun TodayActivity.toMock() = TodayActivityMock(distanceKm, paceSecondsPerKm, activityName?.key, trainingLoad)
fun SleepStageSegment.toMock() = SleepStageSegmentMock(stage.name, startMinute, durationMinutes)
fun SleepSummary.toMock() = SleepSummaryMock(durationMinutes, qualityScore, startTime, endTime, stages.map { it.toMock() })
fun TrainingLoad.toMock() = TrainingLoadMock(value, recommendedMin, recommendedMax, dailyLoads)
fun Recovery.toMock() = RecoveryMock(score, remainingHours)
fun WeeklyPlan.toMock() = WeeklyPlanMock(hasPlan, plannedMinutes, description, currentDayIndex, dailyLoads, workoutName?.key, workoutDurationMinutes, workoutTrainingLoad)
fun TrainingAssessment.toMock() = TrainingAssessmentMock(volumeScore, trend, shortTermLoad, longTermLoad, loadRatio, assessment?.key, explanation?.key)
fun RunningAbility.toMock() = RunningAbilityMock(vo2max, score, displayScore, marathonSeconds)
fun CyclingAbility.toMock() = CyclingAbilityMock(ftp, score, displayScore, abilityLabel?.key)
fun HeartRate.toMock() = HeartRateMock(restingHr, currentHr, averageHr, samples)
fun Stress.toMock() = StressMock(stressLevel, status, averageStress, samples)
fun HrvAssessment.toMock() = HrvAssessmentMock(hrvScore, status, averageMs, normalMin, normalMax)
fun RestingHeartRate.toMock() = RestingHeartRateMock(value, measuredTime, thirtyDayAverage, rangeMin, rangeMax)
fun HealthCheck.toMock() = HealthCheckMock(overallScore, lastCheckDays, measuredTime, heartRate, hrvMs, stress, respiratoryRate, bloodOxygen)
fun BodyManagement.toMock() = BodyManagementMock(weightKg, bodyFat, bmi, measuredDate, trainedMuscleGroups)

fun HealthDashboardData.toMock() = HealthDashboardMockData(
    daily = dailySummary?.toMock(), sleep = sleepSummary?.toMock(),
    todayActivity = todayActivity?.toMock(),
    trainingLoad = trainingLoad?.toMock(), recovery = recovery?.toMock(),
    weeklyPlan = weeklyPlan?.toMock(), trainingAssessment = trainingAssessment?.toMock(),
    runningAbility = runningAbility?.toMock(), cyclingAbility = cyclingAbility?.toMock(),
    heartRate = heartRate?.toMock(), stress = stress?.toMock(),
    hrvAssessment = hrvAssessment?.toMock(), restingHeartRate = restingHeartRate?.toMock(),
    healthCheck = healthCheck?.toMock(), bodyManagement = bodyManagement?.toMock()
)

fun HealthDashboardSnapshot.toMock() = HealthDashboardSnapshotMock(
    user_id = userId,
    scenario = sourceScenario.name,
    enabled_card_types = enabledCardTypes.map { it.name },
    dashboard_data = dashboardData?.toMock(),
    schema_version = schemaVersion
)

// ---- Proto Mock → Domain ----

fun DailySummaryMock.toDomain() = DailySummary(steps, calories, activeMinutes)
fun TodayActivityMock.toDomain() = TodayActivity(distanceKm, paceSecondsPerKm, activityNameKey?.let { LocalizedTextSpec(it) }, trainingLoad)
fun SleepStageSegmentMock.toDomain() = SleepStageSegment(runCatching { SleepStage.valueOf(stage) }.getOrDefault(SleepStage.Light), startMinute, durationMinutes)
fun SleepSummaryMock.toDomain() = SleepSummary(durationMinutes, qualityScore, startTime, endTime, stages.map { it.toDomain() })
fun TrainingLoadMock.toDomain() = TrainingLoad(value, recommendedMin, recommendedMax, dailyLoads)
fun RecoveryMock.toDomain() = Recovery(score, remainingHours)
fun WeeklyPlanMock.toDomain() = WeeklyPlan(hasPlan, plannedMinutes, description, currentDayIndex, dailyLoads, workoutNameKey?.let { LocalizedTextSpec(it) }, workoutDurationMinutes, workoutTrainingLoad)
fun TrainingAssessmentMock.toDomain() = TrainingAssessment(volumeScore, trend, shortTermLoad, longTermLoad, loadRatio, assessmentKey?.let { LocalizedTextSpec(it) }, explanationKey?.let { LocalizedTextSpec(it) })
fun RunningAbilityMock.toDomain() = RunningAbility(vo2max, score, displayScore, marathonSeconds)
fun CyclingAbilityMock.toDomain() = CyclingAbility(ftp, score, displayScore, abilityLabelKey?.let { LocalizedTextSpec(it) })
fun HeartRateMock.toDomain() = HeartRate(restingHr, currentHr, averageHr, samples)
fun StressMock.toDomain() = Stress(stressLevel, status, averageStress, samples)
fun HrvAssessmentMock.toDomain() = HrvAssessment(hrvScore, status, averageMs, normalMin, normalMax)
fun RestingHeartRateMock.toDomain() = RestingHeartRate(value, measuredTime, thirtyDayAverage, rangeMin, rangeMax)
fun HealthCheckMock.toDomain() = HealthCheck(overallScore, lastCheckDays, measuredTime, heartRate, hrvMs, stress, respiratoryRate, bloodOxygen)
fun BodyManagementMock.toDomain() = BodyManagement(weightKg, bodyFat, bmi, measuredDate, trainedMuscleGroups)

fun HealthDashboardMockData.toDomain() = HealthDashboardData(
    dailySummary = daily?.toDomain(), sleepSummary = sleep?.toDomain(),
    todayActivity = todayActivity?.toDomain(),
    trainingLoad = trainingLoad?.toDomain(), recovery = recovery?.toDomain(),
    weeklyPlan = weeklyPlan?.toDomain(), trainingAssessment = trainingAssessment?.toDomain(),
    runningAbility = runningAbility?.toDomain(), cyclingAbility = cyclingAbility?.toDomain(),
    heartRate = heartRate?.toDomain(), stress = stress?.toDomain(),
    hrvAssessment = hrvAssessment?.toDomain(), restingHeartRate = restingHeartRate?.toDomain(),
    healthCheck = healthCheck?.toDomain(), bodyManagement = bodyManagement?.toDomain()
)

fun HealthDashboardSnapshotMock.toDomain(): HealthDashboardSnapshot? {
    val scenario = runCatching { HealthMockScenario.valueOf(scenario) }.getOrDefault(HealthMockScenario.Normal)
    val types = enabled_card_types.mapNotNull { name -> runCatching { HealthCardType.valueOf(name) }.getOrNull() }
    return HealthDashboardSnapshot(
        userId = user_id,
        sourceScenario = scenario,
        enabledCardTypes = types.ifEmpty { DefaultHealthCardOrder },
        dashboardData = dashboard_data?.toDomain(),
        schemaVersion = schema_version
    )
}
