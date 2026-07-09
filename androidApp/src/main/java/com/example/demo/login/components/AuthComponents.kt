package com.example.demo.login.components

import com.example.demo.common.login.VerifyTarget
import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.graphics.Color as AndroidColor
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.VideoView
import androidx.compose.foundation.ScrollState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withLink
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.net.toUri
import com.example.demo.R
import com.example.demo.login.LoginViewModel
import kotlinx.coroutines.delay
import kotlin.math.roundToInt
import kotlin.time.Duration.Companion.milliseconds

@Composable
fun rememberLoginViewModel(): LoginViewModel {
    val context = LocalContext.current.applicationContext
    return remember(context) { LoginViewModel.create(context) }
}

fun Context.findActivity(): Activity? {
    return when (this) {
        is Activity -> this
        is ContextWrapper -> baseContext.findActivity()
        else -> null
    }
}

fun verifyCodeMessage(account: String, targetKind: VerifyTarget): String {
    return if (targetKind == VerifyTarget.Email) {
        "验证码已发送至你的邮箱 $account，有效期10分钟"
    } else {
        "验证码已发送至你的手机+86-$account，有效期10分钟"
    }
}

fun buildLegalText(text: String, highlights: List<String>): AnnotatedString = buildAnnotatedString {
    val validHighlights = highlights.filter(String::isNotBlank)
    var cursor = 0
    while (cursor < text.length) {
        val nextMatch = validHighlights
            .asSequence()
            .mapNotNull { phrase ->
                val start = text.indexOf(phrase, startIndex = cursor)
                if (start >= 0) start to phrase else null
            }
            .sortedWith(compareBy<Pair<Int, String>> { it.first }.thenByDescending { it.second.length })
            .firstOrNull()
        if (nextMatch == null) {
            append(text.substring(cursor))
            cursor = text.length
        } else {
            val (start, phrase) = nextMatch
            if (start > cursor) append(text.substring(cursor, start))
            pushStyle(SpanStyle(color = CorosWhite, fontWeight = FontWeight.Bold))
            append(phrase)
            pop()
            cursor = start + phrase.length
        }
    }
}

fun latestChangedIndex(previous: String, current: String): Int? {
    if (current.isEmpty()) return null
    if (previous == current) return null
    if (current.length < previous.length) return null
    val sharedLength = minOf(previous.length, current.length)
    val firstChanged = (0 until sharedLength).firstOrNull { previous[it] != current[it] }
    if (firstChanged != null) return firstChanged.coerceAtMost(current.lastIndex)
    return if (current.length > previous.length) previous.length.coerceAtMost(current.lastIndex) else current.lastIndex
}

class LatestVisiblePasswordTransformation(private val visibleIndex: Int?) : VisualTransformation {
    override fun filter(text: AnnotatedString): TransformedText {
        val source = text.text
        if (source.isEmpty()) return TransformedText(AnnotatedString(""), OffsetMapping.Identity)
        val indexToReveal = visibleIndex?.takeIf { it in source.indices }
        val masked = buildString(source.length) {
            source.forEachIndexed { index, char ->
                append(if (index == indexToReveal) char else '•')
            }
        }
        return TransformedText(AnnotatedString(masked), OffsetMapping.Identity)
    }
}

@Composable
fun AuthBlackPage(
    onBack: () -> Unit,
    showFeedback: Boolean,
    showBack: Boolean = true,
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
            modifier = Modifier.fillMaxWidth().height(52.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            if (showBack) {
                Text(
                    text = "‹",
                    color = CorosWhite,
                    fontSize = 44.sp,
                    modifier = Modifier.clickable(onClick = onBack)
                )
            }
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
fun CorosLogo(modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        androidx.compose.foundation.Image(
            painter = painterResource(id = R.drawable.logo_coros),
            contentDescription = "COROS Logo",
            modifier = Modifier.width(260.dp).height(48.dp),
            contentScale = ContentScale.Fit
        )
    }
}

@Composable
fun HomeBackgroundVideo(modifier: Modifier = Modifier) {
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
                    val scale = maxOf(width.toFloat() / videoWidth.toFloat(), height.toFloat() / videoHeight.toFloat())
                    val targetWidth = (videoWidth * scale).roundToInt()
                    val targetHeight = (videoHeight * scale).roundToInt()
                    videoView.layoutParams = FrameLayout.LayoutParams(targetWidth, targetHeight, Gravity.CENTER)
                }
                addView(videoView, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, Gravity.CENTER))
                addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ -> resizeVideo() }
                videoView.setOnPreparedListener { mediaPlayer ->
                    mediaPlayer.isLooping = true
                    mediaPlayer.setVolume(0f, 0f)
                    videoWidth = mediaPlayer.videoWidth
                    videoHeight = mediaPlayer.videoHeight
                    resizeVideo()
                    videoView.start()
                }
                videoView.setVideoURI("android.resource://${context.packageName}/${R.raw.home}".toUri())
                videoView.start()
            }
        },
        update = { container ->
            val videoView = container.getChildAt(0) as? VideoView
            if (videoView?.isPlaying == false) videoView.start()
        }
    )
}

@Composable
fun UnderlineInput(
    value: String,
    placeholder: String,
    onValueChange: (String) -> Unit,
    keyboardType: KeyboardType,
    isPassword: Boolean = false,
    autoFocus: Boolean = false
) {
    var passwordVisible by rememberSaveable { mutableStateOf(false) }
    var latestPasswordIndex by remember { mutableStateOf<Int?>(null) }
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current
    val visualTransformation = when {
        !isPassword -> VisualTransformation.None
        passwordVisible -> VisualTransformation.None
        else -> LatestVisiblePasswordTransformation(latestPasswordIndex)
    }
    LaunchedEffect(isPassword, passwordVisible, latestPasswordIndex, value) {
        if (isPassword && !passwordVisible && latestPasswordIndex != null) {
            delay(3000.milliseconds)
            latestPasswordIndex = null
        }
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
                latestPasswordIndex = if (passwordVisible) {
                    null
                } else {
                    latestChangedIndex(value, newValue)
                }
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
            .onFocusChanged { focusState ->
                if (isPassword && !focusState.isFocused) latestPasswordIndex = null
            }
            .focusRequester(focusRequester),
        decorationBox = { innerTextField ->
            Box(modifier = Modifier.fillMaxSize().border(width = 0.dp, color = Color.Transparent)) {
                Row(modifier = Modifier.fillMaxSize().padding(bottom = 1.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(modifier = Modifier.weight(1f).padding(end = 8.dp), contentAlignment = Alignment.CenterStart) {
                        if (value.isBlank()) Text(text = placeholder, color = CorosMuted, fontSize = 17.sp)
                        innerTextField()
                    }
                    ClearInputButton(visible = value.isNotEmpty(), onClick = {
                        latestPasswordIndex = null
                        onValueChange("")
                    })
                    if (isPassword && value.isNotEmpty()) {
                        Spacer(modifier = Modifier.width(6.dp))
                        PasswordVisibilityButton(passwordVisible = passwordVisible, onClick = {
                            passwordVisible = !passwordVisible
                            latestPasswordIndex = null
                        })
                    }
                }
                Box(modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth().height(1.dp).background(CorosLine))
            }
        }
    )
}

@Composable
fun DisabledUnderlineValue(
    value: String,
    placeholder: String
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .alpha(0.62f)
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
                Text(
                    text = value.ifBlank { placeholder },
                    color = if (value.isBlank()) CorosMuted else CorosWhite,
                    fontSize = 17.sp
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

@Composable
fun PhoneInput(value: String, autoFocus: Boolean = false, onValueChange: (String) -> Unit) {
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current
    LaunchedEffect(autoFocus) {
        if (autoFocus) {
            delay(250.milliseconds)
            focusRequester.requestFocus()
            keyboardController?.show()
        }
    }
    Row(modifier = Modifier.fillMaxWidth().height(48.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(text = "+86", color = CorosWhite, fontSize = 17.sp)
        Spacer(modifier = Modifier.width(24.dp))
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
            textStyle = TextStyle(color = CorosWhite, fontSize = 17.sp),
            cursorBrush = SolidColor(CorosRed),
            modifier = Modifier.weight(1f).focusRequester(focusRequester),
            decorationBox = { innerTextField ->
                Box(contentAlignment = Alignment.CenterStart) {
                    if (value.isBlank()) Text(text = "输入手机号", color = CorosMuted, fontSize = 17.sp)
                    innerTextField()
                }
            }
        )
        ClearInputButton(visible = value.isNotEmpty(), onClick = { onValueChange("") })
    }
    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(CorosLine))
}

@Composable
fun AgreementRow(accepted: Boolean, onToggle: () -> Unit, onPrivacyClick: () -> Unit, onServiceTermsClick: () -> Unit) {
    val linkStyle = TextLinkStyles(style = SpanStyle(color = CorosRed))
    val agreementText = buildAnnotatedString {
        append("我已阅读并同意COROS的 ")
        withLink(LinkAnnotation.Clickable(tag = "privacy", styles = linkStyle) { onPrivacyClick() }) { append("《隐私政策》") }
        append(" 和 ")
        withLink(LinkAnnotation.Clickable(tag = "terms", styles = linkStyle) { onServiceTermsClick() }) { append("《服务条款》") }
    }
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
        AgreementCheck(accepted = accepted, modifier = Modifier.padding(top = 6.dp).size(AgreementCheckTouchSize).clickable(onClick = onToggle))
        Spacer(modifier = Modifier.width(6.dp))
        Text(text = agreementText, style = TextStyle(color = CorosWhite, fontSize = AgreementTextSize, lineHeight = AgreementLineHeight), modifier = Modifier.weight(1f))
    }
}

@Composable
fun AgreementCheck(accepted: Boolean, modifier: Modifier = Modifier) {
    Box(modifier = modifier, contentAlignment = Alignment.TopCenter) {
        androidx.compose.foundation.Canvas(modifier = Modifier.size(AgreementCheckVisualSize)) {
            val strokeWidth = 1.dp.toPx()
            val radius = size.minDimension / 2f - strokeWidth / 2f
            val checkStroke = 1.4.dp.toPx()
            drawCircle(color = if (accepted) CorosRed else Color.Transparent, radius = radius)
            drawCircle(color = if (accepted) CorosRed else CorosWhite.copy(alpha = 0.82f), radius = radius, style = androidx.compose.ui.graphics.drawscope.Stroke(width = strokeWidth))
            if (accepted) {
                drawLine(color = CorosWhite, start = Offset(size.width * 0.26f, size.height * 0.52f), end = Offset(size.width * 0.43f, size.height * 0.68f), strokeWidth = checkStroke)
                drawLine(color = CorosWhite, start = Offset(size.width * 0.43f, size.height * 0.68f), end = Offset(size.width * 0.76f, size.height * 0.34f), strokeWidth = checkStroke)
            }
        }
    }
}

@Composable
fun CorosFilledButton(
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
        colors = ButtonDefaults.buttonColors(containerColor = color, disabledContainerColor = color.copy(alpha = 0.45f)),
        shape = RoundedCornerShape(9.dp),
        modifier = Modifier.fillMaxWidth().height(buttonHeight)
    ) {
        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.size(22.dp), color = CorosWhite, strokeWidth = 2.dp)
        } else {
            Text(text = text, color = CorosWhite.copy(alpha = if (enabled) 1f else 0.42f), fontSize = textSize)
        }
    }
}

@Composable
fun CodeBoxes(code: String, hasError: Boolean, onCodeChanged: (String) -> Unit) {
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current
    LaunchedEffect(Unit) {
        delay(250.milliseconds)
        focusRequester.requestFocus()
        keyboardController?.show()
    }
    Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        BasicTextField(
            value = code,
            onValueChange = onCodeChanged,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            textStyle = TextStyle(color = Color.Transparent),
            cursorBrush = SolidColor(Color.Transparent),
            modifier = Modifier.weight(1f).focusRequester(focusRequester),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth()) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(36.dp)) {
                        repeat(4) { index ->
                            val isActiveBox = index == code.length && code.length < 4
                            Box(
                                modifier = Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(12.dp))
                                    .background(if (isActiveBox) Color(0xFF151517) else CorosBlack)
                                    .border(2.dp, if (hasError) CorosRed else Color(0xFF3A3A3D), RoundedCornerShape(12.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                val digit = code.getOrNull(index)?.toString()
                                if (digit != null) Text(text = digit, color = CorosWhite, fontSize = 30.sp)
                                else if (isActiveBox) BlinkingCursor(modifier = Modifier.width(2.dp).height(28.dp))
                            }
                        }
                    }
                    Box(modifier = Modifier.matchParentSize().background(Color.Transparent)) { innerTextField() }
                }
            }
        )
    }
}

@Composable
fun ClearInputButton(visible: Boolean, onClick: () -> Unit) {
    Box(modifier = Modifier.size(34.dp), contentAlignment = Alignment.Center) {
        if (visible) {
            androidx.compose.foundation.Image(
                painter = painterResource(id = R.drawable.icon_delete),
                contentDescription = "清空输入",
                modifier = Modifier.size(28.dp).clickable(onClick = onClick).padding(4.dp),
                contentScale = ContentScale.Fit
            )
        }
    }
}

@Composable
fun PasswordVisibilityButton(passwordVisible: Boolean, onClick: () -> Unit) {
    androidx.compose.foundation.Image(
        painter = painterResource(id = R.drawable.icon_uneye),
        contentDescription = if (passwordVisible) "隐藏密码" else "显示密码",
        modifier = Modifier.size(34.dp).alpha(if (passwordVisible) 0.45f else 1f).clickable(onClick = onClick).padding(3.dp),
        contentScale = ContentScale.Fit
    )
}

@Composable
fun BlinkingCursor(modifier: Modifier = Modifier) {
    var visible by remember { mutableStateOf(true) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(530.milliseconds)
            visible = !visible
        }
    }
    if (visible) Box(modifier = modifier.background(CorosRed))
}

@Composable
fun ThirdPartyArea(onUnavailableClick: () -> Unit) {
    Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
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
fun ThirdPartyCircle(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier.size(34.dp).clip(CircleShape).border(1.dp, Color(0xFF303036), CircleShape).clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = CorosWhite, fontSize = 20.sp)
    }
}

@Composable
fun ErrorText(message: String?) {
    if (!message.isNullOrBlank()) {
        Text(text = message, color = CorosRed, fontSize = 15.sp, modifier = Modifier.padding(top = 10.dp))
    }
}

@Composable
fun TermsConsentSheet(onDismiss: () -> Unit, onPrivacyClick: () -> Unit, onServiceTermsClick: () -> Unit, onAgree: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.78f))) {
        Column(
            modifier = Modifier.align(Alignment.BottomCenter).fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                .background(Color(0xFF1A1A1B)).padding(horizontal = 22.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = "×", color = CorosWhite, fontSize = 34.sp, modifier = Modifier.align(Alignment.End).clickable(onClick = onDismiss))
            Spacer(modifier = Modifier.height(12.dp))
            Text(text = "阅读并同意以下条款，", color = CorosWhite, fontSize = 18.sp, textAlign = TextAlign.Center)
            Row(modifier = Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically) {
                Text(text = "《隐私政策》", color = CorosRed, fontSize = 18.sp, modifier = Modifier.clickable(onClick = onPrivacyClick))
                Text(text = " 和 ", color = CorosWhite, fontSize = 18.sp)
                Text(text = "《服务条款》", color = CorosRed, fontSize = 18.sp, modifier = Modifier.clickable(onClick = onServiceTermsClick))
            }
            Spacer(modifier = Modifier.height(42.dp))
            CorosFilledButton(text = "同意并继续", color = CorosRed, onClick = onAgree)
        }
    }
}

@Composable
fun UnavailableFeatureDialog(onDismiss: () -> Unit) {
    Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.62f)).clickable(onClick = onDismiss), contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier.padding(horizontal = 42.dp).clip(RoundedCornerShape(12.dp))
                .background(Color(0xFF222224)).padding(horizontal = 28.dp, vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = "抱歉，该功能还在实现中", color = CorosWhite, fontSize = 16.sp, textAlign = TextAlign.Center)
            Spacer(modifier = Modifier.height(20.dp))
            Text(text = "知道了", color = CorosRed, fontSize = 16.sp, modifier = Modifier.clickable(onClick = onDismiss))
        }
    }
}

@Composable
fun BlockingLoadingOverlay() {
    Box(modifier = Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.72f)), contentAlignment = Alignment.Center) {
        Box(modifier = Modifier.size(96.dp).clip(RoundedCornerShape(8.dp)).background(Color(0xFF3A3A3C)), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(modifier = Modifier.size(36.dp), color = Color(0xFFD8D8DD), strokeWidth = 4.dp)
        }
    }
}

@Composable
fun VerticalScrollbar(scrollState: ScrollState, modifier: Modifier = Modifier, width: Dp = 3.dp, minThumbHeight: Dp = 24.dp, color: Color = CorosWhite.copy(alpha = 0.45f)) {
    val density = LocalDensity.current
    val widthPx = with(density) { width.toPx() }
    val minThumbHeightPx = with(density) { minThumbHeight.toPx() }
    Box(modifier = modifier.width(width).drawWithContent {
        drawContent()
        val viewportHeight = size.height
        val maxScrollValue = scrollState.maxValue
        if (maxScrollValue <= 0 || viewportHeight <= 0f) return@drawWithContent
        val totalContentHeight = viewportHeight + maxScrollValue
        val thumbHeightPx = (viewportHeight * viewportHeight / totalContentHeight).coerceAtLeast(minThumbHeightPx).coerceAtMost(viewportHeight)
        val maxThumbOffsetPx = viewportHeight - thumbHeightPx
        val progress = (scrollState.value.toFloat() / maxScrollValue.toFloat()).coerceIn(0f, 1f)
        val thumbOffsetPx = progress * maxThumbOffsetPx
        drawRoundRect(color = color, topLeft = Offset(x = 0f, y = thumbOffsetPx), size = Size(width = widthPx, height = thumbHeightPx), cornerRadius = CornerRadius(x = widthPx / 2f, y = widthPx / 2f))
    })
}

@Composable
fun LegalDocumentPage(title: String, paragraphs: List<LegalParagraph>, onBack: () -> Unit) {
    val scrollState = rememberScrollState()
    Column(modifier = Modifier.fillMaxSize().background(CorosBlack).statusBarsPadding().padding(horizontal = 20.dp)) {
        Box(modifier = Modifier.fillMaxWidth().height(52.dp), contentAlignment = Alignment.Center) {
            Text(text = "‹", color = CorosWhite, fontSize = 44.sp, modifier = Modifier.align(Alignment.CenterStart).clickable(onClick = onBack))
            Text(text = title, color = CorosWhite, fontSize = 18.sp, fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
        }
        Box(modifier = Modifier.fillMaxWidth().weight(1f)) {
            Column(modifier = Modifier.fillMaxSize().verticalScroll(scrollState).padding(top = 58.dp, bottom = 32.dp, end = 12.dp)) {
                paragraphs.forEachIndexed { index, paragraph ->
                    LegalParagraphText(paragraph = paragraph)
                    if (index != paragraphs.lastIndex) Spacer(modifier = Modifier.height(if (paragraph.isHeading) 8.dp else 12.dp))
                }
            }
            VerticalScrollbar(scrollState = scrollState, modifier = Modifier.align(Alignment.CenterEnd).fillMaxHeight().padding(top = 24.dp, bottom = 24.dp))
        }
    }
}

@Composable
fun LegalParagraphText(paragraph: LegalParagraph) {
    Text(
        text = buildLegalText(paragraph.text, paragraph.highlights),
        color = if (paragraph.isHeading) CorosWhite else Color(0xFFC9C9CC),
        fontSize = if (paragraph.isHeading) 19.sp else 18.sp,
        lineHeight = if (paragraph.isHeading) 28.sp else 30.sp,
        fontWeight = if (paragraph.isHeading) FontWeight.Bold else FontWeight.Normal
    )
}

// Use com.example.demo.common.login.VerifyTarget instead of local enum
enum class TermsPromptAction { Login, PhoneCode, EmailCode }
