package com.example.demo.auth.data

import android.annotation.SuppressLint
import android.content.Context
import com.example.demo.common.auth.repository.AuthStoreDataSource
import com.example.demo.common.auth.model.MockAuthStore
import com.example.demo.common.auth.mock.MockAuthStoreJson

class AndroidAuthStoreDataSource(context: Context) : AuthStoreDataSource {
    private val preferences = context.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)

    override fun load(): MockAuthStore {
        val raw = preferences.getString(StoreKey, null) ?: return MockAuthStore()
        return runCatching { MockAuthStoreJson.decode(raw) }.getOrDefault(MockAuthStore())
    }

    @SuppressLint("UseKtx")
    override fun save(store: MockAuthStore): Boolean {
        return preferences.edit()
            .putString(StoreKey, MockAuthStoreJson.encode(store))
            .commit()
    }

    private companion object {
        const val PreferencesName = "auth_mock_store"
        const val StoreKey = "training_auth_mock_store"
    }
}