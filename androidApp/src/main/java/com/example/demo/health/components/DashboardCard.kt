package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.HealthCardAction
import com.example.demo.common.health.HealthCardStatus
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.HealthCardVisualKind
import com.example.demo.common.health.HealthChartPoint
import com.example.demo.common.health.HealthMetric
import com.example.demo.common.health.HealthVisualLevel
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.common.health.SleepStage
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.theme.DemoTheme
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

private val CardBlack = AppColors.Health.Card
private val Muted = AppColors.Health.Muted
private val Green = AppColors.Health.VisualGreen
private val Yellow = AppColors.Health.VisualYellow
private val Orange = AppColors.Health.VisualOrange
private val Purple = AppColors.Health.VisualPurple
private val Blue = AppColors.Health.VisualBlue
private val CorosFontFamily = FontFamily(
    Font(R.font.coros_app_regular, FontWeight.Normal),
    Font(R.font.coros_app_bold, FontWeight.Bold),
)

private object FigmaCardHeight {
    val TodayActivity = 114.dp
    val WeeklyPlan = 178.dp
    val TrainingAssessment = 206.dp
    val HealthCheck = 180.dp
    val BodyMap = 188.dp
    val Compact = 122.dp

    fun forKind(kind: HealthCardVisualKind): Dp = when (kind) {
        HealthCardVisualKind.TodayActivity -> TodayActivity
        HealthCardVisualKind.WeeklyPlan -> WeeklyPlan
        HealthCardVisualKind.TrainingAssessment -> TrainingAssessment
        HealthCardVisualKind.HealthCheckGrid -> HealthCheck
        HealthCardVisualKind.BodyMap -> BodyMap
        else -> Compact
    }
}

@Composable
fun DashboardCard(card: HealthCardUiModel, onClick: () -> Unit) {
    val shape = RoundedCornerShape(8.dp)
    Column(
        modifier = Modifier
            .padding(horizontal = AppSpacing.Screen, vertical = 6.dp)
            .fillMaxWidth()
            .height(FigmaCardHeight.forKind(card.visual.kind))
            .clip(shape)
            .clipToBounds()
            .background(CardBlack)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        CardHeader(card)
        Spacer(Modifier.height(if (card.visual.kind == HealthCardVisualKind.TodayActivity) 10.dp else 8.dp))
        Box(Modifier.fillMaxSize().clipToBounds()) {
            if (card.status == HealthCardStatus.Empty) EmptyContent(card) else VisualContent(card.type, card.visual)
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
            color = AppColors.Health.CardTitle,
            fontSize = 16.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
private fun EmptyContent(card: HealthCardUiModel) {
    Text(localizedHealthText(card.summary), color = Muted, fontSize = 12.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
}

@Composable
private fun VisualContent(type: HealthCardType, visual: HealthCardVisualData) {
    when (visual.kind) {
        HealthCardVisualKind.TodayActivity -> ActivityVisual(visual)
        HealthCardVisualKind.WeeklyPlan -> WeeklyVisual(visual)
        HealthCardVisualKind.TrainingLoad -> LoadVisual(visual)
        HealthCardVisualKind.TrainingAssessment -> AssessmentVisual(visual)
        HealthCardVisualKind.RecoveryGauge, HealthCardVisualKind.AbilityGauge -> GaugeVisual(type, visual)
        HealthCardVisualKind.TrendBars -> TrendVisual(type, visual)
        HealthCardVisualKind.RangeIndicator -> RangeVisual(visual)
        HealthCardVisualKind.SleepStages -> SleepVisual(visual)
        HealthCardVisualKind.HealthCheckGrid -> HealthGridVisual(visual)
        HealthCardVisualKind.BodyMap -> BodyVisual(visual)
    }
}

@Composable
private fun ActivityVisual(v: HealthCardVisualData) {
    Row(Modifier.fillMaxSize(), verticalAlignment = Alignment.CenterVertically) {
        AppImage(AppImages.Health.ActivityMap, null, Modifier.size(48.dp).clip(RoundedCornerShape(6.dp)), ContentScale.Crop)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.Center) {
            Row(verticalAlignment = Alignment.Bottom) {
                ValueText(v.primaryValue, 24)
                UnitText(v.primaryUnit, 16)
            }
            Row {
                v.detail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
                v.caption?.let { Text(" ${localizedHealthText(it)}", color = Muted, fontSize = 12.sp, maxLines = 1) }
            }
        }
        AppImage(AppImages.Health.TodayRunner, null, Modifier.size(24.dp))
    }
}

@Composable
private fun WeeklyVisual(v: HealthCardVisualData) {
    Column(Modifier.fillMaxSize()) {
        WeekLabels(v)
        Spacer(Modifier.height(10.dp))
        Row(
            Modifier.fillMaxWidth().height(64.dp).clip(RoundedCornerShape(6.dp)).background(AppColors.Health.ActivityTile).padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AppImage(AppImages.Health.TodayRunner, null, Modifier.size(20.dp))
            Spacer(Modifier.width(6.dp))
            Column(Modifier.weight(1f)) {
                v.caption?.let { Text(localizedHealthText(it), color = AppColors.Core.White, fontSize = 14.sp, maxLines = 1) }
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 12)
                    UnitText(v.primaryUnit, 12)
                }
            }
            MiniBars(v.chartPoints, v.highlightedIndex, Modifier.width(80.dp).height(36.dp), dense = true)
        }
    }
}

@Composable
private fun WeekLabels(v: HealthCardVisualData) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        v.chartPoints.take(7).forEachIndexed { index, point ->
            Box(
                Modifier.size(28.dp).then(if (index == v.highlightedIndex) Modifier.background(AppColors.Health.Action, RoundedCornerShape(14.dp)) else Modifier),
                contentAlignment = Alignment.Center,
            ) {
                Text(localizedHealthText(LocalizedTextSpec(point.label)), color = if (index == v.highlightedIndex) AppColors.Core.White else Muted, fontSize = 14.sp)
            }
        }
    }
}

@Composable
private fun LoadVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                ValueText(v.primaryValue, 32)
                v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
            }
        },
        right = { MiniBars(v.chartPoints, v.highlightedIndex, Modifier.width(130.dp).height(54.dp), colorOverride = AppColors.Health.VisualCyan) },
    )
}

@Composable
private fun AssessmentVisual(v: HealthCardVisualData) {
    Column(Modifier.fillMaxSize()) {
        v.caption?.let { Text(localizedHealthText(it), color = Orange, fontSize = 20.sp, fontWeight = FontWeight.SemiBold) }
        v.detail?.let { Text(localizedHealthText(it), color = AppColors.Health.CardTitle, fontSize = 14.sp, maxLines = 2, lineHeight = 20.sp) }
        Spacer(Modifier.weight(1f))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            v.metrics.take(3).forEachIndexed { index, metric ->
                MetricValue(metric, Modifier.width(82.dp))
                if (index < 2) Box(Modifier.width(1.dp).height(42.dp).background(AppColors.Health.Divider))
            }
        }
    }
}

@Composable
private fun GaugeVisual(type: HealthCardType, v: HealthCardVisualData) {
    val accent = when (type) {
        HealthCardType.Recovery -> AppColors.Health.VisualCyan
        HealthCardType.RunningAbility -> Orange
        HealthCardType.CyclingAbility -> Green
        else -> Green
    }
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) { ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20) }
                v.detail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
            }
        },
        right = { GaugeOverview(v, accent) },
    )
}

@Composable
private fun GaugeOverview(v: HealthCardVisualData, accent: Color) {
    Column(Modifier.width(130.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Canvas(Modifier.width(114.dp).height(58.dp)) {
            val stroke = 4.dp.toPx()
            drawArc(AppColors.Health.GaugeTrack, 180f, 180f, false, style = Stroke(stroke, cap = StrokeCap.Butt))
            val progress = (v.progress ?: 0.0).toFloat().coerceIn(0f, 1f)
            drawArc(accent, 180f, 180f * progress, false, style = Stroke(stroke, cap = StrokeCap.Butt))
            val radians = PI + PI * progress
            val center = Offset(size.width / 2, size.height)
            val radius = size.width * .36f
            drawLine(AppColors.Health.CardTitle, center, Offset(center.x + cos(radians).toFloat() * radius, center.y + sin(radians).toFloat() * radius), 2.dp.toPx(), StrokeCap.Round)
            drawCircle(AppColors.Health.CardTitle, 3.dp.toPx(), center)
        }
        v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
    }
}

@Composable
private fun TrendVisual(type: HealthCardType, v: HealthCardVisualData) {
    val accent = if (type == HealthCardType.HeartRate) AppColors.Health.VisualPink else Yellow
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) { ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20) }
                v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp) }
            }
        },
        right = { MiniBars(v.chartPoints, null, Modifier.width(166.dp).height(56.dp), colorOverride = accent, dense = true) },
    )
}

@Composable
private fun RangeVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) { ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20) }
                v.detail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
            }
        },
        right = { RangeOverview(v) },
    )
}

@Composable
private fun RangeOverview(v: HealthCardVisualData) {
    Column(Modifier.width(130.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
        Canvas(Modifier.fillMaxWidth().height(24.dp)) {
            val r = v.range ?: return@Canvas
            val denominator = max(1.0, r.maximum - r.minimum)
            val normalStart = (((r.normalMin ?: r.minimum) - r.minimum) / denominator).toFloat() * size.width
            val normalEnd = (((r.normalMax ?: r.maximum) - r.minimum) / denominator).toFloat() * size.width
            drawLine(AppColors.Health.RangeTrack, Offset(0f, 15.dp.toPx()), Offset(size.width, 15.dp.toPx()), 4.dp.toPx())
            drawLine(Green, Offset(normalStart, 15.dp.toPx()), Offset(normalEnd, 15.dp.toPx()), 4.dp.toPx())
            val x = ((r.current - r.minimum) / denominator).toFloat().coerceIn(0f, 1f) * size.width
            val path = Path().apply { moveTo(x, 6.dp.toPx()); lineTo(x - 6.dp.toPx(), 14.dp.toPx()); lineTo(x + 6.dp.toPx(), 14.dp.toPx()); close() }
            drawPath(path, AppColors.Core.White)
        }
    }
}

@Composable
private fun SleepVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20)
                    Spacer(Modifier.width(5.dp)); ValueText(v.secondaryValue, 32); UnitText(v.secondaryUnit, 20)
                }
                Text("${v.startTime ?: "--"} – ${v.endTime ?: "--"}", color = Muted, fontSize = 12.sp)
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
                SleepStage.Awake -> 0.dp.toPx() to Yellow
                SleepStage.Rem -> 16.dp.toPx() to AppColors.Health.VisualCyan
                SleepStage.Light -> 32.dp.toPx() to Blue
                SleepStage.Deep -> 48.dp.toPx() to AppColors.Health.VisualDeepBlue
            }
            drawRoundRect(color, Offset(x, y), Size(width, 7.dp.toPx()), CornerRadius(2.dp.toPx()))
        }
    }
}

@Composable
private fun HealthGridVisual(v: HealthCardVisualData) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp) }
        }
        v.metrics.chunked(3).take(2).forEach { row ->
            Row(Modifier.fillMaxWidth().padding(top = 7.dp), horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                row.forEach { MetricValue(it, Modifier.width(92.dp)) }
            }
        }
    }
}

@Composable
private fun BodyVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                v.caption?.let { Text(localizedHealthText(it), color = AppColors.Health.CardTitle, fontSize = 14.sp) }
                Row(verticalAlignment = Alignment.Bottom) { ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20) }
                v.detail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp) }
            }
        },
        right = {
            Column(Modifier.width(142.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Row(Modifier.height(108.dp), horizontalArrangement = Arrangement.Center) {
                    AppImage(AppImages.Health.BodyFront, null, Modifier.width(52.dp).height(108.dp))
                    AppImage(AppImages.Health.BodyBack, null, Modifier.width(52.dp).height(108.dp))
                }
                Row {
                    v.metrics.take(2).forEachIndexed { index, metric ->
                        if (index > 0) Text(" · ", color = Muted, fontSize = 11.sp)
                        Text(localizedHealthText(metric.label), color = Muted, fontSize = 11.sp, maxLines = 1)
                    }
                }
            }
        },
    )
}

@Composable
private fun OverviewRow(left: @Composable () -> Unit, right: @Composable () -> Unit) {
    Row(Modifier.fillMaxSize(), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(141.dp), contentAlignment = Alignment.CenterStart) { left() }
        Spacer(Modifier.weight(1f))
        Box(Modifier.clipToBounds(), contentAlignment = Alignment.CenterEnd) { right() }
    }
}

@Composable
private fun MiniBars(
    points: List<HealthChartPoint>,
    highlighted: Int?,
    modifier: Modifier,
    colorOverride: Color? = null,
    dense: Boolean = false,
) {
    Canvas(modifier.clipToBounds()) {
        if (points.isEmpty()) return@Canvas
        val top = max(1.0, points.maxOf { it.value })
        val gap = (if (dense) 2.dp else 5.dp).toPx()
        val bar = max(1.dp.toPx(), (size.width - gap * (points.size - 1)) / points.size)
        points.forEachIndexed { index, point ->
            val h = if (point.value <= 0) 2.dp.toPx() else (size.height * point.value / top).toFloat().coerceAtLeast(3.dp.toPx())
            val color = colorOverride ?: when {
                index == highlighted -> AppColors.Health.VisualCyan
                point.level == HealthVisualLevel.High -> AppColors.Health.Warning
                point.level == HealthVisualLevel.Elevated -> Orange
                point.level == HealthVisualLevel.Good -> Yellow
                else -> AppColors.Health.VisualBar
            }
            drawRoundRect(color, Offset(index * (bar + gap), size.height - h), Size(bar, h), CornerRadius(minOf(bar / 2, 2.dp.toPx())))
        }
    }
}

@Composable
private fun MetricValue(metric: HealthMetric, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.Start) {
        Row(verticalAlignment = Alignment.Bottom) { ValueText(metric.value, 30); UnitText(metric.unit, 16) }
        Text(localizedHealthText(metric.label), color = Muted, fontSize = 12.sp, maxLines = 1)
    }
}

@Composable
private fun ValueText(value: String?, size: Int) {
    Text(value ?: "--", color = AppColors.Core.White, fontSize = size.sp, fontFamily = CorosFontFamily, fontWeight = FontWeight.Bold, maxLines = 1)
}

@Composable
private fun UnitText(unit: LocalizedTextSpec?, size: Int) {
    unit?.let {
        Text(localizedHealthText(it), color = AppColors.Health.MetricUnit, fontSize = size.sp, fontFamily = CorosFontFamily, fontWeight = FontWeight.Bold, modifier = Modifier.padding(start = 3.dp, bottom = 2.dp), maxLines = 1)
    }
}

@Composable
fun titleOf(type: HealthCardType) = localizedHealthText(LocalizedTextSpec("health_card_${type.resourceName()}_title"))

fun HealthCardType.resourceName() = when (this) {
    HealthCardType.WeeklyPlan -> "weekly_plan"; HealthCardType.TodayActivity -> "today_activity"
    HealthCardType.TrainingLoad -> "training_load"; HealthCardType.TrainingAssessment -> "training_assessment"
    HealthCardType.Recovery -> "recovery"; HealthCardType.RunningAbility -> "running_ability"
    HealthCardType.CyclingAbility -> "cycling_ability"; HealthCardType.HeartRate -> "heart_rate"
    HealthCardType.Stress -> "stress"; HealthCardType.Sleep -> "sleep"
    HealthCardType.HrvAssessment -> "hrv_assessment"; HealthCardType.RestingHeartRate -> "resting_heart_rate"
    HealthCardType.HealthCheck -> "health_check"; HealthCardType.BodyManagement -> "body_management"
}

fun iconOf(type: HealthCardType) = when (type) {
    HealthCardType.WeeklyPlan -> AppImages.Health.WeeklyPlan; HealthCardType.TodayActivity -> AppImages.Health.TodayActivity
    HealthCardType.TrainingLoad -> AppImages.Health.TrainingLoad; HealthCardType.TrainingAssessment -> AppImages.Health.TrainingAssessment
    HealthCardType.Recovery -> AppImages.Health.Recovery; HealthCardType.RunningAbility -> AppImages.Health.RunningAbility
    HealthCardType.CyclingAbility -> AppImages.Health.CyclingAbility; HealthCardType.HeartRate -> AppImages.Health.HeartRate
    HealthCardType.Stress -> AppImages.Health.Stress; HealthCardType.Sleep -> AppImages.Health.Sleep
    HealthCardType.HrvAssessment -> AppImages.Health.HrvAssessment; HealthCardType.RestingHeartRate -> AppImages.Health.RestingHeartRate
    HealthCardType.HealthCheck -> AppImages.Health.HealthCheck; HealthCardType.BodyManagement -> AppImages.Health.BodyManagement
}

@Preview
@Composable
private fun DashboardCardPreview() {
    DemoTheme {
        DashboardCard(
            HealthCardUiModel(HealthCardType.Recovery, LocalizedTextSpec("health_card_recovery_title"), LocalizedTextSpec("health_summary_recovery_normal", listOf("95", "5")), HealthCardStatus.Normal, HealthCardAction.ViewRecovery, 1, "", HealthCardVisualData(HealthCardVisualKind.RecoveryGauge, "95", progress = .95)), {}
        )
    }
}
