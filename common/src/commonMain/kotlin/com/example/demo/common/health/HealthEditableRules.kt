package com.example.demo.common.health

import kotlin.math.roundToInt

object HealthEditableRules {
    private const val HeartSamplesPerDay = 288
    private const val StressSamplesPerDay = 48

    fun derive(source: EditableHealthData): HealthDashboardData {
        require(validate(source)) { "invalid editable health source" }
        val weekly = deriveWeekly(source.weeklyPlan)
        val heartSamples = source.heartRate.fiveMinuteSamples
        val stressSamples = source.stress.halfHourSamples
        val sleepDuration = source.sleep.stages.sumOf { it.durationMinutes }
        val assessmentRatio = source.assessment.shortTermLoad.toDouble() /
            source.assessment.longTermLoad.toDouble()
        val assessmentKeys = when {
            assessmentRatio > 1.2 -> "health_visual_assessment_efficient" to
                "health_visual_assessment_efficient_detail"
            assessmentRatio >= 0.8 -> "health_visual_assessment_maintaining" to
                "health_visual_assessment_maintaining_detail"
            else -> "health_visual_assessment_low" to "health_visual_assessment_low_detail"
        }
        val activityType = activityTypeForPace(source.todayActivity.paceSecondsPerKm)
        val activityIntensity = when (activityType) {
            WorkoutType.Easy -> 7.0
            WorkoutType.Tempo -> 11.0
            WorkoutType.Endurance -> 15.0
            WorkoutType.Rest -> 0.0
        }
        val recoveryHours = (((100 - source.recovery.score) * 0.4).roundToInt()).coerceAtLeast(0)
        val runningMarathonSeconds = (21_600 - source.runningAbility.score * 126)
            .coerceIn(9_000, 21_600)
        val stressAverage = stressSamples.average().roundToInt()
        val hrv = source.hrvAssessment.averageMs
        val hrvStatus = when {
            hrv < 37 -> "severely_low"
            hrv < 47 -> "low"
            hrv <= 57 -> "normal"
            else -> "high"
        }
        val startTime = timeOfDay(source.sleep.startMinuteOfDay)
        val endTime = timeOfDay(source.sleep.startMinuteOfDay + sleepDuration)
        val body = source.bodyManagement
        return HealthDashboardData(
            dailySummary = DailySummary(
                source.dailySummary.steps,
                source.dailySummary.calories,
                source.dailySummary.activeMinutes
            ),
            todayActivity = TodayActivity(
                source.todayActivity.distanceKm,
                source.todayActivity.paceSecondsPerKm,
                LocalizedTextSpec(workoutNameKey(activityType)),
                (source.todayActivity.distanceKm * activityIntensity).roundToInt()
            ),
            sleepSummary = SleepSummary(
                durationMinutes = sleepDuration,
                qualityScore = sleepQuality(source.sleep.stages),
                startTime = startTime,
                endTime = endTime,
                stages = source.sleep.stages.map {
                    SleepStageSegment(it.stage, it.startMinute, it.durationMinutes)
                }
            ),
            trainingLoad = TrainingLoad(
                value = source.trainingLoad.dailyLoads.sum(),
                recommendedMin = 600,
                recommendedMax = 800,
                dailyLoads = source.trainingLoad.dailyLoads
            ),
            recovery = Recovery(source.recovery.score, recoveryHours),
            weeklyPlan = weekly,
            trainingAssessment = TrainingAssessment(
                volumeScore = (assessmentRatio * 65).roundToInt().coerceIn(0, 100),
                trend = when {
                    assessmentRatio > 1.2 -> "increasing"
                    assessmentRatio >= 0.8 -> "stable"
                    else -> "declining"
                },
                shortTermLoad = source.assessment.shortTermLoad,
                longTermLoad = source.assessment.longTermLoad,
                loadRatio = ((assessmentRatio * 100).roundToInt() / 100.0),
                assessment = LocalizedTextSpec(assessmentKeys.first),
                explanation = LocalizedTextSpec(assessmentKeys.second)
            ),
            runningAbility = RunningAbility(
                vo2max = (30 + source.runningAbility.score * 0.3).roundToInt(),
                score = source.runningAbility.score,
                displayScore = source.runningAbility.score.toDouble(),
                marathonSeconds = runningMarathonSeconds
            ),
            cyclingAbility = CyclingAbility(
                ftp = 100 + source.cyclingAbility.score * 2,
                score = source.cyclingAbility.score,
                displayScore = source.cyclingAbility.score.toDouble(),
                abilityLabel = LocalizedTextSpec(cyclingLabelKey(source.cyclingAbility.score))
            ),
            heartRate = HeartRate(
                restingHr = heartSamples.minOrNull(),
                currentHr = heartSamples.last(),
                averageHr = heartSamples.average().roundToInt(),
                intervals = aggregateFiveMinuteHeartSamples(heartSamples),
                fiveMinuteSamples = heartSamples
            ),
            stress = Stress(
                stressLevel = stressAverage,
                status = if (stressAverage >= 60) "high" else "normal",
                averageStress = stressAverage,
                samples = stressSamples
            ),
            hrvAssessment = HrvAssessment(hrv, hrvStatus, hrv, 47, 57),
            restingHeartRate = RestingHeartRate(
                source.restingHeartRate.value,
                source.restingHeartRate.measuredTime,
                source.restingHeartRate.thirtyDayAverage
            ),
            healthCheck = HealthCheck(
                overallScore = healthCheckScore(source.healthCheck),
                lastCheckDays = 0,
                measuredTime = source.healthCheck.measuredTime,
                heartRate = source.healthCheck.heartRate,
                hrvMs = source.healthCheck.hrvMs,
                stress = source.healthCheck.stress,
                respiratoryRate = source.healthCheck.respiratoryRate,
                bloodOxygen = source.healthCheck.bloodOxygen
            ),
            bodyManagement = BodyManagement(
                weightKg = body.weightKg,
                bodyFat = null,
                bmi = null,
                measuredDate = null,
                trainedMuscleGroups = body.trainedMuscleGroups.distinct(),
                weightHistoryKg = body.weightHistoryKg
            )
        )
    }

    fun validate(source: EditableHealthData): Boolean =
        source.dailySummary.steps in 0..99_999 &&
            source.dailySummary.calories in 0..99_999 &&
            source.dailySummary.activeMinutes in 0..99_999 &&
            source.todayActivity.distanceKm in 0.0..500.0 &&
            source.todayActivity.paceSecondsPerKm in 120..1_800 &&
            source.weeklyPlan.days.size == 7 &&
            source.weeklyPlan.days.all {
                (it.type == WorkoutType.Rest && it.distanceKm == 0.0) ||
                    (it.type != WorkoutType.Rest && it.distanceKm in 0.1..500.0)
            } &&
            source.trainingLoad.dailyLoads.size == 7 &&
            source.trainingLoad.dailyLoads.all { it in 0..5_000 } &&
            source.assessment.shortTermLoad in 0..10_000 &&
            source.assessment.longTermLoad in 1..10_000 &&
            source.recovery.score in 0..100 &&
            source.runningAbility.score in 0..100 &&
            source.cyclingAbility.score in 0..100 &&
            source.heartRate.fiveMinuteSamples.size == HeartSamplesPerDay &&
            source.heartRate.fiveMinuteSamples.all { it in 35..220 } &&
            source.stress.halfHourSamples.size == StressSamplesPerDay &&
            source.stress.halfHourSamples.all { it in 0..100 } &&
            validateSleep(source.sleep) &&
            source.hrvAssessment.averageMs in 1..300 &&
            source.restingHeartRate.value in 30..220 &&
            source.restingHeartRate.thirtyDayAverage in 30..220 &&
            validTime(source.restingHeartRate.measuredTime) &&
            source.healthCheck.heartRate in 30..220 &&
            source.healthCheck.hrvMs in 1..300 &&
            source.healthCheck.stress in 0..100 &&
            source.healthCheck.respiratoryRate in 5..60 &&
            source.healthCheck.bloodOxygen in 50..100 &&
            validTime(source.healthCheck.measuredTime) &&
            source.bodyManagement.weightKg in 30.0..200.0 &&
            source.bodyManagement.trainedMuscleGroups.distinct().size ==
                source.bodyManagement.trainedMuscleGroups.size &&
            source.bodyManagement.trainedMuscleGroups.all { muscle ->
                BodyMuscleGroup.entries.any { it.id == muscle }
            } &&
            source.bodyManagement.weightHistoryKg.isNotEmpty() &&
            source.bodyManagement.weightHistoryKg.all { it in 30.0..200.0 }

    fun validateSection(source: EditableHealthData, section: HealthEditableSection): Boolean =
        when (section) {
            HealthEditableSection.DailySummary ->
                source.dailySummary.steps in 0..99_999 &&
                    source.dailySummary.calories in 0..99_999 &&
                    source.dailySummary.activeMinutes in 0..99_999
            HealthEditableSection.TodayActivity ->
                source.todayActivity.distanceKm in 0.0..500.0 &&
                    source.todayActivity.paceSecondsPerKm in 120..1_800
            HealthEditableSection.WeeklyPlan ->
                source.weeklyPlan.days.size == 7 && source.weeklyPlan.days.all {
                    (it.type == WorkoutType.Rest && it.distanceKm == 0.0) ||
                        (it.type != WorkoutType.Rest && it.distanceKm in 0.1..500.0)
                }
            HealthEditableSection.TrainingLoad ->
                source.trainingLoad.dailyLoads.size == 7 &&
                    source.trainingLoad.dailyLoads.all { it in 0..5_000 }
            HealthEditableSection.TrainingAssessment ->
                source.assessment.shortTermLoad in 0..10_000 &&
                    source.assessment.longTermLoad in 1..10_000
            HealthEditableSection.Recovery -> source.recovery.score in 0..100
            HealthEditableSection.RunningAbility -> source.runningAbility.score in 0..100
            HealthEditableSection.CyclingAbility -> source.cyclingAbility.score in 0..100
            HealthEditableSection.HeartRate ->
                source.heartRate.fiveMinuteSamples.size == HeartSamplesPerDay &&
                    source.heartRate.fiveMinuteSamples.all { it in 35..220 }
            HealthEditableSection.Stress ->
                source.stress.halfHourSamples.size == StressSamplesPerDay &&
                    source.stress.halfHourSamples.all { it in 0..100 }
            HealthEditableSection.Sleep -> validateSleep(source.sleep)
            HealthEditableSection.HrvAssessment -> source.hrvAssessment.averageMs in 1..300
            HealthEditableSection.RestingHeartRate ->
                source.restingHeartRate.value in 30..220 &&
                    source.restingHeartRate.thirtyDayAverage in 30..220 &&
                    validTime(source.restingHeartRate.measuredTime)
            HealthEditableSection.HealthCheck ->
                source.healthCheck.heartRate in 30..220 &&
                    source.healthCheck.hrvMs in 1..300 &&
                    source.healthCheck.stress in 0..100 &&
                    source.healthCheck.respiratoryRate in 5..60 &&
                    source.healthCheck.bloodOxygen in 50..100 &&
                    validTime(source.healthCheck.measuredTime)
            HealthEditableSection.BodyManagement ->
                source.bodyManagement.trainedMuscleGroups.distinct().size ==
                    source.bodyManagement.trainedMuscleGroups.size &&
                    source.bodyManagement.trainedMuscleGroups.all { muscle ->
                        BodyMuscleGroup.entries.any { it.id == muscle }
                    }
        }

    fun deriveSection(source: EditableHealthData, section: HealthEditableSection): HealthDashboardData {
        require(validateSection(source, section)) { "invalid editable health section" }
        val complete = DefaultEditableHealthData.value.withSectionFrom(source, section)
        val derived = derive(complete)
        return HealthDashboardData(null, null, null, null).withSectionFrom(derived, section)
    }

    fun validateSleep(input: SleepInput): Boolean {
        if (input.startMinuteOfDay !in 0..1_439 || input.stages.isEmpty()) return false
        var nextStart = 0
        input.stages.forEach { stage ->
            if (stage.startMinute != nextStart || stage.durationMinutes <= 0) return false
            nextStart += stage.durationMinutes
        }
        return nextStart <= 1_440
    }

    fun generateHeartRateSamples(average: Int, pattern: HeartRatePattern): List<Int> {
        require(average in 35..200)
        return List(HeartSamplesPerDay) { index ->
            val hour = index / 12
            val wave = triangleWave(index, 36)
            val circadian = when {
                hour < 6 -> -10
                hour < 9 -> 6
                hour < 17 -> 2
                hour < 21 -> 9
                else -> -5
            }
            val patternOffset = when (pattern) {
                HeartRatePattern.Normal -> 0
                HeartRatePattern.High -> if (index in 96..155) 30 else 10
                HeartRatePattern.Low -> if (index in 0..83) -18 else -8
            }
            (average + wave + circadian + patternOffset).coerceIn(35, 220)
        }.centeredAt(average, 35, 220)
    }

    fun generateStressSamples(average: Int, pattern: StressPattern): List<Int> {
        require(average in 0..100)
        return List(StressSamplesPerDay) { index ->
            val slowWave = triangleWave(index, 16) / 2
            val dayOffset = if (index in 14..39) 6 else -5
            val highWindow = if (pattern == StressPattern.High && index in 20..31) 28 else 0
            (average + slowWave + dayOffset + highWindow).coerceIn(0, 100)
        }.centeredAt(average, 0, 100)
    }

    fun restoreSection(
        source: EditableHealthData,
        section: HealthEditableSection
    ): EditableHealthData {
        val defaults = DefaultEditableHealthData.value
        return when (section) {
            HealthEditableSection.DailySummary -> source.copy(dailySummary = defaults.dailySummary)
            HealthEditableSection.TodayActivity -> source.copy(todayActivity = defaults.todayActivity)
            HealthEditableSection.WeeklyPlan -> source.copy(weeklyPlan = defaults.weeklyPlan)
            HealthEditableSection.TrainingLoad -> source.copy(trainingLoad = defaults.trainingLoad)
            HealthEditableSection.TrainingAssessment -> source.copy(assessment = defaults.assessment)
            HealthEditableSection.Recovery -> source.copy(recovery = defaults.recovery)
            HealthEditableSection.RunningAbility -> source.copy(runningAbility = defaults.runningAbility)
            HealthEditableSection.CyclingAbility -> source.copy(cyclingAbility = defaults.cyclingAbility)
            HealthEditableSection.HeartRate -> source.copy(heartRate = defaults.heartRate)
            HealthEditableSection.Stress -> source.copy(stress = defaults.stress)
            HealthEditableSection.Sleep -> source.copy(sleep = defaults.sleep)
            HealthEditableSection.HrvAssessment -> source.copy(hrvAssessment = defaults.hrvAssessment)
            HealthEditableSection.RestingHeartRate -> source.copy(restingHeartRate = defaults.restingHeartRate)
            HealthEditableSection.HealthCheck -> source.copy(healthCheck = defaults.healthCheck)
            HealthEditableSection.BodyManagement -> source.copy(bodyManagement = defaults.bodyManagement)
        }
    }

    fun restoreAll(@Suppress("UNUSED_PARAMETER") source: EditableHealthData): EditableHealthData =
        DefaultEditableHealthData.value

    fun project(data: HealthDashboardData, corrupted: Boolean = false): HealthEditableProjection {
        if (corrupted) return HealthEditableProjection(
            DefaultEditableHealthData.allEmpty(),
            HealthEditSourceKind.Corrupted
        )
        val modules = listOf(
            data.dailySummary, data.todayActivity, data.weeklyPlan, data.trainingLoad,
            data.trainingAssessment, data.recovery, data.runningAbility, data.cyclingAbility,
            data.heartRate, data.stress, data.sleepSummary, data.hrvAssessment,
            data.restingHeartRate, data.healthCheck, data.bodyManagement
        )
        val sourceKind = when {
            modules.all { it == null } -> HealthEditSourceKind.Empty
            modules.any { it == null } -> HealthEditSourceKind.Partial
            else -> HealthEditSourceKind.Available
        }
        return HealthEditableProjection(fromDashboard(data), sourceKind)
    }

    fun fromDashboard(data: HealthDashboardData): EditableHealthData {
        val empty = DefaultEditableHealthData.allEmpty()
        val daily = data.dailySummary
        val activity = data.todayActivity
        val weekly = data.weeklyPlan
        val load = data.trainingLoad
        val assessment = data.trainingAssessment
        val recovery = data.recovery
        val running = data.runningAbility
        val cycling = data.cyclingAbility
        val heart = data.heartRate
        val stress = data.stress
        val sleep = data.sleepSummary
        val hrv = data.hrvAssessment
        val resting = data.restingHeartRate
        val check = data.healthCheck
        val body = data.bodyManagement
        val heartSamples = heart?.fiveMinuteSamples?.takeIf { it.size == HeartSamplesPerDay }
            ?: empty.heartRate.fiveMinuteSamples
        val stressSamples = when (stress?.samples?.size) {
            StressSamplesPerDay -> stress.samples
            StressSamplesPerDay / 2 -> stress.samples.flatMap { listOf(it, it) }
            else -> empty.stress.halfHourSamples
        }
        val dayPlans = weekly?.dayPlans?.takeIf { it.size == 7 }.orEmpty()
        return EditableHealthData(
            DailySummaryInput(daily?.steps ?: 0, daily?.calories ?: 0, daily?.activeMinutes ?: 0),
            TodayActivityInput(activity?.distanceKm ?: 0.0, activity?.paceSecondsPerKm ?: 0),
            WeeklyPlanInput((dayPlans.map { plan ->
                val type = workoutTypeFromKey(plan.workoutName?.key)
                val pace = paceSeconds(type)
                val distance = if (type == WorkoutType.Rest) 0.0
                else (plan.workoutDurationMinutes ?: 0) * 60.0 / pace
                WeeklyWorkoutInput(type, (distance * 10).roundToInt() / 10.0)
            }).takeIf { it.size == 7 } ?: empty.weeklyPlan.days),
            TrainingLoadInput(load?.dailyLoads?.takeIf { it.size == 7 } ?: empty.trainingLoad.dailyLoads),
            TrainingAssessmentInput(
                assessment?.shortTermLoad ?: 0,
                assessment?.longTermLoad ?: 0
            ),
            RecoveryInput(recovery?.score ?: 0),
            RunningAbilityInput(running?.score ?: running?.displayScore?.roundToInt() ?: 0),
            CyclingAbilityInput(cycling?.score ?: cycling?.displayScore?.roundToInt() ?: 0),
            HeartRateInput(heartSamples),
            StressInput(stressSamples),
            SleepInput(
                sleep?.startTime?.let(::parseTime) ?: 0,
                sleep?.stages?.map { SleepStageInput(it.stage, it.startMinute, it.durationMinutes) }.orEmpty()
            ),
            HrvAssessmentInput(hrv?.averageMs ?: hrv?.hrvScore ?: 0),
            RestingHeartRateInput(
                resting?.value ?: 0,
                resting?.measuredTime?.takeIf(::validTime).orEmpty(),
                resting?.thirtyDayAverage ?: resting?.value ?: 0
            ),
            HealthCheckInput(
                check?.heartRate ?: 0,
                check?.hrvMs ?: 0,
                check?.stress ?: 0,
                check?.respiratoryRate ?: 0,
                check?.bloodOxygen ?: 0,
                check?.measuredTime?.takeIf(::validTime).orEmpty()
            ),
            BodyManagementInput(
                body?.weightKg ?: 0.0,
                body?.trainedMuscleGroups.orEmpty(),
                body?.weightHistoryKg?.ifEmpty { body.weightKg?.let(::listOf).orEmpty() }.orEmpty()
            )
        )
    }

    private fun EditableHealthData.withSectionFrom(
        source: EditableHealthData,
        section: HealthEditableSection
    ): EditableHealthData = when (section) {
        HealthEditableSection.DailySummary -> copy(dailySummary = source.dailySummary)
        HealthEditableSection.TodayActivity -> copy(todayActivity = source.todayActivity)
        HealthEditableSection.WeeklyPlan -> copy(weeklyPlan = source.weeklyPlan)
        HealthEditableSection.TrainingLoad -> copy(trainingLoad = source.trainingLoad)
        HealthEditableSection.TrainingAssessment -> copy(assessment = source.assessment)
        HealthEditableSection.Recovery -> copy(recovery = source.recovery)
        HealthEditableSection.RunningAbility -> copy(runningAbility = source.runningAbility)
        HealthEditableSection.CyclingAbility -> copy(cyclingAbility = source.cyclingAbility)
        HealthEditableSection.HeartRate -> copy(heartRate = source.heartRate)
        HealthEditableSection.Stress -> copy(stress = source.stress)
        HealthEditableSection.Sleep -> copy(sleep = source.sleep)
        HealthEditableSection.HrvAssessment -> copy(hrvAssessment = source.hrvAssessment)
        HealthEditableSection.RestingHeartRate -> copy(restingHeartRate = source.restingHeartRate)
        HealthEditableSection.HealthCheck -> copy(healthCheck = source.healthCheck)
        HealthEditableSection.BodyManagement -> copy(bodyManagement = source.bodyManagement)
    }

    private fun HealthDashboardData.withSectionFrom(
        source: HealthDashboardData,
        section: HealthEditableSection
    ): HealthDashboardData = when (section) {
        HealthEditableSection.DailySummary -> copy(dailySummary = source.dailySummary)
        HealthEditableSection.TodayActivity -> copy(todayActivity = source.todayActivity)
        HealthEditableSection.WeeklyPlan -> copy(weeklyPlan = source.weeklyPlan)
        HealthEditableSection.TrainingLoad -> copy(trainingLoad = source.trainingLoad)
        HealthEditableSection.TrainingAssessment -> copy(trainingAssessment = source.trainingAssessment)
        HealthEditableSection.Recovery -> copy(recovery = source.recovery)
        HealthEditableSection.RunningAbility -> copy(runningAbility = source.runningAbility)
        HealthEditableSection.CyclingAbility -> copy(cyclingAbility = source.cyclingAbility)
        HealthEditableSection.HeartRate -> copy(heartRate = source.heartRate)
        HealthEditableSection.Stress -> copy(stress = source.stress)
        HealthEditableSection.Sleep -> copy(sleepSummary = source.sleepSummary)
        HealthEditableSection.HrvAssessment -> copy(hrvAssessment = source.hrvAssessment)
        HealthEditableSection.RestingHeartRate -> copy(restingHeartRate = source.restingHeartRate)
        HealthEditableSection.HealthCheck -> copy(healthCheck = source.healthCheck)
        HealthEditableSection.BodyManagement -> copy(bodyManagement = source.bodyManagement)
    }

    private fun deriveWeekly(input: WeeklyPlanInput): WeeklyPlan {
        val plans = input.days.mapIndexed { index, workout ->
            if (workout.type == WorkoutType.Rest) {
                WeeklyDayPlan(index)
            } else {
                val duration = (workout.distanceKm * paceSeconds(workout.type) / 60.0).roundToInt()
                val load = (workout.distanceKm * loadMultiplier(workout.type)).roundToInt()
                WeeklyDayPlan(
                    dayIndex = index,
                    workoutName = LocalizedTextSpec(workoutNameKey(workout.type)),
                    workoutDurationMinutes = duration,
                    workoutTrainingLoad = load
                )
            }
        }
        val dailyLoads = plans.map { it.workoutTrainingLoad ?: 0 }
        val selected = plans.getOrNull(3) ?: plans.first()
        return WeeklyPlan(
            hasPlan = plans.any { it.workoutName != null },
            plannedMinutes = plans.sumOf { it.workoutDurationMinutes ?: 0 },
            description = null,
            currentDayIndex = 3,
            dailyLoads = dailyLoads,
            workoutName = selected.workoutName,
            workoutDurationMinutes = selected.workoutDurationMinutes,
            workoutTrainingLoad = selected.workoutTrainingLoad,
            dayPlans = plans
        )
    }

    private fun activityTypeForPace(pace: Int): WorkoutType = when {
        pace > 8 * 60 -> WorkoutType.Easy
        pace >= 5 * 60 -> WorkoutType.Tempo
        else -> WorkoutType.Endurance
    }

    private fun workoutNameKey(type: WorkoutType): String = when (type) {
        WorkoutType.Rest -> "health_visual_workout_rest"
        WorkoutType.Easy -> "health_visual_activity_easy_run"
        WorkoutType.Tempo -> "health_visual_activity_tempo_run"
        WorkoutType.Endurance -> "health_visual_activity_endurance_run"
    }

    private fun workoutTypeFromKey(key: String?): WorkoutType = when (key) {
        "health_visual_activity_easy_run", "health_visual_workout_easy_run" -> WorkoutType.Easy
        "health_visual_activity_tempo_run" -> WorkoutType.Tempo
        "health_visual_activity_endurance_run" -> WorkoutType.Endurance
        else -> WorkoutType.Rest
    }

    private fun paceSeconds(type: WorkoutType): Int = when (type) {
        WorkoutType.Rest -> 0
        WorkoutType.Easy -> 600
        WorkoutType.Tempo -> 360
        WorkoutType.Endurance -> 240
    }

    private fun loadMultiplier(type: WorkoutType): Double = when (type) {
        WorkoutType.Rest -> 0.0
        WorkoutType.Easy -> 7.0
        WorkoutType.Tempo -> 15.0
        WorkoutType.Endurance -> 22.0
    }

    private fun cyclingLabelKey(score: Int): String = when (score) {
        in 0..24 -> "health_visual_cycling_beginner"
        in 25..49 -> "health_visual_cycling_endurance"
        in 50..74 -> "health_visual_cycling_climber"
        else -> "health_visual_cycling_power"
    }

    private fun sleepQuality(stages: List<SleepStageInput>): Int {
        val total = stages.sumOf { it.durationMinutes }.coerceAtLeast(1)
        val restorative = stages.filter { it.stage == SleepStage.Deep || it.stage == SleepStage.Rem }
            .sumOf { it.durationMinutes }
        val awake = stages.filter { it.stage == SleepStage.Awake }.sumOf { it.durationMinutes }
        return (65 + restorative * 45 / total - awake * 35 / total).coerceIn(0, 100)
    }

    private fun healthCheckScore(input: HealthCheckInput): Int {
        val heartScore = 100 - ((input.heartRate - 70).coerceAtLeast(0) * 2)
        val hrvScore = (input.hrvMs * 2).coerceAtMost(100)
        val stressScore = 100 - input.stress
        val respiratoryScore = 100 - (kotlin.math.abs(input.respiratoryRate - 16) * 8)
        val oxygenScore = ((input.bloodOxygen - 90) * 10).coerceIn(0, 100)
        return listOf(heartScore, hrvScore, stressScore, respiratoryScore, oxygenScore)
            .average().roundToInt().coerceIn(0, 100)
    }

    private fun triangleWave(index: Int, period: Int): Int {
        val position = index % period
        val half = period / 2
        return if (position <= half) position - half / 2 else period - position - half / 2
    }

    private fun List<Int>.centeredAt(target: Int, min: Int, max: Int): List<Int> {
        val delta = target - average().roundToInt()
        return map { (it + delta).coerceIn(min, max) }
    }

    private fun timeOfDay(totalMinutes: Int): String {
        val normalized = ((totalMinutes % 1_440) + 1_440) % 1_440
        return "${(normalized / 60).toString().padStart(2, '0')}:" +
            (normalized % 60).toString().padStart(2, '0')
    }

    private fun validTime(value: String): Boolean = parseTime(value) != null

    private fun parseTime(value: String?): Int? {
        val parts = value?.split(':') ?: return null
        if (parts.size != 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        return if (hour in 0..23 && minute in 0..59) hour * 60 + minute else null
    }
}
