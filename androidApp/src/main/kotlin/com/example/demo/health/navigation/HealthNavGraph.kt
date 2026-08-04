package com.example.demo.health.navigation

import androidx.compose.runtime.LaunchedEffect
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import androidx.navigation.toRoute
import com.example.demo.common.health.HealthEditableSection
import com.example.demo.health.CardEditor
import com.example.demo.health.DetailPlaceholder
import com.example.demo.health.NormalDataEditorOverview
import com.example.demo.health.NormalDataSectionEditor
import com.example.demo.health.viewmodel.HealthDashboardViewModel

/**
 * 健康域二级路由组合：健康详情、卡片编辑、正常数据编辑与模块编辑。
 * 由全局 [com.example.demo.auth.navigation.AuthNavGraph] 挂载，auth 域不再感知健康具体路由。
 */
fun NavGraphBuilder.healthNavGraph(
    navController: NavController,
    viewModel: HealthDashboardViewModel
) {
    composable<HealthDetailRoute> { backStackEntry ->
        val route: HealthDetailRoute = backStackEntry.toRoute()
        val card = viewModel.state.uiState?.cards
            ?.firstOrNull { it.type.name == route.cardType }
        if (card == null) {
            LaunchedEffect(route.cardType) {
                navController.popBackStack()
            }
        } else {
            DetailPlaceholder(card) {
                navController.popBackStack()
            }
        }
    }

    composable<HealthEditorRoute> {
        CardEditor(
            initial = viewModel.state.enabledCardTypes,
            onClose = {
                navController.popBackStack()
            },
            onSave = { types ->
                viewModel.saveCardConfiguration(types)
                navController.popBackStack()
            }
        )
    }

    composable<NormalDataEditorRoute> {
        NormalDataEditorOverview(
            viewModel = viewModel,
            onBack = {
                navController.popBackStack()
            },
            onOpenSection = { section ->
                navController.navigate(NormalDataSectionRoute(section.name))
            }
        )
    }

    composable<NormalDataSectionRoute> { backStackEntry ->
        val route: NormalDataSectionRoute = backStackEntry.toRoute()
        val section = HealthEditableSection.entries.firstOrNull {
            it.name == route.section
        }
        if (section == null) {
            LaunchedEffect(route.section) { navController.popBackStack() }
        } else {
            NormalDataSectionEditor(
                section = section,
                viewModel = viewModel,
                onBack = {
                    navController.popBackStack()
                },
                onSaved = {
                    navController.popBackStack()
                }
            )
        }
    }
}
