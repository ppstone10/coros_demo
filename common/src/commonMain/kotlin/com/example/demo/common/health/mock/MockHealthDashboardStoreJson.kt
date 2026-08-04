package com.example.demo.common.health.mock
import com.example.demo.common.health.model.BodyManagement
import com.example.demo.common.health.model.BodyManagementInput
import com.example.demo.common.health.model.CyclingAbility
import com.example.demo.common.health.model.CyclingAbilityInput
import com.example.demo.common.health.model.DailySummary
import com.example.demo.common.health.model.DailySummaryInput
import com.example.demo.common.health.model.EditableHealthData
import com.example.demo.common.health.model.HealthCardType
import com.example.demo.common.health.model.HealthCheck
import com.example.demo.common.health.model.HealthCheckInput
import com.example.demo.common.health.model.HealthDashboardData
import com.example.demo.common.health.model.HealthDashboardSnapshot
import com.example.demo.common.health.model.HeartRate
import com.example.demo.common.health.model.HeartRateInput
import com.example.demo.common.health.model.HeartRateInterval
import com.example.demo.common.health.model.HrvAssessment
import com.example.demo.common.health.model.HrvAssessmentInput
import com.example.demo.common.health.model.LocalizedTextSpec
import com.example.demo.common.health.model.Recovery
import com.example.demo.common.health.model.RecoveryInput
import com.example.demo.common.health.model.RestingHeartRate
import com.example.demo.common.health.model.RestingHeartRateInput
import com.example.demo.common.health.model.RunningAbility
import com.example.demo.common.health.model.RunningAbilityInput
import com.example.demo.common.health.model.SleepInput
import com.example.demo.common.health.model.SleepStage
import com.example.demo.common.health.model.SleepStageInput
import com.example.demo.common.health.model.SleepStageSegment
import com.example.demo.common.health.model.SleepSummary
import com.example.demo.common.health.model.Stress
import com.example.demo.common.health.model.StressInput
import com.example.demo.common.health.model.TodayActivity
import com.example.demo.common.health.model.TodayActivityInput
import com.example.demo.common.health.model.TrainingAssessment
import com.example.demo.common.health.model.TrainingAssessmentInput
import com.example.demo.common.health.model.TrainingLoad
import com.example.demo.common.health.model.TrainingLoadInput
import com.example.demo.common.health.model.WeeklyDayPlan
import com.example.demo.common.health.model.WeeklyPlan
import com.example.demo.common.health.model.WeeklyPlanInput
import com.example.demo.common.health.model.WeeklyWorkoutInput
import com.example.demo.common.health.model.WorkoutType
import com.example.demo.common.health.model.healthScenarioFromPersistedCode
import com.example.demo.common.health.rules.HealthEditableRules
import com.example.demo.common.health.model.toProtoCode
import com.example.demo.common.health.model.CurrentHealthDashboardSchemaVersion
import com.example.demo.common.health.model.DefaultHealthCardOrder

/** common 中唯一的健康快照 JSON 编解码入口；字段名遵循 protobuf JSON lowerCamelCase。 */
object MockHealthDashboardStoreJson {
    fun encode(snapshot: HealthDashboardSnapshot): String = snapshot.toJson().toString()

    fun decode(json: String): HealthDashboardSnapshot = parseJson(json).asObject().toSnapshot()

    fun encodeCollection(snapshots: List<HealthDashboardSnapshot>): String = buildJsonObject {
        put("snapshots", buildJsonArray { snapshots.forEach { add(it.toJson()) } })
    }.toString()

    fun decodeCollection(json: String): List<HealthDashboardSnapshot> {
        val root = parseJson(json).asObject()
        val snapshots = root["snapshots"] as? JsonArray ?: error("Missing snapshots array")
        return snapshots.map { it.asObject().toSnapshot() }
    }

    fun encodeEditable(data: EditableHealthData): String = data.toJson().toString()

    fun decodeEditable(json: String): EditableHealthData =
        parseJson(json).asObject().toEditableHealthData()

    private fun HealthDashboardSnapshot.toJson() = buildJsonObject {
        put("userId", userId)
        put("scenario", sourceScenario.toProtoCode().name)
        put("enabledCardTypes", strings(enabledCardTypes.map { it.name }))
        editableData?.let { put("editableData", it.toJson()) }
        if (editableData == null) dashboardData?.let { put("dashboardData", it.toJson()) }
        put("schemaVersion", schemaVersion)
    }

    private fun JsonObject.toSnapshot(): HealthDashboardSnapshot {
        val userId = string("userId", "user_id") ?: error("Missing userId")
        val sourceScenario = healthScenarioFromPersistedCode(
            string("scenario", "legacyScenario", "legacy_scenario")
        )
        val enabled = array("enabledCardTypes", "enabled_card_types")
            .mapNotNull { it.asPrimitive().contentOrNull }
            .mapNotNull { name -> HealthCardType.entries.firstOrNull { it.name == name } }
            .ifEmpty { DefaultHealthCardOrder }
        val data = obj("dashboardData", "dashboard_data")?.toDashboardData()
        val editableData = obj("editableData", "editable_data")?.toEditableHealthData()
        return HealthDashboardSnapshot(
            userId = userId,
            sourceScenario = sourceScenario,
            enabledCardTypes = enabled,
            dashboardData = data,
            editableData = editableData,
            schemaVersion = int("schemaVersion", "schema_version")
                ?: if (data == null && editableData == null) 1 else CurrentHealthDashboardSchemaVersion
        )
    }

    private fun EditableHealthData.toJson() = buildJsonObject {
        put("dailySummary", buildJsonObject {
            put("steps", dailySummary.steps)
            put("calories", dailySummary.calories)
            put("activeMinutes", dailySummary.activeMinutes)
        })
        put("todayActivity", buildJsonObject {
            put("distanceKm", todayActivity.distanceKm)
            put("paceSecondsPerKm", todayActivity.paceSecondsPerKm)
        })
        put("weeklyPlan", buildJsonObject {
            put("days", buildJsonArray {
                weeklyPlan.days.forEach { day ->
                    add(buildJsonObject {
                        put("type", day.type.name)
                        put("distanceKm", day.distanceKm)
                    })
                }
            })
        })
        put("trainingLoad", buildJsonObject {
            put("dailyLoads", ints(trainingLoad.dailyLoads))
        })
        put("assessment", buildJsonObject {
            put("shortTermLoad", assessment.shortTermLoad)
            put("longTermLoad", assessment.longTermLoad)
        })
        put("recovery", buildJsonObject { put("score", recovery.score) })
        put("runningAbility", buildJsonObject { put("score", runningAbility.score) })
        put("cyclingAbility", buildJsonObject { put("score", cyclingAbility.score) })
        put("heartRate", buildJsonObject {
            put("fiveMinuteSamples", ints(heartRate.fiveMinuteSamples))
        })
        put("stress", buildJsonObject {
            put("halfHourSamples", ints(stress.halfHourSamples))
        })
        put("sleep", buildJsonObject {
            put("startMinuteOfDay", sleep.startMinuteOfDay)
            put("stages", buildJsonArray {
                sleep.stages.forEach { stage ->
                    add(buildJsonObject {
                        put("stage", stage.stage.name)
                        put("startMinute", stage.startMinute)
                        put("durationMinutes", stage.durationMinutes)
                    })
                }
            })
        })
        put("hrvAssessment", buildJsonObject { put("averageMs", hrvAssessment.averageMs) })
        put("restingHeartRate", buildJsonObject {
            put("value", restingHeartRate.value)
            put("measuredTime", restingHeartRate.measuredTime)
            put("thirtyDayAverage", restingHeartRate.thirtyDayAverage)
        })
        put("healthCheck", buildJsonObject {
            put("heartRate", healthCheck.heartRate)
            put("hrvMs", healthCheck.hrvMs)
            put("stress", healthCheck.stress)
            put("respiratoryRate", healthCheck.respiratoryRate)
            put("bloodOxygen", healthCheck.bloodOxygen)
            put("measuredTime", healthCheck.measuredTime)
        })
        put("bodyManagement", buildJsonObject {
            put("weightKg", bodyManagement.weightKg)
            put("trainedMuscleGroups", strings(bodyManagement.trainedMuscleGroups))
            put("weightHistoryKg", doubles(bodyManagement.weightHistoryKg))
        })
    }

    private fun JsonObject.toEditableHealthData(): EditableHealthData {
        val daily = obj("dailySummary", "daily_summary") ?: error("Missing editable dailySummary")
        val activity = obj("todayActivity", "today_activity") ?: error("Missing editable todayActivity")
        val weekly = obj("weeklyPlan", "weekly_plan") ?: error("Missing editable weeklyPlan")
        val load = obj("trainingLoad", "training_load") ?: error("Missing editable trainingLoad")
        val assessment = obj("assessment") ?: error("Missing editable assessment")
        val recovery = obj("recovery") ?: error("Missing editable recovery")
        val running = obj("runningAbility", "running_ability") ?: error("Missing editable runningAbility")
        val cycling = obj("cyclingAbility", "cycling_ability") ?: error("Missing editable cyclingAbility")
        val heart = obj("heartRate", "heart_rate") ?: error("Missing editable heartRate")
        val stressObject = obj("stress") ?: error("Missing editable stress")
        val sleepObject = obj("sleep") ?: error("Missing editable sleep")
        val hrv = obj("hrvAssessment", "hrv_assessment") ?: error("Missing editable hrvAssessment")
        val resting = obj("restingHeartRate", "resting_heart_rate")
            ?: error("Missing editable restingHeartRate")
        val check = obj("healthCheck", "health_check") ?: error("Missing editable healthCheck")
        val body = obj("bodyManagement", "body_management") ?: error("Missing editable bodyManagement")
        return EditableHealthData(
            dailySummary = DailySummaryInput(
                daily.int("steps") ?: error("Missing steps"),
                daily.int("calories") ?: error("Missing calories"),
                daily.int("activeMinutes", "active_minutes") ?: error("Missing activeMinutes")
            ),
            todayActivity = TodayActivityInput(
                activity.double("distanceKm", "distance_km") ?: error("Missing distanceKm"),
                activity.int("paceSecondsPerKm", "pace_seconds_per_km")
                    ?: error("Missing paceSecondsPerKm")
            ),
            weeklyPlan = WeeklyPlanInput(
                weekly.array("days").map { item ->
                    val day = item.asObject()
                    WeeklyWorkoutInput(
                        day.string("type")?.let { name ->
                            WorkoutType.entries.firstOrNull { it.name == name }
                        } ?: error("Invalid workout type"),
                        day.double("distanceKm", "distance_km") ?: error("Missing workout distance")
                    )
                }
            ),
            trainingLoad = TrainingLoadInput(load.intList("dailyLoads", "daily_loads")),
            assessment = TrainingAssessmentInput(
                assessment.int("shortTermLoad", "short_term_load") ?: error("Missing shortTermLoad"),
                assessment.int("longTermLoad", "long_term_load") ?: error("Missing longTermLoad")
            ),
            recovery = RecoveryInput(recovery.int("score") ?: error("Missing recovery score")),
            runningAbility = RunningAbilityInput(
                running.int("score") ?: error("Missing running score")
            ),
            cyclingAbility = CyclingAbilityInput(
                cycling.int("score") ?: error("Missing cycling score")
            ),
            heartRate = HeartRateInput(
                heart.intList("fiveMinuteSamples", "five_minute_samples")
            ),
            stress = StressInput(
                stressObject.intList("halfHourSamples", "half_hour_samples")
            ),
            sleep = SleepInput(
                startMinuteOfDay = sleepObject.int("startMinuteOfDay", "start_minute_of_day")
                    ?: error("Missing sleep start"),
                stages = sleepObject.array("stages").map { item ->
                    val stage = item.asObject()
                    SleepStageInput(
                        stage.string("stage")?.let { name ->
                            SleepStage.entries.firstOrNull { it.name == name }
                        } ?: error("Invalid sleep stage"),
                        stage.int("startMinute", "start_minute") ?: error("Missing stage start"),
                        stage.int("durationMinutes", "duration_minutes")
                            ?: error("Missing stage duration")
                    )
                }
            ),
            hrvAssessment = HrvAssessmentInput(
                hrv.int("averageMs", "average_ms") ?: error("Missing averageMs")
            ),
            restingHeartRate = RestingHeartRateInput(
                resting.int("value") ?: error("Missing resting value"),
                resting.string("measuredTime", "measured_time") ?: error("Missing measuredTime"),
                resting.int("thirtyDayAverage", "thirty_day_average")
                    ?: error("Missing thirtyDayAverage")
            ),
            healthCheck = HealthCheckInput(
                check.int("heartRate", "heart_rate") ?: error("Missing check heartRate"),
                check.int("hrvMs", "hrv_ms") ?: error("Missing check hrvMs"),
                check.int("stress") ?: error("Missing check stress"),
                check.int("respiratoryRate", "respiratory_rate")
                    ?: error("Missing respiratoryRate"),
                check.int("bloodOxygen", "blood_oxygen") ?: error("Missing bloodOxygen"),
                check.string("measuredTime", "measured_time") ?: error("Missing check measuredTime")
            ),
            bodyManagement = BodyManagementInput(
                weightKg = body.double("weightKg", "weight_kg") ?: error("Missing weightKg"),
                trainedMuscleGroups = body.stringList(
                    "trainedMuscleGroups",
                    "trained_muscle_groups"
                ),
                weightHistoryKg = body.doubleList("weightHistoryKg", "weight_history_kg")
            )
        ).also {
            require(HealthEditableRules.validate(it)) { "Invalid editable health data" }
        }
    }

    private fun HealthDashboardData.toJson() = buildJsonObject {
        putNullableObject("daily", dailySummary?.toJson())
        putNullableObject("sleep", sleepSummary?.toJson())
        putNullableObject("trainingLoad", trainingLoad?.toJson())
        putNullableObject("recovery", recovery?.toJson())
        putNullableObject("weeklyPlan", weeklyPlan?.toJson())
        putNullableObject("trainingAssessment", trainingAssessment?.toJson())
        putNullableObject("runningAbility", runningAbility?.toJson())
        putNullableObject("cyclingAbility", cyclingAbility?.toJson())
        putNullableObject("heartRate", heartRate?.toJson())
        putNullableObject("stress", stress?.toJson())
        putNullableObject("hrvAssessment", hrvAssessment?.toJson())
        putNullableObject("restingHeartRate", restingHeartRate?.toJson())
        putNullableObject("healthCheck", healthCheck?.toJson())
        putNullableObject("bodyManagement", bodyManagement?.toJson())
        putNullableObject("todayActivity", todayActivity?.toJson())
    }

    private fun JsonObject.toDashboardData() = HealthDashboardData(
        dailySummary = obj("daily")?.toDailySummary(),
        sleepSummary = obj("sleep")?.toSleepSummary(),
        trainingLoad = obj("trainingLoad", "training_load")?.toTrainingLoad(),
        recovery = obj("recovery")?.toRecovery(),
        todayActivity = obj("todayActivity", "today_activity")?.toTodayActivity(),
        weeklyPlan = obj("weeklyPlan", "weekly_plan")?.toWeeklyPlan(),
        trainingAssessment = obj("trainingAssessment", "training_assessment")?.toTrainingAssessment(),
        runningAbility = obj("runningAbility", "running_ability")?.toRunningAbility(),
        cyclingAbility = obj("cyclingAbility", "cycling_ability")?.toCyclingAbility(),
        heartRate = obj("heartRate", "heart_rate")?.toHeartRate(),
        stress = obj("stress")?.toStress(),
        hrvAssessment = obj("hrvAssessment", "hrv_assessment")?.toHrvAssessment(),
        restingHeartRate = obj("restingHeartRate", "resting_heart_rate")?.toRestingHeartRate(),
        healthCheck = obj("healthCheck", "health_check")?.toHealthCheck(),
        bodyManagement = obj("bodyManagement", "body_management")?.toBodyManagement()
    )

    private fun DailySummary.toJson() = buildJsonObject {
        putNullable("steps", steps); putNullable("calories", calories); putNullable("activeMinutes", activeMinutes)
    }
    private fun JsonObject.toDailySummary() = DailySummary(int("steps"), int("calories"), int("activeMinutes", "active_minutes"))

    private fun TodayActivity.toJson() = buildJsonObject {
        putNullable("distanceKm", distanceKm); putNullable("paceSecondsPerKm", paceSecondsPerKm)
        putNullable("activityNameKey", activityName?.key); putNullable("trainingLoad", trainingLoad)
    }
    private fun JsonObject.toTodayActivity() = TodayActivity(
        double("distanceKm", "distance_km"), int("paceSecondsPerKm", "pace_seconds_per_km"),
        string("activityNameKey", "activity_name_key")?.let(::LocalizedTextSpec), int("trainingLoad", "training_load")
    )

    private fun SleepSummary.toJson() = buildJsonObject {
        putNullable("durationMinutes", durationMinutes); putNullable("qualityScore", qualityScore)
        putNullable("startTime", startTime); putNullable("endTime", endTime)
        put("stages", buildJsonArray { stages.forEach { add(it.toJson()) } })
    }
    private fun SleepStageSegment.toJson() = buildJsonObject {
        put("stage", stage.name); put("startMinute", startMinute); put("durationMinutes", durationMinutes)
    }
    private fun JsonObject.toSleepSummary() = SleepSummary(
        int("durationMinutes", "duration_minutes"), int("qualityScore", "quality_score"),
        string("startTime", "start_time"), string("endTime", "end_time"),
        array("stages").map { value ->
            val item = value.asObject()
            SleepStageSegment(
                item.string("stage")?.let { name -> SleepStage.entries.firstOrNull { it.name == name } } ?: SleepStage.Light,
                item.int("startMinute", "start_minute") ?: 0,
                item.int("durationMinutes", "duration_minutes") ?: 0
            )
        }
    )

    private fun TrainingLoad.toJson() = buildJsonObject {
        putNullable("value", value); put("recommendedMin", recommendedMin); put("recommendedMax", recommendedMax)
        put("dailyLoads", ints(dailyLoads))
    }
    private fun JsonObject.toTrainingLoad() = TrainingLoad(
        int("value"), int("recommendedMin", "recommended_min") ?: 300,
        int("recommendedMax", "recommended_max") ?: 700, intList("dailyLoads", "daily_loads")
    )

    private fun Recovery.toJson() = buildJsonObject { putNullable("score", score); putNullable("remainingHours", remainingHours) }
    private fun JsonObject.toRecovery() = Recovery(int("score"), int("remainingHours", "remaining_hours"))

    private fun WeeklyPlan.toJson() = buildJsonObject {
        put("hasPlan", hasPlan); putNullable("plannedMinutes", plannedMinutes); putNullable("description", description)
        put("currentDayIndex", currentDayIndex); put("dailyLoads", ints(dailyLoads)); putNullable("workoutNameKey", workoutName?.key)
        putNullable("workoutDurationMinutes", workoutDurationMinutes); putNullable("workoutTrainingLoad", workoutTrainingLoad)
        put("dayPlans", buildJsonArray { dayPlans.forEach { add(it.toJson()) } })
    }
    private fun WeeklyDayPlan.toJson() = buildJsonObject {
        put("dayIndex", dayIndex); putNullable("workoutNameKey", workoutName?.key)
        putNullable("workoutDurationMinutes", workoutDurationMinutes); putNullable("workoutTrainingLoad", workoutTrainingLoad)
    }
    private fun JsonObject.toWeeklyPlan() = WeeklyPlan(
        bool("hasPlan", "has_plan") ?: false, int("plannedMinutes", "planned_minutes"), string("description"),
        int("currentDayIndex", "current_day_index") ?: 0, intList("dailyLoads", "daily_loads"),
        string("workoutNameKey", "workout_name_key")?.let(::LocalizedTextSpec),
        int("workoutDurationMinutes", "workout_duration_minutes"), int("workoutTrainingLoad", "workout_training_load"),
        array("dayPlans", "day_plans").map { value ->
            val item = value.asObject()
            WeeklyDayPlan(
                item.int("dayIndex", "day_index") ?: 0,
                item.string("workoutNameKey", "workout_name_key")?.let(::LocalizedTextSpec),
                item.int("workoutDurationMinutes", "workout_duration_minutes"),
                item.int("workoutTrainingLoad", "workout_training_load")
            )
        }
    )

    private fun TrainingAssessment.toJson() = buildJsonObject {
        putNullable("volumeScore", volumeScore); putNullable("trend", trend); putNullable("shortTermLoad", shortTermLoad)
        putNullable("longTermLoad", longTermLoad); putNullable("loadRatio", loadRatio)
        putNullable("assessmentKey", assessment?.key); putNullable("explanationKey", explanation?.key)
    }
    private fun JsonObject.toTrainingAssessment() = TrainingAssessment(
        int("volumeScore", "volume_score"), string("trend"), int("shortTermLoad", "short_term_load"),
        int("longTermLoad", "long_term_load"), double("loadRatio", "load_ratio"),
        string("assessmentKey", "assessment_key")?.let(::LocalizedTextSpec),
        string("explanationKey", "explanation_key")?.let(::LocalizedTextSpec)
    )

    private fun RunningAbility.toJson() = buildJsonObject {
        putNullable("vo2max", vo2max); putNullable("score", score); putNullable("displayScore", displayScore); putNullable("marathonSeconds", marathonSeconds)
    }
    private fun JsonObject.toRunningAbility() = RunningAbility(
        int("vo2max"), int("score"), double("displayScore", "display_score"), int("marathonSeconds", "marathon_seconds")
    )

    private fun CyclingAbility.toJson() = buildJsonObject {
        putNullable("ftp", ftp); putNullable("score", score); putNullable("displayScore", displayScore); putNullable("abilityLabelKey", abilityLabel?.key)
    }
    private fun JsonObject.toCyclingAbility() = CyclingAbility(
        int("ftp"), int("score"), double("displayScore", "display_score"),
        string("abilityLabelKey", "ability_label_key")?.let(::LocalizedTextSpec)
    )

    private fun HeartRate.toJson() = buildJsonObject {
        putNullable("restingHr", restingHr); putNullable("currentHr", currentHr); putNullable("averageHr", averageHr); put("samples", ints(samples))
        put("intervals", buildJsonArray { intervals.forEach { add(it.toJson()) } })
        put("fiveMinuteSamples", ints(fiveMinuteSamples))
    }
    private fun HeartRateInterval.toJson() = buildJsonObject {
        put("startMinute", startMinute); put("minimum", minimum); put("maximum", maximum); put("average", average)
    }
    private fun JsonObject.toHeartRate(): HeartRate {
        val samples = intList("samples")
        val intervals = array("intervals").map { item ->
            val interval = item.asObject()
            HeartRateInterval(
                interval.int("startMinute", "start_minute") ?: 0,
                interval.int("minimum") ?: 0,
                interval.int("maximum") ?: 0,
                interval.int("average") ?: 0
            )
        }.ifEmpty {
            samples.mapIndexed { index, sample -> HeartRateInterval(index * 30, sample, sample, sample) }
        }
        return HeartRate(
            int("restingHr", "resting_hr"),
            int("currentHr", "current_hr"),
            int("averageHr", "average_hr"),
            samples,
            intervals,
            intList("fiveMinuteSamples", "five_minute_samples")
        )
    }

    private fun Stress.toJson() = buildJsonObject {
        putNullable("stressLevel", stressLevel); putNullable("status", status); putNullable("averageStress", averageStress); put("samples", ints(samples))
    }
    private fun JsonObject.toStress() = Stress(
        int("stressLevel", "stress_level"), string("status"), int("averageStress", "average_stress"), intList("samples")
    )

    private fun HrvAssessment.toJson() = buildJsonObject {
        putNullable("hrvScore", hrvScore); putNullable("status", status); putNullable("averageMs", averageMs)
        putNullable("normalMin", normalMin); putNullable("normalMax", normalMax)
    }
    private fun JsonObject.toHrvAssessment() = HrvAssessment(
        int("hrvScore", "hrv_score"), string("status"), int("averageMs", "average_ms"),
        int("normalMin", "normal_min"), int("normalMax", "normal_max")
    )

    private fun RestingHeartRate.toJson() = buildJsonObject {
        putNullable("value", value); putNullable("measuredTime", measuredTime); putNullable("thirtyDayAverage", thirtyDayAverage)
        put("rangeMin", rangeMin); put("rangeMax", rangeMax)
    }
    private fun JsonObject.toRestingHeartRate() = RestingHeartRate(
        int("value"), string("measuredTime", "measured_time"), int("thirtyDayAverage", "thirty_day_average"),
        int("rangeMin", "range_min") ?: 30, int("rangeMax", "range_max") ?: 80
    )

    private fun HealthCheck.toJson() = buildJsonObject {
        putNullable("overallScore", overallScore); putNullable("lastCheckDays", lastCheckDays); putNullable("measuredTime", measuredTime)
        putNullable("heartRate", heartRate); putNullable("hrvMs", hrvMs); putNullable("stress", stress)
        putNullable("respiratoryRate", respiratoryRate); putNullable("bloodOxygen", bloodOxygen)
    }
    private fun JsonObject.toHealthCheck() = HealthCheck(
        int("overallScore", "overall_score"), int("lastCheckDays", "last_check_days"), string("measuredTime", "measured_time"),
        int("heartRate", "heart_rate"), int("hrvMs", "hrv_ms"), int("stress"),
        int("respiratoryRate", "respiratory_rate"), int("bloodOxygen", "blood_oxygen")
    )

    private fun BodyManagement.toJson() = buildJsonObject {
        putNullable("weightKg", weightKg); putNullable("bodyFat", bodyFat); putNullable("bmi", bmi); putNullable("measuredDate", measuredDate)
        put("trainedMuscleGroups", strings(trainedMuscleGroups))
        put("weightHistoryKg", doubles(weightHistoryKg))
    }
    private fun JsonObject.toBodyManagement(): BodyManagement {
        val weight = double("weightKg", "weight_kg")
        val history = doubleListOrNull("weightHistoryKg", "weight_history_kg")
            ?: weight?.let(::listOf).orEmpty()
        return BodyManagement(
            weight, double("bodyFat", "body_fat"), double("bmi"),
            string("measuredDate", "measured_date"),
            stringList("trainedMuscleGroups", "trained_muscle_groups"),
            history
        )
    }

    private fun JsonObject.string(vararg names: String): String? = first(names)?.asPrimitive()?.contentOrNull
    private fun JsonObject.int(vararg names: String): Int? = first(names)?.asPrimitive()?.intOrNull
    private fun JsonObject.long(vararg names: String): Long? = first(names)?.asPrimitive()?.longOrNull
    private fun JsonObject.double(vararg names: String): Double? = first(names)?.asPrimitive()?.doubleOrNull
    private fun JsonObject.bool(vararg names: String): Boolean? = first(names)?.asPrimitive()?.booleanOrNull
    private fun JsonObject.obj(vararg names: String): JsonObject? = first(names) as? JsonObject
    private fun JsonObject.array(vararg names: String): JsonArray = first(names) as? JsonArray ?: JsonArray(emptyList())
    private fun JsonObject.intList(vararg names: String) = array(*names).mapNotNull { it.asPrimitive().intOrNull }
    private fun JsonObject.doubleList(vararg names: String) = array(*names).mapNotNull { it.asPrimitive().doubleOrNull }
    private fun JsonObject.doubleListOrNull(vararg names: String) =
        (first(names) as? JsonArray)?.mapNotNull { it.asPrimitive().doubleOrNull }
    private fun JsonObject.stringList(vararg names: String) = array(*names).mapNotNull { it.asPrimitive().contentOrNull }
    private fun JsonObject.first(names: Array<out String>): JsonValue? = names.firstNotNullOfOrNull { this[it] }?.takeUnless { it is JsonNull }
    private fun JsonValue.asObject() = this as? JsonObject ?: error("Expected JSON object")
    private fun JsonValue.asPrimitive() = this as? JsonPrimitive ?: error("Expected JSON primitive")

    private fun strings(values: List<String>) = buildJsonArray { values.forEach { add(JsonPrimitive(it)) } }
    private fun ints(values: List<Int>) = buildJsonArray { values.forEach { add(JsonPrimitive(it)) } }
    private fun doubles(values: List<Double>) = buildJsonArray { values.forEach { add(JsonPrimitive(it)) } }
    private fun JsonObjectBuilder.putNullableObject(name: String, value: JsonObject?) {
        put(name, value ?: JsonNull)
    }
    private fun JsonObjectBuilder.putNullable(name: String, value: String?) {
        put(name, value?.let(::JsonPrimitive) ?: JsonNull)
    }
    private fun JsonObjectBuilder.putNullable(name: String, value: Int?) {
        put(name, value?.let(::JsonPrimitive) ?: JsonNull)
    }
    private fun JsonObjectBuilder.putNullable(name: String, value: Double?) {
        put(name, value?.let(::JsonPrimitive) ?: JsonNull)
    }
}
