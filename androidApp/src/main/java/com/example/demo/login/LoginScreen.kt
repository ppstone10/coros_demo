package com.example.demo.login

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.graphics.Color as AndroidColor
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
import androidx.compose.foundation.layout.WindowInsets
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
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.VideoView
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.withLink
import androidx.core.view.WindowInsetsControllerCompat
import com.example.demo.R
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.LoginState
import com.example.demo.ui.theme.DemoTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.roundToInt
import kotlin.time.Duration.Companion.milliseconds
import androidx.core.net.toUri

private enum class CorosAuthPage {
    Entrance,
    Login,
    PhoneRegister,
    EmailRegister,
    VerifyCode,
    PasswordSetup,
    PrivacyPolicy,
    ServiceTerms,
    SignedIn
}

private enum class VerifyTargetKind {
    Phone,
    Email
}

private enum class TermsPromptAction {
    Login,
    PhoneCode,
    EmailCode
}

private val CorosRed = Color(0xFFE9003D)
private val CorosButtonRed = Color(0xFFB80035)
private val CorosBlack = Color.Black
private val CorosWhite = Color.White
private val CorosMuted = Color(0xFF8F8F96)
private val CorosLine = Color(0xFF1F1F22)
private val AuthTitleTopPadding = 18.dp
private val AuthTitleSize = 32.sp
private val AgreementCheckTouchSize = 18.dp
private val AgreementCheckVisualSize = 10.dp
private val AgreementTextSize = 14.sp
private val AgreementLineHeight = 24.sp
private val RegisterAgreementTopSpacing = 44.dp
private val RegisterActionTopSpacing = 28.dp

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
    var emailInput by rememberSaveable { mutableStateOf("") }
    var setupPassword by rememberSaveable { mutableStateOf("") }
    var confirmPassword by rememberSaveable { mutableStateOf("") }
    var verifyTargetKind by rememberSaveable { mutableStateOf(VerifyTargetKind.Phone) }
    var termsPromptAction by rememberSaveable { mutableStateOf<TermsPromptAction?>(null) }
    var unavailableDialogVisible by rememberSaveable { mutableStateOf(false) }
    var legalReturnPage by rememberSaveable { mutableStateOf(CorosAuthPage.PhoneRegister) }
    val view = LocalView.current

    fun showUnavailableFeature() {
        unavailableDialogVisible = true
    }

    fun openPrivacyPolicy() {
        legalReturnPage = page
        termsPromptAction = null
        page = CorosAuthPage.PrivacyPolicy
    }

    fun openServiceTerms() {
        legalReturnPage = page
        termsPromptAction = null
        page = CorosAuthPage.ServiceTerms
    }

    fun openVerifyPage(account: String, targetKind: VerifyTargetKind) {
        viewModel.onModeChanged(AuthMode.Register)
        viewModel.onUsernameChanged(account)
        viewModel.onDisplayNameChanged(account)
        verifyTargetKind = targetKind
        codeInput = ""
        localError = null
        page = CorosAuthPage.VerifyCode
    }

    fun requestPhoneVerifyCode(skipTerms: Boolean = false) {
        val validationMessage = viewModel.validatePhoneAccount(state.account)
        when {
            validationMessage != null -> localError = validationMessage
            !skipTerms && !acceptedTerms -> termsPromptAction = TermsPromptAction.PhoneCode
            else -> {
                val message = viewModel.requestVerifyCodeMessage(state.account)
                if (message == null) {
                    openVerifyPage(state.account, VerifyTargetKind.Phone)
                } else {
                    localError = message
                }
            }
        }
    }

    fun requestEmailVerifyCode(skipTerms: Boolean = false) {
        val email = viewModel.normalizeEmailInput(emailInput)
        val validationMessage = viewModel.validateEmailAccount(email)
        when {
            validationMessage != null -> localError = validationMessage
            !skipTerms && !acceptedTerms -> termsPromptAction = TermsPromptAction.EmailCode
            else -> {
                val message = viewModel.requestVerifyCodeMessage(email)
                if (message == null) {
                    openVerifyPage(email, VerifyTargetKind.Email)
                } else {
                    localError = message
                }
            }
        }
    }

    fun submitLogin(skipTerms: Boolean = false) {
        if (!skipTerms && !acceptedTerms) {
            termsPromptAction = TermsPromptAction.Login
        } else {
            viewModel.onModeChanged(AuthMode.Login)
            viewModel.onSubmit()
        }
    }

    fun verifyCurrentCode() {
        if (viewModel.validateVerifyCode(codeInput) != null) return
        val message = viewModel.verifyCodeMessage(state.account, codeInput)
        if (message == null) {
            viewModel.onVerifyCodeChanged(codeInput)
            setupPassword = ""
            confirmPassword = ""
            localError = null
            page = CorosAuthPage.PasswordSetup
        } else {
            localError = message
        }
    }

    SideEffect {
        val activity = view.context.findActivity() ?: return@SideEffect
        WindowInsetsControllerCompat(activity.window, view).apply {
            isAppearanceLightStatusBars = page == CorosAuthPage.Entrance
            isAppearanceLightNavigationBars = false
        }
    }

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
        contentWindowInsets = WindowInsets(0.dp),
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
                    canLogin = viewModel.canSubmitLogin(),
                    acceptedTerms = acceptedTerms,
                    error = localError ?: state.errorMessage,
                    onUnavailableClick = ::showUnavailableFeature,
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
                    onPrivacyClick = ::openPrivacyPolicy,
                    onServiceTermsClick = ::openServiceTerms,
                    onSubmit = { submitLogin() }
                )

                CorosAuthPage.PhoneRegister -> PhoneRegisterPage(
                    state = state,
                    canSendCode = viewModel.canRequestPhoneCode(),
                    acceptedTerms = acceptedTerms,
                    error = localError ?: state.errorMessage,
                    onUnavailableClick = ::showUnavailableFeature,
                    onBack = {
                        localError = null
                        page = CorosAuthPage.Entrance
                    },
                    onPhoneChanged = {
                        viewModel.onUsernameChanged(viewModel.normalizePhoneInput(it))
                        localError = null
                    },
                    onTermsClick = {
                        acceptedTerms = !acceptedTerms
                        localError = null
                    },
                    onPrivacyClick = ::openPrivacyPolicy,
                    onServiceTermsClick = ::openServiceTerms,
                    onSendCode = { requestPhoneVerifyCode() },
                    onEmailRegister = {
                        viewModel.onUsernameChanged("")
                        emailInput = ""
                        localError = null
                        page = CorosAuthPage.EmailRegister
                    }
                )

                CorosAuthPage.EmailRegister -> EmailRegisterPage(
                    email = emailInput,
                    canSendCode = viewModel.canRequestEmailCode(emailInput),
                    acceptedTerms = acceptedTerms,
                    error = localError ?: state.errorMessage,
                    onUnavailableClick = ::showUnavailableFeature,
                    onBack = {
                        localError = null
                        page = CorosAuthPage.Entrance
                    },
                    onEmailChanged = {
                        emailInput = viewModel.normalizeEmailInput(it)
                        localError = null
                    },
                    onTermsClick = {
                        acceptedTerms = !acceptedTerms
                        localError = null
                    },
                    onPrivacyClick = ::openPrivacyPolicy,
                    onServiceTermsClick = ::openServiceTerms,
                    onSendCode = { requestEmailVerifyCode() },
                    onPhoneRegister = {
                        viewModel.onUsernameChanged("")
                        localError = null
                        page = CorosAuthPage.PhoneRegister
                    }
                )

                CorosAuthPage.VerifyCode -> VerifyCodePage(
                    account = state.account,
                    targetKind = verifyTargetKind,
                    code = codeInput,
                    error = localError ?: state.errorMessage,
                    onBack = {
                        localError = null
                        page = if (verifyTargetKind == VerifyTargetKind.Email) {
                            CorosAuthPage.EmailRegister
                        } else {
                            CorosAuthPage.PhoneRegister
                        }
                    },
                    onCodeChanged = {
                        codeInput = viewModel.normalizeVerifyCodeInput(it)
                        localError = null
                    },
                    onCodeComplete = ::verifyCurrentCode,
                    onResend = {
                        val message = viewModel.requestResentVerifyCodeMessage(state.account)
                        if (message == null) {
                            codeInput = ""
                            localError = null
                            true
                        } else {
                            localError = message
                            false
                        }
                    },
                    onUnavailableClick = ::showUnavailableFeature
                )

                CorosAuthPage.PasswordSetup -> PasswordSetupPage(
                    password = setupPassword,
                    confirmPassword = confirmPassword,
                    canRegister = viewModel.canRegisterWithPassword(setupPassword, confirmPassword),
                    error = localError ?: state.errorMessage,
                    isLoading = state.isLoading,
                    onBack = {
                        codeInput = ""
                        viewModel.onVerifyCodeChanged("")
                        localError = null
                        page = CorosAuthPage.VerifyCode
                    },
                    onPasswordChanged = {
                        setupPassword = viewModel.normalizePasswordInput(it)
                        localError = null
                    },
                    onConfirmPasswordChanged = {
                        confirmPassword = viewModel.normalizePasswordInput(it)
                        localError = null
                    },
                    onRegister = {
                        val message = viewModel.validateRegisterPassword(setupPassword, confirmPassword)
                        if (message != null) {
                            localError = message
                        } else {
                            viewModel.onModeChanged(AuthMode.Register)
                            viewModel.onPasswordChanged(setupPassword)
                            viewModel.onVerifyCodeChanged(codeInput)
                            viewModel.onSubmit()
                        }
                    }
                )

                CorosAuthPage.SignedIn -> SignedInPage(
                    state = state,
                    onLogout = viewModel::onLogout
                )

                CorosAuthPage.PrivacyPolicy -> LegalDocumentPage(
                    title = "隐私政策",
                    paragraphs = PrivacyPolicyParagraphs,
                    onBack = {
                        localError = null
                        page = legalReturnPage
                    }
                )

                CorosAuthPage.ServiceTerms -> LegalDocumentPage(
                    title = "服务条款",
                    paragraphs = ServiceTermsParagraphs,
                    onBack = {
                        localError = null
                        page = legalReturnPage
                    }
                )
            }

            termsPromptAction?.let { action ->
                TermsConsentSheet(
                    onDismiss = { termsPromptAction = null },
                    onPrivacyClick = ::openPrivacyPolicy,
                    onServiceTermsClick = ::openServiceTerms,
                    onAgree = {
                        acceptedTerms = true
                        termsPromptAction = null
                        when (action) {
                            TermsPromptAction.Login -> submitLogin(skipTerms = true)
                            TermsPromptAction.PhoneCode -> requestPhoneVerifyCode(skipTerms = true)
                            TermsPromptAction.EmailCode -> requestEmailVerifyCode(skipTerms = true)
                        }
                    }
                )
            }

            if (unavailableDialogVisible) {
                UnavailableFeatureDialog(
                    onDismiss = { unavailableDialogVisible = false }
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

private tailrec fun Context.findActivity(): Activity? {
    return when (this) {
        is Activity -> this
        is ContextWrapper -> baseContext.findActivity()
        else -> null
    }
}

private fun verifyCodeMessage(
    account: String,
    targetKind: VerifyTargetKind
): String {
    return if (targetKind == VerifyTargetKind.Email) {
        "验证码已发送至你的邮箱 $account，有效期10分钟"
    } else {
        "验证码已发送至你的手机+86-$account，有效期10分钟"
    }
}

@Composable
private fun TermsConsentSheet(
    onDismiss: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit,
    onAgree: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.78f))
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                .background(Color(0xFF1A1A1B))
                .padding(horizontal = 22.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "×",
                color = CorosWhite,
                fontSize = 34.sp,
                modifier = Modifier
                    .align(Alignment.End)
                    .clickable(onClick = onDismiss)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "阅读并同意以下条款，",
                color = CorosWhite,
                fontSize = 18.sp,
                textAlign = TextAlign.Center
            )
            Row(
                modifier = Modifier.padding(top = 8.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "《隐私政策》",
                    color = CorosRed,
                    fontSize = 18.sp,
                    modifier = Modifier.clickable(onClick = onPrivacyClick)
                )
                Text(text = " 和 ", color = CorosWhite, fontSize = 18.sp)
                Text(
                    text = "《服务条款》",
                    color = CorosRed,
                    fontSize = 18.sp,
                    modifier = Modifier.clickable(onClick = onServiceTermsClick)
                )
            }
            Spacer(modifier = Modifier.height(42.dp))
            CorosFilledButton(
                text = "同意并继续",
                color = CorosRed,
                onClick = onAgree
            )
        }
    }
}

@Composable
private fun UnavailableFeatureDialog(
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.62f))
            .clickable(onClick = onDismiss),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 42.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(Color(0xFF222224))
                .padding(horizontal = 28.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "抱歉，该功能还在实现中",
                color = CorosWhite,
                fontSize = 16.sp,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(20.dp))
            Text(
                text = "知道了",
                color = CorosRed,
                fontSize = 16.sp,
                modifier = Modifier.clickable(onClick = onDismiss)
            )
        }
    }
}

@Composable
private fun BlockingLoadingOverlay() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.72f)),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(96.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(Color(0xFF3A3A3C)),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(36.dp),
                color = Color(0xFFD8D8DD),
                strokeWidth = 4.dp
            )
        }
    }
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
        HomeBackgroundVideo(modifier = Modifier.fillMaxSize())
        CorosLogo(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 62.dp)
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 20.dp)
                .padding(bottom = 60.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            CorosFilledButton(
                text = "注册",
                color = CorosRed,
                buttonHeight = 48.dp,
                textSize = 18.sp,
                onClick = onRegisterClick
            )
            CorosFilledButton(
                text = "登录",
                color = Color.White.copy(alpha = 0.26f),
                buttonHeight = 48.dp,
                textSize = 18.sp,
                onClick = onLoginClick
            )
        }
    }
}

@Composable
private fun LegalDocumentPage(
    title: String,
    paragraphs: List<LegalParagraph>,
    onBack: () -> Unit
) {
    val scrollState = rememberScrollState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(CorosBlack)
            .statusBarsPadding()
            .padding(horizontal = 20.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "‹",
                color = CorosWhite,
                fontSize = 44.sp,
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .clickable(onClick = onBack)
            )
            Text(
                text = title,
                color = CorosWhite,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
        }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(scrollState)
                    .padding(top = 58.dp, bottom = 32.dp, end = 12.dp)
            ) {
                paragraphs.forEachIndexed { index, paragraph ->
                    LegalParagraphText(paragraph = paragraph)
                    if (index != paragraphs.lastIndex) {
                        Spacer(
                            modifier = Modifier.height(
                                if (paragraph.isHeading) 8.dp else 12.dp
                            )
                        )
                    }
                }
            }

            VerticalScrollbar(
                scrollState = scrollState,
                modifier = Modifier
                    .align(Alignment.CenterEnd)
                    .fillMaxHeight()
                    .padding(top = 24.dp, bottom = 24.dp)
            )
        }
    }
}

@Composable
private fun LegalParagraphText(paragraph: LegalParagraph) {
    Text(
        text = buildLegalText(paragraph.text, paragraph.highlights),
        color = if (paragraph.isHeading) CorosWhite else Color(0xFFC9C9CC),
        fontSize = if (paragraph.isHeading) 19.sp else 18.sp,
        lineHeight = if (paragraph.isHeading) 28.sp else 30.sp,
        fontWeight = if (paragraph.isHeading) FontWeight.Bold else FontWeight.Normal
    )
}

private fun buildLegalText(
    text: String,
    highlights: List<String>
): AnnotatedString = buildAnnotatedString {
    val validHighlights = highlights.filter(String::isNotBlank)
    var cursor = 0

    while (cursor < text.length) {
        val nextMatch = validHighlights
            .asSequence()
            .mapNotNull { phrase ->
                val start = text.indexOf(phrase, startIndex = cursor)
                if (start >= 0) start to phrase else null
            }
            .sortedWith(
                compareBy<Pair<Int, String>> { it.first }
                    .thenByDescending { it.second.length }
            )
            .firstOrNull()

        if (nextMatch == null) {
            append(text.substring(cursor))
            cursor = text.length
        } else {
            val (start, phrase) = nextMatch
            if (start > cursor) {
                append(text.substring(cursor, start))
            }
            pushStyle(SpanStyle(color = CorosWhite, fontWeight = FontWeight.Bold))
            append(phrase)
            pop()
            cursor = start + phrase.length
        }
    }
}

private data class LegalParagraph(
    val text: String,
    val highlights: List<String> = emptyList(),
    val isHeading: Boolean = false
)

@Composable
private fun VerticalScrollbar(
    scrollState: ScrollState,
    modifier: Modifier = Modifier,
    width: Dp = 3.dp,
    minThumbHeight: Dp = 24.dp,
    color: Color = CorosWhite.copy(alpha = 0.45f)
) {
    val density = LocalDensity.current
    val widthPx = with(density) { width.toPx() }
    val minThumbHeightPx = with(density) { minThumbHeight.toPx() }

    Box(
        modifier = modifier
            .width(width)
            .drawWithContent {
                drawContent()

                val viewportHeight = size.height
                val maxScrollValue = scrollState.maxValue

                if (maxScrollValue <= 0 || viewportHeight <= 0f) {
                    return@drawWithContent
                }

                val totalContentHeight = viewportHeight + maxScrollValue

                val thumbHeightPx = (viewportHeight * viewportHeight / totalContentHeight)
                    .coerceAtLeast(minThumbHeightPx)
                    .coerceAtMost(viewportHeight)

                val maxThumbOffsetPx = viewportHeight - thumbHeightPx

                val progress = (
                        scrollState.value.toFloat() / maxScrollValue.toFloat()
                        ).coerceIn(0f, 1f)

                val thumbOffsetPx = progress * maxThumbOffsetPx

                drawRoundRect(
                    color = color,
                    topLeft = Offset(
                        x = 0f,
                        y = thumbOffsetPx
                    ),
                    size = Size(
                        width = widthPx,
                        height = thumbHeightPx
                    ),
                    cornerRadius = CornerRadius(
                        x = widthPx / 2f,
                        y = widthPx / 2f
                    )
                )
            }
    )
}


@Composable
private fun LoginPage(
    state: LoginState,
    canLogin: Boolean,
    acceptedTerms: Boolean,
    error: String?,
    onUnavailableClick: () -> Unit,
    onBack: () -> Unit,
    onAccountChanged: (String) -> Unit,
    onPasswordChanged: (String) -> Unit,
    onTermsClick: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit,
    onSubmit: () -> Unit
) {
    AuthBlackPage(
        onBack = onBack,
        showFeedback = true,
        onUnavailableClick = onUnavailableClick
    ) {
        Text(
            text = "账号登录",
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(45.dp))
        UnderlineInput(
            value = state.account,
            placeholder = "输入手机号或邮箱",
            keyboardType = KeyboardType.Email,
            autoFocus = true,
            onValueChange = onAccountChanged
        )
        Spacer(modifier = Modifier.height(16.dp))
        UnderlineInput(
            value = state.password,
            placeholder = "密码",
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = onPasswordChanged
        )
        Spacer(modifier = Modifier.height(59.dp))
        AgreementRow(
            accepted = acceptedTerms,
            onToggle = onTermsClick,
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick
        )
        Spacer(modifier = Modifier.height(12.dp))
        CorosFilledButton(
            text = "登录",
            color = CorosButtonRed,
            enabled = canLogin,
            isLoading = state.isLoading,
            onClick = onSubmit
        )
        ErrorText(error)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "忘记密码?",
            color = CorosMuted,
            fontSize = 14.sp,
            modifier = Modifier.clickable(onClick = onUnavailableClick)
        )
        Spacer(modifier = Modifier.weight(1f))
        ThirdPartyArea(onUnavailableClick = onUnavailableClick)
        Text(
            text = "V4.8.1.14",
            color = CorosMuted,
            fontSize = 16.sp,
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
    canSendCode: Boolean,
    acceptedTerms: Boolean,
    error: String?,
    onUnavailableClick: () -> Unit,
    onBack: () -> Unit,
    onPhoneChanged: (String) -> Unit,
    onTermsClick: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit,
    onSendCode: () -> Unit,
    onEmailRegister: () -> Unit
) {
    AuthBlackPage(
        onBack = onBack,
        showFeedback = true,
        onUnavailableClick = onUnavailableClick
    ) {
        Text(
            text = "手机号注册",
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        PhoneInput(value = state.account, autoFocus = true, onValueChange = onPhoneChanged)
        Spacer(modifier = Modifier.height(RegisterAgreementTopSpacing))
        AgreementRow(
            accepted = acceptedTerms,
            onToggle = onTermsClick,
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick
        )
        Spacer(modifier = Modifier.height(RegisterActionTopSpacing))
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
            fontSize = 18.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 26.dp)
                .clickable(onClick = onEmailRegister)
        )
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun EmailRegisterPage(
    email: String,
    canSendCode: Boolean,
    acceptedTerms: Boolean,
    error: String?,
    onUnavailableClick: () -> Unit,
    onBack: () -> Unit,
    onEmailChanged: (String) -> Unit,
    onTermsClick: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit,
    onSendCode: () -> Unit,
    onPhoneRegister: () -> Unit
) {
    AuthBlackPage(
        onBack = onBack,
        showFeedback = true,
        onUnavailableClick = onUnavailableClick
    ) {
        Text(
            text = "邮箱注册",
            color = CorosWhite,
            fontSize = AuthTitleSize,
            fontWeight = FontWeight.Light,
            modifier = Modifier.padding(top = AuthTitleTopPadding)
        )
        Spacer(modifier = Modifier.height(60.dp))
        UnderlineInput(
            value = email,
            placeholder = "请输入邮箱",
            keyboardType = KeyboardType.Email,
            autoFocus = true,
            onValueChange = onEmailChanged
        )
        Spacer(modifier = Modifier.height(RegisterAgreementTopSpacing))
        AgreementRow(
            accepted = acceptedTerms,
            onToggle = onTermsClick,
            onPrivacyClick = onPrivacyClick,
            onServiceTermsClick = onServiceTermsClick
        )
        Spacer(modifier = Modifier.height(RegisterActionTopSpacing))
        CorosFilledButton(
            text = "发送验证码",
            color = CorosButtonRed,
            enabled = canSendCode,
            onClick = onSendCode
        )
        ErrorText(error)
        Text(
            text = "手机号注册",
            color = CorosRed,
            fontSize = 18.sp,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 26.dp)
                .clickable(onClick = onPhoneRegister)
        )
        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun VerifyCodePage(
    account: String,
    targetKind: VerifyTargetKind,
    code: String,
    error: String?,
    onBack: () -> Unit,
    onCodeChanged: (String) -> Unit,
    onCodeComplete: () -> Unit,
    onResend: () -> Boolean,
    onUnavailableClick: () -> Unit
) {
    var countdown by rememberSaveable(account, targetKind) { mutableIntStateOf(60) }
    var resendRound by rememberSaveable(account, targetKind) { mutableIntStateOf(0) }
    var resendLoading by rememberSaveable { mutableStateOf(false) }
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
            onCodeComplete()
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
            hasError = !error.isNullOrBlank(),
            onCodeChanged = onCodeChanged
        )
        ErrorText(error)
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
                    modifier = Modifier
                        .clickable {
                            coroutineScope.launch {
                                resendLoading = true
                                delay(650.milliseconds)
                                if (onResend()) {
                                    resendRound += 1
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
                modifier = Modifier.clickable(onClick = onUnavailableClick)
            )
        }
        Spacer(modifier = Modifier.weight(1f))
        }
        if (resendLoading) {
            BlockingLoadingOverlay()
        }
    }
}

@Composable
private fun PasswordSetupPage(
    password: String,
    confirmPassword: String,
    canRegister: Boolean,
    error: String?,
    isLoading: Boolean,
    onBack: () -> Unit,
    onPasswordChanged: (String) -> Unit,
    onConfirmPasswordChanged: (String) -> Unit,
    onRegister: () -> Unit
) {
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
            onValueChange = onPasswordChanged
        )
        Spacer(modifier = Modifier.height(48.dp))
        UnderlineInput(
            value = confirmPassword,
            placeholder = "再次输入密码",
            keyboardType = KeyboardType.Password,
            isPassword = true,
            onValueChange = onConfirmPasswordChanged
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(text = "6-20位必须包含字母和数字", color = Color(0xFFD8D8DD), fontSize = 14.sp)
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
    onUnavailableClick: () -> Unit = {},
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(CorosBlack)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
            .heightIn(min = 812.dp)
            .padding(horizontal = 20.dp)
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
                Text(
                    text = "◔ 建议&反馈",
                    color = CorosMuted,
                    fontSize = 14.sp,
                    modifier = Modifier.clickable(onClick = onUnavailableClick)
                )
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
private fun HomeBackgroundVideo(modifier: Modifier = Modifier) {
    AndroidView(
        modifier = modifier,
        factory = { context ->
            FrameLayout(context).apply {
                setBackgroundColor(AndroidColor.BLACK)
                val videoView = VideoView(context)
                var videoWidth = 0
                var videoHeight = 0

                fun resizeVideo() {
                    if (width == 0 || height == 0 || videoWidth == 0 || videoHeight == 0) return

                    val scale = maxOf(
                        width.toFloat() / videoWidth.toFloat(),
                        height.toFloat() / videoHeight.toFloat()
                    )
                    val targetWidth = (videoWidth * scale).roundToInt()
                    val targetHeight = (videoHeight * scale).roundToInt()
                    videoView.layoutParams = FrameLayout.LayoutParams(
                        targetWidth,
                        targetHeight,
                        Gravity.CENTER
                    )
                }

                addView(
                    videoView,
                    FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        Gravity.CENTER
                    )
                )
                addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ -> resizeVideo() }
                videoView.setOnPreparedListener { mediaPlayer ->
                    mediaPlayer.isLooping = true
                    mediaPlayer.setVolume(0f, 0f)
                    videoWidth = mediaPlayer.videoWidth
                    videoHeight = mediaPlayer.videoHeight
                    resizeVideo()
                    videoView.start()
                }
                videoView.setVideoURI(
                    "android.resource://${context.packageName}/${R.raw.home}".toUri()
                )
                videoView.start()
            }
        },
        update = { container ->
            val videoView = container.getChildAt(0) as? VideoView
            if (videoView?.isPlaying == false) {
                videoView.start()
            }
        }
    )
}

@Composable
private fun UnderlineInput(
    value: String,
    placeholder: String,
    onValueChange: (String) -> Unit,
    keyboardType: KeyboardType,
    isPassword: Boolean = false,
    autoFocus: Boolean = false
) {
    var passwordVisible by rememberSaveable { mutableStateOf(false) }
    var latestPasswordIndex by rememberSaveable { mutableStateOf<Int?>(null) }
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current
    val visualTransformation = when {
        !isPassword -> VisualTransformation.None
        passwordVisible -> VisualTransformation.None
        else -> LatestVisiblePasswordTransformation(latestPasswordIndex)
    }

    LaunchedEffect(autoFocus) {
        if (autoFocus) {
            delay(250.milliseconds)
            focusRequester.requestFocus()
            keyboardController?.show()
        }
    }

    BasicTextField(
        value = value,
        onValueChange = { newValue ->
            if (isPassword) {
                latestPasswordIndex = latestChangedIndex(value, newValue)
            }
            onValueChange(newValue)
        },
        singleLine = true,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
        visualTransformation = visualTransformation,
        textStyle = TextStyle(color = CorosWhite, fontSize = 17.sp),
        cursorBrush = SolidColor(CorosRed),
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .focusRequester(focusRequester),
        decorationBox = { innerTextField ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .border(width = 0.dp, color = Color.Transparent)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(bottom = 1.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 8.dp),
                        contentAlignment = Alignment.CenterStart
                    ) {
                        if (value.isBlank()) {
                            Text(
                                text = placeholder,
                                color = CorosMuted,
                                fontSize = 17.sp
                            )
                        }
                        innerTextField()
                    }
                    ClearInputButton(
                        visible = value.isNotEmpty(),
                        onClick = {
                            latestPasswordIndex = null
                            onValueChange("")
                        }
                    )
                    if (isPassword && value.isNotEmpty()) {
                        Spacer(modifier = Modifier.width(6.dp))
                        PasswordVisibilityButton(
                            passwordVisible = passwordVisible,
                            onClick = {
                                val willShowPassword = !passwordVisible
                                passwordVisible = willShowPassword
                                if (!willShowPassword) {
                                    latestPasswordIndex = null
                                }
                            }
                        )
                    }
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
    autoFocus: Boolean = false,
    onValueChange: (String) -> Unit
) {
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current

    LaunchedEffect(autoFocus) {
        if (autoFocus) {
            delay(250.milliseconds)
            focusRequester.requestFocus()
            keyboardController?.show()
        }
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = "+86", color = CorosWhite, fontSize = 17.sp)
        Spacer(modifier = Modifier.width(24.dp))
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            textStyle = TextStyle(color = CorosWhite, fontSize = 17.sp),
            cursorBrush = SolidColor(CorosRed),
            modifier = Modifier
                .weight(1f)
                .focusRequester(focusRequester),
            decorationBox = { innerTextField ->
                Box(contentAlignment = Alignment.CenterStart) {
                    if (value.isBlank()) {
                        Text(text = "输入手机号", color = CorosMuted, fontSize = 17.sp)
                    }
                    innerTextField()
                }
            }
        )
        ClearInputButton(
            visible = value.isNotEmpty(),
            onClick = { onValueChange("") }
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
    onToggle: () -> Unit,
    onPrivacyClick: () -> Unit,
    onServiceTermsClick: () -> Unit
) {
    val linkStyle = TextLinkStyles(
        style = SpanStyle(color = CorosRed)
    )

    val agreementText = buildAnnotatedString {
        append("我已阅读并同意COROS的 ")

        withLink(
            LinkAnnotation.Clickable(
                tag = "privacy",
                styles = linkStyle
            ) {
                onPrivacyClick()
            }
        ) {
            append("《隐私政策》")
        }

        append(" 和 ")

        withLink(
            LinkAnnotation.Clickable(
                tag = "terms",
                styles = linkStyle
            ) {
                onServiceTermsClick()
            }
        ) {
            append("《服务条款》")
        }
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top
    ) {
        AgreementCheck(
            accepted = accepted,
            modifier = Modifier
                .padding(top = 6.dp)
                .size(AgreementCheckTouchSize)
                .clickable(onClick = onToggle)
        )

        Spacer(modifier = Modifier.width(6.dp))

        Text(
            text = agreementText,
            style = TextStyle(
                color = CorosWhite,
                fontSize = AgreementTextSize,
                lineHeight = AgreementLineHeight
            ),
            modifier = Modifier.weight(1f)
        )
    }
}


@Composable
private fun AgreementCheck(
    accepted: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.TopCenter
    ) {
        Canvas(modifier = Modifier.size(AgreementCheckVisualSize)) {
            val strokeWidth = 1.dp.toPx()
            val radius = size.minDimension / 2f - strokeWidth / 2f

            drawCircle(
                color = if (accepted) CorosRed else Color.Transparent,
                radius = radius
            )
            drawCircle(
                color = if (accepted) CorosRed else CorosWhite.copy(alpha = 0.82f),
                radius = radius,
                style = Stroke(width = strokeWidth)
            )
            if (accepted) {
                val checkStroke = 1.4.dp.toPx()
                drawLine(
                    color = CorosWhite,
                    start = Offset(size.width * 0.26f, size.height * 0.52f),
                    end = Offset(size.width * 0.43f, size.height * 0.68f),
                    strokeWidth = checkStroke
                )
                drawLine(
                    color = CorosWhite,
                    start = Offset(size.width * 0.43f, size.height * 0.68f),
                    end = Offset(size.width * 0.76f, size.height * 0.34f),
                    strokeWidth = checkStroke
                )
            }
        }
    }
}

@Composable
private fun CorosFilledButton(
    text: String,
    color: Color,
    onClick: () -> Unit,
    enabled: Boolean = true,
    isLoading: Boolean = false,
    buttonHeight: Dp = 48.dp,
    textSize: TextUnit = 18.sp
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
            .height(buttonHeight)
    ) {
        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.size(22.dp), color = CorosWhite, strokeWidth = 2.dp)
        } else {
            Text(
                text = text,
                color = CorosWhite.copy(alpha = if (enabled) 1f else 0.42f),
                fontSize = textSize
            )
        }
    }
}

@Composable
private fun CodeBoxes(
    code: String,
    hasError: Boolean,
    onCodeChanged: (String) -> Unit
) {
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current

    LaunchedEffect(Unit) {
        delay(250.milliseconds)
        focusRequester.requestFocus()
        keyboardController?.show()
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        BasicTextField(
            value = code,
            onValueChange = onCodeChanged,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            textStyle = TextStyle(color = Color.Transparent),
            cursorBrush = SolidColor(Color.Transparent),
            modifier = Modifier
                .weight(1f)
                .focusRequester(focusRequester),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(36.dp)
                    ) {
                        repeat(4) { index ->
                            val isActiveBox = index == code.length && code.length < 4
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .aspectRatio(1f)
                                    .clip(RoundedCornerShape(12.dp))
                                    .background(if (isActiveBox) Color(0xFF151517) else CorosBlack)
                                    .border(
                                        2.dp,
                                        if (hasError) CorosRed else Color(0xFF3A3A3D),
                                        RoundedCornerShape(12.dp)
                                    ),
                                contentAlignment = Alignment.Center
                            ) {
                                val digit = code.getOrNull(index)?.toString()
                                if (digit != null) {
                                    Text(text = digit, color = CorosWhite, fontSize = 30.sp)
                                } else if (isActiveBox) {
                                    BlinkingCursor(
                                        modifier = Modifier
                                            .width(2.dp)
                                            .height(28.dp)
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
}

@Composable
private fun ClearInputButton(
    visible: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier.size(34.dp),
        contentAlignment = Alignment.Center
    ) {
        if (visible) {
            Image(
                painter = painterResource(id = R.drawable.icon_delete),
                contentDescription = "清空输入",
                modifier = Modifier
                    .size(28.dp)
                    .clickable(onClick = onClick)
                    .padding(4.dp),
                contentScale = ContentScale.Fit
            )
        }
    }
}

@Composable
private fun PasswordVisibilityButton(
    passwordVisible: Boolean,
    onClick: () -> Unit
) {
    Image(
        painter = painterResource(id = R.drawable.icon_uneye),
        contentDescription = if (passwordVisible) "隐藏密码" else "显示密码",
        modifier = Modifier
            .size(34.dp)
            .alpha(if (passwordVisible) 0.45f else 1f)
            .clickable(onClick = onClick)
            .padding(3.dp),
        contentScale = ContentScale.Fit
    )
}

@Composable
private fun BlinkingCursor(modifier: Modifier = Modifier) {
    var visible by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        while (true) {
            delay(530.milliseconds)
            visible = !visible
        }
    }

    if (visible) {
        Box(modifier = modifier.background(CorosRed))
    }
}

private class LatestVisiblePasswordTransformation(
    private val visibleIndex: Int?
) : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val source = text.text
        if (source.isEmpty()) {
            return TransformedText(AnnotatedString(""), OffsetMapping.Identity)
        }

        val indexToReveal = visibleIndex?.takeIf { it in source.indices }
        val masked = buildString(source.length) {
            source.forEachIndexed { index, char ->
                append(if (index == indexToReveal) char else '•')
            }
        }
        return TransformedText(AnnotatedString(masked), OffsetMapping.Identity)
    }
}

private fun latestChangedIndex(
    previous: String,
    current: String
): Int? {
    if (current.isEmpty()) return null
    if (previous == current) return null
    if (current.length < previous.length) return null

    val sharedLength = minOf(previous.length, current.length)
    val firstChanged = (0 until sharedLength).firstOrNull { previous[it] != current[it] }
    if (firstChanged != null) return firstChanged.coerceAtMost(current.lastIndex)

    return if (current.length > previous.length) {
        previous.length.coerceAtMost(current.lastIndex)
    } else {
        current.lastIndex
    }
}

@Composable
private fun ThirdPartyArea(onUnavailableClick: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.size(width = 120.dp, height = 1.dp).background(CorosLine))
            Text(text = "第三方账号", color = CorosMuted, fontSize = 14.sp, modifier = Modifier.padding(horizontal = 12.dp))
            Box(modifier = Modifier.size(width = 120.dp, height = 1.dp).background(CorosLine))
        }
        Spacer(modifier = Modifier.height(24.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(54.dp)) {
            ThirdPartyCircle(text = "☘", onClick = onUnavailableClick)
            ThirdPartyCircle(text = "···", onClick = onUnavailableClick)
        }
    }
}

@Composable
private fun ThirdPartyCircle(
    text: String,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(34.dp)
            .clip(CircleShape)
            .border(1.dp, Color(0xFF303036), CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = CorosWhite, fontSize = 20.sp)
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

private val PrivacyPolicyParagraphs = listOf(
    LegalParagraph("最后更新时间：2025年12月24日"),
    LegalParagraph("导言"),
    LegalParagraph(
        text = "广东高驰运动科技有限公司（以下简称\"COROS\"或\"我们\"）非常重视用户（或\"您\"）的隐私和个人信息保护，我们将按照法律法规的要求，尽力保护您的个人信息安全。",
        highlights = listOf("COROS", "我们", "您", "隐私和个人信息保护", "个人信息安全")
    ),
    LegalParagraph(
        text = "本个人信息保护政策（以下简称\"本政策\"）适用于您通过 COROS 网站、COROS 移动应用程序（\"COROS App\"）及其他 COROS 产品和服务使用我们的产品与服务。",
        highlights = listOf("本政策", "COROS App", "COROS 产品和服务")
    ),
    LegalParagraph(
        text = "本政策解释了我们如何收集、存储、使用、提供、删除您的信息，以及您享有的权利。请您认真阅读并充分理解本政策，特别是涉及个人敏感信息、系统权限、第三方共享和账号注销的条款。",
        highlights = listOf("收集、存储、使用、提供、删除", "您享有的权利", "认真阅读并充分理解本政策", "个人敏感信息、系统权限、第三方共享和账号注销")
    ),
    LegalParagraph(
        text = "一、我们如何收集和使用您的个人信息",
        isHeading = true
    ),
    LegalParagraph(
        text = "1. 我们将逐一说明所收集的个人信息类型及其对应用途，以便您了解每一项功能所处理的具体个人信息类别、处理目的及处理方式。",
        highlights = listOf("个人信息类型", "处理目的及处理方式")
    ),
    LegalParagraph(
        text = "2. 为了向您提供运动记录、设备连接、账号登录、安全保障和客户支持等服务，我们可能会在获得授权后处理账号信息、设备信息、运动数据、网络状态以及必要的日志信息。",
        highlights = listOf("获得授权后", "账号信息、设备信息、运动数据、网络状态", "必要的日志信息")
    ),
    LegalParagraph(
        text = "二、我们如何提供和共享您的个人信息",
        isHeading = true
    ),
    LegalParagraph(
        text = "除非经过您的同意，我们不会主动将您的个人信息提供至 COROS 以外的第三方。如确需对外提供，或您需要我们向任何第三方提供信息时，我们会直接征得您的同意，但法律法规另有规定的除外。",
        highlights = listOf("除非经过您的同意", "不会主动将您的个人信息提供至 COROS 以外的第三方", "直接征得您的同意")
    ),
    LegalParagraph(
        text = "三、您如何管理自己的个人信息",
        isHeading = true
    ),
    LegalParagraph(
        text = "您可以通过本政策所列途径查询、更新、复制、删除您的个人信息，也可以撤回同意、注销账号、投诉举报。我们会在符合法律法规要求的期限内处理您的请求。",
        highlights = listOf("查询、更新、复制、删除", "撤回同意、注销账号、投诉举报")
    ),
    LegalParagraph(
        text = "四、系统权限和敏感信息",
        isHeading = true
    ),
    LegalParagraph(
        text = "为了依据本政策收集您的信息、向您提供服务、优化我们的服务并保障您的账号安全，我们可能需要向您索取相关系统权限；其中位置等敏感权限不会默认开启，只有在您明确同意后，我们才会在您同意的范围内调用或使用。",
        highlights = listOf("保障您的账号安全", "系统权限", "敏感权限不会默认开启", "您明确同意后")
    ),
    LegalParagraph(
        text = "五、本政策如何更新",
        isHeading = true
    ),
    LegalParagraph(
        text = "我们会持续保护您的个人信息，并根据产品功能、法律法规或监管要求更新本政策。若本政策发生重大变化，我们会以合理方式向您提示。",
        highlights = listOf("持续保护您的个人信息", "本政策发生重大变化", "合理方式向您提示")
    )
)

private val ServiceTermsParagraphs = listOf(
    LegalParagraph("最后更新日期：2023年9月4日"),
    LegalParagraph("特别提示："),
    LegalParagraph(
        text = "本《COROS 用户协议》（以下简称\"本协议\"）是您（或\"用户\"）与广东高驰运动科技股份有限公司（以下简称\"COROS\"或\"我们\"）签订的，就使用 COROS 网站、COROS 移动应用程序（\"COROS App\"）及其他 COROS 产品和服务（统称为\"COROS产品和服务\"）等事宜订立的协议。",
        highlights = listOf("本协议", "用户", "COROS", "我们", "COROS App", "COROS产品和服务")
    ),
    LegalParagraph(
        text = "请您认真阅读并充分理解本协议，特别是以加粗形式提示您注意的免除或减轻 COROS 责任的条款。您有权选择同意或不同意本协议，除非您接受本协议的全部条款，否则您无权注册、登录或使用 COROS 产品和服务。",
        highlights = listOf("认真阅读并充分理解本协议", "加粗形式提示您注意的免除或减轻 COROS 责任的条款", "除非您接受本协议的全部条款，否则您无权注册、登录或使用 COROS 产品和服务")
    ),
    LegalParagraph(
        text = "一旦您点击\"本人已阅读并同意接受本协议的全部内容\"并完成注册流程，即视为您已充分阅读、理解并在您点击接受当时接受本协议的所有内容，本协议即在您与 COROS 之间成立并发生法律效力，您同意接受本协议各项条款的约束。",
        highlights = listOf("一旦您点击\"本人已阅读并同意接受本协议的全部内容\"并完成注册流程", "本协议即在您与 COROS 之间成立并发生法律效力", "您同意接受本协议各项条款的约束")
    ),
    LegalParagraph(
        text = "请注意，本协议内容包括所有我们已经发布或未来可能变更或发布的各类协议、规则、公告或通知。除非法律规定或本协议有相反规定，前述内容一经公布即自动生效并成为本协议不可分割的组成部分，无需另行通知。",
        highlights = listOf("已经发布或未来可能变更或发布", "协议、规则、公告或通知", "一经公布即自动生效")
    ),
    LegalParagraph(
        text = "如您不同意本协议的内容或在您同意本协议之后我们发布生效的任何协议、规则、公告或通知，您应立即取消登录、注销账号、停止使用 COROS 产品和服务；如您继续使用，则视为您始终同意本协议的所有内容并同意遵守。",
        highlights = listOf("如您不同意本协议的内容或在您同意本协议之后我们发布生效的任何协议、规则、公告或通知", "您应立即取消登录、注销账号、停止使用 COROS 产品和服务", "如您继续使用，则视为您始终同意本协议的所有内容并同意遵守")
    ),
    LegalParagraph(
        text = "一、服务范围",
        isHeading = true
    ),
    LegalParagraph(
        text = "1. 我们就使用 COROS 产品和服务给予您一项个人的、不可转让的、不可转授权的、非独占性的、可撤销的许可。",
        highlights = listOf("个人的、不可转让的、不可转授权的、非独占性的、可撤销的")
    ),
    LegalParagraph(
        text = "2. 您应按照法律法规、本协议以及 COROS 发布的规则使用产品和服务，不得利用服务从事违法违规或侵犯他人合法权益的行为。",
        highlights = listOf("法律法规、本协议以及 COROS 发布的规则", "不得利用服务从事违法违规或侵犯他人合法权益的行为")
    ),
    LegalParagraph(
        text = "3. 我们可能根据产品运营情况对服务内容进行调整、更新或优化，并会在合理范围内向您提供必要提示。",
        highlights = listOf("调整、更新或优化", "必要提示")
    ),
    LegalParagraph(
        text = "二、账号与安全",
        isHeading = true
    ),
    LegalParagraph(
        text = "1. 您应对您账号下的所有行为负责，并妥善保管账号、密码和验证码等信息。",
        highlights = listOf("您账号下的所有行为负责", "妥善保管账号、密码和验证码")
    ),
    LegalParagraph(
        text = "2. 如发现账号存在异常使用、被盗用或其他安全风险，请及时联系我们处理。",
        highlights = listOf("异常使用、被盗用或其他安全风险", "及时联系我们处理")
    ),
    LegalParagraph(
        text = "三、协议变更",
        isHeading = true
    ),
    LegalParagraph(
        text = "我们可能根据法律法规变化、业务调整或服务优化需要修改本协议。更新后的协议公布后即生效；如您继续使用 COROS 产品和服务，视为您同意接受更新后的协议。",
        highlights = listOf("修改本协议", "公布后即生效", "继续使用 COROS 产品和服务，视为您同意接受更新后的协议")
    )
)

@Preview(showBackground = true)
@Composable
private fun LoginScreenPreview() {
    DemoTheme {
        LoginScreen(viewModel = LoginViewModel())
    }
}
