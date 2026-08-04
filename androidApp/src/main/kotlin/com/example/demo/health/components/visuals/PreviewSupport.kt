package com.example.demo.health

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.HealthPreviewFixtures
import com.example.demo.core.resources.AppColors
import com.example.demo.core.theme.DemoTheme

internal fun previewHealthVisual(type: HealthCardType): HealthCardVisualData =
    requireNotNull(
        HealthPreviewFixtures.normalState().uiState
            ?.cards
            ?.firstOrNull { it.type == type }
            ?.visual
    ) { "Missing common Preview visual for $type" }

@Composable
internal fun PreviewVisualSurface(content: @Composable () -> Unit) {
    DemoTheme {
        Box(
            Modifier
                .width(360.dp)
                .background(AppColors.Health.Card)
                .padding(16.dp)
        ) {
            content()
        }
    }
}
