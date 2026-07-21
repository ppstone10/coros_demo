package com.example.demo.profile

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.Text
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.demo.MainActivity
import com.example.demo.ui.language.ProvideAppLanguage
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ProfileActivityResultOwnerTest {
    @Test
    fun profileActivityResultLaunchersCanRegisterInMainActivityComposition() {
        var launchersRegistered = false

        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            scenario.onActivity { activity ->
                activity.setContent {
                    ProvideAppLanguage {
                        rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { }
                        rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { }
                        launchersRegistered = true
                        Text("profile launcher host")
                    }
                }
            }
            InstrumentationRegistry.getInstrumentation().waitForIdleSync()
        }

        assertTrue(launchersRegistered)
    }
}
