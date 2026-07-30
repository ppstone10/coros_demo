package com.example.demo.common.health

enum class HealthEditFieldType { Integer, Decimal, Time, Text, Choice }

enum class HealthEditRepeatOperation { Add, Remove }

enum class BodyMuscleGroup(val id: String) {
    Chest("chest"),
    Shoulders("shoulders"),
    Back("back"),
    Biceps("biceps"),
    Triceps("triceps"),
    Abdominals("abdominals"),
    Glutes("glutes"),
    Quadriceps("quadriceps"),
    Hamstrings("hamstrings"),
    Calves("calves")
}

data class HealthEditOption(val value: String, val labelKey: String)

data class HealthEditField(
    val id: String,
    val labelKey: String,
    val value: String,
    val type: HealthEditFieldType,
    val minimum: Double? = null,
    val maximum: Double? = null,
    val options: List<HealthEditOption> = emptyList(),
    val labelArguments: List<String> = emptyList(),
    val groupId: String? = null,
    val rowIndex: Int? = null
)

data class HealthEditRepeatGroup(
    val id: String,
    val addLabelKey: String,
    val itemLabelKey: String,
    val minimumItems: Int,
    val maximumItems: Int
)

data class HealthEditForm(
    val section: HealthEditableSection,
    val titleKey: String,
    val fields: List<HealthEditField>,
    val repeatGroups: List<HealthEditRepeatGroup> = emptyList()
)

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

    fun form(source: EditableHealthData, section: HealthEditableSection): HealthEditForm =
        HealthEditForm(section, titleKey(section), fields(source, section), repeatGroups(section))

    fun apply(
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
                val weight = values.double("weightKg")
                val muscles = values.indexedRows("muscle", "").map { index ->
                    val value = values.required("muscle$index")
                    require(BodyMuscleGroup.entries.any { it.id == value })
                    value
                }.distinct()
                source.copy(
                    bodyManagement = source.bodyManagement.copy(
                        weightKg = weight,
                        trainedMuscleGroups = muscles,
                        weightHistoryKg = source.bodyManagement.weightHistoryKg + weight
                    )
                )
            }
        }
    }.getOrNull()?.takeIf(HealthEditableRules::validate)

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
                bodyManagementForm(
                    weight = values["weightKg"] ?: source.bodyManagement.weightKg.toString(),
                    muscles = rows
                )
            }
            else -> error("Unsupported repeat group")
        }
    }.getOrNull()

    fun encodeValues(values: Map<String, String>): String =
        values.entries.joinToString("&") { (key, value) ->
            "${key.percentEncode()}=${value.percentEncode()}"
        }

    fun decodeValues(spec: String): Map<String, String> =
        spec.split('&').filter(String::isNotBlank).associate { entry ->
            val separator = entry.indexOf('=')
            require(separator > 0) { "Invalid form value" }
            entry.substring(0, separator).percentDecode() to
                entry.substring(separator + 1).percentDecode()
        }

    fun formJson(source: EditableHealthData, section: HealthEditableSection): String =
        formJson(form(source, section))

    fun formJson(form: HealthEditForm): String =
        buildString {
            append("{\"section\":\"").append(form.section.name)
            append("\",\"titleKey\":\"").append(form.titleKey)
            append("\",\"fields\":[")
            form.fields.forEachIndexed { index, field ->
                if (index > 0) append(',')
                append("{\"id\":\"").append(field.id)
                append("\",\"labelKey\":\"").append(field.labelKey)
                append("\",\"value\":\"").append(field.value.jsonEscape())
                append("\",\"type\":\"").append(field.type.name).append('"')
                field.minimum?.let { append(",\"minimum\":").append(it) }
                field.maximum?.let { append(",\"maximum\":").append(it) }
                append(",\"labelArguments\":[")
                field.labelArguments.forEachIndexed { argumentIndex, argument ->
                    if (argumentIndex > 0) append(',')
                    append('"').append(argument.jsonEscape()).append('"')
                }
                append(']')
                field.groupId?.let {
                    append(",\"groupId\":\"").append(it.jsonEscape()).append('"')
                }
                field.rowIndex?.let { append(",\"rowIndex\":").append(it) }
                append(",\"options\":[")
                field.options.forEachIndexed { optionIndex, option ->
                    if (optionIndex > 0) append(',')
                    append("{\"value\":\"").append(option.value)
                    append("\",\"labelKey\":\"").append(option.labelKey).append("\"}")
                }
                append("]}")
            }
            append("],\"repeatGroups\":[")
            form.repeatGroups.forEachIndexed { index, group ->
                if (index > 0) append(',')
                append("{\"id\":\"").append(group.id)
                append("\",\"addLabelKey\":\"").append(group.addLabelKey)
                append("\",\"itemLabelKey\":\"").append(group.itemLabelKey)
                append("\",\"minimumItems\":").append(group.minimumItems)
                append(",\"maximumItems\":").append(group.maximumItems)
                append('}')
            }
            append("]}")
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
                source.bodyManagement.weightKg.toString(),
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
        weight: String,
        muscles: List<String>
    ) = HealthEditForm(
        section = HealthEditableSection.BodyManagement,
        titleKey = titleKey(HealthEditableSection.BodyManagement),
        fields = bodyManagementFields(weight, muscles),
        repeatGroups = repeatGroups(HealthEditableSection.BodyManagement)
    )

    private fun bodyManagementFields(
        weight: String,
        muscles: List<String>
    ): List<HealthEditField> =
        listOf(
            HealthEditField(
                id = "weightKg",
                labelKey = "health_edit_weight",
                value = weight,
                type = HealthEditFieldType.Decimal,
                minimum = 30.0,
                maximum = 200.0
            )
        ) + muscles.mapIndexed { index, muscle ->
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

    private fun String.percentEncode(): String = buildString {
        this@percentEncode.encodeToByteArray().forEach { byte ->
            val value = byte.toInt() and 0xff
            if (
                value in 'a'.code..'z'.code ||
                value in 'A'.code..'Z'.code ||
                value in '0'.code..'9'.code ||
                value == '-'.code || value == '_'.code || value == '.'.code
            ) append(value.toChar())
            else append('%').append(value.toString(16).uppercase().padStart(2, '0'))
        }
    }

    private fun String.percentDecode(): String {
        val bytes = mutableListOf<Byte>()
        var index = 0
        while (index < length) {
            if (this[index] == '%' && index + 2 < length) {
                bytes += substring(index + 1, index + 3).toInt(16).toByte()
                index += 3
            } else {
                bytes += this[index].code.toByte()
                index++
            }
        }
        return bytes.toByteArray().decodeToString()
    }

    private fun String.jsonEscape(): String =
        replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")

    private const val SleepGroupId = "sleepStages"
    private const val MuscleGroupId = "muscleGroups"
    private const val MaxSleepStages = 24
}
