package com.example.demo.auth.data

import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.LoginRequestDto
import com.example.demo.common.auth.model.LoginResult
import com.example.demo.common.auth.model.RegisterRequestDto
import com.example.demo.common.auth.model.UserProfile
import com.example.demo.common.auth.model.UserGender
import com.example.demo.common.auth.model.MeasurementSystem
import com.example.demo.common.auth.repository.InMemoryAuthStoreDataSource
import com.example.demo.core.network.MockServerHttpClient
import com.example.demo.health.data.RemoteHealthDashboardStateDataSource
import com.example.demo.common.health.model.HealthDashboardSnapshot
import com.example.demo.common.health.model.HealthMockScenario
import com.sun.net.httpserver.HttpServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.net.InetSocketAddress

class RemoteAuthRepositoryTest {

    private lateinit var server: HttpServer
    private lateinit var repo: RemoteAuthRepository
    private lateinit var healthSource: RemoteHealthDashboardStateDataSource
    private var capturedPath: String = ""
    private var capturedMethod: String = ""
    private var currentClockMs: Long = 1_000L
    private val healthStore = mutableMapOf<String, String>()
    private fun startServer() {
        server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
        server.createContext("/") { exchange ->
            capturedPath = exchange.requestURI.path
            capturedMethod = exchange.requestMethod
            val fullUri = exchange.requestURI.toString()
            val body = String(exchange.requestBody.readBytes())
            val result = routeWithStatus(capturedMethod, capturedPath, fullUri, body)
            val bytes = result.body.toByteArray()
            exchange.sendResponseHeaders(result.status, bytes.size.toLong())
            exchange.responseBody.use { it.write(bytes) }
        }
        server.start()
        val baseUrl = "http://127.0.0.1:${server.address.port}"
        repo = RemoteAuthRepository(MockServerHttpClient(baseUrl), InMemoryAuthStoreDataSource())
        healthSource = RemoteHealthDashboardStateDataSource(
            MockServerHttpClient(baseUrl),
            InMemoryHealthDashboardStateDataSourceStub()
        )
    }

    private fun baseUrlOf(): String = "http://127.0.0.1:${server.address.port}"

    private fun routeWithStatus(method: String, path: String, fullUri: String, body: String): StubResponse {
        val (status, json) = route(method, path, fullUri, body)
        return StubResponse(status, json)
    }

    private data class StubResponse(val status: Int, val body: String)

    private fun route(method: String, path: String, fullUri: String, body: String): Pair<Int, String> = when {
        method == "POST" && path == "/api/auth/login" -> 200 to
            """{"session":{"userId":"mock-user-default","account":"13107012029","displayName":"COROS User","region":"CN","isValid":true,"issuedAtEpochMs":1000,"expireAtEpochMs":0,"profile":null}}"""
        method == "POST" && path == "/api/auth/register" -> 200 to
            """{"session":{"userId":"mock-user-new","account":"new@example.com","displayName":"New","region":"CN","isValid":true,"issuedAtEpochMs":1000,"expireAtEpochMs":0,"profile":null}}"""
        method == "POST" && path == "/api/auth/verify-code" ->
            200 to """{"account":"13107012029","expireAtEpochMs":61000}"""
        method == "POST" && path == "/api/auth/verify-code/check" -> 200 to """{"ok":true}"""
        method == "GET" && path == "/api/auth/account" && fullUri.contains("account=missing") ->
            200 to """{"exists":false}"""
        method == "GET" && path == "/api/auth/account" -> 200 to """{"exists":true}"""
        method == "POST" && path == "/api/auth/regions" ->
            200 to """{"regions":[{"region":"CN","displayName":"China","isDefault":true},{"region":"US","displayName":"United States","isDefault":false}]}"""
        method == "PUT" && path == "/api/auth/profile" -> 200 to
            """{"session":{"userId":"mock-user-default","account":"13107012029","displayName":"Updated","region":"CN","isValid":true,"issuedAtEpochMs":1000,"expireAtEpochMs":0,"profile":{"username":"Updated","birthDate":"2000-01-01","heightCm":178,"weightKg":70.5,"measurementSystem":"METRIC","phone":"13107012029","countryRegion":"CN","gender":"MALE","email":"","avatarUri":null}}}"""
        method == "POST" && path == "/api/auth/password/change" -> 200 to """{"ok":true}"""
        method == "POST" && path == "/api/auth/password/reset" -> 200 to """{"ok":true}"""
        method == "POST" && path == "/api/auth/logout" -> 200 to """{"ok":true}"""
        method == "DELETE" && path == "/api/auth/account" -> 200 to """{"ok":true}"""
        method == "GET" && path.startsWith("/api/health/") -> {
            val userId = path.removePrefix("/api/health/")
            val stored = healthStore[userId]
            if (stored != null) 200 to """{"snapshot":$stored}"""
            else 404 to """{"error":{"code":"EMPTY_DATA","message":"暂无数据"}}"""
        }
        method == "PUT" && path.startsWith("/api/health/") -> {
            val userId = path.removePrefix("/api/health/")
            healthStore[userId] = body
            200 to """{"ok":true}"""
        }
        else -> 404 to """{"error":{"code":"ACCOUNT_NOT_FOUND","message":"账号不存在"}}"""
    }

    @Before
    fun setUp() {
        startServer()
    }

    @After
    fun tearDown() {
        server.stop(0)
    }

    @Test
    fun loginSuccessMapsServerSession() {
        val result = repo.login(LoginRequestDto("13107012029", "123456"))
        assertTrue(result is LoginResult.Success)
        val session = (result as LoginResult.Success).session
        assertEquals("mock-user-default", session.userId)
        assertEquals("13107012029", session.account)
        assertTrue(session.isValid)
        assertTrue(repo.verifyBusinessAccess() is MockResult.Success)
    }

    @Test
    fun registerSuccessMapsServerSession() {
        val result = repo.register(
            RegisterRequestDto("new@example.com", "abcdef", "1234", "CN", "New")
        )
        assertTrue(result is LoginResult.Success)
        assertEquals("mock-user-new", (result as LoginResult.Success).session.userId)
    }

    @Test
    fun verifyCodeRequestMapsServerExpiry() {
        val result = repo.requestVerifyCode("13107012029", "1234")
        assertTrue(result is MockResult.Success)
        val state = (result as MockResult.Success).data
        assertEquals(61_000L, state.expireAtEpochMs)
        assertEquals("13107012029", state.account)
    }

    @Test
    fun verifyCodeCheckMapsServerOk() {
        assertTrue(repo.verifyCode("13107012029", "1234") is MockResult.Success)
    }

    @Test
    fun hasAccountReadsServerTruth() {
        assertTrue(repo.hasAccount("13107012029"))
        assertFalse(repo.hasAccount("missing@example.com"))
    }

    @Test
    fun regionsMapServerList() {
        val regions = repo.availableRegions()
        assertEquals(2, regions.size)
        assertEquals("CN", regions[0].region)
        assertTrue(regions[0].isDefault)
        assertEquals("US", regions[1].region)
    }

    @Test
    fun saveProfileReturnsUpdatedSession() {
        val login = repo.login(LoginRequestDto("13107012029", "123456"))
        assertTrue(login is LoginResult.Success)

        val profile = UserProfile(
            username = "Updated",
            birthDate = "2000-01-01",
            heightCm = 178,
            weightKg = 70.5,
            measurementSystem = MeasurementSystem.Metric,
            phone = "13107012029",
            countryRegion = "CN",
            gender = UserGender.Male,
            email = ""
        )
        val result = repo.saveProfile(profile)
        assertTrue(result is MockResult.Success)
        assertEquals("Updated", (result as MockResult.Success).data.profile?.username)
    }

    @Test
    fun changePasswordAndResetSucceed() {
        assertTrue(repo.changePassword("13107012029", "123456", "654321") is MockResult.Success)
        assertTrue(repo.resetPassword("13107012029", "abcdef") is MockResult.Success)
    }

    @Test
    fun logoutAndDeleteAccountSucceed() {
        repo.login(LoginRequestDto("13107012029", "123456"))
        assertTrue(repo.clearSession() is MockResult.Success)

        repo.login(LoginRequestDto("13107012029", "123456"))
        assertTrue(repo.deleteCurrentAccount() is MockResult.Success)
    }

    @Test
    fun healthSourceRoundTripsSnapshot() {
        val snapshot = HealthDashboardSnapshot(userId = "mock-user-default")
        val saved = healthSource.save(snapshot)
        assertTrue(saved)

        val loaded = healthSource.load("mock-user-default")
        assertEquals("mock-user-default", loaded?.userId)
        assertEquals(HealthMockScenario.Normal, loaded?.sourceScenario)
    }

    @Test
    fun healthSourceEmptyReturnsNull() {
        assertNull(healthSource.load("mock-user-unknown"))
    }

    @Test
    fun authRequiredAfterClearSession() {
        repo.login(LoginRequestDto("13107012029", "123456"))
        repo.clearSession()
        assertTrue(repo.verifyBusinessAccess() is MockResult.Failure)
        assertEquals(MockError.AuthRequired, (repo.verifyBusinessAccess() as MockResult.Failure).error)
    }

    @Test
    fun sessionExpiresAfterBackgroundTtlWhenClockAdvances() {
        val ttlRepo = RemoteAuthRepository(
            MockServerHttpClient(baseUrlOf()),
            InMemoryAuthStoreDataSource(),
            sessionTtlMs = 10_000L,
            nowEpochMs = { currentClockMs }
        )
        val login = ttlRepo.login(LoginRequestDto("13107012029", "123456"))
        assertTrue(login is LoginResult.Success)
        assertTrue(ttlRepo.verifyBusinessAccess() is MockResult.Success)

        ttlRepo.pauseSession()

        // 模拟进入后台 10s 后冷启动：本地 TTL 判定过期
        currentClockMs += 10_000L
        val cold = ttlRepo.restoreSessionOnColdStart()
        assertEquals(com.example.demo.common.auth.model.SessionResumeResult.Expired, cold)
        assertTrue(ttlRepo.verifyBusinessAccess() is MockResult.Failure)
    }

    @Test
    fun sessionSurvivesBackgroundWithinTtl() {
        val ttlRepo = RemoteAuthRepository(
            MockServerHttpClient(baseUrlOf()),
            InMemoryAuthStoreDataSource(),
            sessionTtlMs = 10_000L,
            nowEpochMs = { currentClockMs }
        )
        ttlRepo.login(LoginRequestDto("13107012029", "123456"))
        ttlRepo.pauseSession()

        // 未超过 TTL 的暖恢复仍保持活跃
        currentClockMs += 5_000L
        assertTrue(ttlRepo.resumeSessionInSameProcess() is com.example.demo.common.auth.model.SessionResumeResult.Active)
        assertTrue(ttlRepo.verifyBusinessAccess() is MockResult.Success)
    }

    private class InMemoryHealthDashboardStateDataSourceStub :
        com.example.demo.common.health.store.HealthDashboardStateDataSource {
        private var snapshots = mutableMapOf<String, HealthDashboardSnapshot>()
        override fun load(userId: String): HealthDashboardSnapshot? = snapshots[userId]
        override fun save(snapshot: HealthDashboardSnapshot): Boolean {
            snapshots[snapshot.userId] = snapshot; return true
        }
        override fun clear(userId: String): Boolean { snapshots.remove(userId); return true }
    }
}
