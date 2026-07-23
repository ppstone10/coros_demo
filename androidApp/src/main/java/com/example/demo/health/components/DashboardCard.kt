package com.example.demo.health

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
import androidx.compose.ui.res.stringResource
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
import com.example.demo.common.health.HealthCardVisualKind
import com.example.demo.common.health.HealthChartPoint
import com.example.demo.common.health.HealthMetric
import com.example.demo.common.health.HealthVisualLevel
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.common.health.SleepStage
import com.example.demo.common.health.BodyManagement
import com.example.demo.common.health.CyclingAbility
import com.example.demo.common.health.DailySummary
import com.example.demo.common.health.HealthCheck
import com.example.demo.common.health.HealthDashboardData
import com.example.demo.common.health.HealthDashboardDataSource
import com.example.demo.common.health.HealthDashboardUseCase
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.health.HeartRate
import com.example.demo.common.health.HrvAssessment
import com.example.demo.common.health.Recovery
import com.example.demo.common.health.RestingHeartRate
import com.example.demo.common.health.RunningAbility
import com.example.demo.common.health.SleepSummary
import com.example.demo.common.health.SleepStageSegment
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

@Composable
fun DashboardCard(card: HealthCardUiModel, onClick: () -> Unit) {
    val shape = RoundedCornerShape(8.dp)
    var selectedWeeklyDay by remember(
        card.type,
        card.visual.highlightedIndex,
        card.visual.weeklyDayPlans
    ) {
        mutableIntStateOf(card.visual.highlightedIndex ?: 0)
    }
    val displayedVisual = if (card.type == HealthCardType.WeeklyPlan) {
        weeklyVisualForSelectedDay(card.visual, selectedWeeklyDay)
    } else {
        card.visual
    }
    Column(
        modifier = Modifier
            .padding(horizontal = AppSpacing.Screen, vertical = 6.dp)
            .fillMaxWidth()
            .clip(shape)
            .clipToBounds()
            .background(CardBlack)
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
                    visual = displayedVisual,
                    onWeeklyDaySelected = { selectedWeeklyDay = it }
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
                    color = Muted,
                    fontSize = 12.sp,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
private fun EmptyContent(card: HealthCardUiModel) {
    Text(localizedHealthText(card.summary), modifier = Modifier.padding(top = 12.dp), color = Muted, fontSize = 14.sp, lineHeight = 18.sp)
}

@Composable
private fun HealthCardVisualContent(
    type: HealthCardType,
    visual: HealthCardVisualData,
    onWeeklyDaySelected: (Int) -> Unit = {}
) {
    when (visual.kind) {
        HealthCardVisualKind.TodayActivity -> ActivityVisual(visual)
        HealthCardVisualKind.WeeklyPlan -> WeeklyVisual(visual, onWeeklyDaySelected)
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
private fun ActivityVisual(v: HealthCardVisualData) {
    Column(Modifier.padding(top = 10.dp).fillMaxWidth()) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
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
}

@Composable
private fun WeeklyVisual(v: HealthCardVisualData, onDaySelected: (Int) -> Unit) {
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
        WeekLabels(v, onDaySelected)
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
                    v.metrics.firstOrNull()?.let {
                        Text("  ${it.value} ${localizedHealthText(it.label)}", color = Muted, fontSize = 11.sp, maxLines = 1)
                    }
                }
            }
            MiniBars(v.chartPoints, v.highlightedIndex, Modifier.width(80.dp).height(36.dp), dense = true)
        }
    }
}

@Composable
private fun WeekLabels(v: HealthCardVisualData, onDaySelected: (Int) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
        v.chartPoints.take(7).forEachIndexed { index, point ->
            Box(
                Modifier
                    .size(28.dp)
                    .then(if (index == v.highlightedIndex) Modifier.background(AppColors.Health.Action, RoundedCornerShape(14.dp)) else Modifier)
                    .clickable { onDaySelected(index) },
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
        right = { LoadOverview(v) },
    )
}

@Composable
private fun LoadOverview(v: HealthCardVisualData) {
    Column(Modifier.width(130.dp)) {
        MiniBars(
            v.chartPoints,
            v.highlightedIndex,
            Modifier.fillMaxWidth().height(36.dp),
            colorOverride = AppColors.Health.VisualCyan,
            showTrack = true,
        )
        Spacer(Modifier.height(4.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            v.chartPoints.take(7).forEachIndexed { index, point ->
                Text(
                    localizedHealthText(LocalizedTextSpec(point.label)),
                    color = if (index == v.highlightedIndex) AppColors.Core.White else Muted,
                    fontSize = 9.sp,
                )
            }
        }
    }
}

@Composable
private fun AssessmentVisual(v: HealthCardVisualData) {
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
        v.caption?.let { Text(localizedHealthText(it), color = Orange, fontSize = 20.sp, fontWeight = FontWeight.SemiBold) }
        v.detail?.let { Text(localizedHealthText(it), color = AppColors.Health.CardTitle, fontSize = 14.sp, maxLines = 2, lineHeight = 20.sp) }
        Spacer(Modifier.height(16.dp))
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
                v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
                v.detail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
            }
        },
        right = {
            if (type == HealthCardType.Recovery) RecoveryGaugeOverview(v)
            else AbilityGaugeOverview(v, accent)
        },
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
                style = Stroke(stroke, cap = StrokeCap.Butt)
            )
            if (progress > 0f) {
                drawArc(
                    AppColors.Health.VisualCyan, 180f, 180f * progress, false,
                    topLeft = Offset(pad, pad), size = arcSize,
                    style = Stroke(stroke, cap = StrokeCap.Butt)
                )
            }
        }
        AppImage(
            AppImages.Health.RecoveryStatus,
            null,
            Modifier.padding(top = 20.dp).width(21.dp).height(30.dp),
        )
        Text(
            stringResource(if (progress >= 0.7f) R.string.health_visual_recovery_ready else R.string.health_visual_recovery_low),
            color = AppColors.Health.CardTitle,
            fontSize = 11.sp,
            modifier = Modifier.align(Alignment.BottomCenter),
            maxLines = 1,
        )
    }
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
                val segmentColor = if ((index + 0.5f) * segmentSpan <= progressSweep) accent else AppColors.Health.GaugeTrack
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
            Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(horizontal = 2.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text("0", color = Muted, fontSize = 10.sp)
            Text("100", color = Muted, fontSize = 10.sp)
        }
    }
}

@Composable
private fun TrendVisual(type: HealthCardType, v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) { ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20) }
                v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp) }
            }
        },
        right = {
            if (type == HealthCardType.HeartRate) HeartRateOverview(v)
            else StressOverview(v)
        },
    )
}

@Composable
private fun HeartRateOverview(v: HealthCardVisualData) {
    Canvas(Modifier.width(166.dp).height(44.dp)) {
        if (v.chartPoints.isEmpty()) return@Canvas
        val chartMinimum = v.chartPoints.minOf { it.minimum ?: it.value }
        val chartMaximum = v.chartPoints.maxOf { it.maximum ?: it.value }
        val topPadding = 3.dp.toPx()
        val drawableHeight = size.height - 2 * topPadding
        val denominator = (v.chartPoints.size - 1).coerceAtLeast(1)
        v.chartPoints.forEachIndexed { index, point ->
            val normalized = normalizedHeartRateInterval(
                point.minimum ?: point.value,
                point.maximum ?: point.value,
                chartMinimum,
                chartMaximum,
            )
            val x = index.toFloat() / denominator * size.width
            val highY = topPadding + drawableHeight * (1f - normalized.endInclusive)
            val lowY = topPadding + drawableHeight * (1f - normalized.start)
            val visibleLowY = max(lowY, highY + 1.dp.toPx())
            drawLine(
                AppColors.Health.VisualPink,
                Offset(x, highY),
                Offset(x, visibleLowY),
                1.dp.toPx(),
                StrokeCap.Butt,
            )
        }
    }
}

@Composable
private fun StressOverview(v: HealthCardVisualData) {
    Canvas(Modifier.width(166.dp).height(56.dp)) {
        if (v.chartPoints.isEmpty()) return@Canvas
        val values = v.chartPoints.map { it.value }
        val high = max(100.0, values.maxOrNull() ?: 100.0)
        val step = 2.dp.toPx().coerceAtLeast(1f)
        val count = (size.width / step).toInt().coerceAtLeast(2)
        repeat(count) { index ->
            val chartPosition = index.toFloat() / (count - 1) * (values.size - 1)
            val leftIndex = chartPosition.toInt().coerceIn(0, values.lastIndex)
            val rightIndex = (leftIndex + 1).coerceAtMost(values.lastIndex)
            val fraction = chartPosition - leftIndex
            val value = values[leftIndex] + (values[rightIndex] - values[leftIndex]) * fraction
            val height = (size.height * (value / high).toFloat()).coerceAtLeast(2.dp.toPx())
            val color = when {
                value >= 80 -> AppColors.Health.VisualOrange
                value >= 60 -> AppColors.Health.VisualYellow
                value >= 35 -> AppColors.Health.StressGood
                else -> AppColors.Health.StressLow
            }
            val x = index * step
            drawLine(color, Offset(x, size.height), Offset(x, size.height - height), 1.dp.toPx(), StrokeCap.Butt)
        }
    }
}

@Composable
private fun RangeVisual(type: HealthCardType, v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                Row(verticalAlignment = Alignment.Bottom) { ValueText(v.primaryValue, 32); UnitText(v.primaryUnit, 20) }
                val leftDetail = if (type == HealthCardType.RestingHeartRate) v.caption else v.detail
                leftDetail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 12.sp, maxLines = 1) }
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
    Column(Modifier.width(130.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        v.detail?.let { Text(localizedHealthText(it), color = Muted, fontSize = 11.sp, maxLines = 1) }
        Canvas(Modifier.fillMaxWidth().height(30.dp)) {
            val r = v.range ?: return@Canvas
            val denominator = max(1.0, r.maximum - r.minimum)
            val y = 10.dp.toPx()
            drawLine(AppColors.Health.VisualPink, Offset(0f, y), Offset(size.width, y), 3.dp.toPx(), StrokeCap.Butt)
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
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(v.range?.minimum?.toInt()?.toString() ?: "--", color = Muted, fontSize = 10.sp)
            Text(v.range?.maximum?.toInt()?.toString() ?: "--", color = Muted, fontSize = 10.sp)
        }
    }
}

@Composable
private fun HrvRangeOverview(v: HealthCardVisualData) {
    val range = v.range
    val unit = v.primaryUnit?.let { localizedHealthText(it) }.orEmpty()
    Column(Modifier.width(130.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            stringResource(
                R.string.health_visual_normal_range_short,
                range?.normalMin?.toInt()?.toString() ?: "--",
                range?.normalMax?.toInt()?.toString() ?: "--",
                unit,
            ),
            color = Muted,
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
                drawRect(color, Offset(index * (segmentWidth + gap), indicatorTop), Size(segmentWidth, indicatorHeight))
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
            Box(Modifier.size(5.dp).background(AppColors.Health.RangeNormal, RoundedCornerShape(3.dp)))
            Spacer(Modifier.width(4.dp))
            v.caption?.let { Text(localizedHealthText(it), color = Muted, fontSize = 10.sp, maxLines = 1) }
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
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
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
    Row(Modifier.fillMaxWidth().height(IntrinsicSize.Min), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(141.dp).fillMaxHeight(), contentAlignment = Alignment.CenterStart) {
            Column(Modifier.padding(top = 8.dp)) { left() }
        }
        Spacer(Modifier.weight(1f))
        Box(Modifier.fillMaxHeight().clipToBounds(), contentAlignment = Alignment.CenterEnd) { right() }
    }
}

@Composable
private fun MiniBars(
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
                point.level == HealthVisualLevel.Elevated -> Orange
                point.level == HealthVisualLevel.Good -> Yellow
                else -> AppColors.Health.VisualBar
            }
            drawRoundRect(color, Offset(x, size.height - h), Size(bar, h), CornerRadius(minOf(bar / 2, 2.dp.toPx())))
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
            SleepStageSegment(SleepStage.Awake, 0, 18), SleepStageSegment(SleepStage.Light, 18, 72),
            SleepStageSegment(SleepStage.Deep, 90, 55), SleepStageSegment(SleepStage.Light, 145, 74),
            SleepStageSegment(SleepStage.Rem, 219, 42), SleepStageSegment(SleepStage.Light, 261, 65),
            SleepStageSegment(SleepStage.Deep, 326, 38), SleepStageSegment(SleepStage.Light, 364, 77),
            SleepStageSegment(SleepStage.Rem, 441, 45), SleepStageSegment(SleepStage.Awake, 486, 18)
        )),
        trainingLoad = TrainingLoad(246, 600, 800, listOf(22, 11, 22, 12, 0, 0, 0)),
        recovery = Recovery(95, 5),
        weeklyPlan = WeeklyPlan(true, 300, null, 3, listOf(0, 0, 0, 78, 0, 0, 0),
            LocalizedTextSpec("health_visual_workout_easy_run"), 102, 78),
        trainingAssessment = TrainingAssessment(78, "increasing", 155, 138, 1.2,
            LocalizedTextSpec("health_visual_assessment_efficient"), LocalizedTextSpec("health_visual_assessment_efficient_detail")),
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
            Modifier.background(AppColors.Health.Page).verticalScroll(rememberScrollState()).padding(vertical = 8.dp)
        ) {
            state.cards.forEach { card ->
                DashboardCard(card) {}
            }
        }
    }
}
