package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.font.FontWeight
import com.example.demo.R
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.HealthRangeLevel
import com.example.demo.ui.resources.AppColors
import kotlin.math.max

@Composable
fun HrvAssessmentVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column(
                Modifier.padding(top = 8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                v.caption?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Core.White,
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                    )
                }
                v.detail?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 12.sp,
                        maxLines = 1,
                    )
                }
            }
        },
        right = { HrvRangeOverview(v) },
    )
}

@Composable
private fun HrvRangeOverview(v: HealthCardVisualData) {
    val range = v.range
    val unit = v.primaryUnit?.let { localizedHealthText(it) }.orEmpty()
    Column(
        Modifier.width(130.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Canvas(Modifier.fillMaxWidth().height(18.dp)) {
            val currentRange = range ?: return@Canvas
            val denominator = max(1.0, currentRange.maximum - currentRange.minimum)
            val indicatorTop = 10.dp.toPx()
            val indicatorHeight = 4.dp.toPx()
            currentRange.segments.forEach { segment ->
                val start = ((segment.minimum - currentRange.minimum) / denominator)
                    .toFloat().coerceIn(0f, 1f)
                val end = ((segment.maximum - currentRange.minimum) / denominator)
                    .toFloat().coerceIn(start, 1f)
                val color = when (segment.level) {
                    HealthRangeLevel.VeryLow -> AppColors.Health.RangeLow
                    HealthRangeLevel.Low -> AppColors.Health.RangeCaution
                    HealthRangeLevel.Normal -> AppColors.Health.RangeNormal
                    HealthRangeLevel.High -> AppColors.Health.RangeHigh
                }
                drawRect(
                    color,
                    Offset(size.width * start, indicatorTop),
                    Size(size.width * (end - start), indicatorHeight),
                )
            }
            val x = ((currentRange.current - currentRange.minimum) / denominator)
                .toFloat()
                .coerceIn(0f, 1f) * size.width
            val marker = Path().apply {
                moveTo(x, 2.dp.toPx())
                lineTo(x - 5.dp.toPx(), 14.dp.toPx())
                lineTo(x + 5.dp.toPx(), 14.dp.toPx())
                close()
            }
            drawPath(marker, AppColors.Core.White)
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(5.dp)
                    .background(AppColors.Health.RangeNormal, RoundedCornerShape(3.dp)),
            )
            Spacer(Modifier.width(4.dp))
            Text(
                stringResource(
                    R.string.health_visual_normal_range_short,
                    range?.normalMin?.toInt()?.toString() ?: "--",
                    range?.normalMax?.toInt()?.toString() ?: "--",
                    unit,
                ),
                color = AppColors.Health.Muted,
                fontSize = 10.sp,
                maxLines = 1,
            )
        }
    }
}
