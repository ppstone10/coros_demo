package com.example.demo.home

import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.health.HealthDashboardScreen
import com.example.demo.health.HealthDashboardViewModel
import com.example.demo.login.LoginViewModel
import com.example.demo.login.signedin.SignedInScreen
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.SelectableImageAssets

private enum class HomeTab(
    @param:StringRes val labelRes: Int,
    val icons: SelectableImageAssets
) {
    Fitness(R.string.nav_fitness, AppImages.Navigation.Fitness),
    Records(R.string.nav_records, AppImages.Navigation.Records),
    Explore(R.string.nav_explore, AppImages.Navigation.Explore),
    Me(R.string.nav_me, AppImages.Navigation.Me)
}

@Composable
fun MainTabsScreen(viewModel: LoginViewModel) {
    var tab by rememberSaveable { mutableStateOf(HomeTab.Fitness) }
    var contentFullscreen by rememberSaveable { mutableStateOf(false) }
    val healthViewModel = remember(viewModel) {
        HealthDashboardViewModel(viewModel.healthStore)
    }
    Column(Modifier.fillMaxSize().background(AppColors.Core.Black)) {
        Box(Modifier.weight(1f)) {
            when (tab) {
                HomeTab.Fitness -> HealthDashboardScreen(
                    healthViewModel = healthViewModel,
                    onWatchClick = {
                        contentFullscreen = false
                        tab = HomeTab.Me
                    },
                    onFullscreenChange = { contentFullscreen = it }
                )
                HomeTab.Me -> SignedInScreen(
                    viewModel,
                    onBack = {},
                    onLogout = {},
                    onAccountDeleted = {},
                    onFullscreenChange = { contentFullscreen = it }
                )
                HomeTab.Records -> RecordsPlaceholderScreen()
                HomeTab.Explore -> ExplorePlaceholderScreen()
            }
        }
        if (!contentFullscreen) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(AppColors.Navigation.Bar)
                    .navigationBarsPadding()
                    .padding(top = 7.dp, bottom = 5.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                HomeTab.entries.forEach { item ->
                    val selected = tab == item
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .clickable { tab = item },
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        AppImage(
                            asset = if (selected) item.icons.selected else item.icons.normal,
                            contentDescription = stringResource(item.labelRes),
                            modifier = Modifier.size(27.dp)
                        )
                        Text(
                            text = stringResource(item.labelRes),
                            color = if (selected) AppColors.Core.White else AppColors.Navigation.Unselected,
                            fontSize = 11.sp,
                            fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal
                        )
                    }
                }
            }
        }
    }
}
