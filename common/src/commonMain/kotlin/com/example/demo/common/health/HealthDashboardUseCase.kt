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
            todayActivity = TodayActivity(8.41, 637, LocalizedTextSpec("health_visual_activity_easy_run"), 78),
            sleepSummary = SleepSummary(504, 86, "23:00", "08:40", normalSleepStages()),
            trainingLoad = TrainingLoad(246, 600, 800, listOf(22, 11, 22, 12, 0, 0, 0)),
            recovery = Recovery(95, 5),
            weeklyPlan = WeeklyPlan(
                true, 300, null, 3, listOf(0, 0, 0, 78, 0, 0, 0),
                LocalizedTextSpec("health_visual_workout_easy_run"), 102, 78
            ),
            trainingAssessment = TrainingAssessment(
                78, "increasing", 155, 138, 1.2,
                LocalizedTextSpec("health_visual_assessment_efficient"), LocalizedTextSpec("health_visual_assessment_efficient_detail")
            ),
            runningAbility = RunningAbility(52, 85, 78.6, 12_621),
            cyclingAbility = CyclingAbility(220, 72, 80.6, LocalizedTextSpec("health_visual_cycling_climber")),
            heartRate = HeartRate(55, 68, 81, normalHeartSamples()),
            stress = Stress(35, "normal", 52, normalStressSamples()),
            hrvAssessment = HrvAssessment(48, "low", 48, 52, 60),
            restingHeartRate = RestingHeartRate(58, "08:45", 52, 30, 80),
            healthCheck = HealthCheck(82, 0, "15:04", 91, 42, 45, 91, 91),
            bodyManagement = BodyManagement(68.2, 15.5, 22.3, "2022/8/7", listOf("chest", "quadriceps"))
        )
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
            heartRate = HeartRate(55, 68, 62, normalHeartSamples()),
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
            heartRate = HeartRate(92, 138, 108, abnormalHeartSamples()),
            stress = Stress(85, "high", 85, abnormalStressSamples()),
            hrvAssessment = HrvAssessment(32, "low", 32, 52, 60),
            restingHeartRate = RestingHeartRate(108, "08:45", 72),
            healthCheck = HealthCheck(35, 30, "15:04", 108, 28, 85, 24, 89),
            bodyManagement = BodyManagement(75.0, 25.0, 27.8, "2022/8/7", listOf("quadriceps"))
        )
        HealthMockScenario.ReadFailure -> error("handled above")
    }
}

private fun normalHeartSamples() = listOf(62, 65, 63, 68, 72, 70, 76, 74, 80, 84, 78, 92, 86, 81, 88, 79, 76, 82, 75, 72, 77, 70, 74, 68)
private fun abnormalHeartSamples() = listOf(92, 98, 105, 112, 108, 118, 125, 138, 132, 128, 145, 138, 134, 142, 130, 126, 136, 122, 118, 124, 116, 110, 120, 108)
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

class HealthDashboardUseCase(private val dataSource: HealthDashboardDataSource) {
    fun load(scenario: HealthMockScenario): MockResult<DashboardUiState> = when (val result = dataSource.load(scenario)) {
        is MockResult.Failure -> MockResult.Failure(result.error)
        is MockResult.Success -> MockResult.Success(toUiState(result.data))
    }

    fun toUiState(data: HealthDashboardData): DashboardUiState {
        val cards = listOf(
            weeklyPlanCard(data.weeklyPlan), activityCard(data.todayActivity), trainingCard(data.trainingLoad),
            trainingAssessmentCard(data.trainingAssessment), recoveryCard(data.recovery),
            runningAbilityCard(data.runningAbility), cyclingAbilityCard(data.cyclingAbility),
            heartRateCard(data.heartRate), stressCard(data.stress), sleepCard(data.sleepSummary),
            hrvAssessmentCard(data.hrvAssessment), restingHeartRateCard(data.restingHeartRate),
            healthCheckCard(data.healthCheck), bodyManagementCard(data.bodyManagement)
        ).sortedWith(compareBy<HealthCardUiModel> { it.priority }.thenBy { it.type.ordinal })
        return DashboardUiState(text("health_today"), text("health_demo_date"), data.dailySummary, cards)
    }

    private fun weeklyPlanCard(value: WeeklyPlan?): HealthCardUiModel = when {
        value == null -> empty(HealthCardType.WeeklyPlan, "health_summary_weekly_empty", HealthCardAction.ViewWeeklyPlan)
        value.hasPlan -> card(
            HealthCardType.WeeklyPlan,
            if (value.description.isNullOrBlank()) text("health_summary_weekly_ready", value.plannedMinutes ?: 0)
            else text("health_summary_weekly_custom", value.description),
            HealthCardStatus.Normal, HealthCardAction.ViewWeeklyPlan, 25, "health_reason_weekly_plan", weeklyVisual(value)
        )
        else -> card(
            HealthCardType.WeeklyPlan,
            if (value.description.isNullOrBlank()) text("health_summary_weekly_empty")
            else text("health_summary_weekly_custom", value.description),
            HealthCardStatus.Empty, HealthCardAction.ViewWeeklyPlan, 40, "health_reason_weekly_unknown", weeklyVisual(value)
        )
    }

    private fun recoveryCard(value: Recovery?): HealthCardUiModel {
        val score = value?.score
        return when {
            score == null -> empty(HealthCardType.Recovery, "health_summary_recovery_empty", HealthCardAction.ViewRecovery)
            score !in 0..100 || score < 40 -> card(HealthCardType.Recovery, text("health_summary_recovery_risk"), HealthCardStatus.Risk, HealthCardAction.ViewRecovery, 0, "health_reason_recovery_risk", recoveryVisual(value))
            else -> card(HealthCardType.Recovery, text("health_summary_recovery_normal", score, value.remainingHours ?: 0), HealthCardStatus.Normal, HealthCardAction.ViewRecovery, 20, "health_reason_recovery_today", recoveryVisual(value))
        }
    }

    private fun sleepCard(value: SleepSummary?): HealthCardUiModel {
        val minutes = value?.durationMinutes
        return when {
            minutes == null -> empty(HealthCardType.Sleep, "health_summary_sleep_empty", HealthCardAction.ViewSleep)
            minutes !in 60..900 || (value.qualityScore ?: 100) < 40 -> card(HealthCardType.Sleep, text("health_summary_sleep_risk"), HealthCardStatus.Risk, HealthCardAction.ViewSleep, 1, "health_reason_sleep_risk", sleepVisual(value))
            else -> card(HealthCardType.Sleep, text("health_summary_sleep_normal", minutes / 60, minutes % 60, value.qualityScore ?: 0), HealthCardStatus.Normal, HealthCardAction.ViewSleep, 21, "health_reason_sleep_today", sleepVisual(value))
        }
    }

    private fun activityCard(value: TodayActivity?): HealthCardUiModel = when {
        value == null || value.distanceKm == null -> empty(HealthCardType.TodayActivity, "health_summary_activity_empty", HealthCardAction.ViewActivity)
        else -> card(
            HealthCardType.TodayActivity,
            text("health_summary_activity_detail", value.distanceKm.f2(), pace(value.paceSecondsPerKm)),
            HealthCardStatus.Normal, HealthCardAction.ViewActivity, 22, "health_reason_activity_today", activityVisual(value)
        )
    }

    private fun trainingCard(value: TrainingLoad?): HealthCardUiModel {
        val load = value?.value
        return when {
            load == null -> empty(HealthCardType.TrainingLoad, "health_summary_training_load_empty", HealthCardAction.ViewTrainingLoad)
            load < 0 || load > value.recommendedMax -> card(HealthCardType.TrainingLoad, text("health_summary_training_load_risk", load), HealthCardStatus.Risk, HealthCardAction.ViewTrainingLoad, 2, "health_reason_training_load_risk", trainingLoadVisual(value))
            else -> card(HealthCardType.TrainingLoad, text("health_summary_training_load_normal", load, value.recommendedMin, value.recommendedMax), HealthCardStatus.Normal, HealthCardAction.ViewTrainingLoad, 30, "health_reason_trend", trainingLoadVisual(value))
        }
    }

    private fun trainingAssessmentCard(value: TrainingAssessment?): HealthCardUiModel = when {
        value == null || value.volumeScore == null -> empty(HealthCardType.TrainingAssessment, "health_summary_training_assessment_empty", HealthCardAction.ViewTrainingAssessment)
        value.volumeScore < 30 -> card(HealthCardType.TrainingAssessment, text("health_summary_training_assessment_risk", value.volumeScore, value.trend ?: "---"), HealthCardStatus.Risk, HealthCardAction.ViewTrainingAssessment, 3, "health_reason_training_assessment_risk", assessmentVisual(value))
        else -> card(HealthCardType.TrainingAssessment, text("health_summary_training_assessment_normal", value.volumeScore, value.trend ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewTrainingAssessment, 23, "health_reason_training_assessment_data", assessmentVisual(value))
    }

    private fun runningAbilityCard(value: RunningAbility?): HealthCardUiModel = when {
        value == null || value.vo2max == null -> empty(HealthCardType.RunningAbility, "health_summary_running_empty", HealthCardAction.ViewRunningAbility)
        value.score != null && value.score < 30 -> card(HealthCardType.RunningAbility, text("health_summary_running_risk", value.vo2max, value.score), HealthCardStatus.Risk, HealthCardAction.ViewRunningAbility, 4, "health_reason_running_risk", runningVisual(value))
        else -> card(HealthCardType.RunningAbility, text("health_summary_running_normal", value.vo2max, value.score ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewRunningAbility, 24, "health_reason_running_data", runningVisual(value))
    }

    private fun cyclingAbilityCard(value: CyclingAbility?): HealthCardUiModel = when {
        value == null || value.ftp == null -> empty(HealthCardType.CyclingAbility, "health_summary_cycling_empty", HealthCardAction.ViewCyclingAbility)
        value.score != null && value.score < 30 -> card(HealthCardType.CyclingAbility, text("health_summary_cycling_risk", value.ftp, value.score), HealthCardStatus.Risk, HealthCardAction.ViewCyclingAbility, 5, "health_reason_cycling_risk", cyclingVisual(value))
        else -> card(HealthCardType.CyclingAbility, text("health_summary_cycling_normal", value.ftp, value.score ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewCyclingAbility, 25, "health_reason_cycling_data", cyclingVisual(value))
    }

    private fun heartRateCard(value: HeartRate?): HealthCardUiModel = when {
        value == null || value.restingHr == null -> empty(HealthCardType.HeartRate, "health_summary_heart_rate_empty", HealthCardAction.ViewHeartRate)
        value.restingHr > 90 || value.currentHr != null && value.currentHr > 160 -> card(HealthCardType.HeartRate, text("health_summary_heart_rate_risk", value.restingHr, value.currentHr ?: "---"), HealthCardStatus.Risk, HealthCardAction.ViewHeartRate, 6, "health_reason_heart_rate_risk", heartVisual(value))
        else -> card(HealthCardType.HeartRate, text("health_summary_heart_rate_normal", value.restingHr, value.currentHr ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewHeartRate, 26, "health_reason_heart_rate_data", heartVisual(value))
    }

    private fun stressCard(value: Stress?): HealthCardUiModel = when {
        value == null || value.stressLevel == null -> empty(HealthCardType.Stress, "health_summary_stress_empty", HealthCardAction.ViewStress)
        value.stressLevel > 80 -> card(HealthCardType.Stress, text("health_summary_stress_risk", value.stressLevel, value.status ?: "---"), HealthCardStatus.Risk, HealthCardAction.ViewStress, 7, "health_reason_stress_risk", stressVisual(value))
        else -> card(HealthCardType.Stress, text("health_summary_stress_normal", value.stressLevel, value.status ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewStress, 27, "health_reason_stress_data", stressVisual(value))
    }

    private fun hrvAssessmentCard(value: HrvAssessment?): HealthCardUiModel = when {
        value == null || value.hrvScore == null -> empty(HealthCardType.HrvAssessment, "health_summary_hrv_empty", HealthCardAction.ViewHrvAssessment)
        value.hrvScore < 40 -> card(HealthCardType.HrvAssessment, text("health_summary_hrv_risk", value.hrvScore, value.status ?: "---"), HealthCardStatus.Risk, HealthCardAction.ViewHrvAssessment, 8, "health_reason_hrv_risk", hrvVisual(value))
        else -> card(HealthCardType.HrvAssessment, text("health_summary_hrv_normal", value.hrvScore, value.status ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewHrvAssessment, 28, "health_reason_hrv_data", hrvVisual(value))
    }

    private fun restingHeartRateCard(value: RestingHeartRate?): HealthCardUiModel = when {
        value == null || value.value == null -> empty(HealthCardType.RestingHeartRate, "health_summary_resting_hr_empty", HealthCardAction.ViewRestingHeartRate)
        value.value > 100 -> card(HealthCardType.RestingHeartRate, text("health_summary_resting_hr_risk", value.value), HealthCardStatus.Risk, HealthCardAction.ViewRestingHeartRate, 9, "health_reason_resting_hr_risk", restingHeartVisual(value))
        else -> card(HealthCardType.RestingHeartRate, text("health_summary_resting_hr_normal", value.value), HealthCardStatus.Normal, HealthCardAction.ViewRestingHeartRate, 29, "health_reason_resting_hr_data", restingHeartVisual(value))
    }

    private fun healthCheckCard(value: HealthCheck?): HealthCardUiModel = when {
        value == null || value.overallScore == null -> empty(HealthCardType.HealthCheck, "health_summary_health_check_empty", HealthCardAction.ViewHealthCheck)
        value.overallScore < 40 -> card(HealthCardType.HealthCheck, text("health_summary_health_check_risk", value.overallScore, value.lastCheckDays ?: 0), HealthCardStatus.Risk, HealthCardAction.ViewHealthCheck, 10, "health_reason_health_check_risk", healthCheckVisual(value))
        else -> card(HealthCardType.HealthCheck, text("health_summary_health_check_normal", value.overallScore, value.lastCheckDays ?: 0), HealthCardStatus.Normal, HealthCardAction.ViewHealthCheck, 31, "health_reason_health_check_data", healthCheckVisual(value))
    }

    private fun bodyManagementCard(value: BodyManagement?): HealthCardUiModel = when {
        value == null || value.weightKg == null -> empty(HealthCardType.BodyManagement, "health_summary_body_empty", HealthCardAction.ViewBodyManagement)
        value.bmi != null && (value.bmi > 28 || value.bmi < 16) -> card(HealthCardType.BodyManagement, text("health_summary_body_risk", value.weightKg, value.bmi.f1()), HealthCardStatus.Risk, HealthCardAction.ViewBodyManagement, 11, "health_reason_body_risk", bodyVisual(value))
        else -> card(HealthCardType.BodyManagement, text("health_summary_body_normal", value.weightKg, value.bmi?.f1() ?: "---"), HealthCardStatus.Normal, HealthCardAction.ViewBodyManagement, 32, "health_reason_body_data", bodyVisual(value))
    }

    private fun activityVisual(value: TodayActivity) = HealthCardVisualData(
        kind = HealthCardVisualKind.TodayActivity,
        primaryValue = value.distanceKm?.f2(),
        primaryUnit = text("health_unit_kilometers"),
        secondaryValue = pace(value.paceSecondsPerKm),
        caption = value.activityName,
        detail = text("health_visual_activity_pace", pace(value.paceSecondsPerKm)),
        metrics = value.trainingLoad?.let { listOf(HealthMetric(text("health_visual_training_load_short"), it.toString())) }.orEmpty(),
        assetKey = "activity_map_mock"
    )

    private fun weeklyVisual(value: WeeklyPlan) = HealthCardVisualData(
        kind = HealthCardVisualKind.WeeklyPlan,
        primaryValue = value.workoutDurationMinutes?.toString(),
        primaryUnit = text("health_unit_minutes_long"),
        caption = value.workoutName,
        chartPoints = dayPoints(value.dailyLoads),
        metrics = value.workoutTrainingLoad?.let { listOf(HealthMetric(text("health_visual_training_load_short"), it.toString())) }.orEmpty(),
        highlightedIndex = value.currentDayIndex
    )

    private fun trainingLoadVisual(value: TrainingLoad) = HealthCardVisualData(
        kind = HealthCardVisualKind.TrainingLoad,
        primaryValue = value.value?.toString(),
        caption = text("health_visual_recommended_range", value.recommendedMin, value.recommendedMax),
        chartPoints = dayPoints(value.dailyLoads)
    )

    private fun assessmentVisual(value: TrainingAssessment) = HealthCardVisualData(
        kind = HealthCardVisualKind.TrainingAssessment,
        primaryValue = value.assessment?.key,
        caption = value.assessment,
        detail = value.explanation,
        metrics = listOfNotNull(
            value.shortTermLoad?.let { HealthMetric(text("health_visual_short_term_load"), it.toString()) },
            value.longTermLoad?.let { HealthMetric(text("health_visual_long_term_load"), it.toString()) },
            value.loadRatio?.let { HealthMetric(text("health_visual_load_ratio"), it.f1()) }
        )
    )

    private fun recoveryVisual(value: Recovery) = HealthCardVisualData(
        kind = HealthCardVisualKind.RecoveryGauge,
        primaryValue = value.score?.toString(),
        primaryUnit = text("health_unit_percent"),
        caption = text("health_visual_recovery_after_hours", value.remainingHours ?: 0),
        progress = value.score?.coerceIn(0, 100)?.div(100.0)
    )

    private fun runningVisual(value: RunningAbility) = HealthCardVisualData(
        kind = HealthCardVisualKind.AbilityGauge,
        primaryValue = (value.displayScore ?: value.score?.toDouble())?.f1(),
        caption = value.marathonSeconds?.let { text("health_visual_marathon_prediction", marathon(it)) },
        progress = value.displayScore?.div(100.0) ?: value.score?.div(100.0)
    )

    private fun cyclingVisual(value: CyclingAbility) = HealthCardVisualData(
        kind = HealthCardVisualKind.AbilityGauge,
        primaryValue = (value.displayScore ?: value.score?.toDouble())?.f1(),
        caption = value.abilityLabel,
        progress = value.displayScore?.div(100.0) ?: value.score?.div(100.0)
    )

    private fun heartVisual(value: HeartRate) = HealthCardVisualData(
        kind = HealthCardVisualKind.TrendBars,
        primaryValue = (value.averageHr ?: value.currentHr ?: value.restingHr)?.toString(),
        primaryUnit = text("health_unit_bpm"),
        caption = text("health_visual_average_heart_rate"),
        chartPoints = value.samples.mapIndexed { index, sample -> HealthChartPoint(index.toString(), sample.toDouble()) }
    )

    private fun stressVisual(value: Stress) = HealthCardVisualData(
        kind = HealthCardVisualKind.TrendBars,
        primaryValue = (value.averageStress ?: value.stressLevel)?.toString(),
        caption = text("health_visual_average_stress"),
        chartPoints = value.samples.mapIndexed { index, sample ->
            HealthChartPoint(index.toString(), sample.toDouble(), stressLevel(sample))
        }
    )

    private fun sleepVisual(value: SleepSummary): HealthCardVisualData {
        val minutes = value.durationMinutes ?: 0
        return HealthCardVisualData(
            kind = HealthCardVisualKind.SleepStages,
            primaryValue = (minutes / 60).toString(), primaryUnit = text("health_unit_hours_short"),
            secondaryValue = (minutes % 60).toString(), secondaryUnit = text("health_unit_minutes_short"),
            sleepStages = value.stages, startTime = value.startTime, endTime = value.endTime
        )
    }

    private fun hrvVisual(value: HrvAssessment): HealthCardVisualData {
        val current = (value.averageMs ?: value.hrvScore ?: 0).toDouble()
        return HealthCardVisualData(
            kind = HealthCardVisualKind.RangeIndicator,
            primaryValue = current.toInt().toString(), primaryUnit = text("health_unit_milliseconds"),
            caption = text(if (current < (value.normalMin ?: 0)) "health_visual_hrv_low" else "health_visual_hrv_balanced"),
            detail = text("health_visual_hrv_average", current.toInt()),
            range = HealthRange(30.0, 80.0, current, value.normalMin?.toDouble(), value.normalMax?.toDouble())
        )
    }

    private fun restingHeartVisual(value: RestingHeartRate): HealthCardVisualData {
        val current = (value.value ?: 0).toDouble()
        return HealthCardVisualData(
            kind = HealthCardVisualKind.RangeIndicator,
            primaryValue = current.toInt().toString(), primaryUnit = text("health_unit_bpm"),
            caption = text("health_visual_measured_at", value.measuredTime ?: "---"),
            detail = text("health_visual_thirty_day_average", value.thirtyDayAverage ?: 0),
            range = HealthRange(value.rangeMin.toDouble(), value.rangeMax.toDouble(), current, average = value.thirtyDayAverage?.toDouble())
        )
    }

    private fun healthCheckVisual(value: HealthCheck) = HealthCardVisualData(
        kind = HealthCardVisualKind.HealthCheckGrid,
        caption = text("health_visual_measured_at", value.measuredTime ?: "---"),
        metrics = listOfNotNull(
            value.heartRate?.let { HealthMetric(text("health_visual_heart_rate"), it.toString(), text("health_unit_bpm")) },
            value.hrvMs?.let { HealthMetric(text("health_visual_hrv"), it.toString(), text("health_unit_milliseconds")) },
            value.stress?.let { HealthMetric(text("health_visual_stress"), it.toString()) },
            value.respiratoryRate?.let { HealthMetric(text("health_visual_respiratory_rate"), it.toString(), text("health_unit_per_minute")) },
            value.bloodOxygen?.let { HealthMetric(text("health_visual_blood_oxygen"), it.toString(), text("health_unit_percent")) }
        )
    )

    private fun bodyVisual(value: BodyManagement) = HealthCardVisualData(
        kind = HealthCardVisualKind.BodyMap,
        primaryValue = value.weightKg?.f1(), primaryUnit = text("health_unit_kilograms"),
        caption = text("health_visual_weight"),
        detail = text("health_visual_measured_date", value.measuredDate ?: "---"),
        metrics = value.trainedMuscleGroups.map { HealthMetric(text("health_visual_muscle_$it"), "") },
        assetKey = "body_muscle_front_back"
    )

    private fun emptyVisual(type: HealthCardType) = HealthCardVisualData(
        kind = when (type) {
            HealthCardType.TodayActivity -> HealthCardVisualKind.TodayActivity
            HealthCardType.WeeklyPlan -> HealthCardVisualKind.WeeklyPlan
            HealthCardType.TrainingLoad -> HealthCardVisualKind.TrainingLoad
            HealthCardType.TrainingAssessment -> HealthCardVisualKind.TrainingAssessment
            HealthCardType.Recovery -> HealthCardVisualKind.RecoveryGauge
            HealthCardType.RunningAbility, HealthCardType.CyclingAbility -> HealthCardVisualKind.AbilityGauge
            HealthCardType.HeartRate, HealthCardType.Stress -> HealthCardVisualKind.TrendBars
            HealthCardType.Sleep -> HealthCardVisualKind.SleepStages
            HealthCardType.HrvAssessment, HealthCardType.RestingHeartRate -> HealthCardVisualKind.RangeIndicator
            HealthCardType.HealthCheck -> HealthCardVisualKind.HealthCheckGrid
            HealthCardType.BodyManagement -> HealthCardVisualKind.BodyMap
        }
    )

    private fun dayPoints(values: List<Int>) = values.mapIndexed { index, value ->
        HealthChartPoint("health_visual_day_${listOf("mon", "tue", "wed", "thu", "fri", "sat", "sun").getOrElse(index) { "mon" }}", value.toDouble())
    }

    private fun stressLevel(value: Int) = when {
        value >= 80 -> HealthVisualLevel.High
        value >= 60 -> HealthVisualLevel.Elevated
        value >= 35 -> HealthVisualLevel.Good
        else -> HealthVisualLevel.Low
    }

    private fun empty(type: HealthCardType, summaryKey: String, action: HealthCardAction) =
        card(type, text(summaryKey), HealthCardStatus.Empty, action, 80 + type.ordinal, "health_reason_missing", emptyVisual(type))

    private fun card(
        type: HealthCardType,
        summary: LocalizedTextSpec,
        status: HealthCardStatus,
        action: HealthCardAction,
        priority: Int,
        priorityReason: String,
        visual: HealthCardVisualData
    ) = HealthCardUiModel(type, title(type), summary, status, action, priority, priorityReason, visual)

    private fun title(type: HealthCardType) = text(
        when (type) {
            HealthCardType.WeeklyPlan -> "health_card_weekly_plan_title"
            HealthCardType.TodayActivity -> "health_card_today_activity_title"
            HealthCardType.TrainingLoad -> "health_card_training_load_title"
            HealthCardType.TrainingAssessment -> "health_card_training_assessment_title"
            HealthCardType.Recovery -> "health_card_recovery_title"
            HealthCardType.RunningAbility -> "health_card_running_ability_title"
            HealthCardType.CyclingAbility -> "health_card_cycling_ability_title"
            HealthCardType.HeartRate -> "health_card_heart_rate_title"
            HealthCardType.Stress -> "health_card_stress_title"
            HealthCardType.Sleep -> "health_card_sleep_title"
            HealthCardType.HrvAssessment -> "health_card_hrv_assessment_title"
            HealthCardType.RestingHeartRate -> "health_card_resting_heart_rate_title"
            HealthCardType.HealthCheck -> "health_card_health_check_title"
            HealthCardType.BodyManagement -> "health_card_body_management_title"
        }
    )

    private fun text(key: String, vararg arguments: Any?) =
        LocalizedTextSpec(key, arguments.map { it?.toString() ?: "---" })
}

private fun Double.f1(): String {
    val v = (this * 10).toLong()
    return "${v / 10}.${v % 10}"
}

private fun Double.f2(): String {
    val v = (this * 100).toLong()
    return "${v / 100}.${(v % 100).toString().padStart(2, '0')}"
}

private fun pace(seconds: Int?): String {
    if (seconds == null || seconds <= 0) return "---"
    return "${seconds / 60}'${(seconds % 60).toString().padStart(2, '0')}\"/km"
}

private fun marathon(seconds: Int): String {
    val hours = seconds / 3600
    val minutes = (seconds % 3600) / 60
    val remaining = seconds % 60
    return "$hours:${minutes.toString().padStart(2, '0')}:${remaining.toString().padStart(2, '0')}"
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
                    when (val generated = dashboardDataSource.load(scenario)) {
                        is MockResult.Failure -> MockResult.Failure(generated.error)
                        is MockResult.Success -> {
                            val updated = resolved.data.copy(
                                sourceScenario = scenario,
                                dashboardData = generated.data,
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

    fun clear(userId: String): Boolean {
        pendingScenarios.remove(userId)
        return stateDataSource.clear(userId)
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

    private fun resolveSnapshot(userId: String): MockResult<HealthDashboardSnapshot> {
        val stored = stateDataSource.load(userId)
        if (stored?.dashboardData != null) return MockResult.Success(stored)
        val sourceScenario = stored?.sourceScenario ?: HealthMockScenario.Normal
        return when (val generated = dashboardDataSource.load(sourceScenario)) {
            is MockResult.Failure -> MockResult.Failure(generated.error)
            is MockResult.Success -> {
                val migrated = (stored ?: HealthDashboardSnapshot(userId)).copy(
                    sourceScenario = sourceScenario,
                    dashboardData = generated.data,
                    schemaVersion = CurrentHealthDashboardSchemaVersion
                )
                if (!stateDataSource.save(migrated)) MockResult.Failure(MockError.PersistFailed)
                else MockResult.Success(migrated)
            }
        }
    }

    private fun HealthDashboardSnapshot.toPersistedDashboard(): MockResult<PersistedDashboard> {
        val data = dashboardData ?: return MockResult.Failure(MockError.CorruptedData)
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
