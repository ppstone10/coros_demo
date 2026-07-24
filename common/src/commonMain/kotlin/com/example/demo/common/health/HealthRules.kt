package com.example.demo.common.health

object HealthRules {
    const val MinimumCardCount = 3

    fun validateMinimumCards(types: List<HealthCardType>): Boolean {
        return types.distinct().size >= MinimumCardCount
    }

    fun computeCardPriority(status: HealthCardStatus, typeOrdinal: Int): Int {
        return when (status) {
            HealthCardStatus.Risk -> typeOrdinal     // 0-13: risk first
            HealthCardStatus.Attention -> 14 + typeOrdinal
            HealthCardStatus.Normal -> 28 + typeOrdinal  // normal middle
            HealthCardStatus.Empty -> 56 + typeOrdinal   // empty last
        }
    }
}
