package com.example.demo.common.health.repository

import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.health.model.HealthDashboardData
import com.example.demo.common.health.model.HealthMockScenario

interface HealthDashboardDataSource {
    fun load(scenario: HealthMockScenario): MockResult<HealthDashboardData>
}
