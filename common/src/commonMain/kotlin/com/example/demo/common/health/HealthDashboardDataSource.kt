package com.example.demo.common.health

import com.example.demo.common.login.MockResult

interface HealthDashboardDataSource {
    fun load(scenario: HealthMockScenario): MockResult<HealthDashboardData>
}
