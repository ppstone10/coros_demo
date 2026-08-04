package com.example.demo.auth

import com.example.demo.auth.viewmodel.SessionLifecycleCoordinator
import org.junit.Assert.assertEquals
import org.junit.Test

class SessionLifecycleCoordinatorTest {

    @Test
    fun firstStartRestoresColdSessionAndLaterStartsResumeWarmSession() {
        val calls = mutableListOf<String>()
        val coordinator = SessionLifecycleCoordinator(
            restoreOnColdStart = { calls += "cold" },
            resumeInSameProcess = { calls += "warm" }
        )

        coordinator.onStart()
        coordinator.onStart()
        coordinator.onStart()

        assertEquals(listOf("cold", "warm", "warm"), calls)
    }

    @Test
    fun recreatedCoordinatorTreatsItsFirstStartAsColdEvenInSameProcess() {
        val calls = mutableListOf<String>()

        SessionLifecycleCoordinator(
            restoreOnColdStart = { calls += "first:cold" },
            resumeInSameProcess = { calls += "first:warm" }
        ).apply {
            onStart()
            onStart()
        }

        SessionLifecycleCoordinator(
            restoreOnColdStart = { calls += "second:cold" },
            resumeInSameProcess = { calls += "second:warm" }
        ).onStart()

        assertEquals(
            listOf("first:cold", "first:warm", "second:cold"),
            calls
        )
    }
}
