package com.example.demo.health

import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGesturesAfterLongPress
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.zIndex
import com.example.demo.R
import com.example.demo.common.health.DefaultHealthCardOrder
import com.example.demo.common.health.HealthCardType
import com.example.demo.ui.resources.AppColors
import com.example.demo.ui.resources.AppImage
import com.example.demo.ui.resources.AppImages
import com.example.demo.ui.resources.AppSpacing
import com.example.demo.ui.resources.AppTypography
import com.example.demo.ui.theme.DemoTheme

private val PageBlack = AppColors.Health.Page
private val CardBlack = AppColors.Health.Card
private val Muted = AppColors.Health.Muted

@Composable
fun CardEditor(
    initial: List<HealthCardType>, onClose: () -> Unit, onSave: (List<HealthCardType>) -> Unit
) {
    val active = remember(initial) { mutableStateListOf<HealthCardType>().apply { addAll(initial) } }
    val listState = rememberLazyListState()
    var draggedType by remember { mutableStateOf<HealthCardType?>(null) }
    var nonAnimatedType by remember { mutableStateOf<HealthCardType?>(null) }
    var dragOffset by remember { mutableFloatStateOf(0f) }
    var warning by remember { mutableStateOf<String?>(null) }
    val minimumCardsWarning = stringResource(R.string.health_minimum_cards)
    val inactive = DefaultHealthCardOrder.filterNot(active::contains)
    Column(Modifier.fillMaxSize().background(PageBlack).statusBarsPadding()) {
        Row(Modifier.fillMaxWidth().height(62.dp).padding(horizontal = AppSpacing.Large), verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.common_back), color = AppColors.Core.White, fontSize = 34.sp, modifier = Modifier.clickable(onClick = onClose))
            Text(stringResource(R.string.health_edit_cards), color = AppColors.Core.White, fontSize = 18.sp, textAlign = TextAlign.Center, modifier = Modifier.weight(1f))
            Box(Modifier.width(64.dp).height(30.dp).clip(RoundedCornerShape(6.dp)).background(AppColors.Health.Action).clickable { onSave(active.toList()) }, contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.common_save), color = AppColors.Core.White, fontSize = AppTypography.Action)
            }
        }
        Text(stringResource(R.string.health_manage_cards), color = Muted, fontSize = AppTypography.Label, modifier = Modifier.padding(horizontal = AppSpacing.Section, vertical = AppSpacing.LabelVertical))
        warning?.let { Text(it, color = AppColors.Health.Warning, fontSize = AppTypography.Supporting, modifier = Modifier.padding(horizontal = AppSpacing.Section, vertical = 4.dp)) }
        LazyColumn(
            state = listState,
            modifier = Modifier.weight(1f).padding(horizontal = AppSpacing.Screen).pointerInput(Unit) {
                detectDragGesturesAfterLongPress(
                    onDragStart = { position ->
                        val item = listState.layoutInfo.visibleItemsInfo.firstOrNull {
                            it.index in active.indices && position.y.toInt() in it.offset..(it.offset + it.size)
                        }
                        draggedType = item?.let { active.getOrNull(it.index) }; nonAnimatedType = draggedType; dragOffset = 0f
                    },
                    onDragCancel = { draggedType = null; dragOffset = 0f },
                    onDragEnd = { draggedType = null; dragOffset = 0f },
                    onDrag = { change, amount ->
                        val type = draggedType ?: return@detectDragGesturesAfterLongPress
                        change.consume()
                        val currentIndex = active.indexOf(type)
                        val layoutInfo = listState.layoutInfo
                        val current = layoutInfo.visibleItemsInfo.firstOrNull { it.index == currentIndex } ?: return@detectDragGesturesAfterLongPress
                        val minOff = layoutInfo.viewportStartOffset - current.offset.toFloat()
                        val maxOff = layoutInfo.viewportEndOffset - current.offset.toFloat() - current.size
                        dragOffset = (dragOffset + amount.y).coerceIn(minOff, maxOff)
                        val dir = amount.y.compareTo(0f)
                        val targetIdx = currentIndex + dir
                        val target = layoutInfo.visibleItemsInfo.firstOrNull { it.index == targetIdx && it.index in active.indices }
                        val center = current.offset + current.size / 2f + dragOffset
                        val swap = when { target == null -> false; dir < 0 -> center <= target.offset + target.size / 2f; dir > 0 -> center >= target.offset + target.size / 2f; else -> false }
                        if (swap && target != null) {
                            val vt = current.offset + dragOffset; val fvi = listState.firstVisibleItemIndex; val fvo = listState.firstVisibleItemScrollOffset
                            active.removeAt(currentIndex); active.add(target.index, type)
                            if (currentIndex == fvi || target.index == fvi) listState.requestScrollToItem(fvi, fvo)
                            dragOffset = vt - target.offset
                            dragOffset = dragOffset.coerceIn(layoutInfo.viewportStartOffset - target.offset.toFloat(), layoutInfo.viewportEndOffset - target.offset.toFloat() - target.size)
                        }
                        val vp = layoutInfo.viewportEndOffset
                        when { amount.y < 0 && change.position.y < 36.dp.toPx() && listState.canScrollBackward -> dragOffset -= listState.dispatchRawDelta(8.dp.toPx())
                            amount.y > 0 && change.position.y > vp - 36.dp.toPx() && listState.canScrollForward -> dragOffset -= listState.dispatchRawDelta(-8.dp.toPx()) }
                    }
                )
            }
        ) {
            itemsIndexed(active, key = { _, t -> t.name }) { idx, type ->
                EditorRow(type, false, idx == 0, idx == active.lastIndex,
                    modifier = if (nonAnimatedType == type) Modifier else Modifier.animateItem(fadeInSpec = null, placementSpec = tween(140), fadeOutSpec = null),
                    dragModifier = Modifier.zIndex(if (draggedType == type) 1f else 0f).graphicsLayer { translationY = if (draggedType == type) dragOffset else 0f; shadowElevation = if (draggedType == type) 10.dp.toPx() else 0f; alpha = if (draggedType == type) .92f else 1f },
                    onAction = { if (active.size > 3) { active.remove(type); warning = null } else warning = minimumCardsWarning }
                )
            }
            if (inactive.isNotEmpty()) {
                item { Text(stringResource(R.string.health_more_daily_data), color = Muted, fontSize = AppTypography.Label, modifier = Modifier.padding(6.dp, AppSpacing.Section, 6.dp, AppSpacing.CaptionBottom)) }
                itemsIndexed(inactive, key = { _, t -> "more_${t.name}" }) { _, type ->
                    EditorRow(type, true, false, false, dragModifier = Modifier) { active.add(type); warning = null }
                }
            }
            item {
                Text(stringResource(R.string.health_restore_defaults), color = AppColors.Health.Action, fontSize = AppTypography.Action,
                    modifier = Modifier.fillMaxWidth().padding(top = AppSpacing.Section, bottom = 32.dp).clip(RoundedCornerShape(8.dp)).background(CardBlack)
                        .clickable { active.clear(); active.addAll(DefaultHealthCardOrder); warning = null }.padding(horizontal = AppSpacing.Large, vertical = 17.dp))
            }
        }
    }
}

@Composable
fun EditorRow(type: HealthCardType, isAdd: Boolean, roundTop: Boolean, roundBottom: Boolean, modifier: Modifier = Modifier, dragModifier: Modifier, onAction: () -> Unit) {
    val shape = RoundedCornerShape(if (roundTop) 8.dp else 0.dp, if (roundTop) 8.dp else 0.dp, if (roundBottom) 8.dp else 0.dp, if (roundBottom) 8.dp else 0.dp)
    Column(modifier.fillMaxWidth().background(CardBlack, shape)) {
        Row(Modifier.fillMaxWidth().then(dragModifier).height(56.dp).padding(horizontal = AppSpacing.Large), verticalAlignment = Alignment.CenterVertically) {
            if (!isAdd) { Text("\u283f", color = AppColors.Health.Muted, fontSize = 18.sp); Spacer(Modifier.width(10.dp)) }
            AppImage(iconOf(type), null, Modifier.size(22.dp)); Spacer(Modifier.width(10.dp))
            Text(titleOf(type), color = AppColors.Health.EditorTitle, fontSize = 15.sp, modifier = Modifier.weight(1f))
            if (isAdd) Box(Modifier.size(30.dp).clip(CircleShape).background(AppColors.Health.AddAction).clickable(onClick = onAction), contentAlignment = Alignment.Center) {
                Text("+", color = AppColors.Core.White, fontSize = 24.sp, lineHeight = 24.sp, fontWeight = FontWeight.Light)
            } else AppImage(AppImages.Health.EditorRemove, stringResource(R.string.health_remove), Modifier.size(30.dp).clickable(onClick = onAction))
        }
        if (!roundBottom) Box(Modifier.padding(start = AppSpacing.Large).fillMaxWidth().height(1.dp).background(AppColors.Health.EditorDivider))
    }
}

@Preview(showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun CardEditorPreview() {
    DemoTheme {
        CardEditor(
            initial = DefaultHealthCardOrder,
            onClose = {},
            onSave = {}
        )
    }
}
