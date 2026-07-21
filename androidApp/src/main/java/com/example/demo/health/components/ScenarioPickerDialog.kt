package com.example.demo.health

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.demo.R
import com.example.demo.common.health.HealthMockScenario
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme

private val CardBlack = AppColors.Health.Card
private val Muted = AppColors.Health.Muted

@Composable
fun ScenarioPickerDialog(
    currentScenario: HealthMockScenario,
    onSelect: (HealthMockScenario) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.health_select_scenario), color = AppColors.Core.White) },
        text = {
            Column {
                HealthMockScenario.entries.forEach { scenario ->
                    Row(
                        modifier = Modifier.fillMaxWidth().clickable { onSelect(scenario) }.padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = scenario == currentScenario,
                            onClick = { onSelect(scenario) },
                            colors = RadioButtonDefaults.colors(selectedColor = AppColors.Health.Steps, unselectedColor = Muted)
                        )
                        Spacer(Modifier.width(8.dp))
                        Text(scenario.displayName(), color = AppColors.Core.White, fontSize = AppTypography.Action)
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(stringResource(R.string.common_cancel), color = AppColors.Health.Steps) } },
        containerColor = CardBlack
    )
}

@Composable
fun HealthMockScenario.displayName() = stringResource(when (this) {
    HealthMockScenario.Normal -> R.string.health_scenario_normal
    HealthMockScenario.PartialMissing -> R.string.health_scenario_partial_missing
    HealthMockScenario.AllEmpty -> R.string.health_scenario_all_empty
    HealthMockScenario.Abnormal -> R.string.health_scenario_abnormal
    HealthMockScenario.ReadFailure -> R.string.health_scenario_read_failure
})

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun ScenarioPickerDialogPreview() {
    var current by remember { mutableStateOf(HealthMockScenario.Normal) }
    DemoTheme {
        ScenarioPickerDialog(
            currentScenario = current,
            onSelect = { current = it },
            onDismiss = {}
        )
    }
}
