package com.example.demo.common.health

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import com.example.demo.common.health.mock.HealthPreviewFixtures
import com.example.demo.common.health.model.HealthCardStatus
import com.example.demo.common.health.model.HealthMockScenario
import com.example.demo.common.health.model.DefaultHealthCardOrder

class HealthPreviewFixturesTest {
    @Test
    fun normalPreviewStateContainsEveryCardWithDeterministicVisualData() {
        val first = HealthPreviewFixtures.normalState()
        val second = HealthPreviewFixtures.normalState()

        assertEquals(HealthMockScenario.Normal, first.currentScenario)
        assertEquals(first, second)
        val uiState = assertNotNull(first.uiState)
        assertEquals(DefaultHealthCardOrder.toSet(), uiState.cards.map { it.type }.toSet())
        assertEquals(DefaultHealthCardOrder.size, uiState.cards.size)
        assertTrue(uiState.cards.all { it.status != HealthCardStatus.Empty })
        assertTrue(uiState.cards.all { card ->
            card.visual.metrics.isNotEmpty() ||
                card.visual.chartPoints.isNotEmpty() ||
                card.visual.progress != null ||
                card.visual.range != null ||
                card.visual.sleepStages.isNotEmpty() ||
                card.visual.primaryValue != null ||
                card.visual.assetKey != null
        })
    }
}
