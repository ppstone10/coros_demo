package com.example.demo.login

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.LoginState
import com.example.demo.common.login.MockResult
import com.example.demo.ui.theme.DemoTheme

private enum class CorosAuthPage {
    Entrance,
    Login,
    PhoneRegister,
    VerifyCode,
    PasswordSetup,
    SignedIn
}

private val CorosRed = Color(0xFFE9003D)
private val CorosButtonRed = Color(0xFFB80035)
private val CorosBlack = Color.Black
private val CorosWhite = Color.White
private val CorosMuted = Color(0xFF8F8F96)
private val CorosLine = Color(0xFF1F1F22)
private val CorosField = Color(0xFF0E0E10)

@Composable
fun LoginScreen(
    modifier: Modifier = Modifier,
    viewModel: LoginViewModel = rememberLoginViewModel()
) {
    val state = viewModel.state
    val snackbarHostState = remember { SnackbarHostState() }
    var page by rememberSaveable {
        mutableStateOf(
            if (state.isLoggedIn && state.currentSession != null) {
                CorosAuthPage.SignedIn
            } else {
                CorosAuthPage.Entrance
            }
        )
    }
    var acceptedTerms by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    var codeInput by rememberSaveable { mutableStateOf("") }
    var setupPassword by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }

    LaunchedEffect(viewModel.effect) {
        when (val effect = viewModel.effect) {
            is LoginEffect.AuthSucceeded -> {
                if (effect.mode == AuthMode.Register) {
                    viewModel.clearSessionSilently()
                    acceptedTerms = false
                    setupPassword = ""
                    confirmPassword = ""
                    page = CorosAuthPage.Login
                } else {
                    page = CorosAuthPage.SignedIn
                }
                localError = null
                viewModel.onEffectConsumed()
                snackbarHostState.showSnackbar(
                    if (effect.mode == AuthMode.Register) "注册成功" else "登录成功"
                )
            }

            is LoginEffect.NavigateHome -> {
                page = CorosAuthPage.SignedIn
                viewModel.onEffectConsumed()
                snackbarHostState.showSnackbar("登录成功")
            }

            LoginEffect.LoggedOut -> {
                page = CorosAuthPage.Entrance
                acceptedTerms = false
                viewModel.onEffectConsumed()
                snackbarHostState.showSnackbar("已退出登录")
            }

            LoginEffect.SessionExpired -> {
                page = CorosAuthPage.Login
                viewModel.onEffectConsumed()
                snackbarHostState.showSnackbar("会话已失效，请重新登录")
            }

            is LoginEffect.ShowMessage -> {
                snackbarHostState.showSnackbar(effect.message)
                viewModel.onEffectConsumed()
            }

            null -> Unit
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = CorosBlack,
        modifier = modifier.fillMaxSize()
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .background(CorosBlack)
        ) {
            when (page) {
                CorosAuthPage.Entrance -> EntrancePage(
                    onRegisterClick = {
                        viewModel.onModeChanged(AuthMode.Register)
                        localError = null
                        page = CorosAuthPage.PhoneRegister
                    },
                    onLoginClick = {
                        viewModel.onModeChanged(AuthMode.Login)
                        localError = null
                        page = CorosAuthPage.Login
                    }
                )

                CorosAuthPage.Login -> LoginPage(
                    state = state,
                    acceptedTerms = acceptedTerms,
                    error = localError ?: state.errorMessage,
                    onBack = {
                        localError = null
                        page = CorosAuthPage.Entrance
                    },
                    onAccountChanged = {
                        viewModel.onUsernameChanged(it)
                        localError = null
                    },
                    onPasswordChanged = {
                        viewModel.onPasswordChanged(it)
                        localError = null
                    },
                    onTermsClick = {
                        acceptedTerms = !acceptedTerms
                        localError = null
                    },
                    onSubmit = {
                        if (!acceptedTerms) {
                            localError = "请先阅读并同意隐私政策和服务条款"
                        } else {
                            viewModel.onModeChanged(AuthMode.Login)
                            viewModel.onSubmit()
                        }
                    }
                )

                CorosAuthPage.PhoneRegister -> PhoneRegisterPage(
                    state = state,
                    acceptedTerms = acceptedTerms,
                    error = localError ?: state.errorMessage,
                    onBack = {
                        localError = null
                        page = CorosAuthPage.Entrance
                    },
                    onPhoneChanged = {
                        viewModel.onUsernameChanged(it)
                        localError = null
                    },
                    onTermsClick = {
                        acceptedTerms = !acceptedTerms
                        localError = null
                    },
                    onSendCode = {
                        when {
                            state.account.length != 11 -> localError = "请输入11位手机号"
                            !acceptedTerms -> localError = "请先阅读并同意隐私政策和服务条款"
                            else -> {
                                when (val result = viewModel.requestVerifyCode(state.account)) {
                                    is MockResult.Success -> {
                                        viewModel.onModeChanged(AuthMode.Register)
                                        viewModel.onDisplayNameChanged(state.account)
                                        codeInput = ""
                                        localError = null
                                        page = CorosAuthPage.VerifyCode
                                    }

                                    is MockResult.Failure -> localError = result.error.message
                                }
                            }
                        }
                    },
                    onEmailRegister = {
                        localError = "当前先实现手机号注册"
                    }
                )

                CorosAuthPage.VerifyCode -> VerifyCodePage(
                    phone = state.account,
                    code = codeInput,
                    error = localError ?: state.errorMessage,
                    isLoading = state.isLoading,
                    onBack = {
                        localError = null
                        page = CorosAuthPage.PhoneRegister
                    },
                    onCodeChanged = {
                        codeInput = it.filter(Char::isDigit).take(4)
                        localError = null
                    },
                    onSubmit = {
                        if (codeInput.length < 4) {
                            localError = "请输入验证码"
                        } else {
                            when (val result = viewModel.verifyCode(state.account, codeInput)) {
                                is MockResult.Success -> {
                                    viewModel.onVerifyCodeChanged(codeInput)
                                    setupPassword = ""
                                    confirmPassword = ""
                                    localError = null
                                    page = CorosAuthPage.PasswordSetup
                                }

                                is MockResult.Failure -> localError = result.error.message
                            }
                        }
                    }
                )

                CorosAuthPage.PasswordSetup -> PasswordSetupPage(
                    password = setupPassword,
                    confirmPassword = confirmPassword,
                    error = localError ?: state.errorMessage,
                    isLoading = state.isLoading,
                    onBack = {
                        localError = null
                        page = CorosAuthPage.VerifyCode
                    },
                    onPasswordChanged = {
                        setupPassword = it
                        localError = null
                    },
                    onConfirmPasswordChanged = {
                        confirmPassword = it
                        localError = null
                    },
                    onRegister = {
                        when {
                            setupPassword.length !in 6..20 -> localError = "密码需要为6-20位"
                            setupPassword != confirmPassword -> localError = "两次输入的密码不一致"
                            else -> {
                                viewModel.onModeChanged(AuthMode.Register)
                                viewModel.onPasswordChanged(setupPassword)
                                viewModel.onVerifyCodeChanged(codeInput)
                                viewModel.onSubmit()
                            }
                        }
                    }
                )

                CorosAuthPage.SignedIn -> SignedInPage(
                    state = state,
                    onLogout = viewModel::onLogout
                )
            }
        }
    }
}

@Composable
private fun rememberLoginViewModel(): LoginViewModel {
    val context = LocalContext.current.applicationContext
    return remember(context) { LoginViewModel.create(context) }
}

@Composable
private fun EntrancePage(
    onRegisterClick: () -> Unit,
    onLoginClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF111111))
    ) {
        CorosLogo(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 84.dp)
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 30.dp)
                .padding(bottom = 82.dp),
            verticalArrangement = Arrangement.spacedBy(28.dp)
        ) {
            CorosFilledButton(
                text = "注册",
                color = CorosRed,
                onClick = onRegisterClick
            )
            CorosFilledButton(
                text = "登录",
                color = Color.White.copy(alpha = 0.18f),
                onClick = onLoginClick
            )
        }
    }
}

@Composable
private fun LoginPage(
    state: LoginState,
    acceptedTerms: Boolean,
    error: String?,
    onBack: () -> Unit,
    onAccountChanged: (String) -> Unit,
    onPasswordChanged: (String) -> Unit,
    onTermsClick: () -> Unit,
    onSubmit: () -> Unit
) {
    val canLogin = state.account.isNotBlank() &&
        state.password.length >= 6 &&
        acceptedTerms &&
        !state.isLoading

    AuthBlackPage(onBack = onBack, showFeedback = true) {
        Text(
            text = "账号登录",
            color = CorosWhite,
            fontSize = 38.sp,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = 56.dp)
        )
        Spacer(modifier = Modifier.height(76.dp))
        UnderlineInput(
            value = state.account,
            placeholder = "输入手机号或邮箱",
            keyboardType = KeyboardType.Email,
            onValueChange = onAccountChanged
        )
        Spacer(modifier = Modifier.height(28.dp))
        UnderlineInput(
            value = state.password,
            placeholder = "密码",
            keyboardType = KeyboardType.Password,
            visualTransformation = PasswordVisualTransformation(),
            onValueChange = onPasswordChanged
        )
        Spacer(modifier = Modifier.height(82.dp))
        AgreementRow(accepted = acceptedTerms, onClick = onTermsClick)
        Spacer(modifier = Modifier.height(22.dp))
        CorosFilledButton(
            text = "登录",
            color = CorosButtonRed,
            enabled = canLogin,
            isLoading = state.isLoading,
            onClick = onSubmit
        )
        ErrorText(error)
        Spacer(modifier = Modifier.height(24.dp))
        Text(text = "忘记密码?", color = CorosMuted, fontSize = 20.sp)
        Spacer(modifier = Modifier.weight(1f))
        ThirdPartyArea()
        Text(
            text = "V4.8.1.14",
            color = CorosMuted,
            fontSize = 20.sp,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 22.dp, bottom = 12.dp),
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun PhoneRegisterPage(
    state: LoginState,
    acceptedTerms: Boolean,
    error: String?,
    onBack: () -> Unit,
    onPhoneChanged: (String) -> Unit,
    onTermsClick: () -> Unit,
    onSendCode: () -> Unit,
    onEmailRegister: () -> Unit
) {
    val canSendCode = state.account.length == 11 &&
        acceptedTerms &&
        !state.isLoading

    AuthBlackPage(onBack = onBack, showFeedback = true) {
        Text(
            text = "手机号注册",
            color = CorosWhite,
            fontSize = 38.sp,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = 56.dp)
        )
        Spacer(modifier = Modifier.height(78.dp))
        PhoneInput(value = state.account, onValueChange = onPhoneChanged)
        Spacer(modifier = Modifier.height(66.dp))
        AgreementRow(accepted = acceptedTerms, onClick = onTermsClick)
        Spacer(modifier = Modifier.height(42.dp))
        CorosFilledButton(
            text = "发送验证码",
            color = CorosButtonRed,
            enabled = canSendCode,
            isLoading = state.isLoading,
            onClick = onSendCode
        )
        ErrorText(error)
        Text(
            text = "邮箱注册",
            color = CorosRed,
            fontSize = 22.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 26.dp)
                .clickable(onClick = onEmailRegister)
        )
        Spacer(modifier = Modifier.weight(1f))
        HomeIndicator()
    }
}

@Composable
private fun VerifyCodePage(
    phone: String,
    code: String,
    error: String?,
    isLoading: Boolean,
    onBack: () -> Unit,
    onCodeChanged: (String) -> Unit,
    onSubmit: () -> Unit
) {
    AuthBlackPage(onBack = onBack, showFeedback = false) {
        Text(
            text = "输入验证码",
            color = CorosWhite,
            fontSize = 38.sp,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = 56.dp)
        )
        Spacer(modifier = Modifier.height(20.dp))
        Text(
            text = "验证码已发送至你的手机+86-$phone，有效期10分钟",
            color = Color(0xFFD8D8DD),
            fontSize = 20.sp,
            lineHeight = 28.sp
        )
        Spacer(modifier = Modifier.height(56.dp))
        CodeBoxes(code = code, onCodeChanged = onCodeChanged)
        Spacer(modifier = Modifier.height(58.dp))
        Row {
            Text(text = "重新发送", color = CorosMuted, fontSize = 20.sp)
            Text(text = "（55s）", color = CorosRed, fontSize = 20.sp)
        }
        ErrorText(error)
        Spacer(modifier = Modifier.height(36.dp))
        CorosFilledButton(
            text = "完成",
            color = CorosButtonRed,
            enabled = !isLoading,
            isLoading = isLoading,
            onClick = onSubmit
        )
        Spacer(modifier = Modifier.weight(1f))
        HomeIndicator()
    }
}

@Composable
private fun PasswordSetupPage(
    password: String,
    confirmPassword: String,
    error: String?,
    isLoading: Boolean,
    onBack: () -> Unit,
    onPasswordChanged: (String) -> Unit,
    onConfirmPasswordChanged: (String) -> Unit,
    onRegister: () -> Unit
) {
    val hasLetter = password.any { it.isLetter() }
    val hasDigit = password.any { it.isDigit() }
    val canRegister = password.length in 6..20 &&
        hasLetter &&
        hasDigit &&
        confirmPassword == password &&
        !isLoading

    AuthBlackPage(onBack = onBack, showFeedback = false) {
        Text(
            text = "设置登录密码",
            color = CorosWhite,
            fontSize = 38.sp,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = 56.dp)
        )
        Spacer(modifier = Modifier.height(82.dp))
        UnderlineInput(
            value = password,
            placeholder = "输入新的密码",
            keyboardType = KeyboardType.Password,
            visualTransformation = PasswordVisualTransformation(),
            onValueChange = { onPasswordChanged(it.take(20)) }
        )
        Spacer(modifier = Modifier.height(52.dp))
        UnderlineInput(
            value = confirmPassword,
            placeholder = "再次输入密码",
            keyboardType = KeyboardType.Password,
            visualTransformation = PasswordVisualTransformation(),
            onValueChange = { onConfirmPasswordChanged(it.take(20)) }
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = "6-20位必须包含字母和数字", color = Color(0xFFD8D8DD), fontSize = 16.sp)
        Spacer(modifier = Modifier.height(80.dp))
        CorosFilledButton(
            text = "注册",
            color = CorosButtonRed,
            enabled = canRegister,
            isLoading = isLoading,
            onClick = onRegister
        )
        ErrorText(error)
        Spacer(modifier = Modifier.weight(1f))
        HomeIndicator()
    }
}

@Composable
private fun SignedInPage(
    state: LoginState,
    onLogout: () -> Unit
) {
    AuthBlackPage(onBack = {}, showFeedback = false) {
        CorosLogo(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 80.dp)
        )
        Spacer(modifier = Modifier.height(96.dp))
        Text(
            text = "欢迎使用 COROS\n${state.currentSession?.account.orEmpty()}",
            color = CorosWhite,
            fontSize = 26.sp,
            lineHeight = 36.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(48.dp))
        CorosFilledButton(text = "退出登录", color = CorosButtonRed, onClick = onLogout)
    }
}

@Composable
private fun AuthBlackPage(
    onBack: () -> Unit,
    showFeedback: Boolean,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(CorosBlack)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .heightIn(min = 812.dp)
            .padding(horizontal = 30.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "‹",
                color = CorosWhite,
                fontSize = 44.sp,
                modifier = Modifier.clickable(onClick = onBack)
            )
            Spacer(modifier = Modifier.weight(1f))
            if (showFeedback) {
                Text(text = "◔ 建议&反馈", color = CorosMuted, fontSize = 18.sp)
            }
        }
        content()
    }
}

@Composable
private fun CorosLogo(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Image(
            painter = painterResource(id = R.drawable.logo_coros),
            contentDescription = "COROS Logo",
            modifier = Modifier
                .width(260.dp)
                .height(48.dp),
            contentScale = ContentScale.Fit
        )
    }
}

@Composable
private fun UnderlineInput(
    value: String,
    placeholder: String,
    onValueChange: (String) -> Unit,
    keyboardType: KeyboardType,
    visualTransformation: VisualTransformation = VisualTransformation.None
) {
    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        visualTransformation = visualTransformation,
        textStyle = TextStyle(color = CorosWhite, fontSize = 21.sp),
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp),
        decorationBox = { innerTextField ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .border(width = 0.dp, color = Color.Transparent)
            ) {
                if (value.isBlank()) {
                    Text(
                        text = placeholder,
                        color = CorosMuted,
                        fontSize = 21.sp,
                        modifier = Modifier.align(Alignment.CenterStart)
                    )
                }
                Box(modifier = Modifier.align(Alignment.CenterStart)) {
                    innerTextField()
                }
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(CorosLine)
                )
            }
        }
    )
}

@Composable
private fun PhoneInput(
    value: String,
    onValueChange: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(54.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = "+86", color = CorosWhite, fontSize = 22.sp)
        Spacer(modifier = Modifier.width(24.dp))
        BasicTextField(
            value = value,
            onValueChange = { onValueChange(it.filter(Char::isDigit).take(11)) },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            textStyle = TextStyle(color = CorosWhite, fontSize = 22.sp),
            modifier = Modifier.weight(1f),
            decorationBox = { innerTextField ->
                Box(contentAlignment = Alignment.CenterStart) {
                    if (value.isBlank()) {
                        Text(text = "输入手机号", color = CorosMuted, fontSize = 22.sp)
                    }
                    innerTextField()
                }
            }
        )
    }
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(CorosLine)
    )
}

@Composable
private fun AgreementRow(
    accepted: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        verticalAlignment = Alignment.Top
    ) {
        AgreementCheck(
            accepted = accepted,
            modifier = Modifier
                .padding(top = 6.dp)
                .size(18.dp)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = buildAnnotatedString {
                append("我已阅读并同意COROS的 ")
                pushStyle(SpanStyle(color = CorosRed))
                append("《隐私政策》")
                pop()
                append(" 和 ")
                pushStyle(SpanStyle(color = CorosRed))
                append("《服务条款》")
                pop()
            },
            color = CorosWhite,
            fontSize = 20.sp,
            lineHeight = 30.sp,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun AgreementCheck(
    accepted: Boolean,
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val strokeWidth = 1.dp.toPx()
        drawCircle(
            color = if (accepted) CorosRed else Color.Transparent,
            radius = size.minDimension / 2f - strokeWidth / 2f
        )
        drawCircle(
            color = CorosWhite,
            radius = size.minDimension / 2f - strokeWidth / 2f,
            style = Stroke(width = strokeWidth)
        )
        if (accepted) {
            val checkStroke = 2.dp.toPx()
            drawLine(
                color = CorosWhite,
                start = Offset(size.width * 0.28f, size.height * 0.52f),
                end = Offset(size.width * 0.43f, size.height * 0.68f),
                strokeWidth = checkStroke
            )
            drawLine(
                color = CorosWhite,
                start = Offset(size.width * 0.43f, size.height * 0.68f),
                end = Offset(size.width * 0.74f, size.height * 0.34f),
                strokeWidth = checkStroke
            )
        }
    }
}

@Composable
private fun CorosFilledButton(
    text: String,
    color: Color,
    onClick: () -> Unit,
    enabled: Boolean = true,
    isLoading: Boolean = false
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        colors = ButtonDefaults.buttonColors(
            containerColor = color,
            disabledContainerColor = color.copy(alpha = 0.45f)
        ),
        shape = RoundedCornerShape(9.dp),
        modifier = Modifier
            .fillMaxWidth()
            .height(66.dp)
    ) {
        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.size(22.dp), color = CorosWhite, strokeWidth = 2.dp)
        } else {
            Text(text = text, color = CorosWhite, fontSize = 24.sp)
        }
    }
}

@Composable
private fun CodeBoxes(
    code: String,
    onCodeChanged: (String) -> Unit
) {
    BasicTextField(
        value = code,
        onValueChange = onCodeChanged,
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
        textStyle = TextStyle(color = Color.Transparent),
        modifier = Modifier.fillMaxWidth(),
        decorationBox = { innerTextField ->
            Box(modifier = Modifier.fillMaxWidth()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(28.dp)
                ) {
                    repeat(4) { index ->
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(12.dp))
                                .background(CorosField)
                                .border(2.dp, Color(0xFF3A3A3D), RoundedCornerShape(12.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            val digit = code.getOrNull(index)?.toString()
                            if (digit != null) {
                                Text(text = digit, color = CorosWhite, fontSize = 30.sp)
                            } else if (index == code.length) {
                                Box(
                                    modifier = Modifier
                                        .width(2.dp)
                                        .height(28.dp)
                                        .background(CorosRed)
                                )
                            }
                        }
                    }
                }
                Box(
                    modifier = Modifier
                        .matchParentSize()
                        .background(Color.Transparent)
                ) {
                    innerTextField()
                }
            }
        }
    )
}

@Composable
private fun ThirdPartyArea() {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.size(width = 140.dp, height = 1.dp).background(CorosLine))
            Text(text = "第三方账号", color = CorosMuted, fontSize = 20.sp, modifier = Modifier.padding(horizontal = 12.dp))
            Box(modifier = Modifier.size(width = 140.dp, height = 1.dp).background(CorosLine))
        }
        Spacer(modifier = Modifier.height(28.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(54.dp)) {
            ThirdPartyCircle(text = "☘")
            ThirdPartyCircle(text = "···")
        }
    }
}

@Composable
private fun ThirdPartyCircle(text: String) {
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(CircleShape)
            .border(1.dp, Color(0xFF303036), CircleShape),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = CorosWhite, fontSize = 24.sp)
    }
}

@Composable
private fun HomeIndicator() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .width(150.dp)
                .height(5.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(CorosWhite)
        )
    }
}

@Composable
private fun ErrorText(message: String?) {
    if (!message.isNullOrBlank()) {
        Text(
            text = message,
            color = CorosRed,
            fontSize = 15.sp,
            modifier = Modifier.padding(top = 10.dp)
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun LoginScreenPreview() {
    DemoTheme {
        LoginScreen(viewModel = LoginViewModel())
    }
}
