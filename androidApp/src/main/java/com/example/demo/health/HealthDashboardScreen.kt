package com.example.demo.health

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
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.demo.R
import com.example.demo.common.health.BodyManagement
import com.example.demo.common.health.CyclingAbility
import com.example.demo.common.health.DailySummary
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.HealthCheck
import com.example.demo.common.health.HealthDashboardData
import com.example.demo.common.health.HealthDashboardDataSource
import com.example.demo.common.health.HealthDashboardUseCase
import com.example.demo.common.health.HealthError
import com.example.demo.common.health.HealthMockScenario
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
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.milliseconds

sealed interface DashboardPage {
    data object Main : DashboardPage
    data class Detail(val card: HealthCardUiModel) : DashboardPage
    data object Editor : DashboardPage
    data object ScenarioPicker : DashboardPage
}

data class DashboardScreenState(
    val page: DashboardPage = DashboardPage.Main
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HealthDashboardScreen(
    healthViewModel: HealthDashboardViewModel,
    onWatchClick: () -> Unit = {},
    onFullscreenChange: (Boolean) -> Unit = {}
) {
    val state = healthViewModel.state
    val effect = healthViewModel.effect
    val isAuthError = state.error == HealthError.AuthRequired
    val isCorrupted = state.error == HealthError.CorruptedData

    var screenState by remember { mutableStateOf(DashboardScreenState()) }

    LaunchedEffect(Unit) { healthViewModel.load() }

    LaunchedEffect(effect) {
        effect?.let { healthViewModel.onEffectConsumed() }
    }

    val pullState = rememberPullToRefreshState()
    pullState.ResetAnimation()

    LaunchedEffect(pullState.isRefreshing) {
        if (pullState.isRefreshing) {
            delay(4460L.milliseconds)
            healthViewModel.refresh()
            pullState.isRefreshing = false
        }
    }
    val showRefreshIndicator = state.isRefreshing || pullState.isRefreshing

    when (val page = screenState.page) {
        DashboardPage.ScenarioPicker -> {
            ScenarioPickerDialog(
                currentScenario = state.currentScenario,
                onSelect = { scenario ->
                    healthViewModel.selectScenario(scenario)
                    screenState = screenState.copy(page = DashboardPage.Main)
                },
                onDismiss = { screenState = screenState.copy(page = DashboardPage.Main) }
            )
        }
        is DashboardPage.Detail -> {
            DetailPlaceholder(page.card) {
                screenState = screenState.copy(page = DashboardPage.Main)
                onFullscreenChange(false)
            }
        }
        DashboardPage.Editor -> {
            CardEditor(
                initial = state.enabledCardTypes,
                onClose = {
                    screenState = screenState.copy(page = DashboardPage.Main)
                    onFullscreenChange(false)
                },
                onSave = { types ->
                    healthViewModel.saveCardConfiguration(types)
                    screenState = screenState.copy(page = DashboardPage.Main)
                    onFullscreenChange(false)
                }
            )
        }
        DashboardPage.Main -> {
            Column(
                Modifier.fillMaxSize().background(AppColors.Health.Page)
            ) {
                HeroTopRow(
                    dateLabel = state.uiState?.dateLabel?.let { localizedHealthText(it) }.orEmpty(),
                    isSyncing = showRefreshIndicator,
                    onClickWatch = onWatchClick,
                    onLongPressWatch = {
                        screenState = screenState.copy(page = DashboardPage.ScenarioPicker)
                    }
                )

                Box(
                    modifier = Modifier.weight(1f).fillMaxWidth().pullToRefresh(pullState)
                ) {
                    Box(Modifier.fillMaxSize()) {
                        LazyColumn(
                            modifier = Modifier.fillMaxSize().pullTranslation(pullState),
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
                                state.uiState != null -> {
                                    item { Spacer(Modifier.height(8.dp)) }
                                    item { ArcAndMetricsSection(state.uiState!!) }
                                    itemsIndexed(
                                        items = state.uiState!!.cards,
                                        key = { _, card -> card.type.name }
                                    ) { _, card ->
                                        DashboardCard(card) {
                                            screenState = screenState.copy(page = DashboardPage.Detail(card))
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
                                                    screenState = screenState.copy(page = DashboardPage.Editor)
                                                    onFullscreenChange(true)
                                                }
                                                .padding(horizontal = AppSpacing.ActionHorizontal, vertical = AppSpacing.Medium)
                                        )
                                    }
                                    item { Spacer(Modifier.height(24.dp)) }
                                }
                            }
                        }

                        if (showRefreshIndicator) {
                            Row(
                                Modifier.fillMaxWidth().align(Alignment.TopCenter).padding(top = AppSpacing.Page),
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
                }
            }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000, locale = "zh")
@Composable
private fun HealthDashboardPreview() {
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
    val dashboardState = useCase.toUiState(data)

    DemoTheme {
        Column(Modifier.fillMaxSize().background(AppColors.Health.Page)) {
            HeroTopRow(dateLabel = "July 21, 2026", isSyncing = false, onClickWatch = {}, onLongPressWatch = {})
            Column(Modifier.verticalScroll(rememberScrollState())) {
                ArcAndMetricsSection(dashboardState)
                dashboardState.cards.forEach { card ->
                    DashboardCard(card) {}
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
