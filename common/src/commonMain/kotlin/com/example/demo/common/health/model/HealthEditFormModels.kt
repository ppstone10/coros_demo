package com.example.demo.common.health.model

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
    val repeatGroups: List<HealthEditRepeatGroup> = emptyList(),
    val sourceKind: HealthEditSourceKind = HealthEditSourceKind.Available,
    val sourceMessageKey: String = sourceKind.messageKey
)

enum class HealthEditValidationReason {
    Required,
    InvalidNumber,
    OutOfRange,
    InvalidChoice,
    InvalidCount,
    Inconsistent
}

data class HealthEditValidationIssue(
    val fieldId: String,
    val labelKey: String,
    val labelArguments: List<String> = emptyList(),
    val reason: HealthEditValidationReason,
    val reasonArguments: List<String> = emptyList()
)

data class HealthEditApplyResult(
    val data: EditableHealthData? = null,
    val issue: HealthEditValidationIssue? = null
) {
    val isSuccess: Boolean get() = data != null && issue == null
}
