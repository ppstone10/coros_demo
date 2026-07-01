package com.example.demo.login

import android.annotation.SuppressLint
import android.content.Context
import com.example.demo.common.login.AuthStoreDataSource
import com.example.demo.common.login.MockAccount
import com.example.demo.common.login.MockAuthSession
import com.example.demo.common.login.MockAuthStore
import com.example.demo.common.login.MockVerifyCodeState
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
    }

    private fun decode(json: JSONObject): MockAuthStore {
        return MockAuthStore(
            accounts = decodeAccounts(json.optJSONArray("accounts") ?: JSONArray()),
            currentSession = decodeSession(json.optJSONObject("current_session")),
            verifyCodes = decodeVerifyCodes(json.optJSONArray("verify_codes") ?: JSONArray())
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
                region = item.optString("region")
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
            isValid = json.optBoolean("is_valid", false)
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
