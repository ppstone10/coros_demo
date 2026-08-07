package com.example.demo.auth.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.withLink
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImages
import com.example.demo.core.theme.DemoTheme
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.milliseconds

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
            Box(modifier = Modifier.fillMaxSize().border(width = 0.dp, color = AppColors.Core.Transparent)) {
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
        Text(text = stringResource(R.string.auth_china_dialing_code), color = CorosWhite, fontSize = 17.sp)
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
                    if (value.isBlank()) Text(text = stringResource(R.string.auth_phone_placeholder), color = CorosMuted, fontSize = 17.sp)
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
        append(stringResource(R.string.auth_terms_inline_prefix))
        withLink(LinkAnnotation.Clickable(tag = "privacy", styles = linkStyle) { onPrivacyClick() }) { append(stringResource(R.string.auth_privacy_policy_link)) }
        append(stringResource(R.string.auth_terms_joiner))
        withLink(LinkAnnotation.Clickable(tag = "terms", styles = linkStyle) { onServiceTermsClick() }) { append(stringResource(R.string.auth_service_terms_link)) }
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
        Canvas(modifier = Modifier.size(AgreementCheckVisualSize)) {
            val strokeWidth = 1.dp.toPx()
            val radius = size.minDimension / 2f - strokeWidth / 2f
            val checkStroke = 1.4.dp.toPx()
            drawCircle(color = if (accepted) CorosRed else AppColors.Core.Transparent, radius = radius)
            drawCircle(color = if (accepted) CorosRed else CorosWhite.copy(alpha = 0.82f), radius = radius, style = Stroke(width = strokeWidth))
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
            textStyle = TextStyle(color = AppColors.Core.Transparent),
            cursorBrush = SolidColor(AppColors.Core.Transparent),
            modifier = Modifier.weight(1f).focusRequester(focusRequester),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth()) {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(36.dp)) {
                        repeat(4) { index ->
                            val isActiveBox = index == code.length && code.length < 4
                            Box(
                                modifier = Modifier.weight(1f).aspectRatio(1f).clip(RoundedCornerShape(12.dp))
                                    .background(if (isActiveBox) AppColors.Auth.InputBox else CorosBlack)
                                    .border(2.dp, if (hasError) CorosRed else AppColors.Auth.InputBorder, RoundedCornerShape(12.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                val digit = code.getOrNull(index)?.toString()
                                if (digit != null) Text(text = digit, color = CorosWhite, fontSize = 30.sp)
                                else if (isActiveBox) BlinkingCursor(modifier = Modifier.width(2.dp).height(28.dp))
                            }
                        }
                    }
                    Box(modifier = Modifier.matchParentSize().background(AppColors.Core.Transparent)) { innerTextField() }
                }
            }
        )
    }
}

@Composable
fun ClearInputButton(visible: Boolean, onClick: () -> Unit) {
    Box(modifier = Modifier.size(34.dp), contentAlignment = Alignment.Center) {
        if (visible) {
            AppImage(
                asset = AppImages.Auth.ClearInput,
                contentDescription = stringResource(R.string.auth_clear_input),
                modifier = Modifier.size(28.dp).clickable(onClick = onClick).padding(4.dp)
            )
        }
    }
}

@Composable
fun PasswordVisibilityButton(passwordVisible: Boolean, onClick: () -> Unit) {
    AppImage(
        asset = AppImages.Auth.PasswordHidden,
        contentDescription = if (passwordVisible) stringResource(R.string.auth_hide_password) else stringResource(R.string.auth_show_password),
        modifier = Modifier.size(34.dp).alpha(if (passwordVisible) 0.45f else 1f).clickable(onClick = onClick).padding(3.dp)
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

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun CorosFilledButtonPreview() {
    DemoTheme {
        Column(Modifier.padding(20.dp)) {
            CorosFilledButton(text = "Register", color = CorosRed, onClick = {})
            Spacer(Modifier.height(12.dp))
            CorosFilledButton(text = "Login", color = CorosRed.copy(alpha = 0.45f), onClick = {}, enabled = false)
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun UnderlineInputPreview() {
    DemoTheme {
        var text by remember { mutableStateOf("") }
        Column(Modifier.padding(20.dp)) {
            UnderlineInput(value = text, placeholder = "Email", onValueChange = { text = it }, keyboardType = KeyboardType.Email)
            Spacer(Modifier.height(20.dp))
            UnderlineInput(value = "password123", placeholder = "Password", onValueChange = {}, keyboardType = KeyboardType.Password, isPassword = true)
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun PhoneInputPreview() {
    DemoTheme {
        var phone by remember { mutableStateOf("") }
        Column(Modifier.padding(20.dp)) {
            PhoneInput(value = phone, onValueChange = { phone = it })
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun CodeBoxesPreview() {
    DemoTheme {
        var code by remember { mutableStateOf("") }
        Column(Modifier.padding(20.dp)) {
            CodeBoxes(code = code, hasError = false, onCodeChanged = { code = it })
            Spacer(Modifier.height(30.dp))
            CodeBoxes(code = "12", hasError = true, onCodeChanged = {})
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun AgreementRowPreview() {
    DemoTheme {
        var accepted by remember { mutableStateOf(false) }
        Column(Modifier.padding(20.dp)) {
            AgreementRow(accepted = accepted, onToggle = { accepted = !accepted }, onPrivacyClick = {}, onServiceTermsClick = {})
        }
    }
}
