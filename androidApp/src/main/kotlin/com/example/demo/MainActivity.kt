package com.example.demo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.Surface
import com.example.demo.ui.theme.DemoTheme
import com.example.demo.navigation.AuthNavGraph
import com.example.demo.ui.language.ProvideAppLanguage
import com.example.demo.ui.language.AppLanguageDialogHost

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ProvideAppLanguage {
                DemoTheme {
                    Surface {
                        AuthNavGraph()
                        AppLanguageDialogHost()
                    }
                }
            }
        }
    }
}
