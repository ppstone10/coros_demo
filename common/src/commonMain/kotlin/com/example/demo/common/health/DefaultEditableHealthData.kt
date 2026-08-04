package com.example.demo.common.health

object DefaultEditableHealthData {
    val value: EditableHealthData by lazy {
        EditableHealthData(
            dailySummary = DailySummaryInput(8_769, 769, 69),
            todayActivity = TodayActivityInput(8.41, 637),
            weeklyPlan = WeeklyPlanInput(
                listOf(
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
                    WeeklyWorkoutInput(WorkoutType.Easy, 4.5),
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
                    WeeklyWorkoutInput(WorkoutType.Easy, 10.2),
                    WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
                    WeeklyWorkoutInput(WorkoutType.Tempo, 10.0),
                    WeeklyWorkoutInput(WorkoutType.Easy, 9.3)
                )
            ),
            trainingLoad = TrainingLoadInput(listOf(22, 11, 22, 12, 0, 0, 0)),
            assessment = TrainingAssessmentInput(155, 138),
            recovery = RecoveryInput(95),
            runningAbility = RunningAbilityInput(79),
            cyclingAbility = CyclingAbilityInput(81),
            heartRate = HeartRateInput(SimulatedHeartRateSamples.normal3),
            stress = StressInput(
                HealthEditableRules.generateStressSamples(45, StressPattern.Normal)
            ),
            sleep = SleepInput(
                startMinuteOfDay = 23 * 60,
                stages = listOf(
                    SleepStageInput(SleepStage.Awake, 0, 18),
                    SleepStageInput(SleepStage.Light, 18, 72),
                    SleepStageInput(SleepStage.Deep, 90, 55),
                    SleepStageInput(SleepStage.Light, 145, 74),
                    SleepStageInput(SleepStage.Rem, 219, 42),
                    SleepStageInput(SleepStage.Light, 261, 65),
                    SleepStageInput(SleepStage.Deep, 326, 38),
                    SleepStageInput(SleepStage.Light, 364, 77),
                    SleepStageInput(SleepStage.Rem, 441, 45),
                    SleepStageInput(SleepStage.Awake, 486, 18)
                )
            ),
            hrvAssessment = HrvAssessmentInput(48),
            restingHeartRate = RestingHeartRateInput(58, "08:45", 52),
            healthCheck = HealthCheckInput(91, 42, 45, 18, 98, "15:04"),
            bodyManagement = BodyManagementInput(
                68.2,
                listOf("chest", "quadriceps"),
                listOf(68.2)
            )
        )
    }

    fun allEmpty(): EditableHealthData = EditableHealthData(
        dailySummary = DailySummaryInput(0, 0, 0),
        todayActivity = TodayActivityInput(0.0, 0),
        weeklyPlan = WeeklyPlanInput(listOf(
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0),
            WeeklyWorkoutInput(WorkoutType.Rest, 0.0)
        )),
        trainingLoad = TrainingLoadInput(listOf(0, 0, 0, 0, 0, 0, 0)),
        assessment = TrainingAssessmentInput(0, 0),
        recovery = RecoveryInput(0),
        runningAbility = RunningAbilityInput(0),
        cyclingAbility = CyclingAbilityInput(0),
        heartRate = HeartRateInput(List(288) { 0 }),
        stress = StressInput(List(48) { 0 }),
        sleep = SleepInput(0, emptyList()),
        hrvAssessment = HrvAssessmentInput(0),
        restingHeartRate = RestingHeartRateInput(0, "", 0),
        healthCheck = HealthCheckInput(0, 0, 0, 0, 0, ""),
        bodyManagement = BodyManagementInput(0.0, emptyList(), emptyList())
    )
}
