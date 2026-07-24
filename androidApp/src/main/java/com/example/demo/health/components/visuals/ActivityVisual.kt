package com.example.demo.health

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages

@Composable
fun ActivityVisual(v: HealthCardVisualData) {
    Column(Modifier.padding(top = 10.dp).fillMaxWidth()) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            AppImage(
                AppImages.Health.ActivityMap, null,
                Modifier.size(48.dp).clip(RoundedCornerShape(6.dp)),
                ContentScale.Crop
            )
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.Center) {
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(v.primaryValue, 24)
                    UnitText(v.primaryUnit, 16)
                }
                Row {
                    v.detail?.let {
                        Text(
                            localizedHealthText(it),
                            color = AppColors.Health.Muted,
                            fontSize = 12.sp,
                            maxLines = 1
                        )
                    }
                    v.caption?.let {
                        Text(
                            " ${localizedHealthText(it)}",
                            color = AppColors.Health.Muted,
                            fontSize = 12.sp,
                            maxLines = 1
                        )
                    }
                }
            }
            AppImage(AppImages.Health.TodayRunner, null, Modifier.size(24.dp))
        }
    }
}
