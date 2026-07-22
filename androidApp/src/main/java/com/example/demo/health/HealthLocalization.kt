package com.example.demo.health

import android.content.res.Resources
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalResources
import com.example.demo.R
import com.example.demo.common.health.LocalizedTextSpec

@Composable
fun localizedHealthText(spec: LocalizedTextSpec): String =
    LocalResources.current.localizedHealthText(spec)

fun Resources.localizedHealthText(spec: LocalizedTextSpec): String {
    val resourceId = healthStringResource(spec.key)
    return if (spec.arguments.isEmpty()) {
        getString(resourceId)
    } else {
        getString(resourceId, *spec.arguments.toTypedArray())
    }
}

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
    "health_summary_activity_detail" -> R.string.health_summary_activity_detail
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
    "health_visual_activity_easy_run" -> R.string.health_visual_activity_easy_run
    "health_visual_workout_easy_run" -> R.string.health_visual_workout_easy_run
    "health_visual_assessment_efficient" -> R.string.health_visual_assessment_efficient
    "health_visual_assessment_efficient_detail" -> R.string.health_visual_assessment_efficient_detail
    "health_visual_cycling_climber" -> R.string.health_visual_cycling_climber
    "health_visual_activity_tempo_run" -> R.string.health_visual_activity_tempo_run
    "health_visual_assessment_overload" -> R.string.health_visual_assessment_overload
    "health_visual_assessment_overload_detail" -> R.string.health_visual_assessment_overload_detail
    "health_visual_cycling_beginner" -> R.string.health_visual_cycling_beginner
    "health_unit_kilometers" -> R.string.health_unit_kilometers
    "health_visual_activity_pace" -> R.string.health_visual_activity_pace
    "health_visual_training_load_short" -> R.string.health_visual_training_load_short
    "health_unit_minutes_long" -> R.string.health_unit_minutes_long
    "health_visual_recommended_range" -> R.string.health_visual_recommended_range
    "health_visual_short_term_load" -> R.string.health_visual_short_term_load
    "health_visual_long_term_load" -> R.string.health_visual_long_term_load
    "health_visual_load_ratio" -> R.string.health_visual_load_ratio
    "health_unit_percent" -> R.string.health_unit_percent
    "health_visual_recovery_after_hours" -> R.string.health_visual_recovery_after_hours
    "health_visual_marathon_prediction" -> R.string.health_visual_marathon_prediction
    "health_unit_bpm" -> R.string.health_unit_bpm
    "health_visual_average_heart_rate" -> R.string.health_visual_average_heart_rate
    "health_visual_average_stress" -> R.string.health_visual_average_stress
    "health_unit_hours_short" -> R.string.health_unit_hours_short
    "health_unit_minutes_short" -> R.string.health_unit_minutes_short
    "health_unit_milliseconds" -> R.string.health_unit_milliseconds
    "health_visual_hrv_low" -> R.string.health_visual_hrv_low
    "health_visual_hrv_balanced" -> R.string.health_visual_hrv_balanced
    "health_visual_hrv_average" -> R.string.health_visual_hrv_average
    "health_visual_measured_at" -> R.string.health_visual_measured_at
    "health_visual_thirty_day_average" -> R.string.health_visual_thirty_day_average
    "health_visual_heart_rate" -> R.string.health_visual_heart_rate
    "health_visual_hrv" -> R.string.health_visual_hrv
    "health_visual_stress" -> R.string.health_visual_stress
    "health_visual_respiratory_rate" -> R.string.health_visual_respiratory_rate
    "health_unit_per_minute" -> R.string.health_unit_per_minute
    "health_visual_blood_oxygen" -> R.string.health_visual_blood_oxygen
    "health_unit_kilograms" -> R.string.health_unit_kilograms
    "health_visual_weight" -> R.string.health_visual_weight
    "health_visual_measured_date" -> R.string.health_visual_measured_date
    "health_visual_muscle_chest" -> R.string.health_visual_muscle_chest
    "health_visual_muscle_quadriceps" -> R.string.health_visual_muscle_quadriceps
    "health_visual_day_mon" -> R.string.health_visual_day_mon
    "health_visual_day_tue" -> R.string.health_visual_day_tue
    "health_visual_day_wed" -> R.string.health_visual_day_wed
    "health_visual_day_thu" -> R.string.health_visual_day_thu
    "health_visual_day_fri" -> R.string.health_visual_day_fri
    "health_visual_day_sat" -> R.string.health_visual_day_sat
    "health_visual_day_sun" -> R.string.health_visual_day_sun
    else -> R.string.health_data_unavailable
}
