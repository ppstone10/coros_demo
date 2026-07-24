package com.example.demo.health

import androidx.compose.animation.core.Animatable
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.rememberLottieComposition
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.demo.R
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme

private val PageBlack = AppColors.Health.Page

@Composable
fun HeroTopRow(
    dateLabel: String,
    isSyncing: Boolean,
    onClickWatch: () -> Unit,
    onLongPressWatch: () -> Unit
) {
    val composition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.watch_status)
    )
    val progressAnim = remember { Animatable(0f) }

    LaunchedEffect(isSyncing) {
        if (isSyncing) {
            progressAnim.snapTo(0f)
            progressAnim.animateTo(1f, tween(4460, easing = LinearEasing))
            progressAnim.snapTo(0f)
        } else {
            progressAnim.snapTo(0f)
        }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(PageBlack)
            .statusBarsPadding()
            .padding(start = AppSpacing.Page, end = AppSpacing.Page, top = AppSpacing.Medium),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                if (dateLabel.isBlank()) " " else dateLabel,
                color = AppColors.Health.Date, fontSize = AppTypography.Caption
            )
            Text(
                stringResource(R.string.health_today),
                color = AppColors.Core.White, fontSize = AppTypography.HeroTitle, fontWeight = FontWeight.SemiBold
            )
        }
        AppImage(
            asset = AppImages.Health.Calendar,
            contentDescription = stringResource(R.string.health_calendar),
            modifier = Modifier.size(23.dp)
        )
        Spacer(Modifier.width(18.dp))
        Box(
            modifier = Modifier
                .size(30.dp)
                .combinedClickable(
                    onClick = onClickWatch,
                    onLongClick = onLongPressWatch
                )
        ) {
            if (composition != null) {
                LottieAnimation(
                    composition = composition,
                    progress = { progressAnim.value },
                    modifier = Modifier.size(30.dp),
                    contentScale = ContentScale.Fit
                )
            }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000, locale = "zh")
@Composable
private fun HeroTopRowPreview() {
    DemoTheme {
        HeroTopRow(dateLabel = "July 21, 2026", isSyncing = false, onClickWatch = {}, onLongPressWatch = {})
    }
}
