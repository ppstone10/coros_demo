package com.example.demo.login

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.LoginRequestDto
import com.example.demo.common.login.LoginResult
import com.example.demo.common.login.MockResult
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AndroidAuthStoreDataSourceTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    @After
    fun clearStoredAuthData() {
        context.getSharedPreferences(PREFERENCES_NAME, 0)
            .edit()
            .clear()
            .commit()
    }

    @Test
    fun loginSessionIsPersistedAndRestoredByNewDataSourceInstance() {
        val firstRepository = LocalMockAuthRepository(AndroidAuthStoreDataSource(context))

        val login = firstRepository.login(
            LoginRequestDto(
                LocalMockAuthRepository.DefaultAccount,
                LocalMockAuthRepository.DefaultPassword
            )
        )
        assertTrue(login is LoginResult.Success)
        val session = (login as LoginResult.Success).session

        val restoredRepository = LocalMockAuthRepository(AndroidAuthStoreDataSource(context))

        assertEquals(session, restoredRepository.currentSession())
        val access = restoredRepository.verifyBusinessAccess()
        assertTrue(access is MockResult.Success<*>)
        assertEquals(session, (access as MockResult.Success<*>).data)
    }

    private companion object {
        const val PREFERENCES_NAME = "auth_mock_store"
    }
}
