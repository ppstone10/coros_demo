package com.example.demo.common.auth.mock
import com.example.demo.common.auth.model.MockAuthStore
import com.example.demo.common.auth.repository.AuthStoreDataSource

class JsonAuthStoreDataSource(
    private val loadJson: () -> String?,
    private val saveJson: (String) -> Boolean
) : AuthStoreDataSource {
    override fun load(): MockAuthStore {
        val raw = loadJson()?.takeIf { it.isNotBlank() } ?: return MockAuthStore()
        return runCatching { MockAuthStoreJson.decode(raw) }.getOrDefault(MockAuthStore())
    }

    override fun save(store: MockAuthStore): Boolean {
        return saveJson(MockAuthStoreJson.encode(store))
    }
}
