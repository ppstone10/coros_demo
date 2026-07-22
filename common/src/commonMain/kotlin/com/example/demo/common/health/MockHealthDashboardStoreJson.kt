package com.example.demo.common.health

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

    private fun HealthDashboardSnapshot.toJson() = buildJsonObject {
        put("userId", userId)
        put("scenario", sourceScenario.name)
        put("enabledCardTypes", strings(enabledCardTypes.map { it.name }))
        dashboardData?.let { put("dashboardData", it.toJson()) }
        put("schemaVersion", schemaVersion)
    }

    private fun JsonObject.toSnapshot(): HealthDashboardSnapshot {
        val userId = string("userId", "user_id") ?: error("Missing userId")
        val sourceScenario = string("scenario")
            ?.let { name -> HealthMockScenario.entries.firstOrNull { it.name == name } }
            ?: HealthMockScenario.Normal
        val enabled = array("enabledCardTypes", "enabled_card_types")
            .mapNotNull { it.asPrimitive().contentOrNull }
            .mapNotNull { name -> HealthCardType.entries.firstOrNull { it.name == name } }
            .ifEmpty { DefaultHealthCardOrder }
        val data = obj("dashboardData", "dashboard_data")?.toDashboardData()
        return HealthDashboardSnapshot(
            userId = userId,
            sourceScenario = sourceScenario,
            enabledCardTypes = enabled,
            dashboardData = data,
            schemaVersion = int("schemaVersion", "schema_version") ?: if (data == null) 1 else CurrentHealthDashboardSchemaVersion
        )
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
    }
    private fun JsonObject.toWeeklyPlan() = WeeklyPlan(
        bool("hasPlan", "has_plan") ?: false, int("plannedMinutes", "planned_minutes"), string("description"),
        int("currentDayIndex", "current_day_index") ?: 0, intList("dailyLoads", "daily_loads"),
        string("workoutNameKey", "workout_name_key")?.let(::LocalizedTextSpec),
        int("workoutDurationMinutes", "workout_duration_minutes"), int("workoutTrainingLoad", "workout_training_load")
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
    }
    private fun JsonObject.toHeartRate() = HeartRate(
        int("restingHr", "resting_hr"), int("currentHr", "current_hr"), int("averageHr", "average_hr"), intList("samples")
    )

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
    }
    private fun JsonObject.toBodyManagement() = BodyManagement(
        double("weightKg", "weight_kg"), double("bodyFat", "body_fat"), double("bmi"),
        string("measuredDate", "measured_date"), stringList("trainedMuscleGroups", "trained_muscle_groups")
    )

    private fun JsonObject.string(vararg names: String): String? = first(names)?.asPrimitive()?.contentOrNull
    private fun JsonObject.int(vararg names: String): Int? = first(names)?.asPrimitive()?.intOrNull
    private fun JsonObject.long(vararg names: String): Long? = first(names)?.asPrimitive()?.longOrNull
    private fun JsonObject.double(vararg names: String): Double? = first(names)?.asPrimitive()?.doubleOrNull
    private fun JsonObject.bool(vararg names: String): Boolean? = first(names)?.asPrimitive()?.booleanOrNull
    private fun JsonObject.obj(vararg names: String): JsonObject? = first(names) as? JsonObject
    private fun JsonObject.array(vararg names: String): JsonArray = first(names) as? JsonArray ?: JsonArray(emptyList())
    private fun JsonObject.intList(vararg names: String) = array(*names).mapNotNull { it.asPrimitive().intOrNull }
    private fun JsonObject.stringList(vararg names: String) = array(*names).mapNotNull { it.asPrimitive().contentOrNull }
    private fun JsonObject.first(names: Array<out String>): JsonValue? = names.firstNotNullOfOrNull { this[it] }?.takeUnless { it is JsonNull }
    private fun JsonValue.asObject() = this as? JsonObject ?: error("Expected JSON object")
    private fun JsonValue.asPrimitive() = this as? JsonPrimitive ?: error("Expected JSON primitive")

    private fun strings(values: List<String>) = buildJsonArray { values.forEach { add(JsonPrimitive(it)) } }
    private fun ints(values: List<Int>) = buildJsonArray { values.forEach { add(JsonPrimitive(it)) } }
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

private sealed interface JsonValue {
    fun render(): String
}

private class JsonObject(
    private val values: Map<String, JsonValue>
) : JsonValue {
    operator fun get(name: String): JsonValue? = values[name]
    override fun render(): String = values.entries.joinToString(prefix = "{", postfix = "}") { (key, value) ->
        "\"${key.jsonEscaped()}\":${value.render()}"
    }
    override fun toString(): String = render()
}

private class JsonArray(
    private val values: List<JsonValue>
) : JsonValue, List<JsonValue> by values {
    override fun render(): String = values.joinToString(prefix = "[", postfix = "]") { it.render() }
    override fun toString(): String = render()
}

private class JsonPrimitive private constructor(
    val content: String,
    private val quoted: Boolean
) : JsonValue {
    constructor(value: String) : this(value, true)
    constructor(value: Int) : this(value.toString(), false)
    constructor(value: Long) : this(value.toString(), false)
    constructor(value: Double) : this(value.toString(), false)
    constructor(value: Boolean) : this(value.toString(), false)

    val contentOrNull: String? get() = content
    val intOrNull: Int? get() = content.toIntOrNull()
    val longOrNull: Long? get() = content.toLongOrNull()
    val doubleOrNull: Double? get() = content.toDoubleOrNull()
    val booleanOrNull: Boolean? get() = when (content) { "true" -> true; "false" -> false; else -> null }

    override fun render(): String = if (quoted) "\"${content.jsonEscaped()}\"" else content
    override fun toString(): String = render()

    companion object {
        fun raw(value: String) = JsonPrimitive(value, false)
    }
}

private object JsonNull : JsonValue {
    override fun render(): String = "null"
    override fun toString(): String = render()
}

private class JsonObjectBuilder {
    private val values = linkedMapOf<String, JsonValue>()
    fun put(name: String, value: JsonValue) { values[name] = value }
    fun put(name: String, value: String) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Int) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Long) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Double) = put(name, JsonPrimitive(value))
    fun put(name: String, value: Boolean) = put(name, JsonPrimitive(value))
    fun build() = JsonObject(values)
}

private class JsonArrayBuilder {
    private val values = mutableListOf<JsonValue>()
    fun add(value: JsonValue) { values += value }
    fun build() = JsonArray(values)
}

private fun buildJsonObject(block: JsonObjectBuilder.() -> Unit): JsonObject = JsonObjectBuilder().apply(block).build()
private fun buildJsonArray(block: JsonArrayBuilder.() -> Unit): JsonArray = JsonArrayBuilder().apply(block).build()

private fun parseJson(json: String): JsonValue = HealthJsonParser(json).parse()

private class HealthJsonParser(private val source: String) {
    private var position = 0

    fun parse(): JsonValue {
        skipWhitespace()
        val value = parseValue()
        skipWhitespace()
        require(position == source.length) { "Unexpected trailing JSON content" }
        return value
    }

    private fun parseValue(): JsonValue {
        skipWhitespace()
        require(position < source.length) { "Unexpected end of JSON" }
        return when (source[position]) {
            '{' -> parseObject()
            '[' -> parseArray()
            '"' -> JsonPrimitive(parseString())
            't' -> parseKeyword("true", JsonPrimitive.raw("true"))
            'f' -> parseKeyword("false", JsonPrimitive.raw("false"))
            'n' -> parseKeyword("null", JsonNull)
            else -> parseNumber()
        }
    }

    private fun parseObject(): JsonObject {
        expect('{')
        skipWhitespace()
        val values = linkedMapOf<String, JsonValue>()
        if (consume('}')) return JsonObject(values)
        while (true) {
            skipWhitespace()
            require(position < source.length && source[position] == '"') { "Expected JSON object key" }
            val key = parseString()
            skipWhitespace()
            expect(':')
            values[key] = parseValue()
            skipWhitespace()
            if (consume('}')) return JsonObject(values)
            expect(',')
        }
    }

    private fun parseArray(): JsonArray {
        expect('[')
        skipWhitespace()
        val values = mutableListOf<JsonValue>()
        if (consume(']')) return JsonArray(values)
        while (true) {
            values += parseValue()
            skipWhitespace()
            if (consume(']')) return JsonArray(values)
            expect(',')
        }
    }

    private fun parseString(): String {
        expect('"')
        val result = StringBuilder()
        while (position < source.length) {
            when (val char = source[position++]) {
                '"' -> return result.toString()
                '\\' -> {
                    require(position < source.length) { "Invalid JSON escape" }
                    when (val escaped = source[position++]) {
                        '"', '\\', '/' -> result.append(escaped)
                        'b' -> result.append('\b')
                        'f' -> result.append('\u000C')
                        'n' -> result.append('\n')
                        'r' -> result.append('\r')
                        't' -> result.append('\t')
                        'u' -> {
                            require(position + 4 <= source.length) { "Invalid unicode escape" }
                            result.append(source.substring(position, position + 4).toInt(16).toChar())
                            position += 4
                        }
                        else -> error("Unsupported JSON escape $escaped")
                    }
                }
                else -> result.append(char)
            }
        }
        error("Unterminated JSON string")
    }

    private fun parseNumber(): JsonPrimitive {
        val start = position
        while (position < source.length && source[position] !in charArrayOf(',', '}', ']', ' ', '\n', '\r', '\t')) position++
        val raw = source.substring(start, position)
        require(raw.toDoubleOrNull() != null) { "Invalid JSON value $raw" }
        return JsonPrimitive.raw(raw)
    }

    private fun parseKeyword(keyword: String, value: JsonValue): JsonValue {
        require(source.startsWith(keyword, position)) { "Invalid JSON keyword" }
        position += keyword.length
        return value
    }

    private fun consume(expected: Char): Boolean {
        if (position < source.length && source[position] == expected) {
            position++
            return true
        }
        return false
    }

    private fun expect(expected: Char) {
        require(consume(expected)) { "Expected '$expected' at $position" }
    }

    private fun skipWhitespace() {
        while (position < source.length && source[position].isWhitespace()) position++
    }
}

private fun String.jsonEscaped(): String = buildString {
    this@jsonEscaped.forEach { char ->
        when (char) {
            '\\' -> append("\\\\")
            '"' -> append("\\\"")
            '\b' -> append("\\b")
            '\u000C' -> append("\\f")
            '\n' -> append("\\n")
            '\r' -> append("\\r")
            '\t' -> append("\\t")
            else -> append(char)
        }
    }
}
