package com.example.demo.health

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.demo.common.health.HealthCardVisualData

@Composable
fun HealthGridVisual(v: HealthCardVisualData) {
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
        v.metrics.chunked(3).take(2).forEach { row ->
            Row(
                Modifier.fillMaxWidth().padding(top = 7.dp),
                horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(18.dp)
            ) {
                row.forEach { MetricValue(it, Modifier.width(92.dp)) }
            }
        }
    }
}
