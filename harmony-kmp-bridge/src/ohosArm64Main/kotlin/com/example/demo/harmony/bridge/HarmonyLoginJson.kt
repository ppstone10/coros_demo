package com.example.demo.harmony.bridge

import com.example.demo.common.login.AuthSession
import com.example.demo.common.login.LoginEffect
import com.example.demo.common.login.LoginState
import com.example.demo.common.login.MockAuthStore
import com.example.demo.common.login.MockAuthStoreJson

internal object HarmonyLoginJson {
    fun stateSnapshot(state: LoginState): String {
        return buildString {
            append('{')
            appendJsonField("mode", state.mode.name)
            append(',')
            appendJsonField("username", state.username)
            append(',')
            appendJsonField("password", state.password)
            append(',')
            appendJsonField("verifyCode", state.verifyCode)
            append(',')
            appendJsonField("displayName", state.displayName)
            append(',')
            appendJsonField("selectedRegion", state.selectedRegion)
            append(',')
            append("\"currentSession\":")
            append(sessionSnapshot(state.currentSession))
            append(',')
            appendJsonBoolean("isLoading", state.isLoading)
            append(',')
            appendJsonBoolean("isLoggedIn", state.isLoggedIn)
            append(',')
            appendJsonField("errorMessage", state.errorMessage.orEmpty())
            append('}')
        }
    }

    fun effectSnapshot(effect: LoginEffect?): String {
        return when (effect) {
            null -> """{"type":"None"}"""
            is LoginEffect.AuthSucceeded -> buildString {
                append('{')
                appendJsonField("type", "AuthSucceeded")
                append(',')
                appendJsonField("mode", effect.mode.name)
                append(',')
                append("\"session\":")
                append(sessionSnapshot(effect.session))
                append('}')
            }

            is LoginEffect.ProfileSaved -> buildString {
                append('{')
                appendJsonField("type", "ProfileSaved")
                append(',')
                append("\"session\":")
                append(sessionSnapshot(effect.session))
                append('}')
            }

            LoginEffect.LoggedOut -> """{"type":"LoggedOut"}"""
            LoginEffect.AccountDeleted -> """{"type":"AccountDeleted"}"""
            LoginEffect.SessionExpired -> """{"type":"SessionExpired","message":"登录已过期"}"""
            is LoginEffect.ShowMessage -> buildString {
                append('{')
                appendJsonField("type", "ShowMessage")
                append(',')
                appendJsonField("message", effect.message)
                append('}')
            }

            is LoginEffect.NavigateHome -> buildString {
                append('{')
                appendJsonField("type", "NavigateHome")
                append(',')
                appendJsonField("message", effect.user.displayName)
                append('}')
            }
        }
    }

    fun storeSnapshot(store: MockAuthStore): String {
        return MockAuthStoreJson.encode(store)
    }

    fun parseStoreSnapshot(json: String): MockAuthStore {
        return MockAuthStoreJson.decode(json)
    }

    fun isStoreSnapshotRoundTripStable(json: String): Boolean {
        return MockAuthStoreJson.isRoundTripStable(json)
    }

    private fun sessionSnapshot(session: AuthSession?): String {
        if (session == null) return "null"
        return buildString {
            append('{')
            appendJsonField("account", session.account)
            append(',')
            appendJsonField("displayName", session.resolvedDisplayName)
            append(',')
            appendJsonField("region", session.region)
            append(',')
            appendJsonBoolean("isValid", session.isValid)
            append(',')
            appendJsonBoolean("isProfileComplete", session.isProfileComplete)
            append('}')
        }
    }

    private fun StringBuilder.appendJsonField(name: String, value: String) {
        append('"')
        append(name)
        append("\":\"")
        append(value.jsonEscaped())
        append('"')
    }

    private fun StringBuilder.appendJsonBoolean(name: String, value: Boolean) {
        append('"')
        append(name)
        append("\":")
        append(value)
    }

    private fun String.jsonEscaped(): String {
        return buildString {
            this@jsonEscaped.forEach { char ->
                when (char) {
                    '\\' -> append("\\\\")
                    '"' -> append("\\\"")
                    '\n' -> append("\\n")
                    '\r' -> append("\\r")
                    '\t' -> append("\\t")
                    else -> append(char)
                }
            }
        }
    }
}
