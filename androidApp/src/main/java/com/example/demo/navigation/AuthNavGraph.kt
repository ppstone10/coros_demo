package com.example.demo.navigation

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
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowInsetsControllerCompat
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.login.LoginViewModel
import com.example.demo.login.components.rememberLoginViewModel
import com.example.demo.login.components.VerifyTargetKind
import com.example.demo.login.components.findActivity
import com.example.demo.login.entrance.EntranceScreen
import com.example.demo.login.legal.PrivacyPolicyScreen
import com.example.demo.login.legal.ServiceTermsScreen
import com.example.demo.login.login.LoginPageScreen
import com.example.demo.login.password.PasswordSetupScreen
import com.example.demo.login.register.EmailRegisterScreen
import com.example.demo.login.register.PhoneRegisterScreen
import com.example.demo.login.signedin.SignedInScreen
import com.example.demo.login.verify.VerifyCodeScreen

object AuthRoutes {
    const val ENTRANCE = "entrance"
    const val LOGIN = "login"
    const val PHONE_REGISTER = "phone_register"
    const val EMAIL_REGISTER = "email_register"
    const val VERIFY_CODE = "verify_code/{account}/{targetKind}"
    const val PASSWORD_SETUP = "password_setup"
    const val PRIVACY_POLICY = "privacy_policy"
    const val SERVICE_TERMS = "service_terms"
    const val SIGNED_IN = "signed_in"

    fun verifyCode(account: String, targetKind: String) = "verify_code/$account/$targetKind"
}

@Composable
fun AuthNavGraph() {
    val viewModel = rememberLoginViewModel()
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }
    val view = LocalView.current

    val startDestination = if (viewModel.state.isLoggedIn && viewModel.state.currentSession != null) {
        AuthRoutes.SIGNED_IN
    } else {
        AuthRoutes.ENTRANCE
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
                    navController.navigate(AuthRoutes.SIGNED_IN) {
                        popUpTo(AuthRoutes.ENTRANCE) { inclusive = true }
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
                        navController.navigate(AuthRoutes.PASSWORD_SETUP)
                    }
                )
            }

            composable(AuthRoutes.PASSWORD_SETUP) {
                PasswordSetupScreen(
                    viewModel = viewModel,
                    onBack = {
                        viewModel.onVerifyCodeChanged("")
                        navController.popBackStack()
                    },
                    onRegisterSuccess = {
                        navController.navigate(AuthRoutes.LOGIN) {
                            popUpTo(AuthRoutes.PHONE_REGISTER) { inclusive = true }
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

            composable(AuthRoutes.SIGNED_IN) {
                SignedInScreen(
                    viewModel = viewModel,
                    onLogout = {
                        viewModel.onLogout()
                        navController.navigate(AuthRoutes.ENTRANCE) {
                            popUpTo(0) { inclusive = true }
                        }
                    }
                )
            }
        }
    }
}
