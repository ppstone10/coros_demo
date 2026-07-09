package com.example.demo.navigation

import com.example.demo.common.login.VerifyTarget
import kotlinx.serialization.Serializable

@Serializable
object EntranceRoute

@Serializable
object LoginRoute

@Serializable
object PhoneRegisterRoute

@Serializable
object EmailRegisterRoute

@Serializable
data class VerifyCodeRoute(val account: String, val targetKind: VerifyTarget)

@Serializable
data class PasswordSetupRoute(val targetKind: VerifyTarget)

@Serializable
object ForgotPasswordRoute

@Serializable
data class ResetPasswordRoute(val account: String)

@Serializable
object PrivacyPolicyRoute

@Serializable
object ServiceTermsRoute

@Serializable
object ProfileCompletionRoute

@Serializable
object SignedInRoute
