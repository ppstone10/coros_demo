package com.example.demo.health

import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.HealthCardVisualKind
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.common.health.WeeklyDayPlan
import org.junit.Assert.assertEquals
import org.junit.Test

class DashboardVisualMathTest {
    @Test
    fun calorieArcUsesZeroToEightHundredClampedScale() {
        assertEquals(0f, calorieArcProgress(null), 0.0001f)
        assertEquals(0f, calorieArcProgress(-20), 0.0001f)
        assertEquals(0.5f, calorieArcProgress(400), 0.0001f)
        assertEquals(1f, calorieArcProgress(800), 0.0001f)
        assertEquals(1f, calorieArcProgress(1_200), 0.0001f)
    }

    @Test
    fun abilityNeedleAndGaugeProgressStayInsideDrawableRange() {
        assertEquals(0f, clampedVisualProgress(-0.25), 0.0001f)
        assertEquals(0.5f, clampedVisualProgress(0.5), 0.0001f)
        assertEquals(1f, clampedVisualProgress(1.25), 0.0001f)
        assertEquals(90f, abilityNeedleAngleDegrees(0.5), 0.0001f)
        assertEquals(180f, abilityNeedleAngleDegrees(2.0), 0.0001f)
    }

    @Test
    fun calorieArcDiameterUsesSmallerDimension() {
        assertEquals(116f, circularArcDiameter(142f, 116f), 0.0001f)
        assertEquals(90f, circularArcDiameter(90f, 120f), 0.0001f)
    }

    @Test
    fun heartRateIntervalNormalizesMinimumAndMaximumWithoutBaseline() {
        val interval = normalizedHeartRateInterval(60.0, 100.0, 40.0, 120.0)
        assertEquals(0.25f, interval.start, 0.0001f)
        assertEquals(0.75f, interval.endInclusive, 0.0001f)

        val reversed = normalizedHeartRateInterval(100.0, 60.0, 40.0, 120.0)
        assertEquals(interval, reversed)
    }

    @Test
    fun rangeMarkerTriangleStaysBelowIndicatorLine() {
        val markerBounds = rangeMarkerVerticalBounds(indicatorBottomY = 13f, gap = 3f, height = 7f)

        assertEquals(16f, markerBounds.start, 0.0001f)
        assertEquals(23f, markerBounds.endInclusive, 0.0001f)
    }

    @Test
    fun weeklyDateSelectionSwitchesOnlyTheDisplayedDayPlan() {
        val original = HealthCardVisualData(
            kind = HealthCardVisualKind.WeeklyPlan,
            highlightedIndex = 3,
            weeklyDayPlans = listOf(
                WeeklyDayPlan(3, LocalizedTextSpec("wednesday"), 60, 50),
                WeeklyDayPlan(4, LocalizedTextSpec("thursday"), 90, 80)
            )
        )

        val thursday = weeklyVisualForSelectedDay(original, 4)

        assertEquals(4, thursday.highlightedIndex)
        assertEquals("thursday", thursday.caption?.key)
        assertEquals("90", thursday.primaryValue)
        assertEquals("80", thursday.metrics.single().value)
        assertEquals(original.weeklyDayPlans, thursday.weeklyDayPlans)
    }
}
