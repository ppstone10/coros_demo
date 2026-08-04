package com.example.demo.auth.viewmodel

internal class SessionLifecycleCoordinator(
    private val restoreOnColdStart: () -> Unit,
    private val resumeInSameProcess: () -> Unit
) {
    private var hasCompletedInitialRestore = false

    fun onStart() {
        if (hasCompletedInitialRestore) {
            resumeInSameProcess()
            return
        }

        hasCompletedInitialRestore = true
        restoreOnColdStart()
    }
}
