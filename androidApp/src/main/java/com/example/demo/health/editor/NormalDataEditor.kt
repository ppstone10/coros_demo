package com.example.demo.health

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.HealthEditField
import com.example.demo.common.health.HealthEditFieldType
import com.example.demo.common.health.HealthEditForm
import com.example.demo.common.health.HealthEditRepeatGroup
import com.example.demo.common.health.HealthEditRepeatOperation
import com.example.demo.common.health.HealthEditValidationIssue
import com.example.demo.common.health.HealthEditValidationReason
import com.example.demo.common.health.HealthEditableSection
import com.example.demo.common.health.HealthEffect
import com.example.demo.common.health.LocalizedTextSpec
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.theme.DemoTheme
import com.example.demo.login.LoginViewModel
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.milliseconds

private val EditorPage = AppColors.Health.Page
private val EditorCard = AppColors.Health.Card
private val EditorMuted = AppColors.Health.Muted

@Composable
private fun SourceNotice(messageKey: String) {
    Text(
        localizedHealthText(LocalizedTextSpec(messageKey)),
        color = AppColors.Health.Warning,
        fontSize = 13.sp,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = AppSpacing.Screen, vertical = 8.dp)
            .background(EditorCard, RoundedCornerShape(10.dp))
            .padding(12.dp)
    )
}

@Composable
private fun validationIssueText(issue: HealthEditValidationIssue): String {
    val label = localizedHealthText(LocalizedTextSpec(issue.labelKey, issue.labelArguments))
    val reasonKey = when (issue.reason) {
        HealthEditValidationReason.Required -> "health_edit_error_required"
        HealthEditValidationReason.InvalidNumber -> "health_edit_error_number"
        HealthEditValidationReason.OutOfRange -> "health_edit_error_range"
        HealthEditValidationReason.InvalidChoice -> "health_edit_error_choice"
        HealthEditValidationReason.InvalidCount -> "health_edit_error_count"
        HealthEditValidationReason.Inconsistent -> "health_edit_error_inconsistent"
    }
    return localizedHealthText(LocalizedTextSpec(reasonKey, listOf(label) + issue.reasonArguments))
}

@Composable
fun NormalDataEditorOverview(
    viewModel: HealthDashboardViewModel,
    onBack: () -> Unit,
    onOpenSection: (HealthEditableSection) -> Unit
) {
    viewModel.beginNormalDataEditing()
    val effect = viewModel.effect
    val savedMessage = localizedHealthText(LocalizedTextSpec("health_edit_saved_refresh"))
    val defaultsMessage = localizedHealthText(LocalizedTextSpec("health_edit_defaults_refresh"))
    var toastEvent by remember { mutableStateOf<Long?>(null) }
    var toastText by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(effect) {
        when (effect) {
            is HealthEffect.NormalDraftSaved -> {
                toastEvent = effect.eventId
                toastText = savedMessage
            }
            is HealthEffect.NormalDefaultsRestored -> {
                toastEvent = effect.eventId
                toastText = defaultsMessage
            }
            else -> Unit
        }
    }
    LaunchedEffect(toastEvent) {
        val event = toastEvent ?: return@LaunchedEffect
        delay(1_500.milliseconds)
        if (toastEvent == event) {
            toastText = null
            viewModel.onEffectConsumed()
        }
    }

    Box(Modifier.fillMaxSize().background(EditorPage).statusBarsPadding()) {
        Column(Modifier.fillMaxSize()) {
            EditorHeader(
                title = localizedHealthText(LocalizedTextSpec("health_edit_normal_data")),
                onBack = onBack,
                action = localizedHealthText(LocalizedTextSpec("health_edit_use_defaults")),
                onAction = viewModel::restoreAllNormalDefaults
            )
            Text(
                localizedHealthText(LocalizedTextSpec("health_edit_select_hint")),
                color = EditorMuted,
                fontSize = 14.sp,
                modifier = Modifier.padding(horizontal = AppSpacing.Screen, vertical = 12.dp)
            )
            viewModel.state.editSourceKind.messageKey.takeIf(String::isNotBlank)?.let { key ->
                SourceNotice(key)
            }
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(10.dp),
                modifier = Modifier.fillMaxSize().padding(horizontal = AppSpacing.Screen)
            ) {
                items(HealthEditableSection.entries, key = { it.name }) { section ->
                    val form = viewModel.normalEditForm(section)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(EditorCard, RoundedCornerShape(12.dp))
                            .clickable { onOpenSection(section) }
                            .padding(horizontal = 16.dp, vertical = 18.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            localizedHealthText(LocalizedTextSpec(form.titleKey)),
                            color = AppColors.Core.White,
                            fontSize = 16.sp,
                            modifier = Modifier.weight(1f)
                        )
                        Text("›", color = EditorMuted, fontSize = 24.sp)
                    }
                }
                item { Spacer(Modifier.height(24.dp)) }
            }
        }
        toastText?.let { message ->
            Text(
                message,
                color = AppColors.Core.White,
                fontSize = 14.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(24.dp)
                    .background(AppColors.Health.NoticeBackground, RoundedCornerShape(10.dp))
                    .padding(horizontal = 18.dp, vertical = 12.dp)
            )
        }
    }
}

@Composable
fun NormalDataSectionEditor(
    section: HealthEditableSection,
    viewModel: HealthDashboardViewModel,
    onBack: () -> Unit,
    onSaved: () -> Unit
) {
    val initial = remember(section) { viewModel.normalEditForm(section) }
    var form by remember(section) { mutableStateOf(initial) }
    val values = remember(section) {
        mutableStateMapOf<String, String>().apply {
            initial.fields.forEach { put(it.id, it.value) }
        }
    }
    var validationIssue by remember { mutableStateOf<HealthEditValidationIssue?>(null) }
    var selectedChoiceFieldId by remember(section) { mutableStateOf<String?>(null) }
    val focusManager = LocalFocusManager.current
    fun useForm(next: HealthEditForm) {
        form = next
        values.clear()
        next.fields.forEach { values[it.id] = it.value }
        validationIssue = null
        selectedChoiceFieldId = null
    }
    fun mutate(group: HealthEditRepeatGroup, operation: HealthEditRepeatOperation, rowIndex: Int? = null) {
        viewModel.mutateNormalEditForm(section, values.toMap(), group.id, operation, rowIndex)
            ?.let(::useForm)
    }

    Box(Modifier.fillMaxSize().background(EditorPage).statusBarsPadding()) {
        Column(Modifier.fillMaxSize()) {
            EditorHeader(
                title = localizedHealthText(LocalizedTextSpec(form.titleKey)),
                onBack = onBack,
                action = stringResource(R.string.common_save),
                onAction = {
                    val result = viewModel.saveNormalEditForm(section, values.toMap())
                    if (result.isSuccess) {
                        onSaved()
                    } else {
                        validationIssue = result.issue
                    }
                }
            )
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.fillMaxSize().padding(horizontal = AppSpacing.Screen)
            ) {
                form.sourceMessageKey.takeIf(String::isNotBlank)?.let { key ->
                    item { SourceNotice(key) }
                }
                item {
                    Button(
                        onClick = {
                            val defaults = viewModel.defaultNormalEditForm(section)
                            useForm(defaults)
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = EditorCard),
                        modifier = Modifier.fillMaxWidth().padding(top = 12.dp)
                    ) {
                        Text(
                            localizedHealthText(LocalizedTextSpec("health_edit_restore_card")),
                            color = AppColors.Core.White
                        )
                    }
                }
                validationIssue?.let { issue ->
                    item {
                        Text(
                            validationIssueText(issue),
                            color = AppColors.Health.Warning,
                            fontSize = 13.sp
                        )
                    }
                }
                items(form.fields.filter { it.groupId == null }, key = { it.id }) { field ->
                    EditField(
                        field = field,
                        value = values[field.id].orEmpty(),
                        onValueChange = { values[field.id] = it },
                        onRequestChoice = {
                            focusManager.clearFocus(force = true)
                            selectedChoiceFieldId = field.id
                        }
                    )
                }
                form.repeatGroups.forEach { group ->
                    val rows = form.fields.filter { it.groupId == group.id }
                        .groupBy { requireNotNull(it.rowIndex) }
                        .toSortedMap()
                    rows.forEach { (rowIndex, fields) ->
                        item(key = "${group.id}-$rowIndex") {
                            RepeatGroupEditor(
                                group = group,
                                rowIndex = rowIndex,
                                fields = fields,
                                values = values,
                                canRemove = rows.size > group.minimumItems,
                                onValueChange = { fieldId, value -> values[fieldId] = value },
                                onRequestChoice = {
                                    focusManager.clearFocus(force = true)
                                    selectedChoiceFieldId = it
                                },
                                onRemove = {
                                    mutate(group, HealthEditRepeatOperation.Remove, rowIndex)
                                }
                            )
                        }
                    }
                    item(key = "${group.id}-add") {
                        val canAdd = rows.size < group.maximumItems
                        Button(
                            onClick = { mutate(group, HealthEditRepeatOperation.Add) },
                            enabled = canAdd,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = EditorCard,
                                contentColor = AppColors.Health.AddAction,
                                disabledContainerColor = EditorCard,
                                disabledContentColor = EditorMuted
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("+ ${localizedHealthText(LocalizedTextSpec(group.addLabelKey))}")
                        }
                    }
                }
                item { Spacer(Modifier.height(32.dp)) }
            }
        }
        form.fields.firstOrNull { it.id == selectedChoiceFieldId }?.let { field ->
            ChoiceSelectionDialog(
                title = localizedHealthText(LocalizedTextSpec(field.labelKey, field.labelArguments)),
                field = field,
                value = values[field.id].orEmpty(),
                onDismiss = { selectedChoiceFieldId = null },
                onSelect = {
                    values[field.id] = it
                    selectedChoiceFieldId = null
                }
            )
        }
    }
}

@Composable
private fun RepeatGroupEditor(
    group: HealthEditRepeatGroup,
    rowIndex: Int,
    fields: List<HealthEditField>,
    values: Map<String, String>,
    canRemove: Boolean,
    onValueChange: (String, String) -> Unit,
    onRequestChoice: (String) -> Unit,
    onRemove: () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(10.dp),
        modifier = Modifier
            .fillMaxWidth()
            .background(EditorCard, RoundedCornerShape(12.dp))
            .padding(12.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                localizedHealthText(
                    LocalizedTextSpec(group.itemLabelKey, listOf((rowIndex + 1).toString()))
                ),
                color = AppColors.Core.White,
                fontSize = 15.sp,
                modifier = Modifier.weight(1f)
            )
            if (canRemove) {
                Text(
                    localizedHealthText(LocalizedTextSpec("health_edit_remove_item")),
                    color = AppColors.Health.Action,
                    fontSize = 13.sp,
                    modifier = Modifier.clickable(onClick = onRemove).padding(8.dp)
                )
            }
        }
        fields.forEach { field ->
            EditField(
                field = field,
                value = values[field.id].orEmpty(),
                onValueChange = { onValueChange(field.id, it) },
                onRequestChoice = { onRequestChoice(field.id) }
            )
        }
    }
}

@Composable
private fun EditField(
    field: HealthEditField,
    value: String,
    onValueChange: (String) -> Unit,
    onRequestChoice: () -> Unit
) {
    val label = localizedHealthText(LocalizedTextSpec(field.labelKey, field.labelArguments))
    if (field.type == HealthEditFieldType.Choice) {
        val current = field.options.firstOrNull { it.value == value } ?: field.options.firstOrNull()
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(EditorCard, RoundedCornerShape(10.dp))
                .clickable(onClick = onRequestChoice)
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(label, color = EditorMuted, modifier = Modifier.weight(1f))
            Text(
                current?.let {
                    localizedHealthText(LocalizedTextSpec(it.labelKey))
                }.orEmpty(),
                color = AppColors.Health.Action
            )
            AppImage(
                asset = AppImages.Health.ChoiceChevron,
                contentDescription = null,
                colorFilter = ColorFilter.tint(AppColors.Health.Action),
                modifier = Modifier
                    .padding(start = 6.dp)
                    .size(14.dp)
                    .rotate(90f)
            )
        }
    } else {
        val keyboardType = when (field.type) {
            HealthEditFieldType.Integer -> KeyboardType.Number
            HealthEditFieldType.Decimal -> KeyboardType.Decimal
            else -> KeyboardType.Text
        }
        Column(
            verticalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier
                .fillMaxWidth()
                .background(EditorCard, RoundedCornerShape(10.dp))
                .padding(horizontal = 14.dp, vertical = 10.dp)
        ) {
            Text(label, color = EditorMuted, fontSize = 13.sp)
            OutlinedTextField(
                value = value,
                onValueChange = onValueChange,
                keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = AppColors.Core.White,
                    unfocusedTextColor = AppColors.Core.White,
                    cursorColor = AppColors.Health.Action,
                    focusedBorderColor = AppColors.Health.Action,
                    unfocusedBorderColor = EditorMuted
                ),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun ChoiceSelectionDialog(
    title: String,
    field: HealthEditField,
    value: String,
    onDismiss: () -> Unit,
    onSelect: (String) -> Unit
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Core.Black.copy(alpha = 0.62f))
            .clickable(onClick = onDismiss)
            .padding(horizontal = 28.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(EditorCard, RoundedCornerShape(16.dp))
                .clickable(onClick = {})
        ) {
            Text(
                title,
                color = AppColors.Core.White,
                fontSize = 17.sp,
                modifier = Modifier.padding(horizontal = 20.dp, vertical = 18.dp)
            )
            LazyColumn(Modifier.fillMaxWidth().heightIn(max = 420.dp)) {
                items(field.options, key = { it.value }) { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(option.value) }
                            .padding(horizontal = 20.dp, vertical = 15.dp)
                    ) {
                        Text(
                            localizedHealthText(LocalizedTextSpec(option.labelKey)),
                            color = AppColors.Core.White,
                            fontSize = 16.sp,
                            modifier = Modifier.weight(1f)
                        )
                        if (option.value == value) {
                            AppImage(
                                asset = AppImages.Health.ChoiceCheck,
                                contentDescription = null,
                                colorFilter = ColorFilter.tint(AppColors.Health.Action),
                                modifier = Modifier.size(18.dp)
                            )
                        }
                    }
                }
            }
            Text(
                stringResource(R.string.common_cancel),
                color = AppColors.Health.Action,
                fontSize = 15.sp,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onDismiss)
                    .padding(16.dp)
            )
        }
    }
}

@Composable
private fun EditorHeader(
    title: String,
    onBack: () -> Unit,
    action: String,
    onAction: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxWidth().height(62.dp).padding(horizontal = 8.dp)
    ) {
        Box(
            contentAlignment = Alignment.CenterStart,
            modifier = Modifier
                .align(Alignment.CenterStart)
                .width(100.dp)
                .height(48.dp)
                .clickable(onClick = onBack)
        ) {
            Text("‹", color = AppColors.Core.White, fontSize = 36.sp)
        }
        Text(
            title,
            color = AppColors.Core.White,
            fontSize = 18.sp,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.align(Alignment.Center).padding(horizontal = 100.dp)
        )
        Text(
            action,
            color = AppColors.Health.Action,
            fontSize = 14.sp,
            textAlign = TextAlign.End,
            maxLines = 1,
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .clickable(onClick = onAction)
                .padding(horizontal = 8.dp, vertical = 14.dp)
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000, locale = "zh")
@Composable
private fun NormalDataEditorOverviewPreview() {
    DemoTheme {
        NormalDataEditorOverview(
            viewModel = HealthDashboardViewModel(LoginViewModel().healthStore),
            onBack = {},
            onOpenSection = {}
        )
    }
}
