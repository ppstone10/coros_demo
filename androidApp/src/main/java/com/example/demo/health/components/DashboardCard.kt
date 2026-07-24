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
import com.example.demo.common.health.BodyManagement
import com.example.demo.common.health.CyclingAbility
import com.example.demo.common.health.DailySummary
import com.example.demo.common.health.HealthCardStatus
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.HealthCardVisualKind
import com.example.demo.common.health.HealthChartPoint
import com.example.demo.common.health.HealthCheck
import com.example.demo.common.health.HealthDashboardData
import com.example.demo.common.health.HealthDashboardDataSource
import com.example.demo.common.health.HealthDashboardUseCase
import com.example.demo.common.health.HealthMetric
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.health.HealthVisualLevel
import com.example.demo.common.health.HeartRate
import com.example.demo.common.health.HrvAssessment
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.common.health.Recovery
import com.example.demo.common.health.RestingHeartRate
import com.example.demo.common.health.RunningAbility
import com.example.demo.common.health.SleepStage
import com.example.demo.common.health.SleepStageSegment
import com.example.demo.common.health.SleepSummary
import com.example.demo.common.health.Stress
import com.example.demo.common.health.TodayActivity
import com.example.demo.common.health.TrainingAssessment
import com.example.demo.common.health.TrainingLoad
import com.example.demo.common.health.WeeklyPlan
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
fun DashboardCard(card: HealthCardUiModel, onClick: () -> Unit) {
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
                HealthCardVisualContent(type = card.type, visual = card.visual)
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
    visual: HealthCardVisualData
) {
    when (visual.kind) {
        HealthCardVisualKind.TodayActivity -> ActivityVisual(visual)
        HealthCardVisualKind.WeeklyPlan -> WeeklyVisual(visual)
        HealthCardVisualKind.TrainingLoad -> LoadVisual(visual)
        HealthCardVisualKind.TrainingAssessment -> AssessmentVisual(visual)
        HealthCardVisualKind.RecoveryGauge, HealthCardVisualKind.AbilityGauge -> GaugeVisual(type, visual)
        HealthCardVisualKind.TrendBars -> TrendVisual(type, visual)
        HealthCardVisualKind.RangeIndicator -> RangeVisual(type, visual)
        HealthCardVisualKind.SleepStages -> SleepVisual(visual)
        HealthCardVisualKind.HealthCheckGrid -> HealthGridVisual(visual)
        HealthCardVisualKind.BodyMap -> BodyVisual(visual)
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
    val useCase = HealthDashboardUseCase(object : HealthDashboardDataSource {
        override fun load(scenario: HealthMockScenario) = error("not used")
    })
    val data = HealthDashboardData(
        dailySummary = DailySummary(8769, 769, 69),
        todayActivity = TodayActivity(8.41, 637, LocalizedTextSpec("health_visual_activity_easy_run"), 78),
        sleepSummary = SleepSummary(504, 86, "23:00", "08:40", listOf(
            SleepStageSegment(SleepStage.Awake, 0, 18),
            SleepStageSegment(SleepStage.Light, 18, 72),
            SleepStageSegment(SleepStage.Deep, 90, 55),
            SleepStageSegment(SleepStage.Light, 145, 74),
            SleepStageSegment(SleepStage.Rem, 219, 42),
            SleepStageSegment(SleepStage.Light, 261, 65),
            SleepStageSegment(SleepStage.Deep, 326, 38),
            SleepStageSegment(SleepStage.Light, 364, 77),
            SleepStageSegment(SleepStage.Rem, 441, 45),
            SleepStageSegment(SleepStage.Awake, 486, 18)
        )),
        trainingLoad = TrainingLoad(246, 600, 800, listOf(22, 11, 22, 12, 0, 0, 0)),
        recovery = Recovery(95, 5),
        weeklyPlan = WeeklyPlan(
            true, 300, null, 3, listOf(0, 0, 0, 78, 0, 0, 0),
            LocalizedTextSpec("health_visual_workout_easy_run"), 102, 78
        ),
        trainingAssessment = TrainingAssessment(
            78, "increasing", 155, 138, 1.2,
            LocalizedTextSpec("health_visual_assessment_efficient"),
            LocalizedTextSpec("health_visual_assessment_efficient_detail")
        ),
        runningAbility = RunningAbility(52, 85, 78.6, 12621),
        cyclingAbility = CyclingAbility(220, 72, 80.6, LocalizedTextSpec("health_visual_cycling_climber")),
        heartRate = HeartRate(55, 68, 81, listOf(62, 65, 63, 68, 72, 70, 76, 74, 80, 84, 78, 92, 86, 81, 88, 79, 76, 82, 75, 72, 77, 70, 74, 68)),
        stress = Stress(35, "normal", 52, listOf(18, 20, 22, 25, 28, 32, 38, 45, 52, 61, 74, 86, 78, 64, 52, 40, 34, 48, 58, 42, 30, 25, 22, 20)),
        hrvAssessment = HrvAssessment(48, "low", 48, 52, 60),
        restingHeartRate = RestingHeartRate(58, "08:45", 52, 30, 80),
        healthCheck = HealthCheck(82, 0, "15:04", 91, 42, 45, 91, 91),
        bodyManagement = BodyManagement(68.2, 15.5, 22.3, "2022/8/7", listOf("chest", "quadriceps"))
    )
    val state = useCase.toUiState(data)

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
