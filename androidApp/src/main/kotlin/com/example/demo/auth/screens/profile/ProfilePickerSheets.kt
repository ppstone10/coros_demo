package com.example.demo.auth.screens.profile

import androidx.activity.compose.BackHandler
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.demo.R
import com.example.demo.auth.components.CorosMuted
import com.example.demo.auth.components.CorosWhite
import com.example.demo.auth.components.ModalScrim
import com.example.demo.core.resources.AppColors
import com.example.demo.core.resources.AppImage
import com.example.demo.core.resources.AppImages
import kotlin.math.abs
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
    val yearSuffix = stringResource(R.string.profile_date_year_suffix)
    val monthSuffix = stringResource(R.string.profile_date_month_suffix)
    val daySuffix = stringResource(R.string.profile_date_day_suffix)
    PickerSheet(title = stringResource(R.string.profile_birth_date), onDismiss = onDismiss, onConfirm = {
        onConfirm("$year$yearSuffix$month$monthSuffix$day$daySuffix")
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
                displayedSuffix = yearSuffix,
                modifier = Modifier.weight(1f),
                onValueChange = { year = it }
            )
            WheelNumberPicker(
                value = month,
                min = 1,
                max = 12,
                displayedSuffix = monthSuffix,
                modifier = Modifier.weight(1f),
                onValueChange = { month = it }
            )
            WheelNumberPicker(
                value = day,
                min = 1,
                max = 31,
                displayedSuffix = daySuffix,
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
    PickerSheet(title = stringResource(R.string.profile_height_picker), onDismiss = onDismiss, onConfirm = { onConfirm(height) }) {
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
    PickerSheet(title = stringResource(R.string.profile_weight_picker), onDismiss = onDismiss, onConfirm = {
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
                    contentDescription = stringResource(R.string.profile_close),
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
                    contentDescription = stringResource(R.string.common_confirm),
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
