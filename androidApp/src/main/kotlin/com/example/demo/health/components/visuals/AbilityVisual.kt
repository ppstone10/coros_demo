package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.ui.resources.AppColors
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

@Composable
fun AbilityVisual(type: HealthCardType, v: HealthCardVisualData) {
    val accent = if (type == HealthCardType.RunningAbility) {
        AppColors.Health.VisualOrange
    } else {
        AppColors.Health.VisualGreen
    }
    OverviewRow(
        left = {
            Column(Modifier.padding(top = 8.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 32)
                    UnitText(v.primaryUnit, 20)
                }
                v.caption?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 12.sp,
                        maxLines = 1,
                    )
                }
            }
        },
        right = { AbilityGaugeOverview(v, accent) },
    )
}

@Composable
private fun AbilityGaugeOverview(v: HealthCardVisualData, accent: Color) {
    Box(Modifier.width(121.dp).height(71.dp)) {
        Canvas(Modifier.fillMaxWidth().height(60.dp)) {
            val stroke = 3.dp.toPx()
            val pad = 5.dp.toPx()
            val arcSize = Size(size.width - 2 * pad, (size.height - pad) * 2)
            val progressSweep = abilityNeedleAngleDegrees(v.progress)
            val segmentCount = 30
            val segmentSpan = 180f / segmentCount
            repeat(segmentCount) { index ->
                val start = 180f + index * segmentSpan
                val segmentColor =
                    if ((index + 0.5f) * segmentSpan <= progressSweep) accent
                    else AppColors.Health.GaugeTrack
                drawArc(
                    segmentColor,
                    startAngle = start,
                    sweepAngle = segmentSpan * 0.68f,
                    useCenter = false,
                    topLeft = Offset(pad, pad),
                    size = arcSize,
                    style = Stroke(stroke, cap = StrokeCap.Butt),
                )
            }
            val center = Offset(size.width / 2f, size.height - pad)
            val radians = PI + Math.toRadians(progressSweep.toDouble())
            val radius = (size.width - 2 * pad) * 0.37f
            drawLine(
                AppColors.Health.CardTitle,
                center,
                Offset(
                    center.x + cos(radians).toFloat() * radius,
                    center.y + sin(radians).toFloat() * radius,
                ),
                1.5.dp.toPx(),
                StrokeCap.Round,
            )
            drawCircle(AppColors.Health.CardTitle, 2.5.dp.toPx(), center)
        }
        Row(
            Modifier.align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(horizontal = 2.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text("0", color = AppColors.Health.Muted, fontSize = 10.sp)
            Text("100", color = AppColors.Health.Muted, fontSize = 10.sp)
        }
    }
}
