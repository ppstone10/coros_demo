package com.example.demo.common.health

data class DailySummaryMock(val steps: Int? = null, val calories: Int? = null, val activeMinutes: Int? = null)
data class SleepSummaryMock(val durationMinutes: Int? = null, val qualityScore: Int? = null)
data class TrainingLoadMock(val value: Int? = null, val recommendedMin: Int = 300, val recommendedMax: Int = 700)
data class RecoveryMock(val score: Int? = null, val remainingHours: Int? = null)
data class WeeklyPlanMock(val hasPlan: Boolean = false, val plannedMinutes: Int? = null, val description: String? = null)
data class TrainingAssessmentMock(val volumeScore: Int? = null, val trend: String? = null)
data class RunningAbilityMock(val vo2max: Int? = null, val score: Int? = null)
data class CyclingAbilityMock(val ftp: Int? = null, val score: Int? = null)
data class HeartRateMock(val restingHr: Int? = null, val currentHr: Int? = null)
data class StressMock(val stressLevel: Int? = null, val status: String? = null)
data class HrvAssessmentMock(val hrvScore: Int? = null, val status: String? = null)
data class RestingHeartRateMock(val value: Int? = null)
data class HealthCheckMock(val overallScore: Int? = null, val lastCheckDays: Int? = null)
data class BodyManagementMock(val weightKg: Double? = null, val bodyFat: Double? = null, val bmi: Double? = null)

data class HealthDashboardMockData(
    val daily: DailySummaryMock? = null, val sleep: SleepSummaryMock? = null,
    val trainingLoad: TrainingLoadMock? = null, val recovery: RecoveryMock? = null,
    val weeklyPlan: WeeklyPlanMock? = null, val trainingAssessment: TrainingAssessmentMock? = null,
    val runningAbility: RunningAbilityMock? = null, val cyclingAbility: CyclingAbilityMock? = null,
    val heartRate: HeartRateMock? = null, val stress: StressMock? = null,
    val hrvAssessment: HrvAssessmentMock? = null, val restingHeartRate: RestingHeartRateMock? = null,
    val healthCheck: HealthCheckMock? = null, val bodyManagement: BodyManagementMock? = null
)

data class HealthDashboardSnapshotMock(
    val user_id: String, val scenario: String, val enabled_card_types: List<String>
)

// ---- Domain → Proto Mock ----

fun DailySummary.toMock() = DailySummaryMock(steps, calories, activeMinutes)
fun SleepSummary.toMock() = SleepSummaryMock(durationMinutes, qualityScore)
fun TrainingLoad.toMock() = TrainingLoadMock(value, recommendedMin, recommendedMax)
fun Recovery.toMock() = RecoveryMock(score, remainingHours)
fun WeeklyPlan.toMock() = WeeklyPlanMock(hasPlan, plannedMinutes, description)
fun TrainingAssessment.toMock() = TrainingAssessmentMock(volumeScore, trend)
fun RunningAbility.toMock() = RunningAbilityMock(vo2max, score)
fun CyclingAbility.toMock() = CyclingAbilityMock(ftp, score)
fun HeartRate.toMock() = HeartRateMock(restingHr, currentHr)
fun Stress.toMock() = StressMock(stressLevel, status)
fun HrvAssessment.toMock() = HrvAssessmentMock(hrvScore, status)
fun RestingHeartRate.toMock() = RestingHeartRateMock(value)
fun HealthCheck.toMock() = HealthCheckMock(overallScore, lastCheckDays)
fun BodyManagement.toMock() = BodyManagementMock(weightKg, bodyFat, bmi)

fun HealthDashboardData.toMock() = HealthDashboardMockData(
    daily = dailySummary?.toMock(), sleep = sleepSummary?.toMock(),
    trainingLoad = trainingLoad?.toMock(), recovery = recovery?.toMock(),
    weeklyPlan = weeklyPlan?.toMock(), trainingAssessment = trainingAssessment?.toMock(),
    runningAbility = runningAbility?.toMock(), cyclingAbility = cyclingAbility?.toMock(),
    heartRate = heartRate?.toMock(), stress = stress?.toMock(),
    hrvAssessment = hrvAssessment?.toMock(), restingHeartRate = restingHeartRate?.toMock(),
    healthCheck = healthCheck?.toMock(), bodyManagement = bodyManagement?.toMock()
)

fun HealthDashboardSnapshot.toMock() = HealthDashboardSnapshotMock(
    user_id = userId, scenario = scenario.name, enabled_card_types = enabledCardTypes.map { it.name }
)

// ---- Proto Mock → Domain ----

fun DailySummaryMock.toDomain() = DailySummary(steps, calories, activeMinutes)
fun SleepSummaryMock.toDomain() = SleepSummary(durationMinutes, qualityScore)
fun TrainingLoadMock.toDomain() = TrainingLoad(value, recommendedMin, recommendedMax)
fun RecoveryMock.toDomain() = Recovery(score, remainingHours)
fun WeeklyPlanMock.toDomain() = WeeklyPlan(hasPlan, plannedMinutes, description)
fun TrainingAssessmentMock.toDomain() = TrainingAssessment(volumeScore, trend)
fun RunningAbilityMock.toDomain() = RunningAbility(vo2max, score)
fun CyclingAbilityMock.toDomain() = CyclingAbility(ftp, score)
fun HeartRateMock.toDomain() = HeartRate(restingHr, currentHr)
fun StressMock.toDomain() = Stress(stressLevel, status)
fun HrvAssessmentMock.toDomain() = HrvAssessment(hrvScore, status)
fun RestingHeartRateMock.toDomain() = RestingHeartRate(value)
fun HealthCheckMock.toDomain() = HealthCheck(overallScore, lastCheckDays)
fun BodyManagementMock.toDomain() = BodyManagement(weightKg, bodyFat, bmi)

fun HealthDashboardMockData.toDomain() = HealthDashboardData(
    dailySummary = daily?.toDomain(), sleepSummary = sleep?.toDomain(),
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
    return HealthDashboardSnapshot(user_id, scenario, types.ifEmpty { DefaultHealthCardOrder })
}
