package com.example.demo.auth.navigation

import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
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
import com.example.demo.auth.components.CorosBlack
import com.example.demo.core.network.AndroidDeviceId
import com.example.demo.core.network.AvatarStore
import com.example.demo.common.auth.model.AuthMode
import com.example.demo.common.auth.model.LoginEffect
import com.example.demo.common.auth.model.PostLoginRoute
import com.example.demo.common.auth.model.VerifyTarget
import com.example.demo.auth.components.rememberLoginViewModel
import com.example.demo.auth.components.findActivity
import com.example.demo.auth.components.localizedAuthMessage
import com.example.demo.auth.screens.entrance.EntranceScreen
import com.example.demo.auth.screens.legal.PrivacyPolicyScreen
import com.example.demo.auth.screens.legal.ServiceTermsScreen
import com.example.demo.auth.screens.LoginPageScreen
import com.example.demo.auth.screens.password.ForgotPasswordScreen
import com.example.demo.auth.screens.password.PasswordSetupScreen
import com.example.demo.auth.screens.password.ResetPasswordScreen
import com.example.demo.auth.screens.profile.ProfileCompletionScreen
import com.example.demo.auth.screens.register.EmailRegisterScreen
import com.example.demo.auth.screens.register.PhoneRegisterScreen
import com.example.demo.home.MainTabsScreen
import com.example.demo.health.navigation.HealthDetailRoute
import com.example.demo.health.navigation.HealthEditorRoute
import com.example.demo.health.navigation.NormalDataEditorRoute
import com.example.demo.health.navigation.healthNavGraph
import com.example.demo.health.viewmodel.HealthDashboardViewModel
import com.example.demo.auth.screens.profile.PersonalProfileEditScreen
import com.example.demo.auth.screens.verify.VerifyCodeScreen
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.time.Duration.Companion.milliseconds

/** MSRV-019：前台会话校验间隔（被顶时最迟该时长后弹窗）。 */
private const val ForegroundSessionCheckIntervalMs = 3_000L

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
    val healthViewModel = remember(viewModel) {
        HealthDashboardViewModel(viewModel.healthStore)
    }
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()
    val view = LocalView.current
    val resources = LocalResources.current
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> viewModel.onAppStarted()
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
                healthViewModel.staleForNewAccount()
                // MSRV-015：登录/切换账号后，用服务器头像覆盖内部目录的当前头像（异步，不阻塞导航）
                coroutineScope.launch {
                    withContext(Dispatchers.IO) {
                        AvatarStore.refreshFromServer(
                            context,
                            effect.session.profile?.avatarUri,
                            AndroidDeviceId.get(context)
                        )
                    }
                }
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
                healthViewModel.staleForNewAccount()
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
            LoginEffect.SessionKicked -> {
                // MSRV-019：被顶弹窗已提示，确认后静默回登录页（不再弹错误提示）
                navController.navigateWithOperation(LoginRoute, NavOperation.ResetKeepingEntranceAndPush)
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ShowMessage -> {
                snackbarHostState.showSnackbar(resources.localizedAuthMessage(effect.message).orEmpty())
                viewModel.onEffectConsumed()
            }
            is LoginEffect.ShowForceLoginDialog -> {
                // 弹窗由 state.confirmForceLogin 驱动（本文件的 AlertDialog），这里只消费 effect
                viewModel.onEffectConsumed()
            }
            null -> {}
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = CorosBlack,
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
                MainTabsScreen(
                    viewModel = viewModel,
                    healthViewModel = healthViewModel,
                    onOpenHealthDetail = { cardType ->
                        navController.navigateWithOperation(
                            HealthDetailRoute(cardType.name),
                            NavOperation.Push
                        )
                    },
                    onOpenHealthEditor = {
                        navController.navigateWithOperation(HealthEditorRoute, NavOperation.Push)
                    },
                    onOpenNormalDataEditor = {
                        navController.navigateWithOperation(NormalDataEditorRoute, NavOperation.Push)
                    },
                    onOpenProfileEditor = {
                        navController.navigateWithOperation(ProfileEditRoute, NavOperation.Push)
                    }
                )
            }

            healthNavGraph(navController = navController, viewModel = healthViewModel)

            composable<ProfileEditRoute> {
                PersonalProfileEditScreen(
                    viewModel = viewModel,
                    onBack = {
                        navController.navigateWithOperation(Unit, NavOperation.Pop)
                    },
                    onSaved = {
                        navController.navigateWithOperation(Unit, NavOperation.Pop)
                    }
                )
            }
        }

        if (viewModel.state.confirmForceLogin) {
            ForceLoginConfirmDialog(
                onConfirm = viewModel::onForceLoginConfirm,
                onDismiss = viewModel::onForceLoginCancel
            )
        }

        // MSRV-019：前台周期性会话校验，被顶即弹窗（弹窗显示期间暂停校验）
        LaunchedEffect(viewModel.state.isLoggedIn, viewModel.state.kickedDialogShown) {
            if (!viewModel.state.isLoggedIn) return@LaunchedEffect
            while (true) {
                delay(ForegroundSessionCheckIntervalMs.milliseconds)
                if (!viewModel.state.kickedDialogShown) {
                    viewModel.checkSessionOnForeground()
                }
            }
        }

        if (viewModel.state.kickedDialogShown) {
            KickedDialog(onConfirm = viewModel::onKickedDialogConfirmed)
        }
    }
}

/** MSRV-016：二次确认"该账号已在其他设备登录，继续将挤下线对方"。 */
@Composable
private fun ForceLoginConfirmDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    val resources = LocalResources.current
    AlertDialog(
        onDismissRequest = onDismiss,
        text = { Text(resources.getString(R.string.auth_force_login_confirm_body)) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(resources.getString(R.string.common_confirm))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(resources.getString(R.string.common_cancel))
            }
        }
    )
}

/** MSRV-019：被顶弹窗——仅确认按钮，确认后回登录页。 */
@Composable
private fun KickedDialog(
    onConfirm: () -> Unit
) {
    val resources = LocalResources.current
    AlertDialog(
        onDismissRequest = {},
        text = { Text(resources.getString(R.string.auth_error_session_expired_elsewhere)) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(resources.getString(R.string.common_confirm))
            }
        }
    )
}
