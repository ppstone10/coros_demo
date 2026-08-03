package com.example.demo.health

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages

@Composable
fun WeeklyVisual(v: HealthCardVisualData) {
    var selectedDay by remember(v.highlightedIndex, v.weeklyDayPlans) {
        mutableIntStateOf(v.highlightedIndex ?: 0)
    }
    val display = weeklyVisualForSelectedDay(v, selectedDay)
    Column(Modifier.padding(top = 8.dp).fillMaxWidth()) {
        WeekLabels(v, selectedDay) { selectedDay = it }
        Spacer(Modifier.height(10.dp))
        Row(
            Modifier
                .fillMaxWidth()
                .height(64.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(AppColors.Health.ActivityTile)
                .padding(horizontal = 16.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AppImage(AppImages.Health.TodayRunner, null, Modifier.size(20.dp))
            Spacer(Modifier.width(6.dp))
            Column(Modifier.weight(1f)) {
                display.caption?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Core.White,
                        fontSize = 14.sp,
                        maxLines = 1
                    )
                }
                Row(verticalAlignment = Alignment.Bottom) {
                    ValueText(display.primaryValue, 12)
                    UnitText(display.primaryUnit, 12)
                    display.metrics.firstOrNull()?.let {
                        Text(
                            "  ${it.value} ${localizedHealthText(it.label)}",
                            color = AppColors.Health.Muted,
                            fontSize = 11.sp,
                            maxLines = 1
                        )
                    }
                }
            }
            MiniBars(
                v.chartPoints, selectedDay,
                Modifier.width(80.dp).height(36.dp),
                dense = true
            )
        }
    }
}

@Composable
private fun WeekLabels(v: HealthCardVisualData, selectedDayIndex: Int, onDaySelected: (Int) -> Unit) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        v.chartPoints.take(7).forEachIndexed { index, point ->
            Box(
                Modifier
                    .size(28.dp)
                    .then(
                        if (index == selectedDayIndex)
                            Modifier.background(AppColors.Health.Action, RoundedCornerShape(14.dp))
                        else Modifier
                    )
                    .clickable { onDaySelected(index) },
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    localizedHealthText(LocalizedTextSpec(point.label)),
                    color = if (index == selectedDayIndex) AppColors.Core.White else AppColors.Health.Muted,
                    fontSize = 14.sp
                )
            }
        }
    }
}
