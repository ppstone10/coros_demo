package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.ui.resources.AppColors
import kotlin.math.max

@Composable
fun TrendVisual(type: HealthCardType, v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 32)
                    UnitText(v.primaryUnit, 20)
                }
                v.caption?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 12.sp
                    )
                }
            }
        },
        right = {
            if (type == HealthCardType.HeartRate) HeartRateOverview(v)
            else StressOverview(v)
        },
    )
}

@Composable
private fun HeartRateOverview(v: HealthCardVisualData) {
    Canvas(Modifier.width(166.dp).height(44.dp)) {
        if (v.chartPoints.isEmpty()) return@Canvas
        val chartMinimum = v.chartPoints.minOf { it.minimum ?: it.value }
        val chartMaximum = v.chartPoints.maxOf { it.maximum ?: it.value }
        val topPadding = 3.dp.toPx()
        val drawableHeight = size.height - 2 * topPadding
        val denominator = (v.chartPoints.size - 1).coerceAtLeast(1)
        v.chartPoints.forEachIndexed { index, point ->
            val normalized = normalizedHeartRateInterval(
                point.minimum ?: point.value,
                point.maximum ?: point.value,
                chartMinimum,
                chartMaximum,
            )
            val x = index.toFloat() / denominator * size.width
            val highY = topPadding + drawableHeight * (1f - normalized.endInclusive)
            val lowY = topPadding + drawableHeight * (1f - normalized.start)
            val visibleLowY = max(lowY, highY + 1.dp.toPx())
            drawLine(
                AppColors.Health.VisualPink,
                Offset(x, highY),
                Offset(x, visibleLowY),
                1.dp.toPx(),
                StrokeCap.Butt,
            )
        }
    }
}

@Composable
private fun StressOverview(v: HealthCardVisualData) {
    Canvas(Modifier.width(166.dp).height(56.dp)) {
        if (v.chartPoints.isEmpty()) return@Canvas
        val values = v.chartPoints.map { it.value }
        val high = max(100.0, values.maxOrNull() ?: 100.0)
        val step = 2.dp.toPx().coerceAtLeast(1f)
        val count = (size.width / step).toInt().coerceAtLeast(2)
        repeat(count) { index ->
            val chartPosition = index.toFloat() / (count - 1) * (values.size - 1)
            val leftIndex = chartPosition.toInt().coerceIn(0, values.lastIndex)
            val rightIndex = (leftIndex + 1).coerceAtMost(values.lastIndex)
            val fraction = chartPosition - leftIndex
            val value = values[leftIndex] + (values[rightIndex] - values[leftIndex]) * fraction
            val height = (size.height * (value / high).toFloat()).coerceAtLeast(2.dp.toPx())
            val color = when {
                value >= 80 -> AppColors.Health.VisualOrange
                value >= 60 -> AppColors.Health.VisualYellow
                value >= 35 -> AppColors.Health.StressGood
                else -> AppColors.Health.StressLow
            }
            val x = index * step
            drawLine(color, Offset(x, size.height), Offset(x, size.height - height), 1.dp.toPx(), StrokeCap.Butt)
        }
    }
}
