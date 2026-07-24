package com.example.demo.health

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.ui.resources.AppColors

@Composable
fun LoadVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                ValueText(v.primaryValue, 32)
                v.caption?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 12.sp,
                        maxLines = 1
                    )
                }
            }
        },
        right = { LoadOverview(v) },
    )
}

@Composable
private fun LoadOverview(v: HealthCardVisualData) {
    Column(Modifier.width(130.dp)) {
        MiniBars(
            v.chartPoints,
            v.highlightedIndex,
            Modifier.fillMaxWidth().height(36.dp),
            colorOverride = AppColors.Health.VisualCyan,
            showTrack = true,
        )
        Spacer(Modifier.height(4.dp))
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            v.chartPoints.take(7).forEachIndexed { index, point ->
                Text(
                    localizedHealthText(LocalizedTextSpec(point.label)),
                    color = if (index == v.highlightedIndex) AppColors.Core.White else AppColors.Health.Muted,
                    fontSize = 9.sp,
                )
            }
        }
    }
}
