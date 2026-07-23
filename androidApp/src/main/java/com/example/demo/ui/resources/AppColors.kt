package com.example.demo.ui.resources

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object AppColors {
    object Core {
        val Black = Color.Black
        val White = Color.White
        val Transparent = Color.Transparent
    }

    object Auth {
        val BrandRed = Color(0xFFE9003D)
        val ButtonRed = Color(0xFFB80035)
        val Muted = Color(0xFF8F8F96)
        val Divider = Color(0xFF1F1F22)
        val InputText = Color(0xFFD8D8DD)
        val InputBox = Color(0xFF151517)
        val InputBorder = Color(0xFF3A3A3D)
        val ThirdPartyBorder = Color(0xFF303036)
        val Sheet = Color(0xFF1A1A1B)
        val Dialog = Color(0xFF222224)
        val Loading = Color(0xFF3A3A3C)
        val LegalText = Color(0xFFC9C9CC)
        val EntranceBackground = Color(0xFF111111)
    }

    object Health {
        val Page = Color.Black
        val Card = Color(0xFF191919)
        val Muted = Color(0xFF777777)
        val EditText = Color(0xFFDDDDDD)
        val Date = Color(0xFF8C8C8C)
        val Gauge = Color(0xFFFFB735)
        val CalorieArcTrack = Color(0xFF343434)
        val CalorieArcStart = Color(0xFFFFD044)
        val CalorieArcEnd = Color(0xFFFFA52F)
        val Steps = Color(0xFF00DF7B)
        val Calories = Color(0xFFFFC928)
        val ActiveDuration = Color(0xFFD72BCC)
        val MetricUnit = Color(0xFF898989)
        val CardTitle = Color(0xFFE8E8E8)
        val Risk = Color(0xFFFFA34A)
        val Chevron = Color(0xFF666666)
        val Action = Color(0xFFF0003C)
        val AddAction = Color(0xFF00DF7B)
        val Warning = Color(0xFFFF4B55)
        val EditorTitle = Color(0xFFECECEC)
        val EditorDivider = Color(0xFF303030)
        val Placeholder = Color(0xFFBBBBBB)
        val VisualGreen = Color(0xFF00DF7B)
        val VisualYellow = Color(0xFFFFC928)
        val VisualOrange = Color(0xFFFF9F30)
        val VisualPurple = Color(0xFFB769FF)
        val VisualBlue = Color(0xFF42A5F5)
        val VisualCyan = Color(0xFF2DCDD3)
        val VisualPink = Color(0xFFE82D8A)
        val VisualDeepBlue = Color(0xFF3156B8)
        val StressLow = Color(0xFF449AFA)
        val StressGood = Color(0xFFAADB37)
        val VisualBar = Color(0xFF626262)
        val GaugeTrack = Color(0xFF333333)
        val RangeTrack = Color(0xFF454545)
        val RangeLow = Color(0xFFE24A54)
        val RangeCaution = Color(0xFFF4BE36)
        val RangeNormal = Color(0xFF62CF72)
        val RangeHigh = Color(0xFFF28B43)
        val ActivityTile = Color(0xFF223C32)
        val Divider = Color(0xFF303030)
    }

    object Profile {
        val Description = Color(0xFFE8E8EC)
        val AvatarBackground = Color(0xFF171719)
        val Value = Color(0xFFDADAE0)
        val EditedValue = Color(0xFFD8D8DC)
        val Control = Color(0xFF19191B)
        val SelectedBorder = Color(0xFF38383C)
        val WheelNear = Color(0xFFCFCFD4)
        val WheelFar = Color(0xFF77777D)
        val WheelFarthest = Color(0xFF4C4C52)
        val WheelSelectedBorder = Color(0xFF34343A)
        val ActionSheet = Color(0xFF18181A)
        val ActionSheetDivider = Color(0xFF101012)
        val SaveEnabled = Color(0xFFF0003C)
        val SaveDisabled = Color(0xFF5F001C)
    }

    object Account {
        val Card = Color(0xFF191919)
        val Muted = Color(0xFF8A8A8E)
        val Complete = Color(0xFF19C875)
        val Incomplete = Color(0xFFFFB735)
        val Destructive = Color(0xFFFF4053)
        val AvatarFallback = Color(0xFF303034)
        val Divider = Color(0xFF2B2B2D)
        val Dialog = Color(0xFF202023)
        val DialogSecondary = Color(0xFF343438)
    }

    object Navigation {
        val Bar = Color(0xF21A1A1C)
        val Unselected = Color(0xFF85868A)
        val Placeholder = Color(0xFFB3B5BA)
    }
}

/** Reusable visual values. Keep page-specific geometry local until it repeats. */
object AppTypography {
    val Caption = 11.sp
    val Supporting = 12.sp
    val Label = 13.sp
    val Action = 14.sp
    val EditorRow = 15.sp
    val CardTitle = 16.sp
    val SectionTitle = 19.sp
    val HeroTitle = 28.sp
}

object AppSpacing {
    val XSmall = 5.dp
    val Small = 8.dp
    val Medium = 10.dp
    val CaptionBottom = 11.dp
    val ContentVertical = 12.dp
    val LabelVertical = 14.dp
    val CardContent = 15.dp
    val Screen = 16.dp
    val Large = 18.dp
    val Page = 20.dp
    val Section = 24.dp
    val ActionHorizontal = 28.dp
}
