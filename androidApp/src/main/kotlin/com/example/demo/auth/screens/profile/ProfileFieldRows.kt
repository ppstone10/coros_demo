package com.example.demo.auth.screens.profile

import android.graphics.Bitmap
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.common.auth.model.UserGender
import com.example.demo.auth.components.CorosLine
import com.example.demo.auth.components.CorosMuted
import com.example.demo.auth.components.CorosRed
import com.example.demo.auth.components.CorosWhite
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImageAsset
import com.example.demo.core.resources.AppImages
@Composable
internal fun ProfileAvatar(
    avatarUri: String?,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
    revision: Int = 0,
    previewBitmap: Bitmap? = null
) {
    Box(
        modifier = modifier
            .size(76.dp)
            .clip(CircleShape)
            .background(AppColors.Profile.AvatarBackground)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        AvatarImageWithRevision(
            avatarUri = avatarUri,
            revision = revision,
            size = 76.dp,
            overrideBitmap = previewBitmap,
            placeholder = {
                AppImage(
                    asset = AppImages.Profile.Camera,
                    contentDescription = stringResource(R.string.profile_add_avatar),
                    modifier = Modifier.fillMaxSize()
                )
            }
        )
    }
}

@Composable
internal fun ProfileTextRow(
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
internal fun GenderRow(selected: UserGender?, onSelected: (UserGender) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().height(62.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RequiredLabel(text = stringResource(R.string.profile_gender), required = true)
        Spacer(modifier = Modifier.weight(1f))
        GenderButton(
            icon = AppImages.Profile.Female,
            text = stringResource(R.string.common_female),
            selected = selected == UserGender.Female,
            onClick = { onSelected(UserGender.Female) }
        )
        Spacer(modifier = Modifier.width(10.dp))
        GenderButton(
            icon = AppImages.Profile.Male,
            text = stringResource(R.string.common_male),
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
