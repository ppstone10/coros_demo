package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.HealthCardStatus
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.HealthChartPoint
import com.example.demo.common.health.HealthMetric
import com.example.demo.common.health.HealthPreviewFixtures
import com.example.demo.common.health.HealthVisualLevel
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.theme.DemoTheme
import kotlin.math.max

internal val CorosFontFamily = FontFamily(
    Font(R.font.coros_app_regular, FontWeight.Normal),
    Font(R.font.coros_app_bold, FontWeight.Bold),
)

@Composable
fun DashboardCard(
    card: HealthCardUiModel,
    onBodyWeightClick: () -> Unit = {},
    onClick: () -> Unit
) {
    val shape = RoundedCornerShape(8.dp)
    Column(
        modifier = Modifier
            .padding(horizontal = AppSpacing.Screen, vertical = 6.dp)
            .fillMaxWidth()
            .clip(shape)
            .clipToBounds()
            .background(AppColors.Health.Card)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        CardHeader(card)
        if (card.status == HealthCardStatus.Empty) {
            EmptyContent(card)
        } else {
            Box(Modifier.fillMaxWidth().clipToBounds()) {
                HealthCardVisualContent(
                    type = card.type,
                    visual = card.visual,
                    onBodyWeightClick = onBodyWeightClick
                )
            }
        }
    }
}

@Composable
private fun CardHeader(card: HealthCardUiModel) {
    Row(Modifier.height(24.dp), verticalAlignment = Alignment.CenterVertically) {
        if (card.type == HealthCardType.TodayActivity) {
            AppImage(AppImages.Health.TodayHeader, null, Modifier.size(20.dp))
        } else {
            AppImage(iconOf(card.type), null, Modifier.size(20.dp))
        }
        Spacer(Modifier.width(5.dp))
        Text(
            localizedHealthText(card.title),
            modifier = Modifier.weight(1f),
            color = AppColors.Health.CardTitle,
            fontSize = 16.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        if (card.type == HealthCardType.HealthCheck) {
            card.visual.caption?.let {
                Text(
                    localizedHealthText(it),
                    color = AppColors.Health.Muted,
                    fontSize = 12.sp,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
private fun EmptyContent(card: HealthCardUiModel) {
    Text(
        localizedHealthText(card.summary),
        modifier = Modifier.padding(top = 12.dp),
        color = AppColors.Health.Muted,
        fontSize = 14.sp,
        lineHeight = 18.sp
    )
}

@Composable
private fun HealthCardVisualContent(
    type: HealthCardType,
    visual: HealthCardVisualData,
    onBodyWeightClick: () -> Unit
) {
    when (type) {
        HealthCardType.TodayActivity -> ActivityVisual(visual)
        HealthCardType.WeeklyPlan -> WeeklyVisual(visual)
        HealthCardType.TrainingLoad -> LoadVisual(visual)
        HealthCardType.TrainingAssessment -> AssessmentVisual(visual)
        HealthCardType.Recovery -> RecoveryVisual(visual)
        HealthCardType.RunningAbility, HealthCardType.CyclingAbility -> AbilityVisual(type, visual)
        HealthCardType.HeartRate, HealthCardType.Stress -> TrendVisual(type, visual)
        HealthCardType.Sleep -> SleepVisual(visual)
        HealthCardType.HrvAssessment -> HrvAssessmentVisual(visual)
        HealthCardType.RestingHeartRate -> RestingHeartRateVisual(visual)
        HealthCardType.HealthCheck -> HealthGridVisual(visual)
        HealthCardType.BodyManagement -> BodyVisual(visual, onBodyWeightClick)
    }
}

@Composable
internal fun OverviewRow(left: @Composable () -> Unit, right: @Composable () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(IntrinsicSize.Min),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.width(141.dp).fillMaxHeight(), contentAlignment = Alignment.CenterStart) {
            Column(Modifier.padding(top = 8.dp)) { left() }
        }
        Spacer(Modifier.weight(1f))
        Box(Modifier.fillMaxHeight().clipToBounds(), contentAlignment = Alignment.CenterEnd) { right() }
    }
}

@Composable
internal fun MiniBars(
    points: List<HealthChartPoint>,
    highlighted: Int?,
    modifier: Modifier,
    colorOverride: Color? = null,
    dense: Boolean = false,
    showTrack: Boolean = false,
) {
    Canvas(modifier.clipToBounds()) {
        if (points.isEmpty()) return@Canvas
        val top = max(1.0, points.maxOf { it.value })
        val gap = (if (dense) 2.dp else 5.dp).toPx()
        val bar = max(1.dp.toPx(), (size.width - gap * (points.size - 1)) / points.size)
        points.forEachIndexed { index, point ->
            val x = index * (bar + gap)
            if (showTrack) {
                drawRoundRect(
                    AppColors.Health.GaugeTrack,
                    Offset(x, 0f),
                    Size(bar, size.height),
                    CornerRadius(minOf(bar / 2, 2.dp.toPx())),
                )
            }
            val h = if (point.value <= 0) 2.dp.toPx() else (size.height * point.value / top).toFloat().coerceAtLeast(3.dp.toPx())
            val color = colorOverride ?: when {
                index == highlighted -> AppColors.Health.VisualCyan
                point.level == HealthVisualLevel.High -> AppColors.Health.Warning
                point.level == HealthVisualLevel.Elevated -> AppColors.Health.VisualOrange
                point.level == HealthVisualLevel.Good -> AppColors.Health.VisualYellow
                else -> AppColors.Health.VisualBar
            }
            drawRoundRect(color, Offset(x, size.height - h), Size(bar, h), CornerRadius(minOf(bar / 2, 2.dp.toPx())))
        }
    }
}

@Composable
internal fun MetricValue(metric: HealthMetric, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.Start) {
        Row(verticalAlignment = Alignment.Bottom) {
            ValueText(metric.value, 30)
            UnitText(metric.unit, 16)
        }
        Text(
            localizedHealthText(metric.label),
            color = AppColors.Health.Muted,
            fontSize = 12.sp,
            maxLines = 1
        )
    }
}

@Composable
internal fun ValueText(value: String?, size: Int) {
    Text(
        value ?: "--",
        color = AppColors.Core.White,
        fontSize = size.sp,
        fontFamily = CorosFontFamily,
        fontWeight = FontWeight.Bold,
        maxLines = 1
    )
}

@Composable
internal fun UnitText(unit: LocalizedTextSpec?, size: Int) {
    unit?.let {
        Text(
            localizedHealthText(it),
            color = AppColors.Health.MetricUnit,
            fontSize = size.sp,
            fontFamily = CorosFontFamily,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 3.dp, bottom = 2.dp),
            maxLines = 1
        )
    }
}

@Composable
fun titleOf(type: HealthCardType) =
    localizedHealthText(LocalizedTextSpec("health_card_${type.resourceName()}_title"))

fun HealthCardType.resourceName() = when (this) {
    HealthCardType.WeeklyPlan -> "weekly_plan"
    HealthCardType.TodayActivity -> "today_activity"
    HealthCardType.TrainingLoad -> "training_load"
    HealthCardType.TrainingAssessment -> "training_assessment"
    HealthCardType.Recovery -> "recovery"
    HealthCardType.RunningAbility -> "running_ability"
    HealthCardType.CyclingAbility -> "cycling_ability"
    HealthCardType.HeartRate -> "heart_rate"
    HealthCardType.Stress -> "stress"
    HealthCardType.Sleep -> "sleep"
    HealthCardType.HrvAssessment -> "hrv_assessment"
    HealthCardType.RestingHeartRate -> "resting_heart_rate"
    HealthCardType.HealthCheck -> "health_check"
    HealthCardType.BodyManagement -> "body_management"
}

fun iconOf(type: HealthCardType) = when (type) {
    HealthCardType.WeeklyPlan -> AppImages.Health.WeeklyPlan
    HealthCardType.TodayActivity -> AppImages.Health.TodayActivity
    HealthCardType.TrainingLoad -> AppImages.Health.TrainingLoad
    HealthCardType.TrainingAssessment -> AppImages.Health.TrainingAssessment
    HealthCardType.Recovery -> AppImages.Health.Recovery
    HealthCardType.RunningAbility -> AppImages.Health.RunningAbility
    HealthCardType.CyclingAbility -> AppImages.Health.CyclingAbility
    HealthCardType.HeartRate -> AppImages.Health.HeartRate
    HealthCardType.Stress -> AppImages.Health.Stress
    HealthCardType.Sleep -> AppImages.Health.Sleep
    HealthCardType.HrvAssessment -> AppImages.Health.HrvAssessment
    HealthCardType.RestingHeartRate -> AppImages.Health.RestingHeartRate
    HealthCardType.HealthCheck -> AppImages.Health.HealthCheck
    HealthCardType.BodyManagement -> AppImages.Health.BodyManagement
}

@Preview(showBackground = true, backgroundColor = 0xFF000000, locale = "zh")
@Composable
private fun AllCardsPreview() {
    val state = requireNotNull(HealthPreviewFixtures.normalState().uiState)

    DemoTheme {
        Column(
            Modifier.background(AppColors.Health.Page)
                .verticalScroll(rememberScrollState())
                .padding(vertical = 8.dp)
        ) {
            state.cards.forEach { card ->
                DashboardCard(card) {}
            }
        }
    }
}
