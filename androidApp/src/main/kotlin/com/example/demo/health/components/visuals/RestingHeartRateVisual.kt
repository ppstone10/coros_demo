package com.example.demo.health.components.visuals

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.model.HealthCardVisualData
import com.example.demo.core.resources.AppColors
import kotlin.math.max
import com.example.demo.common.health.model.HealthCardType
import com.example.demo.health.components.OverviewRow
import com.example.demo.health.components.UnitText
import com.example.demo.health.components.ValueText
import com.example.demo.health.localizedHealthText

@Composable
fun RestingHeartRateVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column(Modifier.padding(top = 8.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(
                        v.primaryValue,
                        32
                    )
                    UnitText(
                        v.primaryUnit,
                        20
                    )
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
        right = { RestingHeartRangeOverview(v) },
    )
}

@Composable
private fun RestingHeartRangeOverview(v: HealthCardVisualData) {
    Column(
        Modifier.width(130.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        v.detail?.let { detail ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Canvas(Modifier.width(3.dp).height(12.dp)) {
                    drawLine(
                        AppColors.Health.Muted,
                        Offset(size.width / 2f, 0f),
                        Offset(size.width / 2f, size.height),
                        1.dp.toPx(),
                        pathEffect = PathEffect.dashPathEffect(floatArrayOf(2.dp.toPx(), 2.dp.toPx()))
                    )
                }
                Text(
                    localizedHealthText(detail),
                    color = AppColors.Health.Muted,
                    fontSize = 11.sp,
                    maxLines = 1,
                )
            }
        }
        Canvas(Modifier.fillMaxWidth().height(18.dp)) {
            val range = v.range ?: return@Canvas
            val denominator = max(1.0, range.maximum - range.minimum)
            val y = 10.dp.toPx()
            drawLine(
                AppColors.Health.VisualPink,
                Offset(0f, y),
                Offset(size.width, y),
                3.dp.toPx(),
                StrokeCap.Butt,
            )
            val x = ((range.current - range.minimum) / denominator)
                .toFloat()
                .coerceIn(0f, 1f) * size.width
            val marker = Path().apply {
                moveTo(x, 2.dp.toPx())
                lineTo(x - 5.dp.toPx(), 14.dp.toPx())
                lineTo(x + 5.dp.toPx(), 14.dp.toPx())
                close()
            }
            drawPath(marker, AppColors.Core.White)
            range.average?.let { average ->
                val averageX = ((average - range.minimum) / denominator)
                    .toFloat()
                    .coerceIn(0f, 1f) * size.width
                drawLine(
                    AppColors.Core.White,
                    Offset(averageX, 2.dp.toPx()),
                    Offset(averageX, 17.dp.toPx()),
                    1.dp.toPx(),
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(2.dp.toPx(), 2.dp.toPx()))
                )
            }
        }
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(
                v.range?.minimum?.toInt()?.toString() ?: "--",
                color = AppColors.Health.Muted,
                fontSize = 10.sp,
            )
            Text(
                v.range?.maximum?.toInt()?.toString() ?: "--",
                color = AppColors.Health.Muted,
                fontSize = 10.sp,
            )
        }
    }
}

@Preview(name = "Resting heart rate visual", showBackground = true, backgroundColor = 0xFF171719)
@Composable
private fun RestingHeartRateVisualPreview() {
    PreviewVisualSurface { RestingHeartRateVisual(previewHealthVisual(HealthCardType.RestingHeartRate)) }
}
