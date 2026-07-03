package com.example.demo.navigation

import android.net.Uri
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowInsetsControllerCompat
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.login.components.rememberLoginViewModel
import com.example.demo.login.components.VerifyTargetKind
import com.example.demo.login.components.findActivity
import com.example.demo.login.entrance.EntranceScreen
import com.example.demo.login.legal.PrivacyPolicyScreen
import com.example.demo.login.legal.ServiceTermsScreen
import com.example.demo.login.login.LoginPageScreen
import com.example.demo.login.password.ForgotPasswordScreen
import com.example.demo.login.password.PasswordSetupScreen
import com.example.demo.login.password.ResetPasswordScreen
import com.example.demo.login.profile.ProfileCompletionScreen
import com.example.demo.login.register.EmailRegisterScreen
import com.example.demo.login.register.PhoneRegisterScreen
import com.example.demo.login.signedin.SignedInScreen
import com.example.demo.login.verify.VerifyCodeScreen
import kotlinx.coroutines.launch

object AuthRoutes {
    const val ENTRANCE = "entrance"
    const val LOGIN = "login"
    const val PHONE_REGISTER = "phone_register"
    const val EMAIL_REGISTER = "email_register"
    const val VERIFY_CODE = "verify_code/{account}/{targetKind}"
    const val PASSWORD_SETUP = "password_setup/{targetKind}"
    const val FORGOT_PASSWORD = "forgot_password"
    const val RESET_PASSWORD = "reset_password/{account}"
    const val PRIVACY_POLICY = "privacy_policy"
    const val SERVICE_TERMS = "service_terms"
    const val PROFILE_COMPLETION = "profile_completion"
    const val SIGNED_IN = "signed_in"

    fun verifyCode(account: String, targetKind: String) = "verify_code/$account/$targetKind"
    fun passwordSetup(targetKind: String) = "password_setup/$targetKind"
    fun resetPassword(account: String) = "reset_password/${Uri.encode(account)}"
}

@Composable
fun AuthNavGraph() {
    val viewModel = rememberLoginViewModel()
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()
    val view = LocalView.current

    val currentSession = viewModel.state.currentSession
    val startDestination = when {
        viewModel.state.isLoggedIn && currentSession?.isProfileComplete == true -> AuthRoutes.SIGNED_IN
        viewModel.state.isLoggedIn && currentSession != null -> AuthRoutes.PROFILE_COMPLETION
        else -> AuthRoutes.ENTRANCE
    }

    SideEffect {
        val activity = view.context.findActivity() ?: return@SideEffect
        WindowInsetsControllerCompat(activity.window, view).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }

    LaunchedEffect(viewModel.effect) {
        when (val effect = viewModel.effect) {
            is LoginEffect.AuthSucceeded -> {
                if (effect.mode == AuthMode.Register) {
                    viewModel.clearSessionSilently()
                    navController.navigate(AuthRoutes.LOGIN) {
                        popUpTo(AuthRoutes.ENTRANCE) { inclusive = false }
                    }
                    snackbarHostState.showSnackbar("注册成功")
                } else {
                    val destination = if (effect.session.isProfileComplete) {
                        AuthRoutes.SIGNED_IN
                    } else {
                        AuthRoutes.PROFILE_COMPLETION
                    }
                    navController.navigate(destination) {
                        popUpTo(AuthRoutes.ENTRANCE) { inclusive = destination == AuthRoutes.SIGNED_IN }
                    }
                    snackbarHostState.showSnackbar("登录成功")
                }
                viewModel.onEffectConsumed()
            }
            is LoginEffect.NavigateHome -> {
                navController.navigate(AuthRoutes.SIGNED_IN) {
                    popUpTo(AuthRoutes.ENTRANCE) { inclusive = true }
                }
                snackbarHostState.showSnackbar("登录成功")
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ProfileSaved -> {
                navController.navigate(AuthRoutes.SIGNED_IN) {
                    popUpTo(AuthRoutes.ENTRANCE) { inclusive = true }
                }
                snackbarHostState.showSnackbar("资料已保存")
                viewModel.onEffectConsumed()
            }
            LoginEffect.LoggedOut -> {
                navController.navigate(AuthRoutes.ENTRANCE) {
                    popUpTo(0) { inclusive = true }
                }
                snackbarHostState.showSnackbar("已退出登录")
                viewModel.onEffectConsumed()
            }
            LoginEffect.SessionExpired -> {
                navController.navigate(AuthRoutes.LOGIN) {
                    popUpTo(AuthRoutes.ENTRANCE) { inclusive = false }
                }
                snackbarHostState.showSnackbar("会话已失效，请重新登录")
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ShowMessage -> {
                snackbarHostState.showSnackbar(effect.message)
                viewModel.onEffectConsumed()
            }
            null -> {}
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = com.example.demo.login.components.CorosBlack,
        contentWindowInsets = WindowInsets(0.dp),
        modifier = Modifier.fillMaxSize()
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = startDestination,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(AuthRoutes.ENTRANCE) {
                EntranceScreen(
                    viewModel = viewModel,
                    onRegisterClick = {
                        viewModel.onModeChanged(AuthMode.Register)
                        navController.navigate(AuthRoutes.PHONE_REGISTER)
                    },
                    onLoginClick = {
                        viewModel.onModeChanged(AuthMode.Login)
                        navController.navigate(AuthRoutes.LOGIN)
                    }
                )
            }

            composable(AuthRoutes.LOGIN) {
                LoginPageScreen(
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                    onLoginSuccess = {},
                    onForgotPasswordClick = { navController.navigate(AuthRoutes.FORGOT_PASSWORD) },
                    onPrivacyClick = { navController.navigate(AuthRoutes.PRIVACY_POLICY) },
                    onServiceTermsClick = { navController.navigate(AuthRoutes.SERVICE_TERMS) }
                )
            }

            composable(AuthRoutes.PHONE_REGISTER) {
                PhoneRegisterScreen(
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                    onSendCode = { account ->
                        viewModel.onUsernameChanged(account)
                        viewModel.onDisplayNameChanged(account)
                        navController.navigate(AuthRoutes.verifyCode(account, "phone"))
                    },
                    onEmailRegister = {
                        viewModel.onUsernameChanged("")
                        navController.navigate(AuthRoutes.EMAIL_REGISTER)
                    },
                    onPrivacyClick = { navController.navigate(AuthRoutes.PRIVACY_POLICY) },
                    onServiceTermsClick = { navController.navigate(AuthRoutes.SERVICE_TERMS) }
                )
            }

            composable(AuthRoutes.EMAIL_REGISTER) {
                EmailRegisterScreen(
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                    onSendCode = { email ->
                        viewModel.onUsernameChanged(email)
                        viewModel.onDisplayNameChanged(email)
                        navController.navigate(AuthRoutes.verifyCode(email, "email"))
                    },
                    onPhoneRegister = {
                        viewModel.onUsernameChanged("")
                        navController.navigate(AuthRoutes.PHONE_REGISTER) {
                            popUpTo(AuthRoutes.ENTRANCE) { inclusive = false }
                        }
                    },
                    onPrivacyClick = { navController.navigate(AuthRoutes.PRIVACY_POLICY) },
                    onServiceTermsClick = { navController.navigate(AuthRoutes.SERVICE_TERMS) }
                )
            }

            composable(
                route = AuthRoutes.VERIFY_CODE,
                arguments = listOf(
                    navArgument("account") { type = NavType.StringType },
                    navArgument("targetKind") { type = NavType.StringType }
                )
            ) { entry ->
                val account = entry.arguments?.getString("account") ?: ""
                val targetKind = when (entry.arguments?.getString("targetKind")) {
                    "email" -> VerifyTargetKind.Email
                    else -> VerifyTargetKind.Phone
                }
                VerifyCodeScreen(
                    account = account,
                    targetKind = targetKind,
                    viewModel = viewModel,
                    onBack = {
                        viewModel.onVerifyCodeChanged("")
                        navController.popBackStack()
                    },
                    onCodeVerified = {
                        navController.navigate(
                            AuthRoutes.passwordSetup(
                                if (targetKind == VerifyTargetKind.Email) "email" else "phone"
                            )
                        )
                    }
                )
            }

            composable(
                route = AuthRoutes.PASSWORD_SETUP,
                arguments = listOf(
                    navArgument("targetKind") { type = NavType.StringType }
                )
            ) { entry ->
                val targetKind = entry.arguments?.getString("targetKind")
                PasswordSetupScreen(
                    viewModel = viewModel,
                    onBack = {
                        viewModel.onVerifyCodeChanged("")
                        val targetRoute = if (targetKind == "email") {
                            AuthRoutes.EMAIL_REGISTER
                        } else {
                            AuthRoutes.PHONE_REGISTER
                        }
                        val restored = navController.popBackStack(targetRoute, inclusive = false)
                        if (!restored) {
                            navController.navigate(targetRoute) {
                                popUpTo(AuthRoutes.ENTRANCE) { inclusive = false }
                            }
                        }
                    },
                    onRegisterSuccess = {
                        navController.navigate(AuthRoutes.LOGIN) {
                            popUpTo(AuthRoutes.PHONE_REGISTER) { inclusive = true }
                        }
                    }
                )
            }

            composable(AuthRoutes.FORGOT_PASSWORD) {
                ForgotPasswordScreen(
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                    onAccountVerified = { account ->
                        navController.navigate(AuthRoutes.resetPassword(account))
                    }
                )
            }

            composable(
                route = AuthRoutes.RESET_PASSWORD,
                arguments = listOf(
                    navArgument("account") { type = NavType.StringType }
                )
            ) { entry ->
                val account = Uri.decode(entry.arguments?.getString("account").orEmpty())
                ResetPasswordScreen(
                    account = account,
                    viewModel = viewModel,
                    onBack = { navController.popBackStack() },
                    onResetSuccess = {
                        navController.navigate(AuthRoutes.LOGIN) {
                            popUpTo(AuthRoutes.LOGIN) { inclusive = false }
                            launchSingleTop = true
                        }
                        coroutineScope.launch {
                            snackbarHostState.showSnackbar("密码已更新")
                        }
                    }
                )
            }

            composable(AuthRoutes.PRIVACY_POLICY) {
                PrivacyPolicyScreen(onBack = { navController.popBackStack() })
            }

            composable(AuthRoutes.SERVICE_TERMS) {
                ServiceTermsScreen(onBack = { navController.popBackStack() })
            }

            composable(AuthRoutes.PROFILE_COMPLETION) {
                ProfileCompletionScreen(
                    viewModel = viewModel,
                    onBack = {
                        viewModel.clearSessionSilently()
                        navController.navigate(AuthRoutes.ENTRANCE) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }

            composable(AuthRoutes.SIGNED_IN) {
                val activity = LocalView.current.context.findActivity()
                SignedInScreen(
                    viewModel = viewModel,
                    onBack = { activity?.finish() },
                    onLogout = {
                        navController.navigate(AuthRoutes.ENTRANCE) {
                            popUpTo(0) { inclusive = true }
                        }
                    },
                    onAccountDeleted = {
                        navController.navigate(AuthRoutes.ENTRANCE) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}
