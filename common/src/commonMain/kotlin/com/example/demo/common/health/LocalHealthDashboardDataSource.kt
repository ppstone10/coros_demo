package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult

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
        HealthMockScenario.Normal -> normalDashboardData(SimulatedHeartRateSamples.normal3)
        HealthMockScenario.PartialMissing -> HealthDashboardData(
            dailySummary = DailySummary(null, 310, 32),
            todayActivity = TodayActivity(5.2, 390, LocalizedTextSpec("health_visual_activity_easy_run"), 45),
            sleepSummary = null,
            trainingLoad = TrainingLoad(526, 300, 700, listOf(42, 70, 64, 81, 95, 84, 90)),
            recovery = Recovery(78, 14),
            weeklyPlan = null,
            trainingAssessment = null,
            runningAbility = RunningAbility(52, 85, 78.6, 12_621),
            cyclingAbility = null,
            heartRate = heartRateFromSamples(SimulatedHeartRateSamples.normal2, restingHr = 55),
            stress = null,
            hrvAssessment = null,
            restingHeartRate = RestingHeartRate(55, "08:45", 52),
            healthCheck = null,
            bodyManagement = BodyManagement(68.2, 15.5, 22.3, "2022/8/7", listOf("chest"))
        )
        HealthMockScenario.AllEmpty -> HealthDashboardData(null, null, null, null)
        HealthMockScenario.Abnormal -> HealthDashboardData(
            dailySummary = DailySummary(12_000, 900, 85),
            todayActivity = TodayActivity(12.4, 330, LocalizedTextSpec("health_visual_activity_tempo_run"), 160),
            sleepSummary = SleepSummary(180, 34, "02:10", "05:10", abnormalSleepStages()),
            trainingLoad = TrainingLoad(1_120, 300, 700, listOf(95, 120, 160, 210, 185, 230, 220)),
            recovery = Recovery(22, 36),
            weeklyPlan = WeeklyPlan(false, null, null),
            trainingAssessment = TrainingAssessment(25, "declining", 240, 130, 1.8, LocalizedTextSpec("health_visual_assessment_overload"), LocalizedTextSpec("health_visual_assessment_overload_detail")),
            runningAbility = RunningAbility(38, 28, 38.0, 15_300),
            cyclingAbility = CyclingAbility(150, 25, 25.0, LocalizedTextSpec("health_visual_cycling_beginner")),
            heartRate = heartRateFromSamples(SimulatedHeartRateSamples.abnormal, restingHr = 92),
            stress = Stress(85, "high", 85, abnormalStressSamples()),
            hrvAssessment = HrvAssessment(32, "low", 32, 52, 60),
            restingHeartRate = RestingHeartRate(108, "08:45", 72),
            healthCheck = HealthCheck(35, 30, "15:04", 108, 28, 85, 24, 89),
            bodyManagement = BodyManagement(75.0, 25.0, 27.8, "2022/8/7", listOf("quadriceps"))
        )
        HealthMockScenario.ReadFailure -> error("handled above")
    }

    private fun normalDashboardData(heartSamples: List<Int>) = HealthDashboardData(
            dailySummary = DailySummary(8769, 769, 69),
            todayActivity = TodayActivity(8.41, 637, LocalizedTextSpec("health_visual_activity_easy_run"), 78),
            sleepSummary = SleepSummary(504, 86, "23:00", "08:40", normalSleepStages()),
            trainingLoad = TrainingLoad(246, 600, 800, listOf(22, 11, 22, 12, 0, 0, 0)),
            recovery = Recovery(95, 5),
            weeklyPlan = WeeklyPlan(
                true, 300, null, 3, listOf(0, 35, 0, 78, 0, 90, 110),
                LocalizedTextSpec("health_visual_workout_easy_run"), 102, 78,
                dayPlans = normalWeeklyDayPlans()
            ),
            trainingAssessment = TrainingAssessment(
                78, "increasing", 155, 138, 1.2,
                LocalizedTextSpec("health_visual_assessment_efficient"), LocalizedTextSpec("health_visual_assessment_efficient_detail")
            ),
            runningAbility = RunningAbility(52, 85, 78.6, 12_621),
            cyclingAbility = CyclingAbility(220, 72, 80.6, LocalizedTextSpec("health_visual_cycling_climber")),
            heartRate = heartRateFromSamples(heartSamples, restingHr = 55),
            stress = Stress(35, "normal", 52, normalStressSamples()),
            hrvAssessment = HrvAssessment(48, "low", 48, 52, 60),
            restingHeartRate = RestingHeartRate(58, "08:45", 52, 30, 80),
            healthCheck = HealthCheck(82, 0, "15:04", 91, 42, 45, 91, 91),
            bodyManagement = BodyManagement(68.2, 15.5, 22.3, "2022/8/7", listOf("chest", "quadriceps"))
        )
}

private fun heartRateFromSamples(samples: List<Int>, restingHr: Int): HeartRate = HeartRate(
    restingHr = restingHr,
    currentHr = samples.lastOrNull(),
    averageHr = samples.takeIf { it.isNotEmpty() }?.let { (it.sum() + it.size / 2) / it.size },
    intervals = aggregateFiveMinuteHeartSamples(samples),
    fiveMinuteSamples = samples
)
private fun normalWeeklyDayPlans() = listOf(
    WeeklyDayPlan(0),
    WeeklyDayPlan(1, LocalizedTextSpec("health_visual_workout_easy_run"), 45, 35),
    WeeklyDayPlan(2),
    WeeklyDayPlan(3, LocalizedTextSpec("health_visual_workout_easy_run"), 102, 78),
    WeeklyDayPlan(4),
    WeeklyDayPlan(5, LocalizedTextSpec("health_visual_activity_tempo_run"), 60, 90),
    WeeklyDayPlan(6, LocalizedTextSpec("health_visual_workout_easy_run"), 93, 110)
)
private fun normalStressSamples() = listOf(18, 20, 22, 25, 28, 32, 38, 45, 52, 61, 74, 86, 78, 64, 52, 40, 34, 48, 58, 42, 30, 25, 22, 20)
private fun abnormalStressSamples() = listOf(62, 68, 72, 78, 84, 90, 95, 88, 92, 97, 91, 86, 94, 98, 92, 89, 96, 90, 87, 93, 88, 84, 90, 86)
private fun normalSleepStages() = listOf(
    SleepStageSegment(SleepStage.Awake, 0, 18), SleepStageSegment(SleepStage.Light, 18, 72),
    SleepStageSegment(SleepStage.Deep, 90, 55), SleepStageSegment(SleepStage.Light, 145, 74),
    SleepStageSegment(SleepStage.Rem, 219, 42), SleepStageSegment(SleepStage.Light, 261, 65),
    SleepStageSegment(SleepStage.Deep, 326, 38), SleepStageSegment(SleepStage.Light, 364, 77),
    SleepStageSegment(SleepStage.Rem, 441, 45), SleepStageSegment(SleepStage.Awake, 486, 18)
)
private fun abnormalSleepStages() = listOf(
    SleepStageSegment(SleepStage.Awake, 0, 30), SleepStageSegment(SleepStage.Light, 30, 40),
    SleepStageSegment(SleepStage.Awake, 70, 25), SleepStageSegment(SleepStage.Light, 95, 35),
    SleepStageSegment(SleepStage.Rem, 130, 20), SleepStageSegment(SleepStage.Awake, 150, 30)
)
