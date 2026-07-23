package com.example.demo.ui.resources

import androidx.annotation.DrawableRes
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import com.example.demo.R

@JvmInline
value class AppImageAsset internal constructor(@param:DrawableRes val resourceId: Int)

data class SelectableImageAssets(
    val normal: AppImageAsset,
    val selected: AppImageAsset
)

object AppImages {
    object Auth {
        val Logo = AppImageAsset(R.drawable.logo_coros)
        val ClearInput = AppImageAsset(R.drawable.icon_delete)
        val PasswordHidden = AppImageAsset(R.drawable.icon_uneye)
    }

    object Profile {
        val Camera = AppImageAsset(R.drawable.icon_camera)
        val Next = AppImageAsset(R.drawable.right_more)
        val Female = AppImageAsset(R.drawable.icon_female)
        val Male = AppImageAsset(R.drawable.icon_male)
        val Close = AppImageAsset(R.drawable.ic_profile_close)
        val Confirm = AppImageAsset(R.drawable.ic_profile_check)
        val Edit = AppImageAsset(R.drawable.icon_edit)
    }

    object Health {
        val Calendar = AppImageAsset(R.drawable.icon_calendar)
        val Device = AppImageAsset(R.drawable.icon_device_sportting)
        val Steps = AppImageAsset(R.drawable.steps_icon)
        val Calories = AppImageAsset(R.drawable.icon_calories)
        val ActiveDuration = AppImageAsset(R.drawable.sport_time_icon)
        val EditorAdd = AppImageAsset(R.drawable.data_screen_edit_add)
        val EditorRemove = AppImageAsset(R.drawable.delete)
        val ActivityMap = AppImageAsset(R.drawable.health_activity_map)
        val TodayHeader = AppImageAsset(R.drawable.health_today_header)
        val TodayRunner = AppImageAsset(R.drawable.health_today_runner)
        val BodyFront = AppImageAsset(R.drawable.health_body_front)
        val BodyBack = AppImageAsset(R.drawable.health_body_back)
        val RecoveryStatus = AppImageAsset(R.drawable.health_recovery_status)

        val WeeklyPlan = AppImageAsset(R.drawable.icon_small_plan)
        val TodayActivity = AppImageAsset(R.drawable.icon_small_training_effect)
        val TrainingLoad = AppImageAsset(R.drawable.icon_small_training_load)
        val TrainingAssessment = AppImageAsset(R.drawable.icon_small_training_effect)
        val Recovery = AppImageAsset(R.drawable.icon_recovery_sports)
        val RunningAbility = AppImageAsset(R.drawable.icon_small_running_ability)
        val CyclingAbility = AppImageAsset(R.drawable.icon_small_cycling)
        val HeartRate = AppImageAsset(R.drawable.icon_small_heart_rate)
        val Stress = AppImageAsset(R.drawable.icon_small_stress)
        val Sleep = AppImageAsset(R.drawable.icon_small_sleep)
        val HrvAssessment = AppImageAsset(R.drawable.icon_small_sleep_hrv)
        val RestingHeartRate = AppImageAsset(R.drawable.icon_small_rhr)
        val HealthCheck = AppImageAsset(R.drawable.icon_small_health_detection)
        val BodyManagement = AppImageAsset(R.drawable.icon_small_body)
    }

    object Navigation {
        val Fitness = SelectableImageAssets(
            normal = AppImageAsset(R.drawable.icon_tab_home),
            selected = AppImageAsset(R.drawable.icon_tab_home_selected)
        )
        val Records = SelectableImageAssets(
            normal = AppImageAsset(R.drawable.icon_tab_workout_list),
            selected = AppImageAsset(R.drawable.icon_tab_workout_list_selected)
        )
        val Explore = SelectableImageAssets(
            normal = AppImageAsset(R.drawable.icon_tab_explore),
            selected = AppImageAsset(R.drawable.icon_tab_explore_selected)
        )
        val Me = SelectableImageAssets(
            normal = AppImageAsset(R.drawable.icon_tab_me),
            selected = AppImageAsset(R.drawable.icon_tab_me_selected)
        )
    }
}

@Composable
fun AppImage(
    asset: AppImageAsset,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Fit,
    colorFilter: ColorFilter? = null
) {
    Image(
        painter = painterResource(asset.resourceId),
        contentDescription = contentDescription,
        modifier = modifier,
        contentScale = contentScale,
        colorFilter = colorFilter
    )
}
