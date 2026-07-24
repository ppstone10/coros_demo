package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.ui.resources.AppColors
import kotlin.math.max

@Composable
fun RangeVisual(type: HealthCardType, v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 32)
                    UnitText(v.primaryUnit, 20)
                }
                val leftDetail = if (type == HealthCardType.RestingHeartRate) v.caption else v.detail
                leftDetail?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 12.sp,
                        maxLines = 1
                    )
                }
            }
        },
        right = {
            if (type == HealthCardType.RestingHeartRate) RestingHeartRangeOverview(v)
            else HrvRangeOverview(v)
        },
    )
}

@Composable
private fun RestingHeartRangeOverview(v: HealthCardVisualData) {
    Column(
        Modifier.width(130.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        v.detail?.let {
            Text(
                localizedHealthText(it),
                color = AppColors.Health.Muted,
                fontSize = 11.sp,
                maxLines = 1
            )
        }
        Canvas(Modifier.fillMaxWidth().height(30.dp)) {
            val r = v.range ?: return@Canvas
            val denominator = max(1.0, r.maximum - r.minimum)
            val y = 10.dp.toPx()
            drawLine(
                AppColors.Health.VisualPink,
                Offset(0f, y),
                Offset(size.width, y),
                3.dp.toPx(),
                StrokeCap.Butt
            )
            val x = ((r.current - r.minimum) / denominator).toFloat().coerceIn(0f, 1f) * size.width
            val markerBounds = rangeMarkerVerticalBounds(
                indicatorBottomY = y + 1.5.dp.toPx(),
                gap = 3.dp.toPx(),
                height = 7.dp.toPx()
            )
            val path = Path().apply {
                moveTo(x, markerBounds.start)
                lineTo(x - 5.dp.toPx(), markerBounds.endInclusive)
                lineTo(x + 5.dp.toPx(), markerBounds.endInclusive)
                close()
            }
            drawPath(path, AppColors.Core.White)
        }
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween
        ) {
            Text(
                v.range?.minimum?.toInt()?.toString() ?: "--",
                color = AppColors.Health.Muted,
                fontSize = 10.sp
            )
            Text(
                v.range?.maximum?.toInt()?.toString() ?: "--",
                color = AppColors.Health.Muted,
                fontSize = 10.sp
            )
        }
    }
}

@Composable
private fun HrvRangeOverview(v: HealthCardVisualData) {
    val range = v.range
    val unit = v.primaryUnit?.let { localizedHealthText(it) }.orEmpty()
    Column(
        Modifier.width(130.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
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
        Canvas(Modifier.fillMaxWidth().height(30.dp)) {
            val r = range ?: return@Canvas
            val colors = listOf(
                AppColors.Health.RangeLow,
                AppColors.Health.RangeCaution,
                AppColors.Health.RangeNormal,
                AppColors.Health.RangeHigh,
            )
            val gap = 2.dp.toPx()
            val segmentWidth = (size.width - gap * 3) / 4f
            val indicatorTop = 9.dp.toPx()
            val indicatorHeight = 4.dp.toPx()
            colors.forEachIndexed { index, color ->
                drawRect(
                    color,
                    Offset(index * (segmentWidth + gap), indicatorTop),
                    Size(segmentWidth, indicatorHeight)
                )
            }
            val denominator = max(1.0, r.maximum - r.minimum)
            val x = ((r.current - r.minimum) / denominator).toFloat().coerceIn(0f, 1f) * size.width
            val markerBounds = rangeMarkerVerticalBounds(
                indicatorBottomY = indicatorTop + indicatorHeight,
                gap = 3.dp.toPx(),
                height = 7.dp.toPx()
            )
            val marker = Path().apply {
                moveTo(x, markerBounds.start)
                lineTo(x - 5.dp.toPx(), markerBounds.endInclusive)
                lineTo(x + 5.dp.toPx(), markerBounds.endInclusive)
                close()
            }
            drawPath(marker, AppColors.Core.White)
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(5.dp)
                    .background(AppColors.Health.RangeNormal, RoundedCornerShape(3.dp))
            )
            Spacer(Modifier.width(4.dp))
            v.caption?.let {
                Text(
                    localizedHealthText(it),
                    color = AppColors.Health.Muted,
                    fontSize = 10.sp,
                    maxLines = 1
                )
            }
        }
    }
}
