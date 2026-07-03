package com.example.demo.login.verify

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.login.AuthMode
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.AuthTitleSize
import com.example.demo.login.components.AuthTitleTopPadding
import com.example.demo.login.components.CorosMuted
import com.example.demo.login.components.CorosRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.AuthBlackPage
import com.example.demo.login.components.BlockingLoadingOverlay
import com.example.demo.login.components.CodeBoxes
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.UnavailableFeatureDialog
import com.example.demo.login.components.VerifyTargetKind
import com.example.demo.login.components.verifyCodeMessage
import com.example.demo.ui.theme.DemoTheme
import androidx.compose.material3.Text
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.milliseconds

@Composable
fun VerifyCodeScreen(
    account: String,
    targetKind: VerifyTargetKind,
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onCodeVerified: () -> Unit
) {
    var code by rememberSaveable(account, targetKind) { mutableStateOf("") }
    var countdown by rememberSaveable(account, targetKind) { mutableIntStateOf(60) }
    var resendRound by rememberSaveable(account, targetKind) { mutableIntStateOf(0) }
    var resendLoading by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var unavailableDialogVisible by rememberSaveable { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(resendRound) {
        countdown = 60
        while (countdown > 0) {
            delay(1000.milliseconds)
            countdown -= 1
        }
    }

    LaunchedEffect(code) {
        if (code.length == 4) {
            delay(120.milliseconds)
            val validationMessage = viewModel.validateVerifyCode(code)
            if (validationMessage != null) {
                localError = validationMessage
                return@LaunchedEffect
            }
            val message = viewModel.verifyCodeMessage(account, code)
            if (message == null) {
                viewModel.onModeChanged(AuthMode.Register)
                viewModel.onVerifyCodeChanged(code)
                onCodeVerified()
            } else {
                localError = message
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        AuthBlackPage(onBack = onBack, showFeedback = false) {
            Text(
                text = "输入验证码",
                color = CorosWhite,
                fontSize = AuthTitleSize,
                fontWeight = FontWeight.Light,
                modifier = Modifier.padding(top = AuthTitleTopPadding)
            )
            Spacer(modifier = Modifier.height(14.dp))
            Text(
                text = verifyCodeMessage(account, targetKind),
                color = Color(0xFFD8D8DD),
                fontSize = 16.sp,
                lineHeight = 24.sp
            )
            Spacer(modifier = Modifier.height(56.dp))
            CodeBoxes(
                code = code,
                hasError = !localError.isNullOrBlank(),
                onCodeChanged = {
                    code = viewModel.normalizeVerifyCodeInput(it)
                    localError = null
                }
            )
            ErrorText(localError)
            Spacer(modifier = Modifier.height(58.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (countdown > 0) {
                    Text(text = "重新发送", color = CorosMuted, fontSize = 16.sp)
                    Text(text = "（${countdown}s）", color = CorosRed, fontSize = 16.sp)
                } else {
                    Text(
                        text = "获取验证码",
                        color = CorosRed,
                        fontSize = 16.sp,
                        modifier = Modifier.clickable {
                            coroutineScope.launch {
                                resendLoading = true
                                delay(650.milliseconds)
                                val message = viewModel.requestResentVerifyCodeMessage(account)
                                if (message == null) {
                                    code = ""
                                    localError = null
                                    resendRound += 1
                                } else {
                                    localError = message
                                }
                                resendLoading = false
                            }
                        }
                    )
                }
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = "收不到验证码?",
                    color = CorosMuted,
                    fontSize = 16.sp,
                    modifier = Modifier.clickable { unavailableDialogVisible = true }
                )
            }
            Spacer(modifier = Modifier.weight(1f))
        }
        if (resendLoading) {
            BlockingLoadingOverlay()
        }
    }

    if (unavailableDialogVisible) {
        UnavailableFeatureDialog(onDismiss = { unavailableDialogVisible = false })
    }
}

@Preview(showBackground = true)
@Composable
private fun VerifyCodeScreenPreview() {
    DemoTheme {
        VerifyCodeScreen(
            account = "13107012029",
            targetKind = VerifyTargetKind.Phone,
            viewModel = LoginViewModel(),
            onBack = {},
            onCodeVerified = {}
        )
    }
}
