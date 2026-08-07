package com.example.demo.health.components

import com.example.demo.common.health.model.HealthCardVisualData
import com.example.demo.common.health.model.HealthMetric
import com.example.demo.common.health.model.LocalizedTextSpec
import kotlin.math.max
import kotlin.math.min

internal const val CALORIE_ARC_MAX = 800

internal fun calorieArcProgress(calories: Int?): Float =
    ((calories ?: 0).coerceIn(0, CALORIE_ARC_MAX) / CALORIE_ARC_MAX.toFloat())

internal fun clampedVisualProgress(progress: Double?): Float =
    (progress ?: 0.0).toFloat().coerceIn(0f, 1f)

internal fun abilityNeedleAngleDegrees(progress: Double?): Float =
    180f * clampedVisualProgress(progress)

internal fun circularArcDiameter(availableWidth: Float, availableHeight: Float): Float =
    min(availableWidth, availableHeight).coerceAtLeast(0f)

internal fun normalizedHeartRateInterval(
    minimum: Double,
    maximum: Double,
    chartMinimum: Double,
    chartMaximum: Double
): ClosedFloatingPointRange<Float> {
    val low = min(minimum, maximum)
    val high = max(minimum, maximum)
    val denominator = max(1.0, chartMaximum - chartMinimum)
    val normalizedLow = ((low - chartMinimum) / denominator).toFloat().coerceIn(0f, 1f)
    val normalizedHigh = ((high - chartMinimum) / denominator).toFloat().coerceIn(0f, 1f)
    return normalizedLow..normalizedHigh
}

internal fun rangeMarkerVerticalBounds(
    indicatorTopY: Float,
    height: Float = 7f
): ClosedFloatingPointRange<Float> {
    val safeHeight = height.coerceAtLeast(0f)
    return (indicatorTopY - safeHeight)..(indicatorTopY + safeHeight / 2f)
}

internal fun weeklyVisualForSelectedDay(
    visual: HealthCardVisualData,
    requestedDayIndex: Int
): HealthCardVisualData {
    val dayIndex = requestedDayIndex.coerceIn(0, 6)
    val plan = visual.weeklyDayPlans.firstOrNull { it.dayIndex == dayIndex }
    return visual.copy(
        primaryValue = plan?.workoutDurationMinutes?.toString(),
        primaryUnit = plan?.workoutDurationMinutes?.let { LocalizedTextSpec("health_unit_minutes_long") },
        caption = plan?.workoutName ?: LocalizedTextSpec("health_visual_weekly_rest_day"),
        metrics = plan?.workoutTrainingLoad?.let {
            listOf(HealthMetric(LocalizedTextSpec("health_visual_training_load_short"), it.toString()))
        }.orEmpty(),
        highlightedIndex = dayIndex
    )
}
