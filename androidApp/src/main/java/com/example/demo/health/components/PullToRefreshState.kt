package com.example.demo.health

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.nestedscroll.NestedScrollConnection
import androidx.compose.ui.input.nestedscroll.NestedScrollSource
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.Velocity
import androidx.compose.ui.unit.dp

enum class PullRefreshPhase {
    Idle,
    Dragging,
    Armed,
    Refreshing,
    Resetting
}

enum class PullRefreshPrompt {
    Hidden,
    Pull,
    Release,
    Syncing
}

internal fun promptForPullRefreshPhase(phase: PullRefreshPhase): PullRefreshPrompt = when (phase) {
    PullRefreshPhase.Idle -> PullRefreshPrompt.Hidden
    PullRefreshPhase.Dragging -> PullRefreshPrompt.Pull
    PullRefreshPhase.Armed -> PullRefreshPrompt.Release
    PullRefreshPhase.Refreshing,
    PullRefreshPhase.Resetting -> PullRefreshPrompt.Syncing
}

internal fun indicatorZIndexForPhase(phase: PullRefreshPhase): Float =
    if (phase == PullRefreshPhase.Idle) 0f else 4f

internal fun indicatorAlphaForPhase(
    phase: PullRefreshPhase,
    progress: Float
): Float = when (phase) {
    PullRefreshPhase.Idle -> 0f
    PullRefreshPhase.Dragging -> (progress / 0.4f).coerceIn(0f, 1f)
    PullRefreshPhase.Armed,
    PullRefreshPhase.Refreshing -> 1f
    PullRefreshPhase.Resetting -> progress.coerceIn(0f, 1f)
}

internal fun phaseForPullOffset(offset: Float, threshold: Float): PullRefreshPhase = when {
    offset <= 0f -> PullRefreshPhase.Idle
    offset >= threshold -> PullRefreshPhase.Armed
    else -> PullRefreshPhase.Dragging
}

internal fun indicatorTopAttachedToBody(
    bodyTop: Float,
    indicatorHeight: Float,
    fixedGap: Float
): Float = bodyTop - indicatorHeight - fixedGap

internal fun indicatorTopForPhase(
    phase: PullRefreshPhase,
    bodyTop: Float,
    indicatorHeight: Float,
    fixedGap: Float
): Float = when (phase) {
    PullRefreshPhase.Idle,
    PullRefreshPhase.Dragging,
    PullRefreshPhase.Armed,
    PullRefreshPhase.Refreshing,
    PullRefreshPhase.Resetting -> indicatorTopAttachedToBody(
        bodyTop = bodyTop,
        indicatorHeight = indicatorHeight,
        fixedGap = fixedGap
    )
}

internal fun pullIndicatorIconRotation(progress: Float): Float =
    progress.coerceIn(0f, 1f) * 45f

object PullRefreshDefaults {
    val RefreshThreshold: Dp = 80.dp
    val RefreshHoldOffset: Dp = 34.dp
    val MaxPullOffset: Dp = 180.dp
    val IndicatorBodyGap: Dp = 80.dp
    val IndicatorMaxWidth: Dp = 168.dp
    const val PullResistance: Float = 0.4f
    const val SettleDurationMillis: Int = 300
}

fun Modifier.pullToRefresh(state: PullToRefreshState): Modifier =
    nestedScroll(state.connection)

fun Modifier.pullTranslation(state: PullToRefreshState): Modifier =
    graphicsLayer { translationY = state.pullOffset }

@Stable
class PullToRefreshState internal constructor(
    val refreshThresholdPx: Float,
    val refreshHoldOffsetPx: Float,
    private val maxPullOffsetPx: Float
) {
    var pullOffset by mutableFloatStateOf(0f)
        private set

    var phase by mutableStateOf(PullRefreshPhase.Idle)
        private set

    val pullProgress: Float
        get() = (pullOffset / refreshThresholdPx).coerceIn(0f, 1f)

    val isRefreshing: Boolean
        get() = phase == PullRefreshPhase.Refreshing

    internal val connection = object : NestedScrollConnection {
        override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
            if (
                source == NestedScrollSource.UserInput &&
                phase != PullRefreshPhase.Refreshing &&
                phase != PullRefreshPhase.Resetting &&
                pullOffset > 0f &&
                available.y < 0f
            ) {
                val consumed = minOf(-available.y, pullOffset)
                pullOffset -= consumed
                phase = phaseForPullOffset(pullOffset, refreshThresholdPx)
                return Offset(0f, -consumed)
            }
            return Offset.Zero
        }

        override fun onPostScroll(
            consumed: Offset,
            available: Offset,
            source: NestedScrollSource
        ): Offset {
            if (
                source == NestedScrollSource.UserInput &&
                phase != PullRefreshPhase.Refreshing &&
                phase != PullRefreshPhase.Resetting &&
                available.y > 0f
            ) {
                pullOffset = (
                    pullOffset + available.y * PullRefreshDefaults.PullResistance
                    ).coerceAtMost(maxPullOffsetPx)
                phase = phaseForPullOffset(pullOffset, refreshThresholdPx)
                return Offset(0f, available.y)
            }
            return Offset.Zero
        }

        override suspend fun onPreFling(available: Velocity): Velocity {
            when (phase) {
                PullRefreshPhase.Armed -> {
                    animateOffsetTo(refreshHoldOffsetPx)
                    phase = PullRefreshPhase.Refreshing
                }
                PullRefreshPhase.Dragging -> reset()
                else -> Unit
            }
            return if (pullOffset > 0f || phase != PullRefreshPhase.Idle) {
                Velocity.Zero
            } else {
                available
            }
        }
    }

    suspend fun completeRefresh() {
        if (phase == PullRefreshPhase.Refreshing) {
            reset()
        }
    }

    private suspend fun reset() {
        phase = PullRefreshPhase.Resetting
        animateOffsetTo(0f)
        pullOffset = 0f
        phase = PullRefreshPhase.Idle
    }

    private suspend fun animateOffsetTo(target: Float) {
        val animation = Animatable(pullOffset)
        animation.animateTo(
            targetValue = target,
            animationSpec = tween(PullRefreshDefaults.SettleDurationMillis)
        ) {
            pullOffset = value
        }
        pullOffset = target
    }
}

@Composable
fun rememberPullToRefreshState(
    refreshThreshold: Dp = PullRefreshDefaults.RefreshThreshold,
    refreshHoldOffset: Dp = PullRefreshDefaults.RefreshHoldOffset,
    maxPullOffset: Dp = PullRefreshDefaults.MaxPullOffset
): PullToRefreshState {
    val density = LocalDensity.current
    val thresholdPx = with(density) { refreshThreshold.toPx() }
    val holdOffsetPx = with(density) { refreshHoldOffset.toPx() }
    val maxOffsetPx = with(density) { maxPullOffset.toPx() }
    return remember(thresholdPx, holdOffsetPx, maxOffsetPx) {
        PullToRefreshState(
            refreshThresholdPx = thresholdPx,
            refreshHoldOffsetPx = holdOffsetPx,
            maxPullOffsetPx = maxOffsetPx
        )
    }
}
