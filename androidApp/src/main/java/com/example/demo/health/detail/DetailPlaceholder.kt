package com.example.demo.health

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
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
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme

private val PageBlack = AppColors.Health.Page

@Composable
fun DetailPlaceholder(card: HealthCardUiModel, onBack: () -> Unit) {
    val title = localizedHealthText(card.title)
    Column(Modifier.fillMaxSize().background(PageBlack).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().height(64.dp).padding(horizontal = AppSpacing.Large), verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.common_back), color = AppColors.Core.White, fontSize = 38.sp, modifier = Modifier.clickable(onClick = onBack))
            Text(title, color = AppColors.Core.White, fontSize = AppTypography.SectionTitle, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
            Spacer(Modifier.width(28.dp))
        }
        Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
            AppImage(iconOf(card.type), null, Modifier.size(56.dp)); Spacer(Modifier.height(20.dp))
            Text(stringResource(R.string.health_pending_feature, title), color = AppColors.Health.Placeholder, fontSize = AppTypography.CardTitle)
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun DetailPlaceholderPreview() {
    DemoTheme {
        DetailPlaceholder(
            card = HealthCardUiModel(
                type = HealthCardType.WeeklyPlan,
                title = LocalizedTextSpec("health_card_weekly_plan_title"),
                summary = LocalizedTextSpec("health_summary_weekly_empty"),
                status = HealthCardStatus.Empty,
                action = HealthCardAction.ViewWeeklyPlan,
                priority = 1,
                priorityReason = ""
            ),
            onBack = {}
        )
    }
}
