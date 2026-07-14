package com.example.demo.login.profile

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.widget.ImageView
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.example.demo.common.login.MeasurementSystem
import com.example.demo.common.login.UserGender
import com.example.demo.common.login.UserProfile
import com.example.demo.common.login.toProfileCountryRegion
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.CorosBlack
import com.example.demo.login.components.CorosButtonRed
import com.example.demo.login.components.CorosFilledButton
import com.example.demo.login.components.CorosLine
import com.example.demo.login.components.CorosMuted
import com.example.demo.login.components.CorosRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.ErrorText
import com.example.demo.login.components.ModalScrim
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImageAsset
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppText
import com.example.demo.ui.theme.DemoTheme
import java.io.File
import java.io.FileOutputStream
import kotlin.math.abs
import androidx.core.net.toUri

private enum class ProfilePicker {
    BirthDate,
    Height,
    Weight,
    Unit,
    Country
}

@Composable
fun ProfileCompletionScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit
) {
    val state = viewModel.state
    val savedProfile = state.currentSession?.profile
    val sessionName = state.currentSession?.resolvedDisplayName.orEmpty()
    var avatarUri by rememberSaveable(savedProfile?.avatarUri) { mutableStateOf(savedProfile?.avatarUri) }
    var username by rememberSaveable(savedProfile?.username, sessionName) {
        mutableStateOf(savedProfile?.username?.takeIf { it.isNotBlank() } ?: sessionName)
    }
    var birthDate by rememberSaveable(savedProfile?.birthDate) { mutableStateOf(savedProfile?.birthDate.orEmpty()) }
    var heightCm by rememberSaveable(savedProfile?.heightCm) { mutableStateOf(savedProfile?.heightCm) }
    var weightKg by rememberSaveable(savedProfile?.weightKg) { mutableStateOf(savedProfile?.weightKg) }
    var measurementSystem by rememberSaveable(savedProfile?.measurementSystem) {
        mutableStateOf(savedProfile?.measurementSystem ?: MeasurementSystem.Metric)
    }
    var phone by rememberSaveable(savedProfile?.phone) { mutableStateOf(savedProfile?.phone.orEmpty()) }
    val registeredCountryRegion = state.currentSession?.region?.toProfileCountryRegion().orEmpty()
    var countryRegion by rememberSaveable(savedProfile?.countryRegion, registeredCountryRegion) {
        mutableStateOf(
            savedProfile?.countryRegion?.takeIf { it.isNotBlank() }
                ?: registeredCountryRegion.ifBlank { "中国" }
        )
    }
    var gender by rememberSaveable(savedProfile?.gender) { mutableStateOf(savedProfile?.gender) }
    var picker by remember { mutableStateOf<ProfilePicker?>(null) }
    var showAvatarSheet by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        if (uri != null) avatarUri = copyAvatarToPrivateFile(context, uri)
    }
    val cameraPicker = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bitmap: Bitmap? ->
        if (bitmap != null) avatarUri = saveAvatarBitmap(context, bitmap)
    }

    val profile = UserProfile(
        avatarUri = avatarUri,
        username = username,
        birthDate = birthDate,
        heightCm = heightCm,
        weightKg = weightKg,
        measurementSystem = measurementSystem,
        phone = phone,
        countryRegion = countryRegion,
        gender = gender
    )

    BackHandler(onBack = onBack)

    Box(modifier = Modifier.fillMaxSize().background(CorosBlack)) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 18.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth().height(52.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = AppText.Common.Back,
                    color = CorosWhite,
                    fontSize = 44.sp,
                    modifier = Modifier.clickable(onClick = onBack)
                )
            }
            Column(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.height(14.dp))
                Text(
                    text = AppText.Profile.CompletionTitle,
                    color = CorosWhite,
                    fontSize = 28.sp,
                    lineHeight = 34.sp,
                    fontWeight = FontWeight.Light
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = AppText.Profile.CompletionDescription,
                    color = AppColors.Profile.Description,
                    fontSize = 14.sp,
                    lineHeight = 20.sp
                )
                Spacer(modifier = Modifier.height(20.dp))
                ProfileAvatar(
                    avatarUri = avatarUri,
                    modifier = Modifier.align(Alignment.CenterHorizontally),
                    onClick = { showAvatarSheet = true }
                )
                Spacer(modifier = Modifier.height(20.dp))
                ProfileTextRow(
                    label = AppText.Profile.Username,
                    required = true,
                    value = username,
                    placeholder = AppText.Profile.UsernamePlaceholder,
                    keyboardType = KeyboardType.Text,
                    onValueChange = { username = it.take(20) }
                )
                ProfilePickerRow(
                    label = AppText.Profile.BirthDate,
                    required = true,
                    value = birthDate,
                    placeholder = AppText.Profile.FillIn,
                    onClick = { picker = ProfilePicker.BirthDate }
                )
                ProfilePickerRow(
                    label = AppText.Profile.Height,
                    required = true,
                    value = heightCm?.let { "$it cm" }.orEmpty(),
                    placeholder = AppText.Profile.FillIn,
                    onClick = { picker = ProfilePicker.Height }
                )
                ProfilePickerRow(
                    label = AppText.Profile.Weight,
                    required = true,
                    value = weightKg?.let { String.format("%.1f kg", it) }.orEmpty(),
                    placeholder = AppText.Profile.FillIn,
                    onClick = { picker = ProfilePicker.Weight }
                )
                ProfilePickerRow(
                    label = AppText.Profile.Measurement,
                    required = false,
                    value = measurementSystem.displayText(),
                    placeholder = "",
                    onClick = { picker = ProfilePicker.Unit }
                )
                ProfileTextRow(
                    label = AppText.Profile.Phone,
                    required = false,
                    value = phone,
                    placeholder = AppText.Profile.PhonePlaceholder,
                    keyboardType = KeyboardType.Phone,
                    onValueChange = { phone = it.filter { char -> char.isDigit() || char == '+' || char == '-' }.take(20) }
                )
                ProfilePickerRow(
                    label = AppText.Profile.CountryRegion,
                    required = false,
                    value = countryRegion,
                    placeholder = AppText.Common.China,
                    onClick = { picker = ProfilePicker.Country }
                )
                GenderRow(selected = gender, onSelected = { gender = it })
                Spacer(modifier = Modifier.height(10.dp))
            }
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(CorosBlack)
                    .padding(top = 8.dp, bottom = 10.dp)
            ) {
                ErrorText(state.errorMessage)
                Spacer(modifier = Modifier.height(5.dp))
                CorosFilledButton(
                    text = AppText.Common.Complete,
                    color = CorosButtonRed,
                    enabled = viewModel.canSubmitProfile(profile),
                    isLoading = state.isLoading,
                    buttonHeight = 48.dp,
                    onClick = { viewModel.onProfileSubmitted(profile) }
                )
            }
        }

        when (picker) {
            ProfilePicker.BirthDate -> BirthDateSheet(
                current = birthDate,
                onDismiss = { picker = null },
                onConfirm = {
                    birthDate = it
                    picker = null
                }
            )
            ProfilePicker.Height -> HeightSheet(
                current = heightCm ?: 175,
                onDismiss = { picker = null },
                onConfirm = {
                    heightCm = it
                    picker = null
                }
            )
            ProfilePicker.Weight -> WeightSheet(
                current = weightKg ?: 60.0,
                onDismiss = { picker = null },
                onConfirm = {
                    weightKg = it
                    picker = null
                }
            )
            ProfilePicker.Unit -> OptionSheet(
                title = AppText.Profile.Measurement,
                options = listOf(
                    MeasurementSystem.Metric to MeasurementSystem.Metric.displayText(),
                    MeasurementSystem.Imperial to MeasurementSystem.Imperial.displayText()
                ),
                selected = measurementSystem,
                onDismiss = { picker = null },
                onConfirm = {
                    measurementSystem = it
                    picker = null
                }
            )
            ProfilePicker.Country -> OptionSheet(
                title = AppText.Profile.CountryRegion,
                options = listOf("中国" to "中国", "美国" to "美国", "英国" to "英国", "日本" to "日本"),
                selected = countryRegion,
                onDismiss = { picker = null },
                onConfirm = {
                    countryRegion = it
                    picker = null
                }
            )
            null -> Unit
        }

        if (showAvatarSheet) {
            AvatarActionSheet(
                onDismiss = { showAvatarSheet = false },
                onAlbum = {
                    showAvatarSheet = false
                    imagePicker.launch("image/*")
                },
                onCamera = {
                    showAvatarSheet = false
                    cameraPicker.launch(null)
                }
            )
        }
    }
}

@Composable
internal fun ProfileAvatar(
    avatarUri: String?,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .size(76.dp)
            .clip(CircleShape)
            .background(AppColors.Profile.AvatarBackground)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (avatarUri.isNullOrBlank()) {
            AppImage(
                asset = AppImages.Profile.Camera,
                contentDescription = AppText.Profile.AddAvatar,
                modifier = Modifier.fillMaxSize()
            )
        } else {
            val context = LocalContext.current
            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = {
                    ImageView(context).apply {
                        scaleType = ImageView.ScaleType.CENTER_CROP
                    }
                },
                update = { it.setImageURI(avatarUri.toUri()) }
            )
        }
    }
}

@Composable
private fun ProfileTextRow(
    label: String,
    required: Boolean,
    value: String,
    placeholder: String,
    keyboardType: KeyboardType,
    onValueChange: (String) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth().height(56.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RequiredLabel(text = label, required = required)
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
            textStyle = TextStyle(
                color = CorosWhite,
                fontSize = 15.sp,
                textAlign = TextAlign.End
            ),
            cursorBrush = SolidColor(CorosRed),
            modifier = Modifier.weight(1f),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
                    if (value.isBlank()) {
                        Text(text = placeholder, color = CorosMuted, fontSize = 15.sp)
                    }
                    innerTextField()
                }
            }
        )
    }
    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(CorosLine))
}

@Composable
fun ProfilePickerRow(
    label: String,
    required: Boolean,
    value: String,
    placeholder: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .clickable(onClick = onClick),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RequiredLabel(text = label, required = required)
        Spacer(modifier = Modifier.weight(1f))
        Text(
            text = value.ifBlank { placeholder },
            color = if (value.isBlank()) CorosMuted else AppColors.Profile.Value,
            fontSize = 15.sp,
            textAlign = TextAlign.End
        )
        Spacer(modifier = Modifier.width(8.dp))
        AppImage(
            asset = AppImages.Profile.Next,
            contentDescription = null,
            modifier = Modifier.size(19.dp)
        )
    }
    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(CorosLine))
}

@Composable
private fun RequiredLabel(text: String, required: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(text = text, color = CorosWhite, fontSize = 16.sp)
        if (required) Text(text = "*", color = CorosRed, fontSize = 13.sp)
    }
}

@Composable
private fun GenderRow(selected: UserGender?, onSelected: (UserGender) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().height(62.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RequiredLabel(text = AppText.Profile.Gender, required = true)
        Spacer(modifier = Modifier.weight(1f))
        GenderButton(
            icon = AppImages.Profile.Female,
            text = AppText.Common.Female,
            selected = selected == UserGender.Female,
            onClick = { onSelected(UserGender.Female) }
        )
        Spacer(modifier = Modifier.width(10.dp))
        GenderButton(
            icon = AppImages.Profile.Male,
            text = AppText.Common.Male,
            selected = selected == UserGender.Male,
            onClick = { onSelected(UserGender.Male) }
        )
    }
}

@Composable
private fun GenderButton(icon: AppImageAsset, text: String, selected: Boolean, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .width(72.dp)
            .height(40.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(AppColors.Profile.Control)
            .border(
                width = if (selected) 1.dp else 0.dp,
                color = if (selected) CorosRed else AppColors.Core.Transparent,
                shape = RoundedCornerShape(8.dp)
            )
            .clickable(onClick = onClick),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        AppImage(
            asset = icon,
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = text,
            color = if (selected) CorosRed else AppColors.Auth.InputText,
            fontSize = 16.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
internal fun BirthDateSheet(
    current: String,
    onDismiss: () -> Unit,
    onConfirm: (String) -> Unit
) {
    val parsed = remember(current) { parseBirthDate(current) }
    var year by rememberSaveable(current) { mutableIntStateOf(parsed.first) }
    var month by rememberSaveable(current) { mutableIntStateOf(parsed.second) }
    var day by rememberSaveable(current) { mutableIntStateOf(parsed.third) }
    PickerSheet(title = AppText.Profile.BirthDate, onDismiss = onDismiss, onConfirm = {
        onConfirm("${year}年${month}月${day}日")
    }) {
        Row(
            modifier = Modifier.fillMaxWidth().height(240.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically
        ) {
            WheelNumberPicker(
                value = year,
                min = 1950,
                max = 2026,
                displayedSuffix = "年",
                modifier = Modifier.weight(1f),
                onValueChange = { year = it }
            )
            WheelNumberPicker(
                value = month,
                min = 1,
                max = 12,
                displayedSuffix = "月",
                modifier = Modifier.weight(1f),
                onValueChange = { month = it }
            )
            WheelNumberPicker(
                value = day,
                min = 1,
                max = 31,
                displayedSuffix = "日",
                modifier = Modifier.weight(1f),
                onValueChange = { day = it }
            )
        }
    }
}

@Composable
internal fun HeightSheet(
    current: Int,
    onDismiss: () -> Unit,
    onConfirm: (Int) -> Unit
) {
    var height by rememberSaveable(current) { mutableIntStateOf(current.coerceIn(100, 230)) }
    PickerSheet(title = AppText.Profile.HeightPicker, onDismiss = onDismiss, onConfirm = { onConfirm(height) }) {
        Box(modifier = Modifier.fillMaxWidth().height(240.dp), contentAlignment = Alignment.Center) {
            WheelNumberPicker(value = height, min = 100, max = 230, onValueChange = { height = it })
        }
    }
}

@Composable
internal fun WeightSheet(
    current: Double,
    onDismiss: () -> Unit,
    onConfirm: (Double) -> Unit
) {
    var integerPart by rememberSaveable(current) { mutableIntStateOf(current.toInt().coerceIn(30, 200)) }
    var decimalPart by rememberSaveable(current) {
        mutableIntStateOf(((current - current.toInt()) * 10).toInt().coerceIn(0, 9))
    }
    PickerSheet(title = AppText.Profile.WeightPicker, onDismiss = onDismiss, onConfirm = {
        onConfirm(integerPart + decimalPart / 10.0)
    }) {
        Row(
            modifier = Modifier.fillMaxWidth().height(240.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            WheelNumberPicker(value = integerPart, min = 30, max = 200, onValueChange = { integerPart = it })
            Text(text = ".", color = CorosWhite, fontSize = 32.sp, modifier = Modifier.padding(horizontal = 16.dp))
            WheelNumberPicker(value = decimalPart, min = 0, max = 9, onValueChange = { decimalPart = it })
        }
    }
}

@Composable
fun <T> OptionSheet(
    title: String,
    options: List<Pair<T, String>>,
    selected: T,
    onDismiss: () -> Unit,
    onConfirm: (T) -> Unit
) {
    var current by remember { mutableStateOf(selected) }
    PickerSheet(title = title, onDismiss = onDismiss, onConfirm = { onConfirm(current) }) {
        Column(
            modifier = Modifier.fillMaxWidth().height(240.dp),
            verticalArrangement = Arrangement.Center
        ) {
            options.forEach { (value, label) ->
                val isSelected = value == current
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp)
                        .padding(horizontal = 20.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .border(
                            width = if (isSelected) 1.dp else 0.dp,
                            color = if (isSelected) AppColors.Profile.SelectedBorder else AppColors.Core.Transparent,
                            shape = RoundedCornerShape(8.dp)
                        )
                        .clickable { current = value },
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = label,
                        color = if (isSelected) CorosWhite else CorosMuted,
                        fontSize = if (isSelected) 22.sp else 18.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun PickerSheet(
    title: String,
    onDismiss: () -> Unit,
    onConfirm: () -> Unit,
    content: @Composable () -> Unit
) {
    BackHandler(onBack = onDismiss)
    Box(modifier = Modifier.fillMaxSize()) {
        ModalScrim(
            color = AppColors.Core.Black.copy(alpha = 0.72f),
            onClick = onDismiss
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 14.dp, topEnd = 14.dp))
                .background(AppColors.Auth.Sheet)
                .navigationBarsPadding()
        ) {
            Box(modifier = Modifier.fillMaxWidth().height(70.dp)) {
                AppImage(
                    asset = AppImages.Profile.Close,
                    contentDescription = AppText.Profile.Close,
                    modifier = Modifier
                        .align(Alignment.CenterStart)
                        .padding(start = 22.dp)
                        .size(32.dp)
                        .clickable(onClick = onDismiss)
                )
                Text(
                    text = title,
                    color = CorosWhite,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.align(Alignment.Center)
                )
                AppImage(
                    asset = AppImages.Profile.Confirm,
                    contentDescription = AppText.Common.Confirm,
                    modifier = Modifier
                        .align(Alignment.CenterEnd)
                        .padding(end = 26.dp)
                        .size(34.dp)
                        .clickable(onClick = onConfirm)
                )
            }
            content()
            Spacer(modifier = Modifier.height(28.dp))
        }
    }
}

@Composable
private fun WheelNumberPicker(
    value: Int,
    min: Int,
    max: Int,
    modifier: Modifier = Modifier,
    displayedSuffix: String = "",
    onValueChange: (Int) -> Unit
) {
    val values = remember(min, max) { (min..max).toList() }
    val selectedIndex = (value - min).coerceIn(0, values.lastIndex)
    val itemHeight = 54.dp
    val density = LocalDensity.current
    val itemHeightPx = with(density) { itemHeight.toPx() }
    val listState = rememberLazyListState(initialFirstVisibleItemIndex = selectedIndex)

    LaunchedEffect(listState.firstVisibleItemIndex, listState.firstVisibleItemScrollOffset, values) {
        val scrollOffsetItems = ((listState.firstVisibleItemScrollOffset + itemHeightPx / 2f) / itemHeightPx).toInt()
        val centerIndex = (listState.firstVisibleItemIndex + scrollOffsetItems).coerceIn(values.indices)
        val centerValue = values[centerIndex]
        if (centerValue != value) onValueChange(centerValue)
    }

    LaunchedEffect(value, values) {
        val target = (value - min).coerceIn(0, values.lastIndex)
        if (abs(listState.firstVisibleItemIndex - target) > 4) {
            listState.scrollToItem(target)
        }
    }

    LazyColumn(
        state = listState,
        modifier = modifier.width(140.dp).height(248.dp),
        contentPadding = PaddingValues(vertical = itemHeight * 2),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        items(values.size) { index ->
            val item = values[index]
            val distance = abs(index - selectedIndex)
            val isSelected = distance == 0
            val textColor = when (distance) {
                0 -> CorosWhite
                1 -> AppColors.Profile.WheelNear
                2 -> AppColors.Profile.WheelFar
                else -> AppColors.Profile.WheelFarthest
            }
            val fontSize = when (distance) {
                0 -> 28.sp
                1 -> 23.sp
                else -> 18.sp
            }
            Box(
                modifier = Modifier
                    .height(itemHeight)
                    .width(112.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .border(
                        width = if (isSelected) 1.dp else 0.dp,
                        color = if (isSelected) AppColors.Profile.WheelSelectedBorder else AppColors.Core.Transparent,
                        shape = RoundedCornerShape(8.dp)
                    )
                    .clickable { onValueChange(item) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "$item$displayedSuffix",
                    color = textColor,
                    fontSize = fontSize,
                    fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal,
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
internal fun AvatarActionSheet(
    onDismiss: () -> Unit,
    onAlbum: () -> Unit,
    onCamera: () -> Unit
) {
    BackHandler(onBack = onDismiss)
    Box(modifier = Modifier.fillMaxSize()) {
        ModalScrim(
            color = AppColors.Core.Black.copy(alpha = 0.42f),
            onClick = onDismiss
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 10.dp, topEnd = 10.dp))
                .background(AppColors.Profile.ActionSheet)
                .navigationBarsPadding()
        ) {
            SheetAction(text = AppText.Profile.TakePhoto, onClick = onCamera)
            Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(CorosLine))
            SheetAction(text = AppText.Profile.Album, onClick = onAlbum)
            Box(modifier = Modifier.fillMaxWidth().height(8.dp).background(AppColors.Profile.ActionSheetDivider))
            SheetAction(text = AppText.Common.Cancel, onClick = onDismiss)
        }
    }
}

@Composable
private fun SheetAction(text: String, onClick: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxWidth().height(64.dp).clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(text = text, color = CorosWhite, fontSize = 20.sp)
    }
}

private fun MeasurementSystem.displayText(): String {
    return when (this) {
        MeasurementSystem.Metric -> "公制（km/m/cm/kg）"
        MeasurementSystem.Imperial -> "英制（mi/ft/inch/lb）"
    }
}

private fun parseBirthDate(value: String): Triple<Int, Int, Int> {
    val numbers = Regex("\\d+").findAll(value).map { it.value.toIntOrNull() ?: 0 }.toList()
    return Triple(
        numbers.getOrNull(0)?.takeIf { it in 1950..2026 } ?: 2002,
        numbers.getOrNull(1)?.takeIf { it in 1..12 } ?: 11,
        numbers.getOrNull(2)?.takeIf { it in 1..31 } ?: 17
    )
}

internal fun saveAvatarBitmap(context: Context, bitmap: Bitmap): String {
    val directory = File(context.filesDir, "profile_avatars").also { it.mkdirs() }
    val file = File(directory, "avatar_${System.currentTimeMillis()}.jpg")
    FileOutputStream(file).use { output ->
        bitmap.compress(Bitmap.CompressFormat.JPEG, 92, output)
    }
    return Uri.fromFile(file).toString()
}

internal fun copyAvatarToPrivateFile(context: Context, uri: Uri): String {
    val directory = File(context.filesDir, "profile_avatars").also { it.mkdirs() }
    val file = File(directory, "avatar_${System.currentTimeMillis()}.jpg")
    context.contentResolver.openInputStream(uri)?.use { input ->
        FileOutputStream(file).use { output -> input.copyTo(output) }
    }
    return Uri.fromFile(file).toString()
}

@Preview(showBackground = true)
@Composable
private fun ProfileCompletionScreenPreview() {
    DemoTheme {
        ProfileCompletionScreen(
            viewModel = LoginViewModel(),
            onBack = {}
        )
    }
}
