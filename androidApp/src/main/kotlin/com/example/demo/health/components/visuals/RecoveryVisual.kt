package com.example.demo.health.components.visuals

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.model.HealthCardVisualData
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImages
import com.example.demo.common.health.model.HealthCardType
import com.example.demo.health.components.OverviewRow
import com.example.demo.health.components.UnitText
import com.example.demo.health.components.ValueText
import com.example.demo.health.components.clampedVisualProgress
import com.example.demo.health.localizedHealthText

@Composable
fun RecoveryVisual(v: HealthCardVisualData) {
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
        right = { RecoveryGaugeOverview(v) },
    )
}

@Composable
private fun RecoveryGaugeOverview(v: HealthCardVisualData) {
    val progress = clampedVisualProgress(v.progress)
    Box(Modifier.width(114.dp).height(78.dp), contentAlignment = Alignment.TopCenter) {
        Canvas(Modifier.width(114.dp).height(58.dp)) {
            val stroke = 4.dp.toPx()
            val pad = 3.dp.toPx()
            val arcSize = Size(size.width - 2 * pad, (size.height - pad) * 2)
            drawArc(
                AppColors.Health.GaugeTrack, 180f, 180f, false,
                topLeft = Offset(pad, pad), size = arcSize,
                style = Stroke(stroke, cap = StrokeCap.Butt),
            )
            if (progress > 0f) {
                drawArc(
                    AppColors.Health.VisualCyan, 180f, 180f * progress, false,
                    topLeft = Offset(pad, pad), size = arcSize,
                    style = Stroke(stroke, cap = StrokeCap.Butt),
                )
            }
        }
        AppImage(
            AppImages.Health.RecoveryStatus,
            null,
            Modifier.padding(top = 20.dp).width(21.dp).height(30.dp),
        )
        Text(
            stringResource(
                if (progress >= 0.7f) R.string.health_visual_recovery_ready
                else R.string.health_visual_recovery_low,
            ),
            color = AppColors.Health.CardTitle,
            fontSize = 11.sp,
            modifier = Modifier.align(Alignment.BottomCenter),
            maxLines = 1,
        )
    }
}

@Preview(name = "Recovery visual", showBackground = true, backgroundColor = 0xFF171719)
@Composable
private fun RecoveryVisualPreview() {
    PreviewVisualSurface { RecoveryVisual(previewHealthVisual(HealthCardType.Recovery)) }
}
