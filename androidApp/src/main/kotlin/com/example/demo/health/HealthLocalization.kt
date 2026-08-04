package com.example.demo.health

import android.content.res.Resources
import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalResources
import com.example.demo.R
import com.example.demo.common.health.model.LocalizedTextSpec

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
    "health_visual_weekly_rest_day" -> R.string.health_visual_weekly_rest_day
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
    "health_visual_hrv_very_low" -> R.string.health_visual_hrv_very_low
    "health_visual_hrv_low" -> R.string.health_visual_hrv_low
    "health_visual_hrv_normal" -> R.string.health_visual_hrv_normal
    "health_visual_hrv_high" -> R.string.health_visual_hrv_high
    "health_visual_hrv_balanced" -> R.string.health_visual_hrv_balanced
    "health_visual_hrv_average" -> R.string.health_visual_hrv_average
    "health_visual_normal_range_short" -> R.string.health_visual_normal_range_short
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
    "health_visual_weekly_primary_muscles" -> R.string.health_visual_weekly_primary_muscles
    "health_visual_measured_date" -> R.string.health_visual_measured_date
    "health_visual_muscle_chest" -> R.string.health_visual_muscle_chest
    "health_visual_muscle_shoulders" -> R.string.health_visual_muscle_shoulders
    "health_visual_muscle_back" -> R.string.health_visual_muscle_back
    "health_visual_muscle_biceps" -> R.string.health_visual_muscle_biceps
    "health_visual_muscle_triceps" -> R.string.health_visual_muscle_triceps
    "health_visual_muscle_abdominals" -> R.string.health_visual_muscle_abdominals
    "health_visual_muscle_glutes" -> R.string.health_visual_muscle_glutes
    "health_visual_muscle_quadriceps" -> R.string.health_visual_muscle_quadriceps
    "health_visual_muscle_hamstrings" -> R.string.health_visual_muscle_hamstrings
    "health_visual_muscle_calves" -> R.string.health_visual_muscle_calves
    "health_visual_no_muscles" -> R.string.health_visual_no_muscles
    "health_visual_day_mon" -> R.string.health_visual_day_mon
    "health_visual_day_tue" -> R.string.health_visual_day_tue
    "health_visual_day_wed" -> R.string.health_visual_day_wed
    "health_visual_day_thu" -> R.string.health_visual_day_thu
    "health_visual_day_fri" -> R.string.health_visual_day_fri
    "health_visual_day_sat" -> R.string.health_visual_day_sat
    "health_visual_day_sun" -> R.string.health_visual_day_sun
    "health_edit_active_minutes" -> R.string.health_edit_active_minutes
    "health_edit_average_heart_rate" -> R.string.health_edit_average_heart_rate
    "health_edit_average_hrv" -> R.string.health_edit_average_hrv
    "health_edit_average_stress" -> R.string.health_edit_average_stress
    "health_edit_blood_oxygen" -> R.string.health_edit_blood_oxygen
    "health_edit_cards" -> R.string.health_edit_cards
    "health_edit_calories" -> R.string.health_edit_calories
    "health_edit_cycling_score" -> R.string.health_edit_cycling_score
    "health_edit_daily_load" -> R.string.health_edit_daily_load
    "health_edit_day_distance" -> R.string.health_edit_day_distance
    "health_edit_day_type" -> R.string.health_edit_day_type
    "health_edit_defaults_refresh" -> R.string.health_edit_defaults_refresh
    "health_edit_distance" -> R.string.health_edit_distance
    "health_edit_heart_pattern" -> R.string.health_edit_heart_pattern
    "health_edit_heart_pattern_high" -> R.string.health_edit_heart_pattern_high
    "health_edit_heart_pattern_low" -> R.string.health_edit_heart_pattern_low
    "health_edit_heart_pattern_normal" -> R.string.health_edit_heart_pattern_normal
    "health_edit_heart_rate" -> R.string.health_edit_heart_rate
    "health_edit_hrv" -> R.string.health_edit_hrv
    "health_edit_invalid" -> R.string.health_edit_invalid
    "health_edit_source_partial" -> R.string.health_edit_source_partial
    "health_edit_source_empty" -> R.string.health_edit_source_empty
    "health_edit_source_corrupted" -> R.string.health_edit_source_corrupted
    "health_edit_error_required" -> R.string.health_edit_error_required
    "health_edit_error_number" -> R.string.health_edit_error_number
    "health_edit_error_range" -> R.string.health_edit_error_range
    "health_edit_error_choice" -> R.string.health_edit_error_choice
    "health_edit_error_count" -> R.string.health_edit_error_count
    "health_edit_error_inconsistent" -> R.string.health_edit_error_inconsistent
    "health_edit_long_load" -> R.string.health_edit_long_load
    "health_edit_measured_time" -> R.string.health_edit_measured_time
    "health_edit_muscle_groups" -> R.string.health_edit_muscle_groups
    "health_edit_day_type_numbered" -> R.string.health_edit_day_type_numbered
    "health_edit_day_distance_numbered" -> R.string.health_edit_day_distance_numbered
    "health_edit_daily_load_numbered" -> R.string.health_edit_daily_load_numbered
    "health_edit_sleep_stage_numbered" -> R.string.health_edit_sleep_stage_numbered
    "health_edit_stage_duration_numbered" -> R.string.health_edit_stage_duration_numbered
    "health_edit_muscle_group_numbered" -> R.string.health_edit_muscle_group_numbered
    "health_edit_sleep_stage_item" -> R.string.health_edit_sleep_stage_item
    "health_edit_muscle_group_item" -> R.string.health_edit_muscle_group_item
    "health_edit_add_sleep_stage" -> R.string.health_edit_add_sleep_stage
    "health_edit_add_muscle_group" -> R.string.health_edit_add_muscle_group
    "health_edit_remove_item" -> R.string.health_edit_remove_item
    "health_edit_normal_data" -> R.string.health_edit_normal_data
    "health_edit_pace_seconds" -> R.string.health_edit_pace_seconds
    "health_edit_recovery_score" -> R.string.health_edit_recovery_score
    "health_edit_respiratory_rate" -> R.string.health_edit_respiratory_rate
    "health_edit_restore_card" -> R.string.health_edit_restore_card
    "health_edit_resting_heart_rate" -> R.string.health_edit_resting_heart_rate
    "health_edit_running_score" -> R.string.health_edit_running_score
    "health_edit_saved_refresh" -> R.string.health_edit_saved_refresh
    "health_edit_select_hint" -> R.string.health_edit_select_hint
    "health_edit_short_load" -> R.string.health_edit_short_load
    "health_edit_sleep_stage" -> R.string.health_edit_sleep_stage
    "health_edit_sleep_stage_awake" -> R.string.health_edit_sleep_stage_awake
    "health_edit_sleep_stage_deep" -> R.string.health_edit_sleep_stage_deep
    "health_edit_sleep_stage_light" -> R.string.health_edit_sleep_stage_light
    "health_edit_sleep_stage_rem" -> R.string.health_edit_sleep_stage_rem
    "health_edit_sleep_start" -> R.string.health_edit_sleep_start
    "health_edit_stage_duration" -> R.string.health_edit_stage_duration
    "health_edit_steps" -> R.string.health_edit_steps
    "health_edit_stress" -> R.string.health_edit_stress
    "health_edit_stress_pattern" -> R.string.health_edit_stress_pattern
    "health_edit_stress_pattern_high" -> R.string.health_edit_stress_pattern_high
    "health_edit_stress_pattern_normal" -> R.string.health_edit_stress_pattern_normal
    "health_edit_thirty_day_average" -> R.string.health_edit_thirty_day_average
    "health_edit_title_bodyManagement" -> R.string.health_edit_title_bodyManagement
    "health_edit_title_cyclingAbility" -> R.string.health_edit_title_cyclingAbility
    "health_edit_title_dailySummary" -> R.string.health_edit_title_dailySummary
    "health_edit_title_healthCheck" -> R.string.health_edit_title_healthCheck
    "health_edit_title_heartRate" -> R.string.health_edit_title_heartRate
    "health_edit_title_hrvAssessment" -> R.string.health_edit_title_hrvAssessment
    "health_edit_title_recovery" -> R.string.health_edit_title_recovery
    "health_edit_title_restingHeartRate" -> R.string.health_edit_title_restingHeartRate
    "health_edit_title_runningAbility" -> R.string.health_edit_title_runningAbility
    "health_edit_title_sleep" -> R.string.health_edit_title_sleep
    "health_edit_title_stress" -> R.string.health_edit_title_stress
    "health_edit_title_todayActivity" -> R.string.health_edit_title_todayActivity
    "health_edit_title_trainingAssessment" -> R.string.health_edit_title_trainingAssessment
    "health_edit_title_trainingLoad" -> R.string.health_edit_title_trainingLoad
    "health_edit_title_weeklyPlan" -> R.string.health_edit_title_weeklyPlan
    "health_edit_use_defaults" -> R.string.health_edit_use_defaults
    "health_edit_weight" -> R.string.health_edit_weight
    "health_edit_workout_easy" -> R.string.health_edit_workout_easy
    "health_edit_workout_endurance" -> R.string.health_edit_workout_endurance
    "health_edit_workout_rest" -> R.string.health_edit_workout_rest
    "health_edit_workout_tempo" -> R.string.health_edit_workout_tempo
    "health_visual_activity_endurance_run" -> R.string.health_visual_activity_endurance_run
    "health_visual_assessment_low" -> R.string.health_visual_assessment_low
    "health_visual_assessment_low_detail" -> R.string.health_visual_assessment_low_detail
    "health_visual_assessment_maintaining" -> R.string.health_visual_assessment_maintaining
    "health_visual_assessment_maintaining_detail" -> R.string.health_visual_assessment_maintaining_detail
    "health_visual_cycling_endurance" -> R.string.health_visual_cycling_endurance
    "health_visual_cycling_power" -> R.string.health_visual_cycling_power
    "health_visual_workout_rest" -> R.string.health_visual_workout_rest
    "health_scenario_normal" -> R.string.health_scenario_normal
    "health_scenario_partial_missing" -> R.string.health_scenario_partial_missing
    "health_scenario_all_empty" -> R.string.health_scenario_all_empty
    "health_scenario_abnormal" -> R.string.health_scenario_abnormal
    "health_scenario_read_failure" -> R.string.health_scenario_read_failure
    else -> R.string.health_data_unavailable
}
