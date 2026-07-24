package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.InMemoryAuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository

@Suppress("unused")
class HealthFacade(
    private val store: HealthStore
) {
    constructor() : this(
        HealthStore(
            LocalMockAuthRepository(InMemoryAuthStoreDataSource()),
            InMemoryHealthDashboardStateDataSource()
        )
    )

    val state: HealthState
        get() = store.state

    fun load() {
        store.dispatch(HealthAction.Load)
    }

    fun selectScenario(name: String): Boolean {
        val scenario = HealthMockScenario.entries.firstOrNull { it.name == name } ?: return false
        store.dispatch(HealthAction.ScenarioSelected(scenario))
        return true
    }

    fun refresh() {
        store.dispatch(HealthAction.Refresh)
    }

    fun saveCardConfiguration(typeNames: List<String>): String? {
        val types = typeNames.mapNotNull { n -> HealthCardType.entries.firstOrNull { it.name == n } }
        store.dispatch(HealthAction.CardConfigurationChanged(types))
        val effect = store.consumeEffect()
        return if (effect is HealthEffect.ShowMessage) effect.message else null
    }

    fun consumeEffect(): HealthEffect? = store.consumeEffect()

    fun healthError(): HealthError? = store.state.error
}

@Suppress("unused")
class HealthFacadeFactory {
    fun createPersistent(
        authRepository: AuthRepository,
        stateDataSource: HealthDashboardStateDataSource
    ): HealthFacade {
        return HealthFacade(HealthStore(authRepository, stateDataSource))
    }
}
