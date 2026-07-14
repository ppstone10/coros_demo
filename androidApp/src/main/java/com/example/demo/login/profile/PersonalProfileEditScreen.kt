package com.example.demo.login.profile

import android.graphics.Bitmap
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.common.login.MeasurementSystem
import com.example.demo.common.login.UserGender
import com.example.demo.common.login.UserProfile
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.CorosBlack
import com.example.demo.login.components.CorosLine
import com.example.demo.login.components.CorosMuted
import com.example.demo.login.components.CorosRed
import com.example.demo.login.components.CorosWhite
import com.example.demo.login.components.ErrorText
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppText
import com.example.demo.ui.theme.DemoTheme

private enum class PersonalProfilePicker {
    BirthDate,
    Gender,
    Height,
    Weight,
    Country
}

@Composable
fun PersonalProfileEditScreen(
    viewModel: LoginViewModel,
    onBack: () -> Unit,
    onSaved: () -> Unit
) {
    val savedProfile = viewModel.state.currentSession?.profile ?: UserProfile()
    var avatarUri by rememberSaveable(savedProfile.avatarUri) {
        mutableStateOf(savedProfile.avatarUri)
    }
    var username by rememberSaveable(savedProfile.username) {
        mutableStateOf(savedProfile.username)
    }
    var gender by rememberSaveable(savedProfile.gender) {
        mutableStateOf(savedProfile.gender)
    }
    var birthDate by rememberSaveable(savedProfile.birthDate) {
        mutableStateOf(savedProfile.birthDate)
    }
    var heightCm by rememberSaveable(savedProfile.heightCm) {
        mutableStateOf(savedProfile.heightCm)
    }
    var weightKg by rememberSaveable(savedProfile.weightKg) {
        mutableStateOf(savedProfile.weightKg)
    }
    var countryRegion by rememberSaveable(savedProfile.countryRegion) {
        mutableStateOf(savedProfile.countryRegion)
    }
    var picker by remember { mutableStateOf<PersonalProfilePicker?>(null) }
    var showAvatarSheet by remember { mutableStateOf(false) }
    var usernameEditing by rememberSaveable { mutableStateOf(false) }
    var localError by rememberSaveable { mutableStateOf<String?>(null) }
    val context = LocalContext.current
    val imagePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        if (uri != null) avatarUri = copyAvatarToPrivateFile(context, uri)
    }
    val cameraPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicturePreview()
    ) { bitmap: Bitmap? ->
        if (bitmap != null) avatarUri = saveAvatarBitmap(context, bitmap)
    }
    val profile = savedProfile.copy(
        avatarUri = avatarUri,
        username = username,
        gender = gender,
        birthDate = birthDate,
        heightCm = heightCm,
        weightKg = weightKg,
        countryRegion = countryRegion
    )
    val hasChanges = profile != savedProfile

    BackHandler(onBack = onBack)

    Box(Modifier.fillMaxSize().background(CorosBlack)) {
        PersonalProfileEditContent(
            profile = profile,
            errorMessage = localError,
            saveEnabled = hasChanges && viewModel.canSubmitProfile(profile),
            onBack = onBack,
            onSave = {
                localError = viewModel.updateProfileMessage(profile)
                if (localError == null) onSaved()
            },
            onAvatarClick = { showAvatarSheet = true },
            usernameEditing = usernameEditing,
            onUsernameEditClick = { usernameEditing = true },
            onUsernameChange = { username = it.take(20) },
            onGenderClick = { picker = PersonalProfilePicker.Gender },
            onBirthDateClick = { picker = PersonalProfilePicker.BirthDate },
            onHeightClick = { picker = PersonalProfilePicker.Height },
            onWeightClick = { picker = PersonalProfilePicker.Weight },
            onCountryClick = { picker = PersonalProfilePicker.Country }
        )

        when (picker) {
            PersonalProfilePicker.BirthDate -> BirthDateSheet(
                current = birthDate,
                onDismiss = { picker = null },
                onConfirm = {
                    birthDate = it
                    picker = null
                }
            )
            PersonalProfilePicker.Gender -> OptionSheet(
                title = AppText.Profile.Gender,
                options = listOf(UserGender.Female to AppText.Common.Female, UserGender.Male to AppText.Common.Male),
                selected = gender ?: UserGender.Male,
                onDismiss = { picker = null },
                onConfirm = {
                    gender = it
                    picker = null
                }
            )
            PersonalProfilePicker.Height -> HeightSheet(
                current = heightCm ?: 175,
                onDismiss = { picker = null },
                onConfirm = {
                    heightCm = it
                    picker = null
                }
            )
            PersonalProfilePicker.Weight -> WeightSheet(
                current = weightKg ?: 60.0,
                onDismiss = { picker = null },
                onConfirm = {
                    weightKg = it
                    picker = null
                }
            )
            PersonalProfilePicker.Country -> OptionSheet(
                title = AppText.Profile.CountryRegion,
                options = listOf("中国" to "中国", "美国" to "美国", "英国" to "英国", "日本" to "日本"),
                selected = countryRegion.ifBlank { AppText.Common.China },
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
private fun PersonalProfileEditContent(
    profile: UserProfile,
    errorMessage: String?,
    saveEnabled: Boolean,
    onBack: () -> Unit,
    onSave: () -> Unit,
    onAvatarClick: () -> Unit,
    usernameEditing: Boolean,
    onUsernameEditClick: () -> Unit,
    onUsernameChange: (String) -> Unit,
    onGenderClick: () -> Unit,
    onBirthDateClick: () -> Unit,
    onHeightClick: () -> Unit,
    onWeightClick: () -> Unit,
    onCountryClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(62.dp)
                .padding(horizontal = 18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = AppText.Common.Back,
                color = CorosWhite,
                fontSize = 34.sp,
                modifier = Modifier
                    .width(64.dp)
                    .clickable(onClick = onBack)
            )
            Text(
                text = AppText.Profile.PersonalInfo,
                color = CorosWhite,
                fontSize = 18.sp,
                fontWeight = FontWeight.Medium,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = AppText.Common.Save,
                color = CorosWhite,
                fontSize = 14.sp,
                modifier = Modifier
                    .width(64.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(if (saveEnabled) AppColors.Profile.SaveEnabled else AppColors.Profile.SaveDisabled)
                    .clickable(enabled = saveEnabled, onClick = onSave)
                    .padding(vertical = 8.dp),
                textAlign = TextAlign.Center
            )
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 26.dp)
        ) {
            Spacer(Modifier.height(20.dp))
            ProfileAvatar(
                avatarUri = profile.avatarUri,
                modifier = Modifier.align(Alignment.CenterHorizontally),
                onClick = onAvatarClick
            )
            Spacer(Modifier.height(28.dp))
            EditableNameRow(
                value = profile.username,
                editing = usernameEditing,
                onEditClick = onUsernameEditClick,
                onValueChange = onUsernameChange
            )
            PersonalProfileValueRow(
                label = AppText.Profile.Gender,
                value = profile.gender.displayText(),
                onClick = onGenderClick
            )
            PersonalProfileValueRow(
                label = AppText.Profile.BirthDate,
                value = profile.birthDate,
                onClick = onBirthDateClick
            )
            PersonalProfileValueRow(
                label = AppText.Profile.Height,
                value = profile.heightCm?.let { "$it cm" }.orEmpty(),
                onClick = onHeightClick
            )
            PersonalProfileValueRow(
                label = AppText.Profile.Weight,
                value = profile.weightKg?.let { String.format("%.1f kg", it) }.orEmpty(),
                onClick = onWeightClick
            )
            PersonalProfileValueRow(
                label = AppText.Profile.CountryRegion,
                value = profile.countryRegion,
                onClick = onCountryClick
            )
            Spacer(Modifier.height(16.dp))
            ErrorText(errorMessage)
        }
    }
}

@Composable
private fun EditableNameRow(
    value: String,
    editing: Boolean,
    onEditClick: () -> Unit,
    onValueChange: (String) -> Unit
) {
    val focusRequester = remember { FocusRequester() }
    LaunchedEffect(editing) {
        if (editing) focusRequester.requestFocus()
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(AppText.Profile.Username, color = CorosWhite, fontSize = 16.sp)
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            enabled = editing,
            singleLine = true,
            textStyle = TextStyle(
                color = AppColors.Profile.EditedValue,
                fontSize = 15.sp,
                textAlign = TextAlign.End
            ),
            cursorBrush = SolidColor(CorosRed),
            modifier = Modifier
                .weight(1f)
                .focusRequester(focusRequester)
        )
        Spacer(Modifier.width(8.dp))
        Box(
            modifier = Modifier
                .size(32.dp)
                .clickable(onClick = onEditClick),
            contentAlignment = Alignment.Center
        ) {
            AppImage(
                asset = AppImages.Profile.Edit,
                contentDescription = AppText.Profile.EditUsername,
                modifier = Modifier.size(16.dp)
            )
        }
    }
    ProfileDivider()
}

@Composable
private fun PersonalProfileValueRow(label: String, value: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp)
            .clickable(onClick = onClick),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, color = CorosWhite, fontSize = 16.sp)
        Spacer(Modifier.weight(1f))
        Text(
            text = value.ifBlank { AppText.Common.NotSet },
            color = if (value.isBlank()) CorosMuted else AppColors.Profile.EditedValue,
            fontSize = 15.sp
        )
        Spacer(Modifier.width(8.dp))
        AppImage(
            asset = AppImages.Profile.Next,
            contentDescription = null,
            modifier = Modifier.size(19.dp)
        )
    }
    ProfileDivider()
}

@Composable
private fun ProfileDivider() {
    Box(
        Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(CorosLine)
    )
}

private fun UserGender?.displayText(): String {
    return when (this) {
        UserGender.Female -> "女"
        UserGender.Male -> "男"
        null -> ""
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun PersonalProfileEditScreenPreview() {
    DemoTheme {
        PersonalProfileEditContent(
            profile = UserProfile(
                username = "pplove",
                birthDate = "1998年7月14日",
                heightCm = 175,
                weightKg = 60.0,
                measurementSystem = MeasurementSystem.Metric,
                countryRegion = "中国",
                gender = UserGender.Male
            ),
            errorMessage = null,
            saveEnabled = true,
            onBack = {},
            onSave = {},
            onAvatarClick = {},
            usernameEditing = false,
            onUsernameEditClick = {},
            onUsernameChange = {},
            onGenderClick = {},
            onBirthDateClick = {},
            onHeightClick = {},
            onWeightClick = {},
            onCountryClick = {}
        )
    }
}
