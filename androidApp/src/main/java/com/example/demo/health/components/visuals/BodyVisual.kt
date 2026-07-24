package com.example.demo.health

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages

@Composable
fun BodyVisual(v: HealthCardVisualData) {
    OverviewRow(
        left = {
            Column {
                v.caption?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.CardTitle,
                        fontSize = 14.sp
                    )
                }
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 32)
                    UnitText(v.primaryUnit, 20)
                }
                v.detail?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 12.sp
                    )
                }
            }
        },
        right = {
            Column(
                Modifier.width(142.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    Modifier.height(108.dp),
                    horizontalArrangement = androidx.compose.foundation.layout.Arrangement.Center
                ) {
                    AppImage(AppImages.Health.BodyFront, null, Modifier.width(52.dp).height(108.dp))
                    AppImage(AppImages.Health.BodyBack, null, Modifier.width(52.dp).height(108.dp))
                }
                Row {
                    v.metrics.take(2).forEachIndexed { index, metric ->
                        if (index > 0) Text(" · ", color = AppColors.Health.Muted, fontSize = 11.sp)
                        Text(
                            localizedHealthText(metric.label),
                            color = AppColors.Health.Muted,
                            fontSize = 11.sp,
                            maxLines = 1
                        )
                    }
                }
            }
        },
    )
}
