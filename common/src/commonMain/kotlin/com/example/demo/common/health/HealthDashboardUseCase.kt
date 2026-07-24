package com.example.demo.common.health

import com.example.demo.common.login.MockResult

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
}
