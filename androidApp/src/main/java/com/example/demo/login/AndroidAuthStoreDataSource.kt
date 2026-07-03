package com.example.demo.login

import android.annotation.SuppressLint
import android.content.Context
import com.example.demo.common.login.AuthStoreDataSource
import com.example.demo.common.login.MeasurementSystem
import com.example.demo.common.login.MockAccount
import com.example.demo.common.login.MockAuthSession
import com.example.demo.common.login.MockAuthStore
import com.example.demo.common.login.MockVerifyCodeState
import com.example.demo.common.login.UserGender
import com.example.demo.common.login.UserProfile
import org.json.JSONArray
import org.json.JSONObject

class AndroidAuthStoreDataSource(context: Context) : AuthStoreDataSource {
    private val preferences = context.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)

    override fun load(): MockAuthStore {
        val raw = preferences.getString(StoreKey, null) ?: return MockAuthStore()
        return runCatching { decode(JSONObject(raw)) }.getOrDefault(MockAuthStore())
    }

    @SuppressLint("UseKtx")
    override fun save(store: MockAuthStore): Boolean {
        return preferences.edit()
            .putString(StoreKey, encode(store).toString())
            .commit()
    }

    private fun encode(store: MockAuthStore): JSONObject {
        return JSONObject()
            .put("accounts", JSONArray().also { array ->
                store.accounts.forEach { account ->
                    array.put(
                        JSONObject()
                            .put("user_id", account.userId)
                            .put("account", account.account)
                            .put("password_hash", account.passwordHash)
                            .put("display_name", account.displayName)
                            .put("region", account.region)
                            .put("profile", encodeProfile(account.profile))
                    )
                }
            })
            .put(
                "current_session",
                store.currentSession?.let { session ->
                    JSONObject()
                        .put("user_id", session.userId)
                        .put("account", session.account)
                        .put("display_name", session.displayName)
                        .put("region", session.region)
                        .put("is_valid", session.isValid)
                        .put("profile", encodeProfile(session.profile))
                } ?: JSONObject.NULL
            )
            .put("verify_codes", JSONArray().also { array ->
                store.verifyCodes.forEach { code ->
                    array.put(
                        JSONObject()
                            .put("account", code.account)
                            .put("code", code.code)
                            .put("expire_at_epoch_ms", code.expireAtEpochMs)
                    )
                }
            })
            .put("default_accounts_initialized", store.defaultAccountsInitialized)
    }

    private fun decode(json: JSONObject): MockAuthStore {
        return MockAuthStore(
            accounts = decodeAccounts(json.optJSONArray("accounts") ?: JSONArray()),
            currentSession = decodeSession(json.optJSONObject("current_session")),
            verifyCodes = decodeVerifyCodes(json.optJSONArray("verify_codes") ?: JSONArray()),
            defaultAccountsInitialized = json.optBoolean("default_accounts_initialized", false)
        )
    }

    private fun decodeAccounts(array: JSONArray): List<MockAccount> {
        return List(array.length()) { index ->
            val item = array.getJSONObject(index)
            MockAccount(
                userId = item.optString("user_id"),
                account = item.optString("account"),
                passwordHash = item.optString("password_hash"),
                displayName = item.optString("display_name"),
                region = item.optString("region"),
                profile = decodeProfile(item.optJSONObject("profile"))
            )
        }
    }

    private fun decodeSession(json: JSONObject?): MockAuthSession? {
        if (json == null) return null
        return MockAuthSession(
            userId = json.optString("user_id"),
            account = json.optString("account"),
            displayName = json.optString("display_name"),
            region = json.optString("region"),
            isValid = json.optBoolean("is_valid", false),
            profile = decodeProfile(json.optJSONObject("profile"))
        )
    }

    private fun encodeProfile(profile: UserProfile?): Any {
        if (profile == null) return JSONObject.NULL
        return JSONObject()
            .put("avatar_uri", profile.avatarUri)
            .put("username", profile.username)
            .put("birth_date", profile.birthDate)
            .put("height_cm", profile.heightCm)
            .put("weight_kg", profile.weightKg)
            .put("measurement_system", profile.measurementSystem.name)
            .put("phone", profile.phone)
            .put("country_region", profile.countryRegion)
            .put("gender", profile.gender?.name)
    }

    private fun decodeProfile(json: JSONObject?): UserProfile? {
        if (json == null) return null
        return UserProfile(
            avatarUri = json.optString("avatar_uri").takeIf { it.isNotBlank() },
            username = json.optString("username"),
            birthDate = json.optString("birth_date"),
            heightCm = if (json.has("height_cm") && !json.isNull("height_cm")) {
                json.optInt("height_cm")
            } else {
                null
            },
            weightKg = if (json.has("weight_kg") && !json.isNull("weight_kg")) {
                json.optDouble("weight_kg")
            } else {
                null
            },
            measurementSystem = json.optString("measurement_system")
                .takeIf { it.isNotBlank() }
                ?.let { runCatching { MeasurementSystem.valueOf(it) }.getOrNull() }
                ?: MeasurementSystem.Metric,
            phone = json.optString("phone"),
            countryRegion = json.optString("country_region").ifBlank { "中国" },
            gender = json.optString("gender")
                .takeIf { it.isNotBlank() }
                ?.let { runCatching { UserGender.valueOf(it) }.getOrNull() }
        )
    }

    private fun decodeVerifyCodes(array: JSONArray): List<MockVerifyCodeState> {
        return List(array.length()) { index ->
            val item = array.getJSONObject(index)
            MockVerifyCodeState(
                account = item.optString("account"),
                code = item.optString("code"),
                expireAtEpochMs = item.optLong("expire_at_epoch_ms")
            )
        }
    }

    private companion object {
        const val PreferencesName = "auth_mock_store"
        const val StoreKey = "training_auth_mock_store"
    }
}
