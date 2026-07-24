package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.SleepStage
import com.example.demo.ui.resources.AppColors
import kotlin.math.max

@Composable
fun SleepVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = androidx.compose.ui.Alignment.Bottom) {
                    ValueText(v.primaryValue, 32)
                    UnitText(v.primaryUnit, 20)
                    Spacer(Modifier.width(5.dp))
                    ValueText(v.secondaryValue, 32)
                    UnitText(v.secondaryUnit, 20)
                }
                Text(
                    "${v.startTime ?: "--"} – ${v.endTime ?: "--"}",
                    color = AppColors.Health.Muted,
                    fontSize = 12.sp
                )
            }
        },
        right = { SleepOverview(v) },
    )
}

@Composable
private fun SleepOverview(v: HealthCardVisualData) {
    Canvas(Modifier.width(130.dp).height(56.dp)) {
        val total = max(1, v.sleepStages.maxOfOrNull { it.startMinute + it.durationMinutes } ?: 1)
        v.sleepStages.forEach { segment ->
            val x = size.width * segment.startMinute / total
            val width = max(2f, size.width * segment.durationMinutes / total - 2.dp.toPx())
            val (y, color) = when (segment.stage) {
                SleepStage.Awake -> 0.dp.toPx() to AppColors.Health.VisualYellow
                SleepStage.Rem -> 16.dp.toPx() to AppColors.Health.VisualCyan
                SleepStage.Light -> 32.dp.toPx() to AppColors.Health.VisualBlue
                SleepStage.Deep -> 48.dp.toPx() to AppColors.Health.VisualDeepBlue
            }
            drawRoundRect(color, Offset(x, y), Size(width, 7.dp.toPx()), CornerRadius(2.dp.toPx()))
        }
    }
}
