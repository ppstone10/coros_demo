package com.example.demo.navigation

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.platform.LocalView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowInsetsControllerCompat
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.example.demo.R
import com.example.demo.common.login.AuthMode
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.PostLoginRoute
import com.example.demo.common.login.VerifyTarget
import com.example.demo.login.components.rememberLoginViewModel
import com.example.demo.login.components.findActivity
import com.example.demo.login.components.localizedAuthMessage
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
import com.example.demo.home.MainTabsScreen
import com.example.demo.login.verify.VerifyCodeScreen
import kotlinx.coroutines.launch

private enum class NavOperation {
    Push, Pop, ReplaceTop, ResetTo, ResetKeepingEntranceAndPush
}

private fun NavController.navigateWithOperation(
    route: Any,
    operation: NavOperation
) {
    when (operation) {
        NavOperation.Push -> navigate(route)
        NavOperation.Pop -> popBackStack()
        NavOperation.ReplaceTop -> {
            popBackStack()
            navigate(route)
        }
        NavOperation.ResetTo -> navigate(route) {
            popUpTo(0) { inclusive = true }
        }
        NavOperation.ResetKeepingEntranceAndPush -> navigate(route) {
            popUpTo<EntranceRoute> { inclusive = false }
        }
    }
}

@Composable
fun AuthNavGraph() {
    val viewModel = rememberLoginViewModel()
    val navController = rememberNavController()
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()
    val view = LocalView.current
    val resources = LocalResources.current
    val lifecycleOwner = LocalLifecycleOwner.current

    LaunchedEffect(Unit) {
        viewModel.onAppForegrounded()
    }

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_STOP -> viewModel.onAppBackgrounded()
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    val currentSession = viewModel.state.currentSession
    val startDestination: Any = when {
        viewModel.state.isLoggedIn && currentSession?.isProfileComplete == true -> SignedInRoute
        viewModel.state.isLoggedIn && currentSession != null -> ProfileCompletionRoute
        else -> EntranceRoute
    }

    SideEffect {
        val activity = view.context.findActivity() ?: return@SideEffect
        WindowInsetsControllerCompat(activity.window, view).apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = false
        }
    }

    LaunchedEffect(viewModel.effect, resources) {
        when (val effect = viewModel.effect) {
            is LoginEffect.AuthSucceeded -> {
                val destination = when (effect.nextRoute) {
                    PostLoginRoute.SignedIn -> SignedInRoute
                    PostLoginRoute.ProfileCompletion -> ProfileCompletionRoute
                }
                navController.navigateWithOperation(destination, NavOperation.ResetTo)
                val msg = if (effect.mode == AuthMode.Register)
                    R.string.auth_register_success else R.string.auth_login_success
                snackbarHostState.showSnackbar(resources.getString(msg))
                viewModel.onEffectConsumed()
            }
            is LoginEffect.NavigateHome -> {
                navController.navigateWithOperation(SignedInRoute, NavOperation.ResetTo)
                snackbarHostState.showSnackbar(resources.getString(R.string.auth_login_success))
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ProfileSaved -> {
                navController.navigateWithOperation(SignedInRoute, NavOperation.ResetTo)
                snackbarHostState.showSnackbar(resources.getString(R.string.profile_saved))
                viewModel.onEffectConsumed()
            }
            LoginEffect.LoggedOut -> {
                navController.navigateWithOperation(EntranceRoute, NavOperation.ResetTo)
                snackbarHostState.showSnackbar(resources.getString(R.string.account_logout_success))
                viewModel.onEffectConsumed()
            }
            LoginEffect.AccountDeleted -> {
                navController.navigateWithOperation(EntranceRoute, NavOperation.ResetTo)
                snackbarHostState.showSnackbar(resources.getString(R.string.account_delete_success))
                viewModel.onEffectConsumed()
            }
            LoginEffect.SessionExpired -> {
                navController.navigateWithOperation(LoginRoute, NavOperation.ResetKeepingEntranceAndPush)
                snackbarHostState.showSnackbar(resources.getString(R.string.auth_session_expired))
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ShowMessage -> {
                snackbarHostState.showSnackbar(resources.localizedAuthMessage(effect.message).orEmpty())
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
            composable<EntranceRoute> {
                EntranceScreen(
                    viewModel = viewModel,
                    onRegisterClick = {
                        viewModel.onModeChanged(AuthMode.Register)
                        navController.navigateWithOperation(PhoneRegisterRoute, NavOperation.Push)
                    },
                    onLoginClick = {
                        viewModel.onModeChanged(AuthMode.Login)
                        navController.navigateWithOperation(LoginRoute, NavOperation.Push)
                    }
                )
            }

            composable<LoginRoute> {
                LoginPageScreen(
                    viewModel = viewModel,
                    onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) },
                    onLoginSuccess = {},
                    onForgotPasswordClick = {
                        navController.navigateWithOperation(ForgotPasswordRoute, NavOperation.Push)
                    },
                    onPrivacyClick = { navController.navigateWithOperation(PrivacyPolicyRoute, NavOperation.Push) },
                    onServiceTermsClick = { navController.navigateWithOperation(ServiceTermsRoute, NavOperation.Push) }
                )
            }

            composable<PhoneRegisterRoute> {
                PhoneRegisterScreen(
                    viewModel = viewModel,
                    onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) },
                    onSendCode = { account ->
                        viewModel.onUsernameChanged(account)
                        viewModel.onDisplayNameChanged(account)
                        navController.navigateWithOperation(
                            VerifyCodeRoute(account = account, targetKind = VerifyTarget.Phone),
                            NavOperation.Push
                        )
                    },
                    onEmailRegister = {
                        viewModel.onUsernameChanged("")
                        navController.navigateWithOperation(EmailRegisterRoute, NavOperation.ReplaceTop)
                    },
                    onPrivacyClick = { navController.navigateWithOperation(PrivacyPolicyRoute, NavOperation.Push) },
                    onServiceTermsClick = { navController.navigateWithOperation(ServiceTermsRoute, NavOperation.Push) }
                )
            }

            composable<EmailRegisterRoute> {
                EmailRegisterScreen(
                    viewModel = viewModel,
                    onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) },
                    onSendCode = { email ->
                        viewModel.onUsernameChanged(email)
                        viewModel.onDisplayNameChanged(email)
                        navController.navigateWithOperation(
                            VerifyCodeRoute(account = email, targetKind = VerifyTarget.Email),
                            NavOperation.Push
                        )
                    },
                    onPhoneRegister = {
                        viewModel.onUsernameChanged("")
                        navController.navigateWithOperation(PhoneRegisterRoute, NavOperation.ReplaceTop)
                    },
                    onPrivacyClick = { navController.navigateWithOperation(PrivacyPolicyRoute, NavOperation.Push) },
                    onServiceTermsClick = { navController.navigateWithOperation(ServiceTermsRoute, NavOperation.Push) }
                )
            }

            composable<VerifyCodeRoute> { backStackEntry ->
                val route: VerifyCodeRoute = backStackEntry.toRoute()
                VerifyCodeScreen(
                    account = route.account,
                    targetKind = route.targetKind,
                    viewModel = viewModel,
                    onBack = {
                        viewModel.onVerifyCodeChanged("")
                        navController.navigateWithOperation(Unit, NavOperation.Pop)
                    },
                    onCodeVerified = {
                        navController.navigateWithOperation(
                            PasswordSetupRoute(targetKind = route.targetKind),
                            NavOperation.Push
                        )
                    }
                )
            }

            composable<PasswordSetupRoute> { backStackEntry ->
                val route: PasswordSetupRoute = backStackEntry.toRoute()
                PasswordSetupScreen(
                    viewModel = viewModel,
                    onBack = {
                        viewModel.onVerifyCodeChanged("")
                        val targetRoute = if (route.targetKind == VerifyTarget.Email) {
                            EmailRegisterRoute
                        } else {
                            PhoneRegisterRoute
                        }
                        navController.navigateWithOperation(targetRoute, NavOperation.ResetKeepingEntranceAndPush)
                    },
                    onRegisterSuccess = {}
                )
            }

            composable<ForgotPasswordRoute> {
                ForgotPasswordScreen(
                    viewModel = viewModel,
                    onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) },
                    onAccountVerified = { account ->
                        navController.navigateWithOperation(
                            ResetPasswordRoute(account = account),
                            NavOperation.Push
                        )
                    }
                )
            }

            composable<ResetPasswordRoute> { backStackEntry ->
                val route: ResetPasswordRoute = backStackEntry.toRoute()
                ResetPasswordScreen(
                    account = route.account,
                    viewModel = viewModel,
                    onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) },
                    onResetSuccess = {
                        navController.navigateWithOperation(LoginRoute, NavOperation.ResetKeepingEntranceAndPush)
                        coroutineScope.launch {
                            snackbarHostState.showSnackbar(resources.getString(R.string.auth_password_updated))
                        }
                    }
                )
            }

            composable<PrivacyPolicyRoute> {
                PrivacyPolicyScreen(onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) })
            }

            composable<ServiceTermsRoute> {
                ServiceTermsScreen(onBack = { navController.navigateWithOperation(Unit, NavOperation.Pop) })
            }

            composable<ProfileCompletionRoute> {
                ProfileCompletionScreen(
                    viewModel = viewModel,
                    onBack = {
                        viewModel.clearSessionSilently()
                        navController.navigateWithOperation(EntranceRoute, NavOperation.ResetTo)
                    }
                )
            }

            composable<SignedInRoute> {
                MainTabsScreen(viewModel)
            }
        }
    }
}
