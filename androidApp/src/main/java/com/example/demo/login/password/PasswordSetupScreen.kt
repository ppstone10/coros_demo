package com.example.demo.login.password

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.UnderlineInput
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text

@Composable
fun PasswordSetupScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onRegisterSuccess: () -> Unit
) {
    val state = viewModel.state
    var password by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }

    fun register() {
        val message = viewModel.validateRegisterPassword(password, confirmPassword)
        if (message != null) {
            localError = message
        } else {
            viewModel.onModeChanged(AuthMode.Register)
            viewModel.onPasswordChanged(password)
            viewModel.onSubmit()
        }
    }

    LaunchedEffect(viewModel.effect) {
        when (viewModel.effect) {
            is LoginEffect.AuthSucceeded -> {
                viewModel.clearSessionSilently()
                onRegisterSuccess()
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ShowMessage -> {
                localError = (viewModel.effect as LoginEffect.ShowMessage).message
                viewModel.onEffectConsumed()
            }
            else -> viewModel.onEffectConsumed()
        }
    }

    AuthBlackPage(onBack = onBack, showFeedback = false) {
        Text(
            text = "设置登录密码",
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        UnderlineInput(
            value = password,
            placeholder = "输入新的密码",
            keyboardType = KeyboardType.Password,
            isPassword = true,
            autoFocus = true,
            onValueChange = {
                password = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(48.dp))
        UnderlineInput(
            value = confirmPassword,
            placeholder = "再次输入密码",
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = {
                confirmPassword = viewModel.normalizePasswordInput(it)
                localError = null
            }
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = "6-20位必须包含字母和数字", color = Color(0xFFD8D8DD), fontSize = 14.sp)
        Spacer(modifier = Modifier.height(80.dp))
        CorosFilledButton(
            text = "注册",
            color = CorosButtonRed,
            enabled = viewModel.canRegisterWithPassword(password, confirmPassword),
            isLoading = state.isLoading,
            onClick = { register() }
        )
        ErrorText(localError ?: state.errorMessage)
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Preview(showBackground = true)
@Composable
private fun PasswordSetupScreenPreview() {
    DemoTheme {
        PasswordSetupScreen(
            viewModel = LoginViewModel(),
            onBack = {},
            onRegisterSuccess = {}
        )
    }
}
