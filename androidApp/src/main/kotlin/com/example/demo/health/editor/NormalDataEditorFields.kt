package com.example.demo.health.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.health.model.HealthEditField
import com.example.demo.common.health.model.HealthEditFieldType
import com.example.demo.common.health.model.HealthEditRepeatGroup
import com.example.demo.common.health.model.LocalizedTextSpec
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImages
import com.example.demo.health.localizedHealthText

@Composable
internal fun RepeatGroupEditor(
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
internal fun EditField(
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
internal fun ChoiceSelectionDialog(
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
