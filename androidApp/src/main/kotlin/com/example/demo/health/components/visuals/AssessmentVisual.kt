package com.example.demo.health

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.ui.resources.AppColors

@Composable
fun AssessmentVisual(v: HealthCardVisualData) {
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
        v.caption?.let {
            Text(
                localizedHealthText(it),
                color = AppColors.Health.VisualOrange,
                fontSize = 20.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
        v.detail?.let {
            Text(
                localizedHealthText(it),
                color = AppColors.Health.CardTitle,
                fontSize = 14.sp,
                maxLines = 2,
                lineHeight = 20.sp
            )
        }
        Spacer(Modifier.height(16.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween) {
            v.metrics.take(3).forEachIndexed { index, metric ->
                MetricValue(metric, Modifier.width(82.dp))
                if (index < 2) Box(Modifier.width(1.dp).height(42.dp).background(AppColors.Health.Divider))
            }
        }
    }
}
