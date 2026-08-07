package com.example.demo.health.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.health.model.HealthEditValidationIssue
import com.example.demo.common.health.model.HealthEditValidationReason
import com.example.demo.common.health.model.LocalizedTextSpec
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppSpacing
import com.example.demo.health.localizedHealthText

@Composable
internal fun SourceNotice(messageKey: String) {
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
internal fun validationIssueText(issue: HealthEditValidationIssue): String {
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
internal fun EditorHeader(
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
