package com.example.demo.health.components.visuals

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.demo.common.health.model.HealthCardType
import com.example.demo.common.health.model.HealthCardVisualData
import com.example.demo.health.components.MetricValue

@Composable
fun HealthGridVisual(v: HealthCardVisualData) {
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
        v.metrics.chunked(3).take(2).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(top = 7.dp),
                horizontalArrangement = Arrangement.spacedBy(18.dp)
            ) {
                row.forEach {
                    MetricValue(
                        it,
                        Modifier.width(92.dp)
                    )
                }
            }
        }
    }
}

@Preview(name = "Health check visual", showBackground = true, backgroundColor = 0xFF171719)
@Composable
private fun HealthGridVisualPreview() {
    PreviewVisualSurface {
        HealthGridVisual(
            previewHealthVisual(HealthCardType.HealthCheck)
        )
    }
}
