package com.example.demo.common.health.model

internal fun activityVisual(value: TodayActivity) = HealthCardVisualData(
    kind = HealthCardVisualKind.TodayActivity,
    primaryValue = value.distanceKm?.f2(),
    primaryUnit = text("health_unit_kilometers"),
    secondaryValue = pace(value.paceSecondsPerKm),
    caption = value.activityName,
    detail = text("health_visual_activity_pace", pace(value.paceSecondsPerKm)),
    metrics = value.trainingLoad?.let { listOf(HealthMetric(text("health_visual_training_load_short"), it.toString())) }.orEmpty(),
    assetKey = "activity_map_mock"
)

internal fun weeklyVisual(value: WeeklyPlan) = HealthCardVisualData(
    kind = HealthCardVisualKind.WeeklyPlan,
    primaryValue = value.workoutDurationMinutes?.toString(),
    primaryUnit = text("health_unit_minutes_long"),
    caption = value.workoutName,
    chartPoints = dayPoints(value.dailyLoads),
    metrics = value.workoutTrainingLoad?.let { listOf(HealthMetric(text("health_visual_training_load_short"), it.toString())) }.orEmpty(),
    highlightedIndex = value.currentDayIndex,
    weeklyDayPlans = value.dayPlans.ifEmpty {
        (0..6).map { dayIndex ->
            if (dayIndex == value.currentDayIndex) {
                WeeklyDayPlan(dayIndex, value.workoutName, value.workoutDurationMinutes, value.workoutTrainingLoad)
            } else {
                WeeklyDayPlan(dayIndex)
            }
        }
    }
)

internal fun trainingLoadVisual(value: TrainingLoad) = HealthCardVisualData(
    kind = HealthCardVisualKind.TrainingLoad,
    primaryValue = value.value?.toString(),
    caption = text("health_visual_recommended_range", value.recommendedMin, value.recommendedMax),
    chartPoints = dayPoints(value.dailyLoads)
)

internal fun assessmentVisual(value: TrainingAssessment) = HealthCardVisualData(
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

internal fun recoveryVisual(value: Recovery) = HealthCardVisualData(
    kind = HealthCardVisualKind.RecoveryGauge,
    primaryValue = value.score?.toString(),
    primaryUnit = text("health_unit_percent"),
    caption = text("health_visual_recovery_after_hours", value.remainingHours ?: 0),
    progress = value.score?.coerceIn(0, 100)?.div(100.0)
)

internal fun runningVisual(value: RunningAbility) = HealthCardVisualData(
    kind = HealthCardVisualKind.AbilityGauge,
    primaryValue = (value.displayScore ?: value.score?.toDouble())?.f1(),
    caption = value.marathonSeconds?.let { text("health_visual_marathon_prediction", marathon(it)) },
    progress = value.displayScore?.div(100.0) ?: value.score?.div(100.0)
)

internal fun cyclingVisual(value: CyclingAbility) = HealthCardVisualData(
    kind = HealthCardVisualKind.AbilityGauge,
    primaryValue = (value.displayScore ?: value.score?.toDouble())?.f1(),
    caption = value.abilityLabel,
    progress = value.displayScore?.div(100.0) ?: value.score?.div(100.0)
)

internal fun heartVisual(value: HeartRate) = HealthCardVisualData(
    kind = HealthCardVisualKind.TrendBars,
    primaryValue = (value.averageHr ?: value.currentHr ?: value.restingHr)?.toString(),
    primaryUnit = text("health_unit_bpm"),
    caption = text("health_visual_average_heart_rate"),
    chartPoints = value.intervals.ifEmpty {
        value.samples.mapIndexed { index, sample -> HeartRateInterval(index * 30, sample, sample, sample) }
    }.map { interval ->
        HealthChartPoint(
            label = halfHourLabel(interval.startMinute),
            value = interval.average.toDouble(),
            minimum = interval.minimum.toDouble(),
            maximum = interval.maximum.toDouble(),
            average = interval.average.toDouble()
        )
    }
)

internal fun stressVisual(value: Stress) = HealthCardVisualData(
    kind = HealthCardVisualKind.TrendBars,
    primaryValue = (value.averageStress ?: value.stressLevel)?.toString(),
    caption = text("health_visual_average_stress"),
    chartPoints = value.samples.mapIndexed { index, sample ->
        HealthChartPoint(index.toString(), sample.toDouble(), stressLevel(sample))
    }
)

internal fun sleepVisual(value: SleepSummary): HealthCardVisualData {
    val minutes = value.durationMinutes ?: 0
    return HealthCardVisualData(
        kind = HealthCardVisualKind.SleepStages,
        primaryValue = (minutes / 60).toString(), primaryUnit = text("health_unit_hours_short"),
        secondaryValue = (minutes % 60).toString(), secondaryUnit = text("health_unit_minutes_short"),
        sleepStages = value.stages, startTime = value.startTime, endTime = value.endTime
    )
}

internal fun hrvVisual(value: HrvAssessment): HealthCardVisualData {
    val current = (value.averageMs ?: value.hrvScore ?: 0).toDouble()
    val range = hrvRange(
        current = current,
        normalMin = value.normalMin?.toDouble(),
        normalMax = value.normalMax?.toDouble()
    )
    return HealthCardVisualData(
        kind = HealthCardVisualKind.RangeIndicator,
        primaryValue = current.toInt().toString(), primaryUnit = text("health_unit_milliseconds"),
        caption = text(hrvStatusKey(current, range)),
        detail = text("health_visual_hrv_average", current.toInt()),
        range = range
    )
}

internal fun hrvRange(
    current: Double,
    normalMin: Double?,
    normalMax: Double?
): HealthRange {
    val resolvedNormalMin = (normalMin ?: 47.0).coerceIn(42.0, 65.0)
    val resolvedNormalMax = (normalMax ?: 57.0).coerceIn(resolvedNormalMin, 65.0)
    return HealthRange(
        minimum = 40.0,
        maximum = 65.0,
        current = current,
        normalMin = resolvedNormalMin,
        normalMax = resolvedNormalMax,
        segments = listOf(
            HealthRangeSegment(40.0, 42.0, HealthRangeLevel.VeryLow),
            HealthRangeSegment(42.0, resolvedNormalMin, HealthRangeLevel.Low),
            HealthRangeSegment(resolvedNormalMin, resolvedNormalMax, HealthRangeLevel.Normal),
            HealthRangeSegment(resolvedNormalMax, 65.0, HealthRangeLevel.High)
        )
    )
}

internal fun hrvStatusKey(current: Double, range: HealthRange): String {
    val veryLowMax = range.segments.firstOrNull { it.level == HealthRangeLevel.VeryLow }?.maximum
        ?: range.minimum
    val normalMin = range.normalMin ?: veryLowMax
    val normalMax = range.normalMax ?: normalMin
    return when {
        current < veryLowMax -> "health_visual_hrv_very_low"
        current < normalMin -> "health_visual_hrv_low"
        current <= normalMax -> "health_visual_hrv_normal"
        else -> "health_visual_hrv_high"
    }
}

internal fun HealthRange.segmentFractions(): List<Double> {
    val total = (maximum - minimum).coerceAtLeast(1.0)
    return segments.map { segment ->
        (segment.maximum.coerceIn(minimum, maximum) - segment.minimum.coerceIn(minimum, maximum))
            .coerceAtLeast(0.0) / total
    }
}

internal fun HealthRange.currentFraction(): Double {
    val total = (maximum - minimum).coerceAtLeast(1.0)
    return ((current - minimum) / total).coerceIn(0.0, 1.0)
}

internal fun restingHeartVisual(value: RestingHeartRate): HealthCardVisualData {
    val current = (value.value ?: 0).toDouble()
    return HealthCardVisualData(
        kind = HealthCardVisualKind.RangeIndicator,
        primaryValue = current.toInt().toString(), primaryUnit = text("health_unit_bpm"),
        caption = text("health_visual_measured_at", value.measuredTime ?: "---"),
        detail = text("health_visual_thirty_day_average", value.thirtyDayAverage ?: 0),
        range = HealthRange(value.rangeMin.toDouble(), value.rangeMax.toDouble(), current, average = value.thirtyDayAverage?.toDouble())
    )
}

internal fun healthCheckVisual(value: HealthCheck) = HealthCardVisualData(
    kind = HealthCardVisualKind.HealthCheckGrid,
    caption = value.measuredTime?.let { text("health_visual_measured_at", it) },
    metrics = listOfNotNull(
        value.heartRate?.let { HealthMetric(text("health_visual_heart_rate"), it.toString(), text("health_unit_bpm")) },
        value.hrvMs?.let { HealthMetric(text("health_visual_hrv"), it.toString(), text("health_unit_milliseconds")) },
        value.stress?.let { HealthMetric(text("health_visual_stress"), it.toString()) },
        value.respiratoryRate?.let { HealthMetric(text("health_visual_respiratory_rate"), it.toString(), text("health_unit_per_minute")) },
        value.bloodOxygen?.let { HealthMetric(text("health_visual_blood_oxygen"), it.toString(), text("health_unit_percent")) }
    )
)

private val bodyRegionsByMuscleGroup = mapOf(
    BodyMuscleGroup.Chest.id to listOf("chest_front"),
    BodyMuscleGroup.Shoulders.id to listOf("shoulders_front", "shoulders_back"),
    BodyMuscleGroup.Back.id to listOf(
        "trapezius_back",
        "latissimus_back",
        "erector_spinae_back"
    ),
    BodyMuscleGroup.Biceps.id to listOf("biceps_front"),
    BodyMuscleGroup.Triceps.id to listOf("triceps_back"),
    BodyMuscleGroup.Abdominals.id to listOf("abdominals_front"),
    BodyMuscleGroup.Glutes.id to listOf("glutes_back"),
    BodyMuscleGroup.Quadriceps.id to listOf("quadriceps_front"),
    BodyMuscleGroup.Hamstrings.id to listOf("hamstrings_back"),
    BodyMuscleGroup.Calves.id to listOf("calves_front", "calves_back")
)

internal fun bodyHighlightRegions(muscleGroups: List<String>): List<String> =
    muscleGroups.flatMap { bodyRegionsByMuscleGroup[it].orEmpty() }.distinct()

internal fun bodyVisual(value: BodyManagement): HealthCardVisualData {
    val bodyHighlightRegions = bodyHighlightRegions(value.trainedMuscleGroups)
    return HealthCardVisualData(
        kind = HealthCardVisualKind.BodyMap,
        primaryValue = value.weightKg?.f1(), primaryUnit = text("health_unit_kilograms"),
        caption = text("health_visual_weight"),
        detail = text("health_visual_measured_date", value.measuredDate ?: "---"),
        footer = text("health_visual_weekly_primary_muscles"),
        highlightedBodyRegions = bodyHighlightRegions,
        assetKey = "body_muscle_aligned_masks"
    )
}

internal fun emptyVisual(type: HealthCardType) = HealthCardVisualData(
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

internal fun dayPoints(values: List<Int>) = values.mapIndexed { index, value ->
    HealthChartPoint("health_visual_day_${listOf("mon", "tue", "wed", "thu", "fri", "sat", "sun").getOrElse(index) { "mon" }}", value.toDouble())
}

internal fun halfHourLabel(startMinute: Int): String {
    val minuteOfDay = startMinute.coerceIn(0, 23 * 60 + 30)
    val hour = minuteOfDay / 60
    val minute = minuteOfDay % 60
    return hour.toString().padStart(2, '0') + ":" + minute.toString().padStart(2, '0')
}

internal fun stressLevel(value: Int) = when {
    value >= 80 -> HealthVisualLevel.High
    value >= 60 -> HealthVisualLevel.Elevated
    value >= 35 -> HealthVisualLevel.Good
    else -> HealthVisualLevel.Low
}

internal fun text(key: String, vararg arguments: Any?) =
    LocalizedTextSpec(key, arguments.map { it?.toString() ?: "---" })

internal fun Double.f1(): String {
    val v = (this * 10).toLong()
    return "${v / 10}.${v % 10}"
}

internal fun Double.f2(): String {
    val v = (this * 100).toLong()
    return "${v / 100}.${(v % 100).toString().padStart(2, '0')}"
}

internal fun pace(seconds: Int?): String {
    if (seconds == null || seconds <= 0) return "---"
    return "${seconds / 60}'${(seconds % 60).toString().padStart(2, '0')}\"/km"
}

internal fun marathon(seconds: Int): String {
    val hours = seconds / 3600
    val minutes = (seconds % 3600) / 60
    val remaining = seconds % 60
    return "$hours:${minutes.toString().padStart(2, '0')}:${remaining.toString().padStart(2, '0')}"
}
