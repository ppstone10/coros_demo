package com.example.demo.health

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Velocity
import androidx.compose.ui.unit.dp
import com.example.demo.R
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.common.login.MockError
import com.example.demo.common.login.MockResult
import com.example.demo.login.LoginViewModel
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.resources.AppTypography
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.milliseconds

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
    var selectedScenario by remember(viewModel.state.currentSession) { mutableStateOf(HealthMockScenario.Normal) }

    val dashboard = (result as? MockResult.Success)?.data
    val state = dashboard?.uiState
    val failureError = (result as? MockResult.Failure)?.error
    val isAuthError = failureError != null && failureError != MockError.CorruptedData
    val isCorrupted = failureError == MockError.CorruptedData

    LaunchedEffect(dashboard?.scenario) {
        dashboard?.scenario?.let { selectedScenario = it }
    }

    if (showScenarioPicker) {
        ScenarioPickerDialog(
            currentScenario = selectedScenario,
            onSelect = { scenario ->
                viewModel.selectHealthScenario(scenario)
                selectedScenario = scenario
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
            delay(4460.milliseconds)
            result = viewModel.refreshHealthDashboard()
            isRefreshing = false
        }
    }

    Column(
        Modifier
            .fillMaxSize()
            .background(AppColors.Health.Page)
    ) {
        HeroTopRow(
            dateLabel = state?.dateLabel?.let { localizedHealthText(it) }.orEmpty(),
            isSyncing = isRefreshing,
            onLongPressWatch = { showScenarioPicker = true }
        )

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
                                    text = stringResource(R.string.health_edit_cards),
                                    color = AppColors.Health.EditText,
                                    fontSize = AppTypography.Label,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(AppSpacing.Large)
                                        .clip(RoundedCornerShape(22.dp))
                                        .background(AppColors.Health.Card)
                                        .clickable {
                                            editing = true
                                            onFullscreenChange(true)
                                        }
                                        .padding(horizontal = AppSpacing.ActionHorizontal, vertical = AppSpacing.Medium)
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
                            .padding(top = AppSpacing.Page),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(16.dp),
                            color = AppColors.Health.Steps,
                            strokeWidth = 2.dp
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(stringResource(R.string.health_data_syncing), color = AppColors.Health.Muted, fontSize = AppTypography.Supporting)
                    }
                }
            }

            Spacer(Modifier.height(0.dp))
        }
    }
}
