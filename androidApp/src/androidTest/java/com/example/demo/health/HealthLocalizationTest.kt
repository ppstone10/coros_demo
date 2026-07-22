package com.example.demo.health

import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.demo.common.health.LocalizedTextSpec
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class HealthLocalizationTest {
    @Test
    fun percentUnitWithoutArgumentsDoesNotEnterFormatter() {
        val resources = ApplicationProvider.getApplicationContext<android.content.Context>().resources

        assertEquals("%", resources.localizedHealthText(LocalizedTextSpec("health_unit_percent")))
    }
}
