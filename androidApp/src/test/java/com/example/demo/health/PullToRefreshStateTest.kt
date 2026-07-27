package com.example.demo.health

import org.junit.Assert.assertEquals
import org.junit.Test

class PullToRefreshStateTest {
    @Test
    fun offsetBelowThresholdIsDragging() {
        assertEquals(
            PullRefreshPhase.Dragging,
            phaseForPullOffset(offset = 79f, threshold = 80f)
        )
    }

    @Test
    fun offsetAtThresholdIsArmed() {
        assertEquals(
            PullRefreshPhase.Armed,
            phaseForPullOffset(offset = 80f, threshold = 80f)
        )
    }

    @Test
    fun zeroOffsetIsIdle() {
        assertEquals(
            PullRefreshPhase.Idle,
            phaseForPullOffset(offset = 0f, threshold = 80f)
        )
    }

    @Test
    fun iconRotationIsClampedAndRemainsSubtle() {
        assertEquals(45f, pullIndicatorIconRotation(progress = 2f))
    }

    @Test
    fun promptChangesAcrossDraggingArmedAndRefreshing() {
        assertEquals(
            PullRefreshPrompt.Pull,
            promptForPullRefreshPhase(PullRefreshPhase.Dragging)
        )
        assertEquals(
            PullRefreshPrompt.Release,
            promptForPullRefreshPhase(PullRefreshPhase.Armed)
        )
        assertEquals(
            PullRefreshPrompt.Syncing,
            promptForPullRefreshPhase(PullRefreshPhase.Refreshing)
        )
    }

    @Test
    fun visiblePromptsStayAboveHeroDuringDraggingAndRefresh() {
        assertEquals(4f, indicatorZIndexForPhase(PullRefreshPhase.Dragging))
        assertEquals(4f, indicatorZIndexForPhase(PullRefreshPhase.Armed))
        assertEquals(4f, indicatorZIndexForPhase(PullRefreshPhase.Refreshing))
    }

    @Test
    fun draggingPromptBecomesFullyVisibleBeforeThreshold() {
        assertEquals(0.5f, indicatorAlphaForPhase(PullRefreshPhase.Dragging, 0.2f))
        assertEquals(1f, indicatorAlphaForPhase(PullRefreshPhase.Dragging, 0.4f))
        assertEquals(1f, indicatorAlphaForPhase(PullRefreshPhase.Armed, 1f))
        assertEquals(1f, indicatorAlphaForPhase(PullRefreshPhase.Refreshing, 1f))
    }

    @Test
    fun draggingIndicatorKeepsFixedGapAndMovesWithBody() {
        val firstTop = indicatorTopAttachedToBody(
            bodyTop = 300f,
            indicatorHeight = 20f,
            fixedGap = 60f
        )
        val secondTop = indicatorTopAttachedToBody(
            bodyTop = 340f,
            indicatorHeight = 20f,
            fixedGap = 60f
        )

        assertEquals(220f, firstTop)
        assertEquals(260f, secondTop)
        assertEquals(40f, secondTop - firstTop)
        assertEquals(60f, 300f - (firstTop + 20f))
        assertEquals(60f, 340f - (secondTop + 20f))
    }

    @Test
    fun refreshAndResetKeepTheSameBodyAttachment() {
        assertEquals(
            244f,
            indicatorTopForPhase(
                phase = PullRefreshPhase.Refreshing,
                bodyTop = 324f,
                indicatorHeight = 20f,
                fixedGap = 60f
            )
        )
        assertEquals(
            200f,
            indicatorTopForPhase(
                phase = PullRefreshPhase.Resetting,
                bodyTop = 280f,
                indicatorHeight = 20f,
                fixedGap = 60f
            )
        )
    }
}
