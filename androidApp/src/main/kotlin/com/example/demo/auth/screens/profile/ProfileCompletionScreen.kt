package com.example.demo.auth.screens.profile

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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.auth.model.MeasurementSystem
import com.example.demo.common.auth.rules.LoginRules
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.model.toProfileCountryCode
import com.example.demo.auth.viewmodel.LoginViewModel
import com.example.demo.auth.components.CorosBlack
import com.example.demo.auth.components.CorosButtonRed
import com.example.demo.auth.components.CorosFilledButton
import com.example.demo.auth.components.CorosWhite
import com.example.demo.auth.components.ErrorText
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.countryDisplayName
import com.example.demo.core.network.AndroidDeviceId
import com.example.demo.core.theme.DemoTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
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
    val accountDefaults = LoginRules.profileDefaults(
        account = state.currentSession?.account.orEmpty(),
        savedProfile = savedProfile
    )
    var avatarUri by rememberSaveable(savedProfile?.avatarUri) { mutableStateOf(savedProfile?.avatarUri) }
    var username by rememberSaveable(savedProfile?.username, accountDefaults.username) {
        mutableStateOf(accountDefaults.username)
    }
    var birthDate by rememberSaveable(savedProfile?.birthDate) { mutableStateOf(savedProfile?.birthDate.orEmpty()) }
    var heightCm by rememberSaveable(savedProfile?.heightCm) { mutableStateOf(savedProfile?.heightCm) }
    var weightKg by rememberSaveable(savedProfile?.weightKg) { mutableStateOf(savedProfile?.weightKg) }
    var measurementSystem by rememberSaveable(savedProfile?.measurementSystem) {
        mutableStateOf(savedProfile?.measurementSystem ?: MeasurementSystem.Metric)
    }
    var phone by rememberSaveable(savedProfile?.phone, accountDefaults.phone) {
        mutableStateOf(accountDefaults.phone)
    }
    var email by rememberSaveable(savedProfile?.email, accountDefaults.email) {
        mutableStateOf(accountDefaults.email)
    }
    val registeredCountryRegion = state.currentSession?.region?.toProfileCountryCode().orEmpty()
    val defaultCountry = "CN"
    var countryRegion by rememberSaveable(savedProfile?.countryRegion, registeredCountryRegion) {
        mutableStateOf(
            savedProfile?.countryRegion?.takeIf { it.isNotBlank() }
                ?: registeredCountryRegion.ifBlank { defaultCountry }
        )
    }
    var gender by rememberSaveable(savedProfile?.gender) { mutableStateOf(savedProfile?.gender) }
    var picker by remember { mutableStateOf<ProfilePicker?>(null) }
    var showAvatarSheet by remember { mutableStateOf(false) }
    val context = LocalContext.current
    val focusManager = LocalFocusManager.current
    val scope = rememberCoroutineScope()
    fun openPicker(next: ProfilePicker) {
        focusManager.clearFocus(force = true)
        picker = next
    }
    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
        val userId = state.currentSession?.userId
        if (uri != null && userId != null) {
            scope.launch {
                val path = withContext(Dispatchers.IO) { uploadAvatarFromUri(context, uri, userId) }
                if (path != null) avatarUri = path
            }
        }
    }
    val cameraPicker = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bitmap: Bitmap? ->
        val userId = state.currentSession?.userId
        if (bitmap != null && userId != null) {
            scope.launch {
                val path = withContext(Dispatchers.IO) {
                    uploadAvatarBitmap(bitmap, userId, AndroidDeviceId.get(context), context)
                }
                if (path != null) avatarUri = path
            }
        }
    }

    val profile = UserProfile(
        avatarUri = avatarUri,
        username = username,
        birthDate = birthDate,
        heightCm = heightCm,
        weightKg = weightKg,
        measurementSystem = measurementSystem,
        phone = phone,
        email = email,
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
                    text = stringResource(R.string.common_back),
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
                    text = stringResource(R.string.profile_completion_title),
                    color = CorosWhite,
                    fontSize = 28.sp,
                    lineHeight = 34.sp,
                    fontWeight = FontWeight.Light
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.profile_completion_description),
                    color = AppColors.Profile.Description,
                    fontSize = 14.sp,
                    lineHeight = 20.sp
                )
                Spacer(modifier = Modifier.height(20.dp))
                ProfileAvatar(
                    avatarUri = avatarUri,
                    modifier = Modifier.align(Alignment.CenterHorizontally),
                    onClick = {
                        focusManager.clearFocus(force = true)
                        showAvatarSheet = true
                    }
                )
                Spacer(modifier = Modifier.height(20.dp))
                ProfileTextRow(
                    label = stringResource(R.string.profile_username),
                    required = true,
                    value = username,
                    placeholder = stringResource(R.string.profile_username_placeholder),
                    keyboardType = KeyboardType.Text,
                    onValueChange = { username = it.take(20) }
                )
                ProfilePickerRow(
                    label = stringResource(R.string.profile_birth_date),
                    required = true,
                    value = birthDate,
                    placeholder = stringResource(R.string.profile_fill_in),
                    onClick = { openPicker(ProfilePicker.BirthDate) }
                )
                ProfilePickerRow(
                    label = stringResource(R.string.profile_height),
                    required = true,
                    value = heightCm?.let { "$it cm" }.orEmpty(),
                    placeholder = stringResource(R.string.profile_fill_in),
                    onClick = { openPicker(ProfilePicker.Height) }
                )
                ProfilePickerRow(
                    label = stringResource(R.string.profile_weight),
                    required = true,
                    value = weightKg?.let { String.format("%.1f kg", it) }.orEmpty(),
                    placeholder = stringResource(R.string.profile_fill_in),
                    onClick = { openPicker(ProfilePicker.Weight) }
                )
                ProfilePickerRow(
                    label = stringResource(R.string.profile_measurement),
                    required = false,
                    value = measurementSystem.displayText(),
                    placeholder = "",
                    onClick = { openPicker(ProfilePicker.Unit) }
                )
                ProfileTextRow(
                    label = stringResource(R.string.profile_phone),
                    required = false,
                    value = phone,
                    placeholder = stringResource(R.string.profile_phone_placeholder),
                    keyboardType = KeyboardType.Phone,
                    onValueChange = { phone = it.filter { char -> char.isDigit() || char == '+' || char == '-' }.take(20) }
                )
                ProfileTextRow(
                    label = stringResource(R.string.profile_email),
                    required = false,
                    value = email,
                    placeholder = stringResource(R.string.profile_email_placeholder),
                    keyboardType = KeyboardType.Email,
                    onValueChange = { email = viewModel.normalizeEmailInput(it).take(100) }
                )
                ProfilePickerRow(
                    label = stringResource(R.string.profile_country_region),
                    required = false,
                    value = countryDisplayName(countryRegion),
                    placeholder = stringResource(R.string.common_china),
                    onClick = { openPicker(ProfilePicker.Country) }
                )
                GenderRow(selected = gender, onSelected = {
                    focusManager.clearFocus(force = true)
                    gender = it
                })
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
                    text = stringResource(R.string.common_complete),
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
                title = stringResource(R.string.profile_measurement),
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
                title = stringResource(R.string.profile_country_region),
                options = localizedCountryOptions(),
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
@Preview(showBackground = true, locale = "zh")
@Composable
private fun ProfileCompletionScreenPreview() {
    DemoTheme {
        ProfileCompletionScreen(
            viewModel = LoginViewModel(),
            onBack = {}
        )
    }
}
