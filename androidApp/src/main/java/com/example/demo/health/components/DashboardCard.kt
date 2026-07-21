package com.example.demo.health

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.HealthCardAction
import com.example.demo.common.health.HealthCardStatus
import com.example.demo.common.health.HealthCardType
import com.example.demo.common.health.HealthCardUiModel
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme

private val CardBlack = AppColors.Health.Card
private val Muted = AppColors.Health.Muted

@Composable
fun DashboardCard(card: HealthCardUiModel, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .padding(horizontal = AppSpacing.Screen, vertical = AppSpacing.XSmall)
            .fillMaxWidth()
            .heightIn(min = 76.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(CardBlack)
            .clickable(onClick = onClick)
            .padding(horizontal = AppSpacing.CardContent, vertical = AppSpacing.ContentVertical),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AppImage(iconOf(card.type), null, Modifier.size(22.dp))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(localizedHealthText(card.title), color = AppColors.Health.CardTitle, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            Spacer(Modifier.height(5.dp))
            Text(
                localizedHealthText(card.summary),
                color = if (card.status == HealthCardStatus.Risk) AppColors.Health.Risk else Muted,
                fontSize = AppTypography.Supporting, maxLines = 2, overflow = TextOverflow.Ellipsis
            )
        }
        Text(stringResource(R.string.common_next), color = AppColors.Health.Chevron, fontSize = 24.sp)
    }
}

@Composable
fun titleOf(type: HealthCardType) = localizedHealthText(LocalizedTextSpec("health_card_${type.resourceName()}_title"))

fun HealthCardType.resourceName() = when (this) {
    HealthCardType.WeeklyPlan -> "weekly_plan"; HealthCardType.TodayActivity -> "today_activity"
    HealthCardType.TrainingLoad -> "training_load"; HealthCardType.TrainingAssessment -> "training_assessment"
    HealthCardType.Recovery -> "recovery"; HealthCardType.RunningAbility -> "running_ability"
    HealthCardType.CyclingAbility -> "cycling_ability"; HealthCardType.HeartRate -> "heart_rate"
    HealthCardType.Stress -> "stress"; HealthCardType.Sleep -> "sleep"
    HealthCardType.HrvAssessment -> "hrv_assessment"; HealthCardType.RestingHeartRate -> "resting_heart_rate"
    HealthCardType.HealthCheck -> "health_check"; HealthCardType.BodyManagement -> "body_management"
}

fun iconOf(type: HealthCardType) = when (type) {
    HealthCardType.WeeklyPlan -> AppImages.Health.WeeklyPlan; HealthCardType.TodayActivity -> AppImages.Health.TodayActivity
    HealthCardType.TrainingLoad -> AppImages.Health.TrainingLoad; HealthCardType.TrainingAssessment -> AppImages.Health.TrainingAssessment
    HealthCardType.Recovery -> AppImages.Health.Recovery; HealthCardType.RunningAbility -> AppImages.Health.RunningAbility
    HealthCardType.CyclingAbility -> AppImages.Health.CyclingAbility; HealthCardType.HeartRate -> AppImages.Health.HeartRate
    HealthCardType.Stress -> AppImages.Health.Stress; HealthCardType.Sleep -> AppImages.Health.Sleep
    HealthCardType.HrvAssessment -> AppImages.Health.HrvAssessment; HealthCardType.RestingHeartRate -> AppImages.Health.RestingHeartRate
    HealthCardType.HealthCheck -> AppImages.Health.HealthCheck; HealthCardType.BodyManagement -> AppImages.Health.BodyManagement
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun DashboardCardPreview() {
    DemoTheme {
        DashboardCard(
            card = HealthCardUiModel(
                type = HealthCardType.WeeklyPlan,
                title = LocalizedTextSpec("health_card_weekly_plan_title"),
                summary = LocalizedTextSpec("health_summary_weekly_empty"),
                status = HealthCardStatus.Empty,
                action = HealthCardAction.ViewWeeklyPlan,
                priority = 1,
                priorityReason = ""
            ),
            onClick = {}
        )
    }
}
