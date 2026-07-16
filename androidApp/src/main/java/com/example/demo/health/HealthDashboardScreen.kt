package com.example.demo.health

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.Velocity
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.zIndex
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.rememberLottieComposition
import com.example.demo.common.health.DashboardUiState
import com.example.demo.common.health.DailySummary
import com.example.demo.common.health.DefaultHealthCardOrder
import com.example.demo.common.health.HealthCardStatus
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult
import com.example.demo.login.LoginViewModel
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImageAsset
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppText
import com.example.demo.ui.theme.DemoTheme
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.milliseconds

private val PageBlack = AppColors.Health.Page
private val CardBlack = AppColors.Health.Card
private val Muted = AppColors.Health.Muted

private const val LottieDurationMs = 4460L

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HealthDashboardScreen(
    viewModel: LoginViewModel,
    onFullscreenChange: (Boolean) -> Unit = {}
) {
    var result by remember(viewModel.state.currentSession) { mutableStateOf(viewModel.loadHealthDashboard()) }
    var editing by remember { mutableStateOf(false) }
    var detail by remember { mutableStateOf<HealthCardUiModel?>(null) }
    var showScenarioPicker by remember { mutableStateOf(false) }
    var isRefreshing by remember { mutableStateOf(false) }

    val dashboard = (result as? MockResult.Success)?.data
    val state = dashboard?.uiState
    val failureError = (result as? MockResult.Failure)?.error
    val isAuthError = failureError != null && failureError != MockError.CorruptedData
    val isCorrupted = failureError == MockError.CorruptedData

    if (showScenarioPicker) {
        ScenarioPickerDialog(
            currentScenario = dashboard?.scenario ?: HealthMockScenario.Normal,
            onSelect = { scenario ->
                viewModel.selectHealthScenario(scenario)
                showScenarioPicker = false
            },
            onDismiss = { showScenarioPicker = false }
        )
    }
    if (editing && dashboard != null) {
        BackHandler { editing = false; onFullscreenChange(false) }
        CardEditor(
            initial = dashboard.enabledCardTypes,
            onClose = { editing = false; onFullscreenChange(false) },
            onSave = { types ->
                result = viewModel.saveHealthCardConfiguration(types)
                editing = false
                onFullscreenChange(false)
            }
        )
        return
    }
    detail?.let { card ->
        BackHandler { detail = null; onFullscreenChange(false) }
        DetailPlaceholder(card) { detail = null; onFullscreenChange(false) }
        return
    }

    LaunchedEffect(isRefreshing) {
        if (isRefreshing) {
            delay(LottieDurationMs.milliseconds)
            result = viewModel.loadHealthDashboard()
            isRefreshing = false
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(PageBlack)
    ) {
        // Part 1: 固定顶部，不上滑
        HeroTopRow(
            dateLabel = state?.dateLabel ?: "",
            isSyncing = isRefreshing,
            onLongPressWatch = { showScenarioPicker = true }
        )

        // Part 2: 可滑动内容区 + 自定义下拉拉伸回弹
        var pullOffset by remember { mutableFloatStateOf(0f) }
        var pullAnimating by remember { mutableStateOf(0) }

        LaunchedEffect(pullAnimating) {
            if (pullAnimating > 0) {
                val target: Float = pullAnimating.toFloat()
                val start: Float = pullOffset
                val anim = Animatable(start)
                anim.animateTo(target, tween(300))
                pullOffset = target
            }
        }

        LaunchedEffect(isRefreshing) {
            if (!isRefreshing && pullOffset > 0f) {
                val anim = Animatable(pullOffset)
                anim.animateTo(0f, tween(300))
                pullOffset = 0f
            }
        }

        val pullConnection = remember {
            object : NestedScrollConnection {
                override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
                    if (pullOffset > 0f && available.y < 0f) {
                        val consumed = minOf(-available.y, pullOffset)
                        pullOffset -= consumed
                        return Offset(0f, -consumed)
                    }
                    return Offset.Zero
                }

                override fun onPostScroll(
                    consumed: Offset, available: Offset, source: NestedScrollSource
                ): Offset {
                    if (available.y > 0f && source == NestedScrollSource.UserInput) {
                        pullOffset = (pullOffset + available.y * 0.4f).coerceAtMost(250f)
                        return Offset(0f, available.y)
                    }
                    return Offset.Zero
                }

                override suspend fun onPreFling(available: Velocity): Velocity {
                    if (pullOffset > 0f) {
                        if (!isRefreshing && pullOffset > 80f) {
                            isRefreshing = true
                        }
                        pullAnimating = if (isRefreshing) 60 else 0
                    }
                    return available
                }
            }
        }

        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .nestedScroll(pullConnection)
        ) {
            Box(Modifier.fillMaxSize()) {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer { translationY = pullOffset },
                    state = rememberLazyListState()
            ) {
                    when {
                        isAuthError -> {
                            item {
                                Box(Modifier.fillMaxWidth().height(400.dp), contentAlignment = Alignment.Center) {
                                    Text(AppText.Health.DataUnavailable, color = AppColors.Core.White)
                                }
                            }
                        }
                        isCorrupted -> {
                            item { Spacer(Modifier.height(46.dp)) }
                            item {
                                Column(
                                    Modifier.fillMaxWidth().padding(horizontal = 20.dp),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Spacer(Modifier.height(80.dp))
                                    Text("数据已损坏，下拉尝试重新同步", color = AppColors.Health.Risk, fontSize = 14.sp)
                                }
                            }
                        }
                        state != null -> {
                            item { Spacer(Modifier.height(8.dp)) }
                            item { ArcAndMetricsSection(state) }
                            itemsIndexed(
                                items = state.cards,
                                key = { _, card -> card.type.name }
                            ) { _, card ->
                                DashboardCard(card) {
                                    detail = card
                                    onFullscreenChange(true)
                                }
                            }
                            item {
                                Text(
                                    text = AppText.Health.EditCards,
                                    color = AppColors.Health.EditText,
                                    fontSize = 13.sp,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(18.dp)
                                        .clip(RoundedCornerShape(22.dp))
                                        .background(CardBlack)
                                        .clickable {
                                            editing = true
                                            onFullscreenChange(true)
                                        }
                                        .padding(horizontal = 28.dp, vertical = 10.dp)
                                )
                            }
                            item { Spacer(Modifier.height(24.dp)) }
                        }
                    }
                }

                if (isRefreshing) {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .align(Alignment.TopCenter)
                            .padding(top = 20.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            color = AppColors.Health.Steps,
                            strokeWidth = 2.dp
                        )
                        Spacer(Modifier.width(8.dp))
                        Text("数据同步中", color = Muted, fontSize = 12.sp)
                    }
                }
            }

            // Part 3: 底部留白
            Spacer(Modifier.height(0.dp))
        }
    }
}

@Composable
private fun HeroTopRow(
    dateLabel: String,
    isSyncing: Boolean,
    onLongPressWatch: () -> Unit
) {
    val composition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(com.example.demo.R.raw.watch_status)
    )
    val progressAnim = remember { Animatable(0f) }

    LaunchedEffect(isSyncing) {
        if (isSyncing) {
            progressAnim.snapTo(0f)
            progressAnim.animateTo(1f, tween(4460, easing = LinearEasing))
            progressAnim.snapTo(0f)
        } else {
            progressAnim.snapTo(0f)
        }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(PageBlack)
            .statusBarsPadding()
            .padding(start = 20.dp, end = 20.dp, top = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                if (dateLabel.isBlank()) " " else dateLabel,
                color = AppColors.Health.Date, fontSize = 11.sp
            )
            Text(
                AppText.Health.Today,
                color = AppColors.Core.White, fontSize = 28.sp, fontWeight = FontWeight.SemiBold
            )
        }
        AppImage(
            asset = AppImages.Health.Calendar,
            contentDescription = AppText.Health.Calendar,
            modifier = Modifier.size(23.dp)
        )
        Spacer(Modifier.width(18.dp))
        Box(
            modifier = Modifier
                .size(30.dp)
                .combinedClickable(
                    onClick = {},
                    onLongClick = onLongPressWatch
                )
        ) {
            if (composition != null) {
                LottieAnimation(
                    composition = composition,
                    progress = { progressAnim.value },
                    modifier = Modifier.size(30.dp),
                    contentScale = ContentScale.Fit
                )
            }
        }
    }
}

@Composable
private fun ArcAndMetricsSection(state: DashboardUiState) {
    ArcAndMetrics(state)
}

@Composable
private fun ArcAndMetrics(state: DashboardUiState) {
    Box(
        Modifier
            .fillMaxWidth()
            .height(150.dp)
            .padding(horizontal = 20.dp)
    ) {
        Canvas(
            Modifier
                .size(150.dp)
                .align(Alignment.Center)
        ) {
            drawArc(
                color = AppColors.Health.Gauge,
                startAngle = 135f,
                sweepAngle = 270f,
                useCenter = false,
                style = Stroke(5.dp.toPx(), cap = StrokeCap.Round),
                topLeft = Offset(10.dp.toPx(), 10.dp.toPx()),
                size = Size(size.width - 20.dp.toPx(), size.height - 20.dp.toPx())
            )
        }
        Row(
            modifier = Modifier.fillMaxSize(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Metric(
                state.dailySummary?.steps ?: 0,
                AppText.Health.StepsUnit, AppImages.Health.Steps, AppColors.Health.Steps
            )
            Metric(
                state.dailySummary?.calories ?: 0,
                AppText.Health.CaloriesUnit, AppImages.Health.Calories, AppColors.Health.Calories
            )
            Metric(
                state.dailySummary?.activeMinutes ?: 0,
                AppText.Health.MinutesUnit, AppImages.Health.ActiveDuration, AppColors.Health.ActiveDuration
            )
        }
    }
}

@Composable
private fun Metric(value: Int, unit: String, icon: AppImageAsset, iconColor: Color) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.width(82.dp)) {
        AppImage(asset = icon, contentDescription = null, colorFilter = ColorFilter.tint(iconColor), modifier = Modifier.size(22.dp))
        Text(text = value.toString(), color = AppColors.Core.White, fontSize = 26.sp, letterSpacing = 1.sp)
        Text(text = unit, color = AppColors.Health.MetricUnit, fontSize = 11.sp)
    }
}

@Composable
private fun ScenarioPickerDialog(
    currentScenario: HealthMockScenario,
    onSelect: (HealthMockScenario) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("选择数据场景", color = AppColors.Core.White) },
        text = {
            Column {
                HealthMockScenario.entries.forEach { scenario ->
                    Row(
                        modifier = Modifier.fillMaxWidth().clickable { onSelect(scenario) }.padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = scenario == currentScenario,
                            onClick = { onSelect(scenario) },
                            colors = RadioButtonDefaults.colors(selectedColor = AppColors.Health.Steps, unselectedColor = Muted)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(scenario.displayName(), color = AppColors.Core.White, fontSize = 14.sp)
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("取消", color = AppColors.Health.Steps) } },
        containerColor = CardBlack
    )
}

private fun HealthMockScenario.displayName() = when (this) {
    HealthMockScenario.Normal -> "正常数据"
    HealthMockScenario.PartialMissing -> "部分数据缺失"
    HealthMockScenario.AllEmpty -> "全部数据为空"
    HealthMockScenario.Abnormal -> "异常数据"
    HealthMockScenario.ReadFailure -> "数据损坏"
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
            Text(card.title, color = AppColors.Health.CardTitle, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            Spacer(Modifier.height(5.dp))
            Text(
                card.summary,
                color = if (card.status == HealthCardStatus.Risk) AppColors.Health.Risk else Muted,
                fontSize = 12.sp, maxLines = 2, overflow = TextOverflow.Ellipsis
            )
        }
        Text(AppText.Common.Next, color = AppColors.Health.Chevron, fontSize = 24.sp)
    }
}

// ---- CardEditor, EditorRow, DetailPlaceholder ----

@Composable
private fun CardEditor(
    initial: List<HealthCardType>, onClose: () -> Unit, onSave: (List<HealthCardType>) -> Unit
) {
    val active = remember(initial) { mutableStateListOf<HealthCardType>().apply { addAll(initial) } }
    val listState = rememberLazyListState()
    var draggedType by remember { mutableStateOf<HealthCardType?>(null) }
    var nonAnimatedType by remember { mutableStateOf<HealthCardType?>(null) }
    var dragOffset by remember { mutableFloatStateOf(0f) }
    var warning by remember { mutableStateOf<String?>(null) }
    val inactive = DefaultHealthCardOrder.filterNot(active::contains)
    Column(Modifier.fillMaxSize().background(PageBlack).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().height(62.dp).padding(horizontal = 18.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(AppText.Common.Back, color = AppColors.Core.White, fontSize = 34.sp, modifier = Modifier.clickable(onClick = onClose))
            Text(AppText.Health.EditCards, color = AppColors.Core.White, fontSize = 18.sp, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
            Box(Modifier.width(64.dp).height(30.dp).clip(RoundedCornerShape(6.dp)).background(AppColors.Health.Action).clickable { onSave(active.toList()) }, contentAlignment = Alignment.Center) {
                Text(AppText.Common.Save, color = AppColors.Core.White, fontSize = 14.sp)
            }
        }
        Text(AppText.Health.ManageOrder, color = Muted, fontSize = 13.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 14.dp))
        warning?.let { Text(it, color = AppColors.Health.Warning, fontSize = 12.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 4.dp)) }
        LazyColumn(
            state = listState,
            modifier = Modifier.weight(1f).padding(horizontal = 16.dp).pointerInput(Unit) {
                detectDragGesturesAfterLongPress(
                    onDragStart = { position ->
                        val item = listState.layoutInfo.visibleItemsInfo.firstOrNull {
                            it.index in active.indices && position.y.toInt() in it.offset..(it.offset + it.size)
                        }
                        draggedType = item?.let { active.getOrNull(it.index) }; nonAnimatedType = draggedType; dragOffset = 0f
                    },
                    onDragCancel = { draggedType = null; dragOffset = 0f },
                    onDragEnd = { draggedType = null; dragOffset = 0f },
                    onDrag = { change, amount ->
                        val type = draggedType ?: return@detectDragGesturesAfterLongPress
                        change.consume()
                        val currentIndex = active.indexOf(type)
                        val layoutInfo = listState.layoutInfo
                        val current = layoutInfo.visibleItemsInfo.firstOrNull { it.index == currentIndex } ?: return@detectDragGesturesAfterLongPress
                        val minOff = layoutInfo.viewportStartOffset - current.offset.toFloat()
                        val maxOff = layoutInfo.viewportEndOffset - current.offset.toFloat() - current.size
                        dragOffset = (dragOffset + amount.y).coerceIn(minOff, maxOff)
                        val dir = amount.y.compareTo(0f)
                        val targetIdx = currentIndex + dir
                        val target = layoutInfo.visibleItemsInfo.firstOrNull { it.index == targetIdx && it.index in active.indices }
                        val center = current.offset + current.size / 2f + dragOffset
                        val swap = when { target == null -> false; dir < 0 -> center <= target.offset + target.size / 2f; dir > 0 -> center >= target.offset + target.size / 2f; else -> false }
                        if (swap && target != null) {
                            val vt = current.offset + dragOffset; val fvi = listState.firstVisibleItemIndex; val fvo = listState.firstVisibleItemScrollOffset
                            active.removeAt(currentIndex); active.add(target.index, type)
                            if (currentIndex == fvi || target.index == fvi) listState.requestScrollToItem(fvi, fvo)
                            dragOffset = vt - target.offset
                            dragOffset = dragOffset.coerceIn(layoutInfo.viewportStartOffset - target.offset.toFloat(), layoutInfo.viewportEndOffset - target.offset.toFloat() - target.size)
                        }
                        val vp = layoutInfo.viewportEndOffset
                        when { amount.y < 0 && change.position.y < 36.dp.toPx() && listState.canScrollBackward -> dragOffset -= listState.dispatchRawDelta(8.dp.toPx())
                            amount.y > 0 && change.position.y > vp - 36.dp.toPx() && listState.canScrollForward -> dragOffset -= listState.dispatchRawDelta(-8.dp.toPx()) }
                    }
                )
            }
        ) {
            itemsIndexed(active, key = { _, t -> t.name }) { idx, type ->
                EditorRow(type, false, idx == 0, idx == active.lastIndex,
                    modifier = if (nonAnimatedType == type) Modifier else Modifier.animateItem(fadeInSpec = null, placementSpec = tween(140), fadeOutSpec = null),
                    dragModifier = Modifier.zIndex(if (draggedType == type) 1f else 0f).graphicsLayer { translationY = if (draggedType == type) dragOffset else 0f; shadowElevation = if (draggedType == type) 10.dp.toPx() else 0f; alpha = if (draggedType == type) .92f else 1f },
                    onAction = { if (active.size > 3) { active.remove(type); warning = null } else warning = AppText.Health.MinimumCards }
                )
            }
            if (inactive.isNotEmpty()) {
                item { Text(AppText.Health.MoreDailyData, color = Muted, fontSize = 13.sp, modifier = Modifier.padding(6.dp, 24.dp, 6.dp, 11.dp)) }
                itemsIndexed(inactive, key = { _, t -> "more_${t.name}" }) { _, type ->
                    EditorRow(type, true, false, false, dragModifier = Modifier) { active.add(type); warning = null }
                }
            }
            item {
                Text(AppText.Health.RestoreDefaults, color = AppColors.Health.Action, fontSize = 14.sp,
                    modifier = Modifier.fillMaxWidth().padding(top = 24.dp, bottom = 32.dp).clip(RoundedCornerShape(8.dp)).background(CardBlack)
                        .clickable { active.clear(); active.addAll(DefaultHealthCardOrder); warning = null }.padding(horizontal = 18.dp, vertical = 17.dp))
            }
        }
    }
}

@Composable
private fun EditorRow(type: HealthCardType, isAdd: Boolean, roundTop: Boolean, roundBottom: Boolean, modifier: Modifier = Modifier, dragModifier: Modifier, onAction: () -> Unit) {
    val shape = RoundedCornerShape(if (roundTop) 8.dp else 0.dp, if (roundTop) 8.dp else 0.dp, if (roundBottom) 8.dp else 0.dp, if (roundBottom) 8.dp else 0.dp)
    Column(modifier.fillMaxWidth().background(CardBlack, shape)) {
        Row(Modifier.fillMaxWidth().then(dragModifier).height(56.dp).padding(horizontal = 18.dp), verticalAlignment = Alignment.CenterVertically) {
            if (!isAdd) { Text(AppText.Health.DragHandle, color = AppColors.Health.Muted, fontSize = 18.sp); Spacer(Modifier.width(10.dp)) }
            AppImage(iconOf(type), null, Modifier.size(22.dp)); Spacer(Modifier.width(10.dp))
            Text(titleOf(type), color = AppColors.Health.EditorTitle, fontSize = 15.sp, modifier = Modifier.weight(1f))
            if (isAdd) Box(Modifier.size(30.dp).clip(CircleShape).background(AppColors.Health.AddAction).clickable(onClick = onAction), contentAlignment = Alignment.Center) {
                Text("+", color = AppColors.Core.White, fontSize = 24.sp, lineHeight = 24.sp, fontWeight = FontWeight.Light)
            } else AppImage(AppImages.Health.EditorRemove, AppText.Health.Remove, Modifier.size(30.dp).clickable(onClick = onAction))
        }
        if (!roundBottom) Box(Modifier.padding(start = 18.dp).fillMaxWidth().height(1.dp).background(AppColors.Health.EditorDivider))
    }
}

@Composable
private fun DetailPlaceholder(card: HealthCardUiModel, onBack: () -> Unit) {
    Column(Modifier.fillMaxSize().background(PageBlack).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().height(64.dp).padding(horizontal = 18.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(AppText.Common.Back, color = AppColors.Core.White, fontSize = 38.sp, modifier = Modifier.clickable(onClick = onBack))
            Text(card.title, color = AppColors.Core.White, fontSize = 19.sp, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
            Spacer(Modifier.width(28.dp))
        }
        Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            AppImage(iconOf(card.type), null, Modifier.size(56.dp)); Spacer(Modifier.height(20.dp))
            Text(AppText.Health.pendingFeature(card.title), color = AppColors.Health.Placeholder, fontSize = 16.sp)
        }
    }
}

private fun titleOf(type: HealthCardType) = when (type) {
    HealthCardType.WeeklyPlan -> AppText.Health.WeeklyPlan; HealthCardType.TodayActivity -> AppText.Health.TodayActivity
    HealthCardType.TrainingLoad -> AppText.Health.TrainingLoad; HealthCardType.TrainingAssessment -> AppText.Health.TrainingAssessment
    HealthCardType.Recovery -> AppText.Health.Recovery; HealthCardType.RunningAbility -> AppText.Health.RunningAbility
    HealthCardType.CyclingAbility -> AppText.Health.CyclingAbility; HealthCardType.HeartRate -> AppText.Health.HeartRate
    HealthCardType.Stress -> AppText.Health.Stress; HealthCardType.Sleep -> AppText.Health.Sleep
    HealthCardType.HrvAssessment -> AppText.Health.HrvAssessment; HealthCardType.RestingHeartRate -> AppText.Health.RestingHeartRate
    HealthCardType.HealthCheck -> AppText.Health.HealthCheck; HealthCardType.BodyManagement -> AppText.Health.BodyManagement
}

private fun iconOf(type: HealthCardType) = when (type) {
    HealthCardType.WeeklyPlan -> AppImages.Health.WeeklyPlan; HealthCardType.TodayActivity -> AppImages.Health.TodayActivity
    HealthCardType.TrainingLoad -> AppImages.Health.TrainingLoad; HealthCardType.TrainingAssessment -> AppImages.Health.TrainingAssessment
    HealthCardType.Recovery -> AppImages.Health.Recovery; HealthCardType.RunningAbility -> AppImages.Health.RunningAbility
    HealthCardType.CyclingAbility -> AppImages.Health.CyclingAbility; HealthCardType.HeartRate -> AppImages.Health.HeartRate
    HealthCardType.Stress -> AppImages.Health.Stress; HealthCardType.Sleep -> AppImages.Health.Sleep
    HealthCardType.HrvAssessment -> AppImages.Health.HrvAssessment; HealthCardType.RestingHeartRate -> AppImages.Health.RestingHeartRate
    HealthCardType.HealthCheck -> AppImages.Health.HealthCheck; HealthCardType.BodyManagement -> AppImages.Health.BodyManagement
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun HealthDashboardScreenPreview() {
    DemoTheme {
        Column(Modifier.fillMaxSize().background(PageBlack)) {
            HeroTopRow("7月15日 星期三", isSyncing = false, onLongPressWatch = {})
            ArcAndMetricsSection(DashboardUiState("今天", "7月15日 星期三", DailySummary(8769, 769, 69), emptyList()))
        }
    }
}
