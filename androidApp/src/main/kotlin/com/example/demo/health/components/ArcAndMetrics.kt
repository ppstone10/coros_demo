package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.DailySummary
import com.example.demo.common.health.DashboardUiState
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImageAsset
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme

@Composable
fun ArcAndMetricsSection(state: DashboardUiState) {
    ArcAndMetrics(state)
}

@Composable
fun ArcAndMetrics(state: DashboardUiState) {
    Box(
        Modifier
            .fillMaxWidth()
            .height(140.dp)
            .padding(horizontal = 20.dp)
    ) {
        Canvas(
            Modifier
                .size(116.dp)
                .align(Alignment.Center)
        ) {
            val progress = calorieArcProgress(state.dailySummary?.calories)
            val stroke = 5.dp.toPx()
            val inset = stroke / 2
            val arcColor = lerp(AppColors.Health.CalorieArcStart, AppColors.Health.CalorieArcEnd, progress)
            drawArc(
                color = AppColors.Health.CalorieArcTrack,
                startAngle = 135f,
                sweepAngle = 270f,
                useCenter = false,
                style = Stroke(stroke, cap = StrokeCap.Round),
                topLeft = Offset(inset, inset),
                size = Size(size.width - stroke, size.height - stroke)
            )
            if (progress > 0f) {
                drawArc(
                    color = arcColor,
                    startAngle = 135f,
                    sweepAngle = 270f * progress,
                    useCenter = false,
                    style = Stroke(stroke, cap = StrokeCap.Round),
                    topLeft = Offset(inset, inset),
                    size = Size(size.width - stroke, size.height - stroke)
                )
            }
        }
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Metric(
                state.dailySummary?.steps ?: 0,
                stringResource(R.string.health_unit_steps), AppImages.Health.Steps, AppColors.Health.Steps
            )
            Metric(
                state.dailySummary?.calories ?: 0,
                stringResource(R.string.health_unit_calories), AppImages.Health.Calories, AppColors.Health.Calories
            )
            Metric(
                state.dailySummary?.activeMinutes ?: 0,
                stringResource(R.string.health_unit_minutes), AppImages.Health.ActiveDuration, AppColors.Health.ActiveDuration
            )
        }
    }
}

@Composable
fun Metric(value: Int, unit: String, icon: AppImageAsset, iconColor: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(82.dp)) {
        AppImage(asset = icon, contentDescription = null, colorFilter = ColorFilter.tint(iconColor), modifier = Modifier.size(22.dp))
        Text(text = value.toString(), color = AppColors.Core.White, fontSize = 26.sp, letterSpacing = 1.sp)
        Text(text = unit, color = AppColors.Health.MetricUnit, fontSize = AppTypography.Caption)
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun ArcAndMetricsPreview() {
    DemoTheme {
        Box(Modifier.fillMaxSize()) {
            ArcAndMetricsSection(
                DashboardUiState(
                    LocalizedTextSpec("health_today"),
                    LocalizedTextSpec("health_demo_date"),
                    DailySummary(8769, 769, 69),
                    emptyList()
                )
            )
        }
    }
}
