package com.example.demo.health

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.HealthCardVisualData
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImageAsset
import com.example.demo.core.resources.AppImages
import androidx.compose.ui.res.stringResource
import com.example.demo.R

@Composable
fun BodyVisual(v: HealthCardVisualData, onWeightClick: () -> Unit) {
    val frontRegions = v.highlightedBodyRegions.filter { it.endsWith("_front") }
    val backRegions = v.highlightedBodyRegions.filter { it.endsWith("_back") }
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
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable(onClick = onWeightClick)
                ) {
                    ValueText(v.primaryValue, 32)
                    UnitText(v.primaryUnit, 20)
                    Spacer(Modifier.width(6.dp))
                    AppImage(
                        AppImages.Profile.Edit,
                        stringResource(R.string.profile_edit_username),
                        Modifier.size(16.dp)
                    )
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
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    modifier = Modifier.width(108.dp).height(108.dp)
                ) {
                    BodyFigure(AppImages.Health.BodyMaleFrontBase, frontRegions)
                    BodyFigure(AppImages.Health.BodyMaleBackBase, backRegions)
                }
                v.footer?.let {
                    Text(
                        localizedHealthText(it),
                        color = AppColors.Health.Muted,
                        fontSize = 9.sp,
                        maxLines = 1
                    )
                }
            }
        },
    )
}

@Composable
private fun BodyFigure(base: AppImageAsset, regions: List<String>) {
    Box(Modifier.width(52.dp).height(108.dp)) {
        AppImage(base, null, Modifier.fillMaxSize())
        regions.forEach { region ->
            AppImages.Health.BodyMuscleRegions[region]?.let { asset ->
                BodyRegionLayer(asset)
            }
        }
    }
}

@Composable
private fun BodyRegionLayer(asset: AppImageAsset) {
    AppImage(
        asset = asset,
        contentDescription = null,
        modifier = Modifier.fillMaxSize(),
        colorFilter = ColorFilter.tint(AppColors.Health.Action)
    )
}

@Preview(name = "Body management visual", showBackground = true, backgroundColor = 0xFF171719)
@Composable
private fun BodyVisualPreview() {
    PreviewVisualSurface {
        BodyVisual(previewHealthVisual(com.example.demo.common.health.HealthCardType.BodyManagement), onWeightClick = {})
    }
}
