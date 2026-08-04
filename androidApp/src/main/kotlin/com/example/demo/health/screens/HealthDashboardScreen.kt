package com.example.demo.health.screens

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
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.zIndex
import com.example.demo.R
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthError
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.health.HealthPreviewFixtures
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppSpacing
import com.example.demo.core.resources.AppTypography
import com.example.demo.core.theme.DemoTheme
import com.example.demo.auth.screens.profile.WeightSheet
import com.example.demo.health.pullToRefresh
import com.example.demo.health.pullTranslation
import com.example.demo.health.viewmodel.HealthDashboardViewModel
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import kotlin.time.Duration.Companion.milliseconds

sealed interface DashboardPage {
    data object Main : DashboardPage
    data object ScenarioPicker : DashboardPage
}

data class DashboardScreenState(
    val page: DashboardPage = DashboardPage.Main
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HealthDashboardScreen(
    healthViewModel: HealthDashboardViewModel,
    listState: LazyListState,
    onWatchClick: () -> Unit = {},
    onOpenDetail: (HealthCardType) -> Unit = {},
    onOpenEditor: () -> Unit = {},
    onOpenNormalDataEditor: () -> Unit = {}
) {
    val state = healthViewModel.state
    val effect = healthViewModel.effect
    val isAuthError = state.error == HealthError.AuthRequired
    val isCorrupted = state.error == HealthError.CorruptedData

    var screenState by remember { mutableStateOf(DashboardScreenState()) }
    var editingBodyWeight by remember { mutableStateOf<Double?>(null) }
    val pullState = _root_ide_package_.com.example.demo.health.rememberPullToRefreshState()

    LaunchedEffect(Unit) {
        if (healthViewModel.state.isRefreshing) {
            pullState.beginProgrammaticRefresh()
        } else if (healthViewModel.state.uiState == null) {
            healthViewModel.load()
        }
    }

    LaunchedEffect(effect) {
        effect?.let { healthViewModel.onEffectConsumed() }
    }

    LaunchedEffect(pullState.isRefreshing) {
        if (pullState.isRefreshing) {
            delay(4460L.milliseconds)
            healthViewModel.refresh()
            withContext(NonCancellable) {
                pullState.completeRefresh()
            }
        }
    }
    val showRefreshIndicator = state.isRefreshing || pullState.isRefreshing

    when (val page = screenState.page) {
        DashboardPage.ScenarioPicker -> {
            _root_ide_package_.com.example.demo.health.ScenarioPickerDialog(
                currentScenario = state.currentScenario,
                onSelect = { scenario ->
                    healthViewModel.selectScenario(scenario)
                    screenState = screenState.copy(page = DashboardPage.Main)
                    if (scenario == HealthMockScenario.Normal) {
                        onOpenNormalDataEditor()
                    }
                },
                onDismiss = { screenState = screenState.copy(page = DashboardPage.Main) }
            )
        }
        DashboardPage.Main -> {
            var heroHeightPx by remember { mutableIntStateOf(0) }
            var refreshIndicatorHeightPx by remember { mutableIntStateOf(0) }
            val density = LocalDensity.current
            val heroHeight = with(density) { heroHeightPx.toDp() }
            val indicatorBodyGapPx = with(density) {
                com.example.demo.health.PullRefreshDefaults.IndicatorBodyGap.toPx()
            }
            val indicatorAlphaProgress = when (pullState.phase) {
                com.example.demo.health.PullRefreshPhase.Resetting -> (
                    pullState.pullOffset / pullState.refreshHoldOffsetPx
                    ).coerceIn(0f, 1f)
                else -> pullState.pullProgress
            }
            val indicatorAlpha = _root_ide_package_.com.example.demo.health.indicatorAlphaForPhase(
                phase = pullState.phase,
                progress = indicatorAlphaProgress
            )
            val indicatorTopPx = _root_ide_package_.com.example.demo.health.indicatorTopForPhase(
                phase = pullState.phase,
                bodyTop = heroHeightPx + pullState.pullOffset,
                indicatorHeight = refreshIndicatorHeightPx.toFloat(),
                fixedGap = indicatorBodyGapPx
            )
            val refreshLabel = when (_root_ide_package_.com.example.demo.health.promptForPullRefreshPhase(
                pullState.phase
            )) {
                com.example.demo.health.PullRefreshPrompt.Pull -> stringResource(R.string.health_pull_to_refresh)
                com.example.demo.health.PullRefreshPrompt.Release -> stringResource(R.string.health_release_to_refresh)
                com.example.demo.health.PullRefreshPrompt.Syncing -> stringResource(R.string.health_data_syncing)
                com.example.demo.health.PullRefreshPrompt.Hidden -> ""
            }

            Box(
                Modifier
                    .fillMaxSize()
                    .background(AppColors.Health.Page)
                    .pullToRefresh(pullState)
            ) {
                Box(
                    Modifier
                        .fillMaxSize()
                        .padding(top = heroHeight)
                        .pullTranslation(pullState)
                        .zIndex(1f)
                ) {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        state = listState
                    ) {
                        when {
                            isAuthError -> {
                                item {
                                    Box(Modifier.fillMaxWidth().height(400.dp), contentAlignment = Alignment.Center) {
                                        Text(stringResource(R.string.health_data_unavailable), color = AppColors.Core.White)
                                    }
                                }
                            }
                            isCorrupted -> {
                                item { Spacer(Modifier.height(46.dp)) }
                                item {
                                    Column(
                                        Modifier.fillMaxWidth().padding(horizontal = AppSpacing.Page),
                                        horizontalAlignment = Alignment.CenterHorizontally
                                    ) {
                                        Spacer(Modifier.height(80.dp))
                                        Text(stringResource(R.string.health_data_corrupted), color = AppColors.Health.Risk, fontSize = AppTypography.Action)
                                    }
                                }
                            }
                            state.uiState != null -> {
                                item { Spacer(Modifier.height(8.dp)) }
                                item {
                                    _root_ide_package_.com.example.demo.health.ArcAndMetricsSection(
                                        state.uiState!!
                                    )
                                }
                                itemsIndexed(
                                    items = state.uiState!!.cards,
                                    key = { _, card -> card.type.name }
                                ) { _, card ->
                                    _root_ide_package_.com.example.demo.health.DashboardCard(
                                        card = card,
                                        onClick = { onOpenDetail(card.type) },
                                        onBodyWeightClick = {
                                            editingBodyWeight =
                                                card.visual.primaryValue?.toDoubleOrNull() ?: 60.0
                                        }
                                    )
                                }
                                item {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(AppSpacing.Large),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            text = stringResource(R.string.health_edit_cards),
                                            color = AppColors.Health.EditText,
                                            fontSize = AppTypography.Label,
                                            modifier = Modifier
                                                .wrapContentWidth()
                                                .clip(RoundedCornerShape(22.dp))
                                                .background(AppColors.Health.Card)
                                                .clickable {
                                                    onOpenEditor()
                                                }
                                                .padding(
                                                    horizontal = AppSpacing.ActionHorizontal,
                                                    vertical = AppSpacing.Medium
                                                )
                                        )
                                    }
                                }
                                item { Spacer(Modifier.height(24.dp)) }
                            }
                        }
                    }
                }

                if (pullState.phase != com.example.demo.health.PullRefreshPhase.Idle) {
                    Row(
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .widthIn(max = com.example.demo.health.PullRefreshDefaults.IndicatorMaxWidth)
                            .onGloballyPositioned {
                                refreshIndicatorHeightPx = it.size.height
                            }
                            .graphicsLayer {
                                translationY = indicatorTopPx
                                alpha = indicatorAlpha
                                val scale = 0.94f + 0.06f * indicatorAlpha
                                scaleX = scale
                                scaleY = scale
                            }
                            .zIndex(
                                _root_ide_package_.com.example.demo.health.indicatorZIndexForPhase(
                                    pullState.phase
                                )
                            ),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier
                                .size(16.dp)
                                .graphicsLayer {
                                    rotationZ = if (
                                        pullState.phase == com.example.demo.health.PullRefreshPhase.Dragging ||
                                        pullState.phase == com.example.demo.health.PullRefreshPhase.Armed
                                    ) {
                                        _root_ide_package_.com.example.demo.health.pullIndicatorIconRotation(
                                            pullState.pullProgress
                                        )
                                    } else {
                                        0f
                                    }
                                },
                            color = AppColors.Health.Steps,
                            strokeWidth = 2.dp
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(
                            refreshLabel,
                            color = AppColors.Health.Muted,
                            fontSize = AppTypography.Supporting
                        )
                    }
                }

                Box(
                    Modifier
                        .align(Alignment.TopCenter)
                        .fillMaxWidth()
                        .onGloballyPositioned { heroHeightPx = it.size.height }
                        .zIndex(3f)
                ) {
                    _root_ide_package_.com.example.demo.health.HeroTopRow(
                        dateLabel = state.uiState?.dateLabel?.let {
                            _root_ide_package_.com.example.demo.health.localizedHealthText(it)
                        }.orEmpty(),
                        isSyncing = showRefreshIndicator,
                        onClickWatch = onWatchClick,
                        onLongPressWatch = {
                            screenState = screenState.copy(page = DashboardPage.ScenarioPicker)
                        }
                    )
                }
            }
        }
    }

    editingBodyWeight?.let { current ->
        WeightSheet(
            current = current,
            onDismiss = { editingBodyWeight = null },
            onConfirm = { selected ->
                healthViewModel.saveBodyWeight(selected)
                editingBodyWeight = null
            }
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000, locale = "zh")
@Composable
private fun HealthDashboardPreview() {
    val dashboardState = requireNotNull(HealthPreviewFixtures.normalState().uiState)

    DemoTheme {
        Column(Modifier.fillMaxSize().background(AppColors.Health.Page)) {
            _root_ide_package_.com.example.demo.health.HeroTopRow(
                dateLabel = "July 21, 2026",
                isSyncing = false,
                onClickWatch = {},
                onLongPressWatch = {})
            Column(Modifier.verticalScroll(rememberScrollState())) {
                _root_ide_package_.com.example.demo.health.ArcAndMetricsSection(dashboardState)
                dashboardState.cards.forEach { card ->
                    _root_ide_package_.com.example.demo.health.DashboardCard(card) {}
                }
                Text(
                    text = stringResource(R.string.health_edit_cards),
                    color = AppColors.Health.EditText,
                    fontSize = AppTypography.Label,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(AppSpacing.Large)
                        .clip(RoundedCornerShape(22.dp))
                        .background(AppColors.Health.Card)
                        .padding(horizontal = AppSpacing.ActionHorizontal, vertical = AppSpacing.Medium)
                )
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}
