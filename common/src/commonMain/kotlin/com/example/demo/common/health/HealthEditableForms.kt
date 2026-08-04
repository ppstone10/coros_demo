package com.example.demo.common.health

object HealthEditableForms {
    private val workoutOptions = WorkoutType.entries.map {
        HealthEditOption(it.name, "health_edit_workout_${it.name.lowercase()}")
    }
    private val heartPatternOptions = HeartRatePattern.entries.map {
        HealthEditOption(it.name, "health_edit_heart_pattern_${it.name.lowercase()}")
    }
    private val stressPatternOptions = StressPattern.entries.map {
        HealthEditOption(it.name, "health_edit_stress_pattern_${it.name.lowercase()}")
    }
    private val sleepStageOptions = SleepStage.entries.map {
        HealthEditOption(it.name, "health_edit_sleep_stage_${it.name.lowercase()}")
    }
    private val muscleOptions = BodyMuscleGroup.entries.map {
        HealthEditOption(it.id, "health_visual_muscle_${it.id}")
    }

    fun form(
        source: EditableHealthData,
        section: HealthEditableSection,
        sourceKind: HealthEditSourceKind = HealthEditSourceKind.Available
    ): HealthEditForm = HealthEditForm(
        section,
        titleKey(section),
        fields(source, section),
        repeatGroups(section),
        sourceKind
    )

    fun apply(
        source: EditableHealthData,
        section: HealthEditableSection,
        values: Map<String, String>
    ): EditableHealthData? = applyDetailed(source, section, values).data

    fun applyDetailed(
        source: EditableHealthData,
        section: HealthEditableSection,
        values: Map<String, String>
    ): HealthEditApplyResult {
        validateRawValues(source, section, values)?.let {
            return HealthEditApplyResult(issue = it)
        }
        val updated = applyUnchecked(source, section, values)
            ?: return HealthEditApplyResult(
                issue = sectionIssue(section, HealthEditValidationReason.Inconsistent)
            )
        if (!HealthEditableRules.validateSection(updated, section)) {
            return HealthEditApplyResult(issue = semanticIssue(updated, section))
        }
        return HealthEditApplyResult(data = updated)
    }

    private fun applyUnchecked(
        source: EditableHealthData,
        section: HealthEditableSection,
        values: Map<String, String>
    ): EditableHealthData? = runCatching {
        when (section) {
            HealthEditableSection.DailySummary -> source.copy(
                dailySummary = DailySummaryInput(
                    values.int("steps"),
                    values.int("calories"),
                    values.int("activeMinutes")
                )
            )
            HealthEditableSection.TodayActivity -> source.copy(
                todayActivity = TodayActivityInput(
                    values.double("distanceKm"),
                    values.int("paceSecondsPerKm")
                )
            )
            HealthEditableSection.WeeklyPlan -> source.copy(
                weeklyPlan = WeeklyPlanInput(
                    List(7) { index ->
                        WeeklyWorkoutInput(
                            WorkoutType.valueOf(values.required("day${index}Type")),
                            values.double("day${index}Distance")
                        )
                    }
                )
            )
            HealthEditableSection.TrainingLoad -> source.copy(
                trainingLoad = TrainingLoadInput(List(7) { values.int("day${it}Load") })
            )
            HealthEditableSection.TrainingAssessment -> source.copy(
                assessment = TrainingAssessmentInput(
                    values.int("shortTermLoad"),
                    values.int("longTermLoad")
                )
            )
            HealthEditableSection.Recovery -> source.copy(
                recovery = RecoveryInput(values.int("score"))
            )
            HealthEditableSection.RunningAbility -> source.copy(
                runningAbility = RunningAbilityInput(values.int("score"))
            )
            HealthEditableSection.CyclingAbility -> source.copy(
                cyclingAbility = CyclingAbilityInput(values.int("score"))
            )
            HealthEditableSection.HeartRate -> source.copy(
                heartRate = HeartRateInput(
                    HealthEditableRules.generateHeartRateSamples(
                        values.int("average"),
                        HeartRatePattern.valueOf(values.required("pattern"))
                    )
                )
            )
            HealthEditableSection.Stress -> source.copy(
                stress = StressInput(
                    HealthEditableRules.generateStressSamples(
                        values.int("average"),
                        StressPattern.valueOf(values.required("pattern"))
                    )
                )
            )
            HealthEditableSection.Sleep -> {
                val start = parseTime(values.required("startTime"))
                    ?: error("Invalid start time")
                var nextStart = 0
                val indices = values.indexedRows("stage", "Type")
                require(indices.isNotEmpty())
                val stages = indices.map { index ->
                    val stage = SleepStage.valueOf(values.required("stage${index}Type"))
                    val duration = values.int("stage${index}Duration")
                    SleepStageInput(stage, nextStart, duration).also { nextStart += duration }
                }
                source.copy(sleep = SleepInput(start, stages))
            }
            HealthEditableSection.HrvAssessment -> source.copy(
                hrvAssessment = HrvAssessmentInput(values.int("averageMs"))
            )
            HealthEditableSection.RestingHeartRate -> source.copy(
                restingHeartRate = RestingHeartRateInput(
                    values.int("value"),
                    values.required("measuredTime"),
                    values.int("thirtyDayAverage")
                )
            )
            HealthEditableSection.HealthCheck -> source.copy(
                healthCheck = HealthCheckInput(
                    values.int("heartRate"),
                    values.int("hrvMs"),
                    values.int("stress"),
                    values.int("respiratoryRate"),
                    values.int("bloodOxygen"),
                    values.required("measuredTime")
                )
            )
            HealthEditableSection.BodyManagement -> {
                val muscles = values.indexedRows("muscle", "").map { index ->
                    val value = values.required("muscle$index")
                    require(BodyMuscleGroup.entries.any { it.id == value })
                    value
                }.distinct()
                source.copy(
                    bodyManagement = source.bodyManagement.copy(
                        trainedMuscleGroups = muscles
                    )
                )
            }
        }
    }.getOrNull()

    fun mutate(
        source: EditableHealthData,
        section: HealthEditableSection,
        values: Map<String, String>,
        groupId: String,
        operation: HealthEditRepeatOperation,
        rowIndex: Int? = null
    ): HealthEditForm? = runCatching {
        when {
            section == HealthEditableSection.Sleep && groupId == SleepGroupId -> {
                val rows = values.indexedRows("stage", "Type").map { index ->
                    values.required("stage${index}Type") to values.required("stage${index}Duration")
                }.toMutableList()
                when (operation) {
                    HealthEditRepeatOperation.Add -> {
                        require(rows.size < MaxSleepStages)
                        rows += SleepStage.Light.name to "30"
                    }
                    HealthEditRepeatOperation.Remove -> {
                        require(rows.size > 1)
                        rows.removeAt(requireNotNull(rowIndex))
                    }
                }
                sleepForm(
                    startTime = values["startTime"] ?: time(source.sleep.startMinuteOfDay),
                    rows = rows
                )
            }
            section == HealthEditableSection.BodyManagement && groupId == MuscleGroupId -> {
                val rows = values.indexedRows("muscle", "").map { index ->
                    values.required("muscle$index")
                }.toMutableList()
                when (operation) {
                    HealthEditRepeatOperation.Add -> {
                        val next = BodyMuscleGroup.entries.firstOrNull { it.id !in rows }
                            ?: error("All muscle groups selected")
                        rows += next.id
                    }
                    HealthEditRepeatOperation.Remove -> rows.removeAt(requireNotNull(rowIndex))
                }
                bodyManagementForm(muscles = rows)
            }
            else -> error("Unsupported repeat group")
        }
    }.getOrNull()

    fun encodeValues(values: Map<String, String>): String = HealthEditFormJson.encodeValues(values)

    fun decodeValues(spec: String): Map<String, String> = HealthEditFormJson.decodeValues(spec)

    fun formJson(source: EditableHealthData, section: HealthEditableSection): String =
        HealthEditFormJson.formJson(source, section)

    fun formJson(form: HealthEditForm): String = HealthEditFormJson.formJson(form)

    fun applyResultJson(result: HealthEditApplyResult): String =
        HealthEditFormJson.applyResultJson(result)

    private fun validateRawValues(
        source: EditableHealthData,
        section: HealthEditableSection,
        values: Map<String, String>
    ): HealthEditValidationIssue? {
        val fields = when (section) {
            HealthEditableSection.BodyManagement -> {
                val indices = runCatching { values.indexedRows("muscle", "") }.getOrElse {
                    return sectionIssue(section, HealthEditValidationReason.Inconsistent)
                }
                bodyManagementFields(indices.map { values["muscle$it"].orEmpty() })
            }
            HealthEditableSection.Sleep -> {
                val indices = runCatching { values.indexedRows("stage", "Type") }.getOrElse {
                    return sectionIssue(section, HealthEditValidationReason.Inconsistent)
                }
                sleepFields(
                    values["startTime"].orEmpty(),
                    indices.map { index ->
                        values["stage${index}Type"].orEmpty() to
                            values["stage${index}Duration"].orEmpty()
                    }
                )
            }
            else -> fields(source, section)
        }
        fields.forEach { field ->
            val raw = values[field.id]
            if (raw.isNullOrBlank()) {
                return field.issue(HealthEditValidationReason.Required)
            }
            when (field.type) {
                HealthEditFieldType.Integer, HealthEditFieldType.Decimal -> {
                    val number = raw.toDoubleOrNull()
                        ?: return field.issue(HealthEditValidationReason.InvalidNumber)
                    if (field.type == HealthEditFieldType.Integer && raw.toIntOrNull() == null) {
                        return field.issue(HealthEditValidationReason.InvalidNumber)
                    }
                    val minimum = field.minimum
                    val maximum = field.maximum
                    if ((minimum != null && number < minimum) || (maximum != null && number > maximum)) {
                        return field.issue(
                            HealthEditValidationReason.OutOfRange,
                            listOf(formatBound(minimum), formatBound(maximum))
                        )
                    }
                }
                HealthEditFieldType.Choice -> if (field.options.none { it.value == raw }) {
                    return field.issue(HealthEditValidationReason.InvalidChoice)
                }
                HealthEditFieldType.Time -> if (parseTime(raw) == null) {
                    return field.issue(HealthEditValidationReason.Inconsistent)
                }
                HealthEditFieldType.Text -> Unit
            }
        }
        return null
    }

    private fun semanticIssue(
        source: EditableHealthData,
        section: HealthEditableSection
    ): HealthEditValidationIssue = when (section) {
        HealthEditableSection.WeeklyPlan -> {
            val index = source.weeklyPlan.days.indexOfFirst {
                (it.type == WorkoutType.Rest && it.distanceKm != 0.0) ||
                    (it.type != WorkoutType.Rest && it.distanceKm !in 0.1..500.0)
            }.coerceAtLeast(0)
            HealthEditValidationIssue(
                "day${index}Distance",
                "health_edit_day_distance_numbered",
                listOf((index + 1).toString()),
                HealthEditValidationReason.Inconsistent
            )
        }
        HealthEditableSection.Sleep -> HealthEditValidationIssue(
            "sleepStages",
            "health_edit_sleep_stage",
            reason = if (source.sleep.stages.isEmpty()) HealthEditValidationReason.InvalidCount
            else HealthEditValidationReason.Inconsistent,
            reasonArguments = if (source.sleep.stages.isEmpty()) listOf("1", MaxSleepStages.toString()) else emptyList()
        )
        else -> sectionIssue(section, HealthEditValidationReason.Inconsistent)
    }

    private fun sectionIssue(
        section: HealthEditableSection,
        reason: HealthEditValidationReason
    ) = HealthEditValidationIssue(
        fieldId = section.name,
        labelKey = titleKey(section),
        reason = reason
    )

    private fun HealthEditField.issue(
        reason: HealthEditValidationReason,
        reasonArguments: List<String> = emptyList()
    ) = HealthEditValidationIssue(id, labelKey, labelArguments, reason, reasonArguments)

    private fun formatBound(value: Double?): String = when {
        value == null -> ""
        value % 1.0 == 0.0 -> value.toInt().toString()
        else -> value.toString()
    }

    private fun fields(source: EditableHealthData, section: HealthEditableSection): List<HealthEditField> =
        when (section) {
            HealthEditableSection.DailySummary -> listOf(
                integer("steps", "health_edit_steps", source.dailySummary.steps, 0, 200_000),
                integer("calories", "health_edit_calories", source.dailySummary.calories, 0, 20_000),
                integer("activeMinutes", "health_edit_active_minutes", source.dailySummary.activeMinutes, 0, 1_440)
            )
            HealthEditableSection.TodayActivity -> listOf(
                decimal("distanceKm", "health_edit_distance", source.todayActivity.distanceKm, 0.0, 500.0),
                integer("paceSecondsPerKm", "health_edit_pace_seconds", source.todayActivity.paceSecondsPerKm, 120, 1_800)
            )
            HealthEditableSection.WeeklyPlan -> source.weeklyPlan.days.flatMapIndexed { index, day ->
                listOf(
                    choice(
                        "day${index}Type",
                        "health_edit_day_type_numbered",
                        day.type.name,
                        workoutOptions
                    ).copy(labelArguments = listOf((index + 1).toString())),
                    decimal(
                        "day${index}Distance",
                        "health_edit_day_distance_numbered",
                        day.distanceKm,
                        0.0,
                        500.0
                    ).copy(labelArguments = listOf((index + 1).toString()))
                )
            }
            HealthEditableSection.TrainingLoad -> source.trainingLoad.dailyLoads.mapIndexed { index, value ->
                integer(
                    "day${index}Load",
                    "health_edit_daily_load_numbered",
                    value,
                    0,
                    5_000
                ).copy(labelArguments = listOf((index + 1).toString()))
            }
            HealthEditableSection.TrainingAssessment -> listOf(
                integer("shortTermLoad", "health_edit_short_load", source.assessment.shortTermLoad, 0, 10_000),
                integer("longTermLoad", "health_edit_long_load", source.assessment.longTermLoad, 1, 10_000)
            )
            HealthEditableSection.Recovery -> listOf(
                integer("score", "health_edit_recovery_score", source.recovery.score, 0, 100)
            )
            HealthEditableSection.RunningAbility -> listOf(
                integer("score", "health_edit_running_score", source.runningAbility.score, 0, 100)
            )
            HealthEditableSection.CyclingAbility -> listOf(
                integer("score", "health_edit_cycling_score", source.cyclingAbility.score, 0, 100)
            )
            HealthEditableSection.HeartRate -> listOf(
                integer(
                    "average",
                    "health_edit_average_heart_rate",
                    source.heartRate.fiveMinuteSamples.average().toInt(),
                    35,
                    200
                ),
                choice("pattern", "health_edit_heart_pattern", HeartRatePattern.Normal.name, heartPatternOptions)
            )
            HealthEditableSection.Stress -> listOf(
                integer(
                    "average",
                    "health_edit_average_stress",
                    source.stress.halfHourSamples.average().toInt(),
                    0,
                    100
                ),
                choice("pattern", "health_edit_stress_pattern", StressPattern.Normal.name, stressPatternOptions)
            )
            HealthEditableSection.Sleep -> sleepFields(
                time(source.sleep.startMinuteOfDay),
                source.sleep.stages.map { it.stage.name to it.durationMinutes.toString() }
            )
            HealthEditableSection.HrvAssessment -> listOf(
                integer("averageMs", "health_edit_average_hrv", source.hrvAssessment.averageMs, 1, 300)
            )
            HealthEditableSection.RestingHeartRate -> listOf(
                integer("value", "health_edit_resting_heart_rate", source.restingHeartRate.value, 30, 220),
                HealthEditField("measuredTime", "health_edit_measured_time", source.restingHeartRate.measuredTime, HealthEditFieldType.Time),
                integer("thirtyDayAverage", "health_edit_thirty_day_average", source.restingHeartRate.thirtyDayAverage, 30, 220)
            )
            HealthEditableSection.HealthCheck -> listOf(
                integer("heartRate", "health_edit_heart_rate", source.healthCheck.heartRate, 30, 220),
                integer("hrvMs", "health_edit_hrv", source.healthCheck.hrvMs, 1, 300),
                integer("stress", "health_edit_stress", source.healthCheck.stress, 0, 100),
                integer("respiratoryRate", "health_edit_respiratory_rate", source.healthCheck.respiratoryRate, 5, 60),
                integer("bloodOxygen", "health_edit_blood_oxygen", source.healthCheck.bloodOxygen, 50, 100),
                HealthEditField("measuredTime", "health_edit_measured_time", source.healthCheck.measuredTime, HealthEditFieldType.Time)
            )
            HealthEditableSection.BodyManagement -> bodyManagementFields(
                source.bodyManagement.trainedMuscleGroups
            )
        }

    private fun repeatGroups(section: HealthEditableSection): List<HealthEditRepeatGroup> =
        when (section) {
            HealthEditableSection.Sleep -> listOf(
                HealthEditRepeatGroup(
                    id = SleepGroupId,
                    addLabelKey = "health_edit_add_sleep_stage",
                    itemLabelKey = "health_edit_sleep_stage_item",
                    minimumItems = 1,
                    maximumItems = MaxSleepStages
                )
            )
            HealthEditableSection.BodyManagement -> listOf(
                HealthEditRepeatGroup(
                    id = MuscleGroupId,
                    addLabelKey = "health_edit_add_muscle_group",
                    itemLabelKey = "health_edit_muscle_group_item",
                    minimumItems = 0,
                    maximumItems = BodyMuscleGroup.entries.size
                )
            )
            else -> emptyList()
        }

    private fun sleepForm(
        startTime: String,
        rows: List<Pair<String, String>>
    ) = HealthEditForm(
        section = HealthEditableSection.Sleep,
        titleKey = titleKey(HealthEditableSection.Sleep),
        fields = sleepFields(startTime, rows),
        repeatGroups = repeatGroups(HealthEditableSection.Sleep)
    )

    private fun sleepFields(
        startTime: String,
        rows: List<Pair<String, String>>
    ): List<HealthEditField> =
        listOf(
            HealthEditField(
                "startTime",
                "health_edit_sleep_start",
                startTime,
                HealthEditFieldType.Time
            )
        ) + rows.flatMapIndexed { index, (stage, duration) ->
            val arguments = listOf((index + 1).toString())
            listOf(
                choice(
                    "stage${index}Type",
                    "health_edit_sleep_stage_numbered",
                    stage,
                    sleepStageOptions
                ).copy(labelArguments = arguments, groupId = SleepGroupId, rowIndex = index),
                HealthEditField(
                    id = "stage${index}Duration",
                    labelKey = "health_edit_stage_duration_numbered",
                    value = duration,
                    type = HealthEditFieldType.Integer,
                    minimum = 1.0,
                    maximum = 1_440.0,
                    labelArguments = arguments,
                    groupId = SleepGroupId,
                    rowIndex = index
                )
            )
        }

    private fun bodyManagementForm(
        muscles: List<String>
    ) = HealthEditForm(
        section = HealthEditableSection.BodyManagement,
        titleKey = titleKey(HealthEditableSection.BodyManagement),
        fields = bodyManagementFields(muscles),
        repeatGroups = repeatGroups(HealthEditableSection.BodyManagement)
    )

    private fun bodyManagementFields(
        muscles: List<String>
    ): List<HealthEditField> =
        muscles.mapIndexed { index, muscle ->
            choice(
                id = "muscle$index",
                label = "health_edit_muscle_group_numbered",
                value = muscle,
                options = muscleOptions
            ).copy(
                labelArguments = listOf((index + 1).toString()),
                groupId = MuscleGroupId,
                rowIndex = index
            )
        }

    private fun titleKey(section: HealthEditableSection): String =
        "health_edit_title_${section.name.replaceFirstChar { it.lowercase() }}"

    private fun integer(
        id: String,
        label: String,
        value: Int,
        min: Int,
        max: Int
    ) = HealthEditField(id, label, value.toString(), HealthEditFieldType.Integer, min.toDouble(), max.toDouble())

    private fun decimal(
        id: String,
        label: String,
        value: Double,
        min: Double,
        max: Double
    ) = HealthEditField(id, label, value.toString(), HealthEditFieldType.Decimal, min, max)

    private fun choice(
        id: String,
        label: String,
        value: String,
        options: List<HealthEditOption>
    ) = HealthEditField(id, label, value, HealthEditFieldType.Choice, options = options)

    private fun Map<String, String>.required(id: String): String =
        get(id)?.takeIf(String::isNotBlank) ?: error("Missing $id")

    private fun Map<String, String>.int(id: String): Int = required(id).toInt()
    private fun Map<String, String>.double(id: String): Double = required(id).toDouble()

    private fun Map<String, String>.indexedRows(prefix: String, suffix: String): List<Int> {
        val indices = keys.mapNotNull { key ->
            if (!key.startsWith(prefix) || !key.endsWith(suffix)) return@mapNotNull null
            key.substring(prefix.length, key.length - suffix.length).toIntOrNull()
        }.distinct().sorted()
        require(indices == indices.indices.toList()) { "Repeat rows must be contiguous" }
        return indices
    }

    private fun time(minutes: Int): String =
        "${(minutes / 60).toString().padStart(2, '0')}:" +
            (minutes % 60).toString().padStart(2, '0')

    private fun parseTime(value: String): Int? {
        val parts = value.split(':')
        if (parts.size != 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        return if (hour in 0..23 && minute in 0..59) hour * 60 + minute else null
    }

    private const val SleepGroupId = "sleepStages"
    private const val MuscleGroupId = "muscleGroups"
    private const val MaxSleepStages = 24
}
