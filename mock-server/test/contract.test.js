const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { createApp, resetStore, setPersistEnabled } = require('../src/app');
const store = require('../src/store');

let server;
let base;

// 测试使用独立数据文件且不落盘，绝不触碰运行时实例的数据
store.configureDataFile('mock-server-store-test.json');
setPersistEnabled(false);

function jsonHeaders() {
  return { 'Content-Type': 'application/json' };
}

async function post(path, body) {
  const res = await fetch(`${base}${path}`, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

async function put(path, body) {
  const res = await fetch(`${base}${path}`, {
    method: 'PUT',
    headers: jsonHeaders(),
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

async function del(path, body) {
  const res = await fetch(`${base}${path}`, {
    method: 'DELETE',
    headers: jsonHeaders(),
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

async function get(path) {
  const res = await fetch(`${base}${path}`);
  return { status: res.status, body: await res.json() };
}

before(async () => {
  resetStore();
  const app = createApp();
  server = app.listen(0);
  await new Promise((resolve) => server.on('listening', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => {
  server.close();
});

test('MSRV-001: 登录默认种子账号返回服务器权威会话', async () => {
  const { status, body } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  assert.strictEqual(status, 200);
  assert.strictEqual(body.session.account, '13107012029');
  assert.strictEqual(body.session.userId, 'mock-user-default');
  assert.strictEqual(body.session.isValid, true);
});

test('MSRV-001: 健康 GET 返回服务器权威数据（空态为 EMPTY_DATA）', async () => {
  const { status, body } = await get('/api/health/mock-user-default');
  assert.strictEqual(status, 404);
  assert.strictEqual(body.error.code, 'EMPTY_DATA');
});

test('MSRV-003: regions 返回 CN/US 且 CN 为默认', async () => {
  const { status, body } = await post('/api/auth/regions', {});
  assert.strictEqual(status, 200);
  const codes = body.regions.map((r) => r.region);
  assert.deepStrictEqual(codes, ['CN', 'US']);
  assert.strictEqual(body.regions[0].isDefault, true);
});

test('MSRV-003: 注册成功返回会话且可登录', async () => {
  const verify = await post('/api/auth/verify-code', { account: 'newuser@example.com' });
  assert.strictEqual(verify.status, 200);

  const { status, body } = await post('/api/auth/register', {
    account: 'newuser@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
    displayName: 'New User',
  });
  assert.strictEqual(status, 200);
  assert.strictEqual(body.session.account, 'newuser@example.com');
  assert.strictEqual(body.session.isValid, true);

  const login = await post('/api/auth/login', {
    account: 'newuser@example.com',
    password: 'abcdef',
  });
  assert.strictEqual(login.status, 200);
});

test('MSRV-003: 重复注册返回 ACCOUNT_EXISTS(409)', async () => {
  const verify = await post('/api/auth/verify-code', { account: 'dup@example.com' });
  assert.strictEqual(verify.status, 200);
  await post('/api/auth/register', {
    account: 'dup@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  const { status, body } = await post('/api/auth/register', {
    account: 'dup@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  assert.strictEqual(status, 409);
  assert.strictEqual(body.error.code, 'ACCOUNT_EXISTS');
});

test('MSRV-003: 密码错误返回 PASSWORD_INCORRECT(401)', async () => {
  const { status, body } = await post('/api/auth/login', {
    account: '13107012029',
    password: 'wrongpw',
  });
  assert.strictEqual(status, 401);
  assert.strictEqual(body.error.code, 'PASSWORD_INCORRECT');
});

test('MSRV-003: 账号不存在返回 ACCOUNT_NOT_FOUND(404)', async () => {
  const { status, body } = await post('/api/auth/login', {
    account: 'missing@example.com',
    password: 'abcdef',
  });
  assert.strictEqual(status, 404);
  assert.strictEqual(body.error.code, 'ACCOUNT_NOT_FOUND');
});

test('MSRV-003: 验证码错误返回 VERIFY_CODE_INVALID(400)', async () => {
  const { status, body } = await post('/api/auth/register', {
    account: 'badcode@example.com',
    password: 'abcdef',
    verifyCode: '9999',
    region: 'CN',
  });
  assert.strictEqual(status, 400);
  assert.strictEqual(body.error.code, 'VERIFY_CODE_INVALID');
});

test('MSRV-003: 账号存在预检查返回 exists，且不存在账号返回 false', async () => {
  const exists = await get('/api/auth/account?account=13107012029');
  assert.strictEqual(exists.status, 200);
  assert.strictEqual(exists.body.exists, true);

  const missing = await get('/api/auth/account?account=nobody@example.com');
  assert.strictEqual(missing.status, 200);
  assert.strictEqual(missing.body.exists, false);
});

test('MSRV-003: 验证码预检查对正确验证码返回 ok，错误/过期返回错误', async () => {
  await post('/api/auth/verify-code', { account: 'checkcode@example.com' });

  const ok = await post('/api/auth/verify-code/check', {
    account: 'checkcode@example.com',
    code: '1234',
  });
  assert.strictEqual(ok.status, 200);
  assert.strictEqual(ok.body.ok, true);

  const bad = await post('/api/auth/verify-code/check', {
    account: 'checkcode@example.com',
    code: '9999',
  });
  assert.strictEqual(bad.status, 400);
  assert.strictEqual(bad.body.error.code, 'VERIFY_CODE_INVALID');
});

test('MSRV-003: 更新资料成功且会话随之更新', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const userId = login.session.userId;

  const profile = {
    username: 'Updated Name',
    birthDate: '2000-01-01',
    heightCm: 178,
    weightKg: 70.5,
    measurementSystem: 'METRIC',
    phone: '13107012029',
    countryRegion: 'CN',
    gender: 'MALE',
    email: '',
  };
  const { status, body } = await put('/api/auth/profile', { userId, profile });
  assert.strictEqual(status, 200);
  assert.strictEqual(body.session.profile.username, 'Updated Name');

  const readback = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  assert.strictEqual(readback.body.session.profile.username, 'Updated Name');
});

test('MSRV-003: 修改密码成功后旧密码失效新密码可用', async () => {
  const change = await post('/api/auth/password/change', {
    account: '13107012029',
    oldPassword: '123456',
    newPassword: '654321',
  });
  assert.strictEqual(change.status, 200);

  const oldLogin = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  assert.strictEqual(oldLogin.status, 401);

  const newLogin = await post('/api/auth/login', {
    account: '13107012029',
    password: '654321',
  });
  assert.strictEqual(newLogin.status, 200);
});

test('MSRV-003: 重置密码后新密码可登录', async () => {
  const reset = await post('/api/auth/password/reset', {
    account: '13107012029',
    newPassword: 'abcdef',
  });
  assert.strictEqual(reset.status, 200);
  const login = await post('/api/auth/login', {
    account: '13107012029',
    password: 'abcdef',
  });
  assert.strictEqual(login.status, 200);
});

test('MSRV-003: 登出后会话失效，GET session 返回 AUTH_REQUIRED', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: 'abcdef',
  });
  const userId = login.session.userId;

  const logout = await post('/api/auth/logout', { userId });
  assert.strictEqual(logout.status, 200);

  const session = await get(`/api/auth/session?userId=${userId}`);
  assert.strictEqual(session.status, 401);
  assert.strictEqual(session.body.error.code, 'AUTH_REQUIRED');
});

test('MSRV-003: 注销账号级联删除该用户健康数据', async () => {
  const verify = await post('/api/auth/verify-code', { account: 'delete-me@example.com' });
  assert.strictEqual(verify.status, 200);
  await post('/api/auth/register', {
    account: 'delete-me@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  const { body: login } = await post('/api/auth/login', {
    account: 'delete-me@example.com',
    password: 'abcdef',
  });
  const userId = login.session.userId;

  const snapshot = { userId, scenario: 'NORMAL', enabledCardTypes: ['RECOVERY'], schemaVersion: 7 };
  const saved = await put(`/api/health/${userId}`, snapshot);
  assert.strictEqual(saved.status, 200);

  const deleted = await del('/api/auth/account', { userId });
  assert.strictEqual(deleted.status, 200);

  const health = await get(`/api/health/${userId}`);
  assert.strictEqual(health.status, 404);
  assert.strictEqual(health.body.error.code, 'EMPTY_DATA');
});

test('MSRV-004: 健康快照 PUT 后 GET 可读回，字段保持一致', async () => {
  const snapshot = {
    userId: 'mock-user-default',
    scenario: 'NORMAL',
    enabledCardTypes: ['RECOVERY', 'TRAINING_LOAD'],
    editableData: {
      dailySummary: { steps: 8769, calories: 769, activeMinutes: 69 },
      todayActivity: { distanceKm: 8.41, paceSecondsPerKm: 637 },
      weeklyPlan: { days: [{ type: 'EASY_RUN', distanceKm: 5.0 }] },
      trainingLoad: { dailyLoads: [22, 11, 22, 12, 0, 0, 0] },
      assessment: { shortTermLoad: 155, longTermLoad: 138 },
      recovery: { score: 95 },
      runningAbility: { score: 85 },
      cyclingAbility: { score: 72 },
      heartRate: { fiveMinuteSamples: [60, 61, 62] },
      stress: { halfHourSamples: [35, 40] },
      sleep: { startMinuteOfDay: 420, stages: [{ stage: 'LIGHT', startMinute: 0, durationMinutes: 60 }] },
      hrvAssessment: { averageMs: 48 },
      restingHeartRate: { value: 58, measuredTime: '08:45', thirtyDayAverage: 52 },
      healthCheck: { heartRate: 91, hrvMs: 42, stress: 45, respiratoryRate: 91, bloodOxygen: 91, measuredTime: '15:04' },
      bodyManagement: { weightKg: 68.2, trainedMuscleGroups: ['chest'], weightHistoryKg: [68.2] },
    },
    schemaVersion: 7,
  };
  const saved = await put(`/api/health/${snapshot.userId}`, snapshot);
  assert.strictEqual(saved.status, 200);

  const read = await get(`/api/health/${snapshot.userId}`);
  assert.strictEqual(read.status, 200);
  assert.strictEqual(read.body.snapshot.userId, 'mock-user-default');
  assert.strictEqual(read.body.snapshot.editableData.dailySummary.steps, 8769);
  assert.strictEqual(read.body.snapshot.enabledCardTypes.length, 2);
});

test('MSRV-004: 不同 userId 健康数据相互隔离', async () => {
  const a = { userId: 'user-a', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 };
  const b = { userId: 'user-b', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 };
  await put('/api/health/user-a', a);
  await put('/api/health/user-b', b);

  const readA = await get('/api/health/user-a');
  const readB = await get('/api/health/user-b');
  assert.strictEqual(readA.status, 200);
  assert.strictEqual(readB.status, 200);
  assert.strictEqual(readA.body.snapshot.userId, 'user-a');
  assert.strictEqual(readB.body.snapshot.userId, 'user-b');
});

test('MSRV-004: 场景选择接口返回服务器场景', async () => {
  const { status, body } = await get('/api/health/mock-user-default/scenario');
  assert.strictEqual(status, 200);
  assert.strictEqual(body.scenario, 'NORMAL');
});

test('MSRV-012: 重置后种子账号与健康空态可恢复', async () => {
  resetStore();
  const login = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  assert.strictEqual(login.status, 200);

  const regions = await post('/api/auth/regions', {});
  assert.strictEqual(regions.status, 200);
});

test('MSRV-008: 认证 store 快照可按 userId 拉取与提交', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const userId = login.session.userId;

  const pulled = await get(`/api/sync/auth?userId=${userId}`);
  assert.strictEqual(pulled.status, 200);
  assert.strictEqual(pulled.body.store.accounts[0].userId, userId);
  assert.strictEqual(pulled.body.store.currentSession.userId, userId);

  const pushed = await put('/api/sync/auth', {
    store: {
      accounts: [{ userId, account: '13107012029', displayName: 'Sync Name', region: 'CN' }],
      currentSession: { ...login.session, displayName: 'Sync Name' },
      verifyCodes: [],
      defaultAccountsInitialized: true,
    },
  });
  assert.strictEqual(pushed.status, 200);

  const readback = await get(`/api/sync/auth?userId=${userId}`);
  assert.strictEqual(readback.body.store.accounts[0].displayName, 'Sync Name');
});

test('MSRV-008: 注册新账号经 sync/auth 持久化（非首个账号也能保存）', async () => {
  const verify = await post('/api/auth/verify-code', { account: 'harmony-new@example.com' });
  assert.strictEqual(verify.status, 200);
  const registered = await post('/api/auth/register', {
    account: 'harmony-new@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
    displayName: 'Harmony New',
  });
  assert.strictEqual(registered.status, 200);
  const newUserId = registered.body.session.userId;

  const sync = await put('/api/sync/auth', {
    store: {
      accounts: [
        { userId: 'mock-user-default', account: '13107012029', displayName: 'COROS User', region: 'CN' },
        { userId: newUserId, account: 'harmony-new@example.com', displayName: 'Harmony New', region: 'CN' },
      ],
      currentSession: registered.body.session,
      verifyCodes: [],
      defaultAccountsInitialized: true,
    },
  });
  assert.strictEqual(sync.status, 200);

  const pulled = await get(`/api/sync/auth?userId=${newUserId}`);
  assert.strictEqual(pulled.status, 200);
  assert.strictEqual(pulled.body.store.accounts[0].userId, newUserId);
  assert.strictEqual(pulled.body.store.currentSession.userId, newUserId);
});

test('MSRV-008: 健康快照集合可整体拉取与提交', async () => {
  const snapshot = {
    userId: 'sync-user',
    scenario: 'NORMAL',
    enabledCardTypes: ['RECOVERY'],
    editableData: null,
    schemaVersion: 7,
  };
  const saved = await put('/api/sync/health', { snapshots: [snapshot] });
  assert.strictEqual(saved.status, 200);

  const pulled = await get('/api/sync/health');
  assert.strictEqual(pulled.status, 200);
  const found = pulled.body.snapshots.find((s) => s.userId === 'sync-user');
  assert.strictEqual(found.userId, 'sync-user');

  const health = await get('/api/health/sync-user');
  assert.strictEqual(health.status, 200);
  assert.strictEqual(health.body.snapshot.userId, 'sync-user');
});

test('MSRV-008-SYNC: 同步健康快照按 userId 合并，不覆盖其他用户', async () => {
  const userA = { userId: 'merge-user-a', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 };
  const userB = { userId: 'merge-user-b', scenario: 'ABNORMAL', enabledCardTypes: [], schemaVersion: 7 };
  await put('/api/sync/health', { snapshots: [userA, userB] });

  // 鸿蒙仅提交 userB 的新数据，userA 必须保留
  const updatedB = { userId: 'merge-user-b', scenario: 'NORMAL', enabledCardTypes: ['RECOVERY'], schemaVersion: 7 };
  const saved = await put('/api/sync/health', { snapshots: [updatedB] });
  assert.strictEqual(saved.status, 200);

  const a = await get('/api/health/merge-user-a');
  assert.strictEqual(a.status, 200);
  assert.strictEqual(a.body.snapshot.scenario, 'NORMAL');
  assert.deepStrictEqual(a.body.snapshot.enabledCardTypes, []);

  const b = await get('/api/health/merge-user-b');
  assert.strictEqual(b.status, 200);
  assert.deepStrictEqual(b.body.snapshot.enabledCardTypes, ['RECOVERY']);
});

test('MSRV-008-SYNC: 认证 store 同步只更新当前会话用户，不覆盖其他账号', async () => {
  resetStore();
  // 服务器已有用户 A 的账号（种子默认账号）
  const storeA = {
    accounts: [{ userId: 'mock-user-default', account: '13107012029', displayName: 'COROS User', region: 'CN' }],
    currentSession: null,
    verifyCodes: [],
    defaultAccountsInitialized: true,
  };
  await put('/api/sync/auth', { store: storeA });

  // 鸿蒙以新用户 B 会话提交 store（accounts 同时包含 A 与 B），服务器不应用 A 覆盖，只处理 B
  const verify = await post('/api/auth/verify-code', { account: 'harmony-merge@example.com' });
  assert.strictEqual(verify.status, 200);
  const register = await post('/api/auth/register', {
    account: 'harmony-merge@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
    displayName: 'Harmony Merge',
  });
  assert.strictEqual(register.status, 200);
  const userB = register.body.session;

  const pushed = await put('/api/sync/auth', {
    store: {
      accounts: [
        { userId: 'mock-user-default', account: '13107012029', displayName: 'COROS User', region: 'CN' },
        { userId: userB.userId, account: 'harmony-merge@example.com', displayName: 'Harmony Merge', region: 'CN' },
      ],
      currentSession: userB,
      verifyCodes: [],
      defaultAccountsInitialized: true,
    },
  });
  assert.strictEqual(pushed.status, 200);

  const readB = await get(`/api/sync/auth?userId=${userB.userId}`);
  assert.strictEqual(readB.status, 200);
  assert.strictEqual(readB.body.store.currentSession.userId, userB.userId);
});

test('MSRV-015: 头像 PUT 后 GET 返回相同二进制', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const userId = login.session.userId;
  const imageBytes = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46]);

  const uploaded = await fetch(`${base}/api/avatar/${userId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/jpeg' },
    body: imageBytes,
  });
  assert.strictEqual(uploaded.status, 200);
  const uploadedBody = await uploaded.json();
  assert.strictEqual(uploadedBody.ok, true);

  const downloaded = await fetch(`${base}/api/avatar/${userId}`);
  assert.strictEqual(downloaded.status, 200);
  assert.strictEqual(downloaded.headers.get('content-type'), 'image/jpeg');
  const bytes = Buffer.from(await downloaded.arrayBuffer());
  assert.deepStrictEqual(bytes, imageBytes);
});

test('MSRV-015: 注销账号级联删除头像文件', async () => {
  const verify = await post('/api/auth/verify-code', { account: 'avatar-delete@example.com' });
  assert.strictEqual(verify.status, 200);
  const registered = await post('/api/auth/register', {
    account: 'avatar-delete@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
    displayName: 'Avatar Del',
  });
  assert.strictEqual(registered.status, 200);
  const userId = registered.body.session.userId;

  const uploaded = await fetch(`${base}/api/avatar/${userId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/jpeg' },
    body: Buffer.from([0xff, 0xd8, 0xff]),
  });
  assert.strictEqual(uploaded.status, 200);

  const deleted = await del('/api/auth/account', { userId });
  assert.strictEqual(deleted.status, 200);

  const after = await fetch(`${base}/api/avatar/${userId}`);
  assert.strictEqual(after.status, 404);
});

test('MSRV-015: 未知用户头像上传返回 ACCOUNT_NOT_FOUND', async () => {
  const uploaded = await fetch(`${base}/api/avatar/missing-user`, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/jpeg' },
    body: Buffer.from([0xff, 0xd8, 0xff]),
  });
  assert.strictEqual(uploaded.status, 404);
  const body = await uploaded.json();
  assert.strictEqual(body.error.code, 'ACCOUNT_NOT_FOUND');
});
