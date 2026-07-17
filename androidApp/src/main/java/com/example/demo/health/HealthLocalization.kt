package com.example.demo.health

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.common.health.LocalizedTextSpec

@Composable
fun localizedHealthText(spec: LocalizedTextSpec): String =
    stringResource(healthStringResource(spec.key), *spec.arguments.toTypedArray())

@StringRes
private fun healthStringResource(key: String): Int = when (key) {
    "health_today" -> R.string.health_today
    "health_demo_date" -> R.string.health_demo_date
    "health_card_weekly_plan_title" -> R.string.health_card_weekly_plan_title
    "health_card_today_activity_title" -> R.string.health_card_today_activity_title
    "health_card_training_load_title" -> R.string.health_card_training_load_title
    "health_card_training_assessment_title" -> R.string.health_card_training_assessment_title
    "health_card_recovery_title" -> R.string.health_card_recovery_title
    "health_card_running_ability_title" -> R.string.health_card_running_ability_title
    "health_card_cycling_ability_title" -> R.string.health_card_cycling_ability_title
    "health_card_heart_rate_title" -> R.string.health_card_heart_rate_title
    "health_card_stress_title" -> R.string.health_card_stress_title
    "health_card_sleep_title" -> R.string.health_card_sleep_title
    "health_card_hrv_assessment_title" -> R.string.health_card_hrv_assessment_title
    "health_card_resting_heart_rate_title" -> R.string.health_card_resting_heart_rate_title
    "health_card_health_check_title" -> R.string.health_card_health_check_title
    "health_card_body_management_title" -> R.string.health_card_body_management_title
    "health_summary_weekly_empty" -> R.string.health_summary_weekly_empty
    "health_summary_weekly_ready" -> R.string.health_summary_weekly_ready
    "health_summary_weekly_custom" -> R.string.health_summary_weekly_custom
    "health_summary_recovery_empty" -> R.string.health_summary_recovery_empty
    "health_summary_recovery_risk" -> R.string.health_summary_recovery_risk
    "health_summary_recovery_normal" -> R.string.health_summary_recovery_normal
    "health_summary_sleep_empty" -> R.string.health_summary_sleep_empty
    "health_summary_sleep_risk" -> R.string.health_summary_sleep_risk
    "health_summary_sleep_normal" -> R.string.health_summary_sleep_normal
    "health_summary_activity_empty" -> R.string.health_summary_activity_empty
    "health_summary_activity_normal" -> R.string.health_summary_activity_normal
    "health_summary_training_load_empty" -> R.string.health_summary_training_load_empty
    "health_summary_training_load_risk" -> R.string.health_summary_training_load_risk
    "health_summary_training_load_normal" -> R.string.health_summary_training_load_normal
    "health_summary_training_assessment_empty" -> R.string.health_summary_training_assessment_empty
    "health_summary_training_assessment_risk" -> R.string.health_summary_training_assessment_risk
    "health_summary_training_assessment_normal" -> R.string.health_summary_training_assessment_normal
    "health_summary_running_empty" -> R.string.health_summary_running_empty
    "health_summary_running_risk" -> R.string.health_summary_running_risk
    "health_summary_running_normal" -> R.string.health_summary_running_normal
    "health_summary_cycling_empty" -> R.string.health_summary_cycling_empty
    "health_summary_cycling_risk" -> R.string.health_summary_cycling_risk
    "health_summary_cycling_normal" -> R.string.health_summary_cycling_normal
    "health_summary_heart_rate_empty" -> R.string.health_summary_heart_rate_empty
    "health_summary_heart_rate_risk" -> R.string.health_summary_heart_rate_risk
    "health_summary_heart_rate_normal" -> R.string.health_summary_heart_rate_normal
    "health_summary_stress_empty" -> R.string.health_summary_stress_empty
    "health_summary_stress_risk" -> R.string.health_summary_stress_risk
    "health_summary_stress_normal" -> R.string.health_summary_stress_normal
    "health_summary_hrv_empty" -> R.string.health_summary_hrv_empty
    "health_summary_hrv_risk" -> R.string.health_summary_hrv_risk
    "health_summary_hrv_normal" -> R.string.health_summary_hrv_normal
    "health_summary_resting_hr_empty" -> R.string.health_summary_resting_hr_empty
    "health_summary_resting_hr_risk" -> R.string.health_summary_resting_hr_risk
    "health_summary_resting_hr_normal" -> R.string.health_summary_resting_hr_normal
    "health_summary_health_check_empty" -> R.string.health_summary_health_check_empty
    "health_summary_health_check_risk" -> R.string.health_summary_health_check_risk
    "health_summary_health_check_normal" -> R.string.health_summary_health_check_normal
    "health_summary_body_empty" -> R.string.health_summary_body_empty
    "health_summary_body_risk" -> R.string.health_summary_body_risk
    "health_summary_body_normal" -> R.string.health_summary_body_normal
    else -> R.string.health_data_unavailable
}
