package com.example.demo.common.login

interface AuthStoreDataSource {
    fun load(): MockAuthStore
    fun save(store: MockAuthStore): Boolean
}

class InMemoryAuthStoreDataSource(
    initialStore: MockAuthStore = MockAuthStore()
) : AuthStoreDataSource {
    private var store: MockAuthStore = initialStore

    override fun load(): MockAuthStore = store

    override fun save(store: MockAuthStore): Boolean {
        this.store = store
        return true
    }
}
