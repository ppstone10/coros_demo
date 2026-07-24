package com.example.demo.health

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.unit.Velocity

fun Modifier.pullToRefresh(state: PullToRefreshState): Modifier = this.nestedScroll(state.connection)

fun Modifier.pullTranslation(state: PullToRefreshState): Modifier = this.graphicsLayer { translationY = state.pullOffset }

class PullToRefreshState {
    var pullOffset by mutableFloatStateOf(0f)
        private set
    var isRefreshing by mutableStateOf(false)

    internal val connection = object : NestedScrollConnection {
        override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
            if (pullOffset > 0f && available.y < 0f) {
                val consumed = minOf(-available.y, pullOffset)
                pullOffset -= consumed
                return Offset(0f, -consumed)
            }
            return Offset.Zero
        }

        override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
            if (available.y > 0f && source == NestedScrollSource.UserInput) {
                pullOffset = (pullOffset + available.y * 0.4f).coerceAtMost(250f)
                return Offset(0f, available.y)
            }
            return Offset.Zero
        }

        override suspend fun onPreFling(available: Velocity): Velocity {
            if (pullOffset > 0f && !isRefreshing && pullOffset > 80f) {
                isRefreshing = true
            }
            return available
        }
    }

    @Composable
    fun ResetAnimation() {
        LaunchedEffect(isRefreshing) {
            if (!isRefreshing && pullOffset > 0f) {
                val anim = Animatable(pullOffset)
                anim.animateTo(0f, tween(300))
                pullOffset = 0f
            }
        }
    }
}

@Composable
fun rememberPullToRefreshState(): PullToRefreshState {
    return remember { PullToRefreshState() }
}
