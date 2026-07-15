package com.example.demo.health

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.example.demo.common.health.DashboardUiState
import com.example.demo.common.health.DailySummary
import com.example.demo.common.health.DefaultHealthCardOrder
import com.example.demo.common.health.HealthCardAction
import com.example.demo.common.health.HealthCardStatus
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.login.MockResult
import com.example.demo.login.LoginViewModel
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImageAsset
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppText
import com.example.demo.ui.theme.DemoTheme

private val PageBlack = AppColors.Health.Page
private val CardBlack = AppColors.Health.Card
private val Muted = AppColors.Health.Muted

@Composable
fun HealthDashboardScreen(
    viewModel: LoginViewModel,
    onFullscreenChange: (Boolean) -> Unit = {}
) {
    var result by remember(viewModel.state.currentSession) { mutableStateOf(viewModel.loadHealthDashboard()) }
    var editing by remember { mutableStateOf(false) }
    var detail by remember { mutableStateOf<HealthCardUiModel?>(null) }
    val dashboard = (result as? MockResult.Success)?.data
    val state = dashboard?.uiState
    if (editing && dashboard != null) {
        BackHandler {
            editing = false
            onFullscreenChange(false)
        }
        CardEditor(
            initial = dashboard.enabledCardTypes,
            onClose = {
                editing = false
                onFullscreenChange(false)
            },
            onSave = { types ->
                result = viewModel.saveHealthCardConfiguration(types)
                editing = false
                onFullscreenChange(false)
            }
        )
        return
    }
    detail?.let { card ->
        BackHandler {
            detail = null
            onFullscreenChange(false)
        }
        DetailPlaceholder(card) {
            detail = null
            onFullscreenChange(false)
        }
        return
    }
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PageBlack)
    ) {
        if (state != null) {
            Column(
                Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                Hero(state)
                state.cards.forEach { card ->
                    DashboardCard(card) {
                        detail = card
                        onFullscreenChange(true)
                    }
                }
                Text(
                    text = AppText.Health.EditCards,
                    color = AppColors.Health.EditText,
                    fontSize = 13.sp,
                    modifier = Modifier
                        .align(Alignment.CenterHorizontally)
                        .padding(18.dp)
                        .clip(RoundedCornerShape(22.dp))
                        .background(CardBlack)
                        .clickable {
                            editing = true
                            onFullscreenChange(true)
                        }
                        .padding(horizontal = 28.dp, vertical = 10.dp)
                )
                Spacer(Modifier.height(24.dp))
            }
        } else {
            Text(
                text = AppText.Health.DataUnavailable,
                color = AppColors.Core.White,
                modifier = Modifier.align(Alignment.Center)
            )
        }
    }
}

@Composable
private fun Hero(state: DashboardUiState) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .height(292.dp)
            .background(PageBlack)
            .statusBarsPadding()
            .padding(horizontal = 20.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(Modifier.weight(1f)) {
                Text(state.dateLabel, color = AppColors.Health.Date, fontSize = 11.sp)
                Text(AppText.Health.Today, color = AppColors.Core.White, fontSize = 28.sp, fontWeight = FontWeight.SemiBold)
            }
            AppImage(
                asset = AppImages.Health.Calendar,
                contentDescription = AppText.Health.Calendar,
                modifier = Modifier.size(23.dp)
            )
            Spacer(Modifier.width(18.dp))
            AppImage(
                asset = AppImages.Health.Device,
                contentDescription = AppText.Health.SportDevice,
                modifier = Modifier.size(23.dp)
            )
        }
        Spacer(Modifier.height(46.dp))
        Box(
            Modifier
                .fillMaxWidth()
                .height(128.dp)
        ) {
            Canvas(
                Modifier
                    .size(150.dp, 125.dp)
                    .align(Alignment.Center)
            ) {
                drawArc(
                    color = AppColors.Health.Gauge,
                    startAngle = 135f,
                    sweepAngle = 270f,
                    useCenter = false,
                    style = Stroke(5.dp.toPx(), cap = StrokeCap.Round),
                    topLeft = Offset(12.dp.toPx(), 5.dp.toPx()),
                    size = Size(size.width - 24.dp.toPx(), size.height - 10.dp.toPx())
                )
            }
            Row(
                modifier = Modifier.fillMaxSize(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Metric(
                    state.dailySummary?.steps ?: 0,
                    AppText.Health.StepsUnit,
                    AppImages.Health.Steps,
                    AppColors.Health.Steps
                )
                Metric(
                    state.dailySummary?.calories ?: 0,
                    AppText.Health.CaloriesUnit,
                    AppImages.Health.Calories,
                    AppColors.Health.Calories
                )
                Metric(
                    state.dailySummary?.activeMinutes ?: 0,
                    AppText.Health.MinutesUnit,
                    AppImages.Health.ActiveDuration,
                    AppColors.Health.ActiveDuration
                )
            }
        }
    }
}

@Composable
private fun Metric(value: Int, unit: String, icon: AppImageAsset, iconColor: Color) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(82.dp)
    ) {
        AppImage(
            asset = icon,
            contentDescription = null,
            colorFilter = ColorFilter.tint(iconColor),
            modifier = Modifier.size(22.dp)
        )
        Text(
            text = value.toString(),
            color = AppColors.Core.White,
            fontSize = 28.sp,
            letterSpacing = 1.sp
        )
        Text(
            text = unit,
            color = AppColors.Health.MetricUnit,
            fontSize = 11.sp
        )
    }
}

@Composable
private fun DashboardCard(card: HealthCardUiModel, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .padding(horizontal = 16.dp, vertical = 5.dp)
            .fillMaxWidth()
            .heightIn(min = 76.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(CardBlack)
            .clickable(onClick = onClick)
            .padding(horizontal = 15.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AppImage(iconOf(card.type), null, Modifier.size(22.dp))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(
                text = card.title,
                color = AppColors.Health.CardTitle,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium
            )
            Spacer(Modifier.height(5.dp))
            Text(
                text = card.summary,
                color = if (card.status == HealthCardStatus.Risk) AppColors.Health.Risk else Muted,
                fontSize = 12.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
        Text(AppText.Common.Next, color = AppColors.Health.Chevron, fontSize = 24.sp)
    }
}

@Composable
private fun CardEditor(
    initial: List<HealthCardType>,
    onClose: () -> Unit,
    onSave: (List<HealthCardType>) -> Unit
) {
    val active = remember(initial) {
        mutableStateListOf<HealthCardType>().apply { addAll(initial) }
    }
    val listState = rememberLazyListState()
    var draggedType by remember { mutableStateOf<HealthCardType?>(null) }
    var nonAnimatedType by remember { mutableStateOf<HealthCardType?>(null) }
    var dragOffset by remember { mutableFloatStateOf(0f) }
    var warning by remember { mutableStateOf<String?>(null) }
    val inactive = DefaultHealthCardOrder.filterNot(active::contains)
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(PageBlack)
            .statusBarsPadding()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(62.dp)
                .padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = AppText.Common.Back,
                color = AppColors.Core.White,
                fontSize = 34.sp,
                modifier = Modifier.clickable(onClick = onClose)
            )
            Text(
                text = AppText.Health.EditCards,
                color = AppColors.Core.White,
                fontSize = 18.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1f)
            )
            Box(
                modifier = Modifier
                    .width(64.dp)
                    .height(30.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(AppColors.Health.Action)
                    .clickable { onSave(active.toList()) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = AppText.Common.Save,
                    color = AppColors.Core.White,
                    fontSize = 14.sp
                )
            }
        }
        Text(
            text = AppText.Health.ManageOrder,
            color = Muted,
            fontSize = 13.sp,
            modifier = Modifier.padding(horizontal = 24.dp, vertical = 14.dp)
        )
        warning?.let {
            Text(
                text = it,
                color = AppColors.Health.Warning,
                fontSize = 12.sp,
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 4.dp)
            )
        }
        LazyColumn(
            state = listState,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 16.dp)
                .pointerInput(Unit) {
                    detectDragGesturesAfterLongPress(
                        onDragStart = { position ->
                            val item = listState.layoutInfo.visibleItemsInfo.firstOrNull { info ->
                                info.index in active.indices &&
                                    position.y.toInt() in info.offset..(info.offset + info.size)
                            }
                            draggedType = item?.let { active.getOrNull(it.index) }
                            nonAnimatedType = draggedType
                            dragOffset = 0f
                        },
                        onDragCancel = {
                            draggedType = null
                            dragOffset = 0f
                        },
                        onDragEnd = {
                            draggedType = null
                            dragOffset = 0f
                        },
                        onDrag = { change, amount ->
                            val type = draggedType
                                ?: return@detectDragGesturesAfterLongPress
                            change.consume()
                            val currentIndex = active.indexOf(type)
                            val layoutInfo = listState.layoutInfo
                            val current = layoutInfo.visibleItemsInfo.firstOrNull {
                                it.index == currentIndex
                            } ?: return@detectDragGesturesAfterLongPress
                            val minimumOffset =
                                layoutInfo.viewportStartOffset - current.offset.toFloat()
                            val maximumOffset =
                                layoutInfo.viewportEndOffset - current.offset.toFloat() - current.size
                            dragOffset = (dragOffset + amount.y).coerceIn(
                                minimumOffset,
                                maximumOffset
                            )
                            val direction = amount.y.compareTo(0f)
                            val targetIndex = currentIndex + direction
                            val target = layoutInfo.visibleItemsInfo.firstOrNull {
                                it.index == targetIndex && it.index in active.indices
                            }
                            val draggedCenter = current.offset + current.size / 2f + dragOffset
                            val shouldSwap = when {
                                target == null -> false
                                direction < 0 -> draggedCenter <= target.offset + target.size / 2f
                                direction > 0 -> draggedCenter >= target.offset + target.size / 2f
                                else -> false
                            }
                            if (shouldSwap && target != null) {
                                val visualTop = current.offset + dragOffset
                                val firstVisibleIndex = listState.firstVisibleItemIndex
                                val firstVisibleOffset = listState.firstVisibleItemScrollOffset
                                active.removeAt(currentIndex)
                                active.add(target.index, type)
                                if (
                                    currentIndex == firstVisibleIndex ||
                                    target.index == firstVisibleIndex
                                ) {
                                    listState.requestScrollToItem(
                                        index = firstVisibleIndex,
                                        scrollOffset = firstVisibleOffset
                                    )
                                }
                                dragOffset = visualTop - target.offset
                                val targetMinimumOffset =
                                    layoutInfo.viewportStartOffset - target.offset.toFloat()
                                val targetMaximumOffset =
                                    layoutInfo.viewportEndOffset - target.offset.toFloat() - target.size
                                dragOffset = dragOffset.coerceIn(
                                    targetMinimumOffset,
                                    targetMaximumOffset
                                )
                            }
                            val viewport = layoutInfo.viewportEndOffset
                            when {
                                amount.y < 0 &&
                                    change.position.y < 36.dp.toPx() &&
                                    listState.canScrollBackward -> {
                                    val consumed = listState.dispatchRawDelta(8.dp.toPx())
                                    dragOffset -= consumed
                                }
                                amount.y > 0 &&
                                    change.position.y > viewport - 36.dp.toPx() &&
                                    listState.canScrollForward -> {
                                    val consumed = listState.dispatchRawDelta(-8.dp.toPx())
                                    dragOffset -= consumed
                                }
                            }
                        }
                    )
                }
        ) {
            itemsIndexed(active, key = { _, type -> type.name }) { index, type ->
                EditorRow(
                    type = type,
                    isAdd = false,
                    roundTop = index == 0,
                    roundBottom = index == active.lastIndex,
                    itemModifier = if (nonAnimatedType == type) {
                        Modifier
                    } else {
                        Modifier.animateItem(
                            fadeInSpec = null,
                            placementSpec = tween(durationMillis = 140),
                            fadeOutSpec = null
                        )
                    },
                    dragModifier = Modifier
                        .zIndex(if (draggedType == type) 1f else 0f)
                        .graphicsLayer {
                            translationY = if (draggedType == type) dragOffset else 0f
                            shadowElevation = if (draggedType == type) 10.dp.toPx() else 0f
                            alpha = if (draggedType == type) .92f else 1f
                        },
                    onAction = {
                        if (active.size > 3) {
                            active.remove(type)
                            warning = null
                        } else {
                            warning = AppText.Health.MinimumCards
                        }
                    }
                )
            }
            if (inactive.isNotEmpty()) {
                item {
                    Text(
                        text = AppText.Health.MoreDailyData,
                        color = Muted,
                        fontSize = 13.sp,
                        modifier = Modifier.padding(6.dp, 24.dp, 6.dp, 11.dp)
                    )
                }
                itemsIndexed(
                    items = inactive,
                    key = { _, type -> "more_${type.name}" }
                ) { index, type ->
                    EditorRow(
                        type = type,
                        isAdd = true,
                        roundTop = index == 0,
                        roundBottom = index == inactive.lastIndex,
                        dragModifier = Modifier
                    ) {
                        active.add(type)
                        warning = null
                    }
                }
            }
            item {
                Text(
                    text = AppText.Health.RestoreDefaults,
                    color = AppColors.Health.Action,
                    fontSize = 14.sp,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 24.dp, bottom = 32.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(CardBlack)
                        .clickable {
                            active.clear()
                            active.addAll(DefaultHealthCardOrder)
                            warning = null
                        }
                        .padding(horizontal = 18.dp, vertical = 17.dp)
                )
            }
        }
    }
}

@Composable
private fun EditorRow(
    type: HealthCardType,
    isAdd: Boolean,
    roundTop: Boolean,
    roundBottom: Boolean,
    itemModifier: Modifier = Modifier,
    dragModifier: Modifier,
    onAction: () -> Unit
) {
    val shape = RoundedCornerShape(
        topStart = if (roundTop) 8.dp else 0.dp,
        topEnd = if (roundTop) 8.dp else 0.dp,
        bottomStart = if (roundBottom) 8.dp else 0.dp,
        bottomEnd = if (roundBottom) 8.dp else 0.dp
    )
    Column(
        itemModifier
            .fillMaxWidth()
            .background(CardBlack, shape)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .then(dragModifier)
                .height(56.dp)
                .padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (!isAdd) {
                Text(AppText.Health.DragHandle, color = AppColors.Health.Muted, fontSize = 18.sp)
                Spacer(Modifier.width(10.dp))
            }
            AppImage(iconOf(type), null, Modifier.size(22.dp))
            Spacer(Modifier.width(10.dp))
            Text(
                text = titleOf(type),
                color = AppColors.Health.EditorTitle,
                fontSize = 15.sp,
                modifier = Modifier.weight(1f)
            )
            if (isAdd) {
                Box(
                    modifier = Modifier
                        .size(30.dp)
                        .clip(CircleShape)
                        .background(AppColors.Health.AddAction)
                        .clickable(onClick = onAction),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "+",
                        color = AppColors.Core.White,
                        fontSize = 24.sp,
                        lineHeight = 24.sp,
                        fontWeight = FontWeight.Light
                    )
                }
            } else {
                AppImage(
                    asset = AppImages.Health.EditorRemove,
                    contentDescription = AppText.Health.Remove,
                    modifier = Modifier
                        .size(30.dp)
                        .clickable(onClick = onAction)
                )
            }
        }
        if (!roundBottom) {
            Box(
                Modifier
                    .padding(start = 18.dp)
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(AppColors.Health.EditorDivider)
            )
        }
    }
}

@Composable
private fun DetailPlaceholder(card: HealthCardUiModel, onBack: () -> Unit) {
    Column(
        Modifier
            .fillMaxSize()
            .background(PageBlack)
            .statusBarsPadding()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(64.dp)
                .padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = AppText.Common.Back,
                color = AppColors.Core.White,
                fontSize = 38.sp,
                modifier = Modifier.clickable(onClick = onBack)
            )
            Text(
                text = card.title,
                color = AppColors.Core.White,
                fontSize = 19.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1f)
            )
            Spacer(Modifier.width(28.dp))
        }
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            AppImage(iconOf(card.type), null, Modifier.size(56.dp))
            Spacer(Modifier.height(20.dp))
            Text(
                text = AppText.Health.pendingFeature(card.title),
                color = AppColors.Health.Placeholder,
                fontSize = 16.sp
            )
        }
    }
}

private fun titleOf(type: HealthCardType) = when (type) {
    HealthCardType.WeeklyPlan -> AppText.Health.WeeklyPlan
    HealthCardType.TodayActivity -> AppText.Health.TodayActivity
    HealthCardType.TrainingLoad -> AppText.Health.TrainingLoad
    HealthCardType.TrainingAssessment -> AppText.Health.TrainingAssessment
    HealthCardType.Recovery -> AppText.Health.Recovery
    HealthCardType.RunningAbility -> AppText.Health.RunningAbility
    HealthCardType.CyclingAbility -> AppText.Health.CyclingAbility
    HealthCardType.HeartRate -> AppText.Health.HeartRate
    HealthCardType.Stress -> AppText.Health.Stress
    HealthCardType.Sleep -> AppText.Health.Sleep
    HealthCardType.HrvAssessment -> AppText.Health.HrvAssessment
    HealthCardType.RestingHeartRate -> AppText.Health.RestingHeartRate
    HealthCardType.HealthCheck -> AppText.Health.HealthCheck
    HealthCardType.BodyManagement -> AppText.Health.BodyManagement
}

private fun iconOf(type: HealthCardType) = when (type) {
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

@Preview(showBackground = true, backgroundColor = 0xFF000000, heightDp = 820)
@Composable
private fun HealthDashboardContentPreview() {
    val state = DashboardUiState(
        greeting = "今天",
        dateLabel = "7月14日 星期二",
        dailySummary = DailySummary(8769, 769, 69),
        cards = listOf(
            previewCard(HealthCardType.Recovery, "体力恢复", "恢复评分 78，预计 14 小时后恢复"),
            previewCard(HealthCardType.Sleep, "睡眠", "昨夜睡眠 7小时18分，质量 86"),
            previewCard(HealthCardType.TrainingLoad, "本周负荷", "本周负荷 526，建议范围 300-700")
        )
    )
    DemoTheme {
        Column(Modifier.fillMaxSize().background(PageBlack)) {
            Hero(state)
            state.cards.forEach { card -> DashboardCard(card, onClick = {}) }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000, heightDp = 900)
@Composable
private fun CardEditorPreview() {
    DemoTheme {
        CardEditor(
            initial = DefaultHealthCardOrder.take(8),
            onClose = {},
            onSave = {}
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun HealthCardDetailPreview() {
    DemoTheme {
        DetailPlaceholder(
            card = previewCard(HealthCardType.Sleep, "睡眠", "昨夜睡眠 7小时18分"),
            onBack = {}
        )
    }
}

private fun previewCard(
    type: HealthCardType,
    title: String,
    summary: String
) = HealthCardUiModel(
    type = type,
    title = title,
    summary = summary,
    status = HealthCardStatus.Normal,
    action = HealthCardAction.OpenCard,
    priority = 0,
    priorityReason = "Preview"
)
