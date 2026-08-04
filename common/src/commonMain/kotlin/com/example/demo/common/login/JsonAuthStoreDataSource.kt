package com.example.demo.common.login

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
