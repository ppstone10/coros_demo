package com.example.demo.common.health

import com.example.demo.common.login.AuthRepository
import com.example.demo.common.login.InMemoryAuthStoreDataSource
import com.example.demo.common.login.LocalMockAuthRepository
import com.example.demo.common.login.LocalMockAuthRepository.Companion.DefaultVerifyCode
import com.example.demo.common.login.LoginResult
import com.example.demo.common.login.RegisterUseCase
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class HealthStoreTest {

    @Test
    fun healthActionDispatchProducesExpectedState() {
        val store = createStore()
        store.dispatch(HealthAction.Load)
        val state = store.state
        assertNotNull(state.uiState, "Load should produce a non-null uiState")
        assertEquals(14, state.uiState.cards.size, "Normal scenario should have 14 cards")
    }

    @Test
    fun healthStateReflectsScenarioSelection() {
        val store = createStore()
        store.dispatch(HealthAction.Load)
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Abnormal))
        assertEquals(HealthMockScenario.Abnormal, store.state.currentScenario)
    }

    @Test
    fun healthEffectIsProducedAfterRefresh() {
        val store = createStore()
        assertNull(store.consumeEffect(), "No effect before any action")
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Abnormal))
        store.dispatch(HealthAction.Refresh)
        val effect = store.consumeEffect()
        assertNotNull(effect, "Refresh should produce an effect")
        assertNull(store.consumeEffect(), "Second consume should return null")
    }

    @Test
    fun healthStoreReflectsErrorStateOnUnauthenticatedAccess() {
        val repo = LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L })
        val store = HealthStore(repo, InMemoryHealthDashboardStateDataSource())
        store.dispatch(HealthAction.Load)
        val state = store.state
        assertNull(state.uiState, "Unauthenticated access should not produce uiState")
        assertEquals(HealthError.AuthRequired, state.error, "Unauthenticated access should return AuthRequired")
    }

    @Test
    fun healthStateResetsOnEffectConsumed() {
        val store = createStore()
        store.dispatch(HealthAction.Load)
        store.dispatch(HealthAction.EffectConsumed)
        assertNull(store.consumeEffect(), "Effect should be consumed after EffectConsumed action")
    }

    @Test
    fun healthEffectScenarioChangedAfterRefresh() {
        val store = createStore()
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Abnormal))
        store.dispatch(HealthAction.Refresh)
        val effect = store.consumeEffect()
        assertTrue(
            effect is HealthEffect.ScenarioChanged,
            "Refresh after scenario change should produce ScenarioChanged, got $effect"
        )
    }

    @Test
    fun healthConfigSavedEffectAfterSavingConfiguration() {
        val store = createStore()
        store.dispatch(HealthAction.Load)
        store.consumeEffect()
        val types = listOf(HealthCardType.Sleep, HealthCardType.Stress, HealthCardType.HeartRate)
        store.dispatch(HealthAction.CardConfigurationChanged(types))
        val effect = store.consumeEffect()
        assertIs<HealthEffect.ConfigSaved>(effect, "Saving config should produce ConfigSaved")
        assertEquals(types, effect.types)
    }

    @Test
    fun healthStorePreservesExistingTestsBehavior() {
        val store = createStore()
        store.dispatch(HealthAction.Load)
        store.consumeEffect()
        assertNotNull(store.state.uiState)
        val cards = store.state.uiState!!.cards
        assertTrue(cards.size >= 12, "Should have at least 12 cards like existing test")
        assertTrue(cards.first().priority <= cards.last().priority, "Cards should be sorted by priority")
    }

    @Test
    fun healthStoreDispatchEffectConsumedClearsEffect() {
        val store = createStore()
        store.dispatch(HealthAction.ScenarioSelected(HealthMockScenario.Abnormal))
        store.dispatch(HealthAction.Refresh)
        assertNotNull(store.consumeEffect())
        store.dispatch(HealthAction.EffectConsumed)
        assertNull(store.consumeEffect())
    }

    @Test
    fun healthStoreRejectsInvalidCardConfiguration() {
        val store = createStore()
        store.dispatch(HealthAction.Load)
        store.consumeEffect()
        val twoTypes = listOf(HealthCardType.Sleep, HealthCardType.Stress)
        store.dispatch(HealthAction.CardConfigurationChanged(twoTypes))
        val effect = store.consumeEffect()
        assertIs<HealthEffect.ShowMessage>(effect, "Less than 3 cards should produce error message")
    }

    private fun createStore(): HealthStore {
        val repo = repository(true)
        val persistence = InMemoryHealthDashboardStateDataSource()
        return HealthStore(repo, persistence)
    }

    private fun repository(register: Boolean): AuthRepository =
        LocalMockAuthRepository(InMemoryAuthStoreDataSource(), nowEpochMs = { 1_000L }).also { repo ->
            if (register) {
                repo.requestVerifyCode("store_test@example.com", DefaultVerifyCode)
                assertIs<LoginResult.Success>(
                    RegisterUseCase(repo).execute(
                        "store_test@example.com", "password1", DefaultVerifyCode, "CN", "Store Test"
                    )
                )
            }
        }
}
