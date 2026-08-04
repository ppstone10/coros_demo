package com.example.demo.health.navigation

import kotlinx.serialization.Serializable

@Serializable
data class HealthDetailRoute(val cardType: String)

@Serializable
object HealthEditorRoute

@Serializable
object NormalDataEditorRoute

@Serializable
data class NormalDataSectionRoute(val section: String)
