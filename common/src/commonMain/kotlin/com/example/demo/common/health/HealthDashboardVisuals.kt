package com.example.demo.common.health

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
    return HealthCardVisualData(
        kind = HealthCardVisualKind.RangeIndicator,
        primaryValue = current.toInt().toString(), primaryUnit = text("health_unit_milliseconds"),
        caption = text(if (current < (value.normalMin ?: 0)) "health_visual_hrv_low" else "health_visual_hrv_balanced"),
        detail = text("health_visual_hrv_average", current.toInt()),
        range = HealthRange(30.0, 80.0, current, value.normalMin?.toDouble(), value.normalMax?.toDouble())
    )
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

internal fun bodyVisual(value: BodyManagement) = HealthCardVisualData(
    kind = HealthCardVisualKind.BodyMap,
    primaryValue = value.weightKg?.f1(), primaryUnit = text("health_unit_kilograms"),
    caption = text("health_visual_weight"),
    detail = text("health_visual_measured_date", value.measuredDate ?: "---"),
    metrics = value.trainedMuscleGroups.map { HealthMetric(text("health_visual_muscle_$it"), "") },
    assetKey = "body_muscle_front_back"
)

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
