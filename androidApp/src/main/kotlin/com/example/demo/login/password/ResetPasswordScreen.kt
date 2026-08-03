package com.example.demo.login.password

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.DisabledUnderlineValue
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.UnderlineInput
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.theme.DemoTheme

@Composable
fun ResetPasswordScreen(
    account: String,
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onResetSuccess: () -> Unit
) {
    var newPassword by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }

    fun resetPassword() {
        val validationMessage = viewModel.validateRegisterPassword(newPassword, confirmPassword)
        if (validationMessage != null) {
            localError = validationMessage
            return
        }
        val message = viewModel.resetPasswordMessage(
            account = account,
            newPassword = newPassword
        )
        if (message == null) {
            onResetSuccess()
        } else {
            localError = message
        }
    }

    AuthBlackPage(onBack = onBack, showFeedback = false) {
        Text(
            text = stringResource(R.string.auth_set_new_password),
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(42.dp))
        Text(text = stringResource(R.string.auth_account), color = AppColors.Auth.InputText, fontSize = 14.sp)
        Spacer(modifier = Modifier.height(8.dp))
        DisabledUnderlineValue(
            value = account,
            placeholder = stringResource(R.string.auth_account)
        )
        Spacer(modifier = Modifier.height(42.dp))
        UnderlineInput(
            value = newPassword,
            placeholder = stringResource(R.string.auth_new_password_placeholder),
            keyboardType = KeyboardType.Password,
            isPassword = true,
            autoFocus = true,
            onValueChange = {
                newPassword = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(42.dp))
        UnderlineInput(
            value = confirmPassword,
            placeholder = stringResource(R.string.auth_confirm_new_password_placeholder),
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = {
                confirmPassword = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = stringResource(R.string.auth_password_rule), color = AppColors.Auth.InputText, fontSize = 14.sp)
        Spacer(modifier = Modifier.height(72.dp))
        CorosFilledButton(
            text = stringResource(R.string.common_complete),
            color = CorosButtonRed,
            enabled = viewModel.canSubmitResetPassword(newPassword, confirmPassword),
            onClick = { resetPassword() }
        )
        ErrorText(localError)
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Preview(showBackground = true)
@Composable
private fun ResetPasswordScreenPreview() {
    DemoTheme {
        ResetPasswordScreen(
            account = "13107012029",
            viewModel = LoginViewModel(),
            onBack = {},
            onResetSuccess = {}
        )
    }
}
