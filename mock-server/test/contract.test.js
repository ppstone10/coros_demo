const { test, before, after } = require('node:test');
const assert = require('node:assert');
const { createApp, resetStore, setPersistEnabled } = require('../src/app');
const store = require('../src/store');

let server;
let base;

// 测试使用独立数据目录且默认不落盘，绝不触碰运行时实例的数据
store.configureDataDir('contract-test');
setPersistEnabled(false);

function jsonHeaders(extra = {}) {
  return { 'Content-Type': 'application/json', ...extra };
}

async function request(method, path, body, headers = {}) {
  const res = await fetch(`${base}${path}`, {
    method,
    headers: jsonHeaders(headers),
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (e) {
    json = text;
  }
  return { status: res.status, body: json };
}

function post(path, body, headers) {
  return request('POST', path, body, headers);
}
function put(path, body, headers) {
  return request('PUT', path, body, headers);
}
function del(path, body, headers) {
  return request('DELETE', path, body, headers);
}
function get(path, headers) {
  return request('GET', path, undefined, headers);
}

/** 携带设备标识的请求头；不传则服务端按 device-default 处理。 */
function devHeaders(deviceId) {
  return { 'X-Device-Id': deviceId };
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
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const { status, body } = await get(`/api/health/${login.session.userId}`);
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

  // 恢复种子密码，保证后续用例基于默认口令
  const restore = await post('/api/auth/password/reset', {
    account: '13107012029',
    newPassword: '123456',
  });
  assert.strictEqual(restore.status, 200);
  const login123 = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  assert.strictEqual(login123.status, 200);
});

test('MSRV-003: 登出后会话失效，GET session 返回 AUTH_REQUIRED', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
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

  // 账号与会话一并删除：再访问健康接口应因无会话返回 AUTH_REQUIRED
  const health = await get(`/api/health/${userId}`);
  assert.strictEqual(health.status, 401);
  assert.strictEqual(health.body.error.code, 'AUTH_REQUIRED');
  assert.strictEqual(store.getHealthSnapshot(userId), null);
});

test('MSRV-004: 健康快照 PUT 后 GET 可读回，字段保持一致', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const userId = login.session.userId;
  const snapshot = {
    userId,
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
  assert.strictEqual(read.body.snapshot.userId, userId);
  assert.strictEqual(read.body.snapshot.editableData.dailySummary.steps, 8769);
  assert.strictEqual(read.body.snapshot.enabledCardTypes.length, 2);
});

test('MSRV-004: 不同 userId 健康数据相互隔离', async () => {
  await post('/api/auth/verify-code', { account: 'iso-a@example.com' });
  const ra = await post('/api/auth/register', {
    account: 'iso-a@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  await post('/api/auth/verify-code', { account: 'iso-b@example.com' });
  const rb = await post('/api/auth/register', {
    account: 'iso-b@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  const userIdA = ra.body.session.userId;
  const userIdB = rb.body.session.userId;

  await put(`/api/health/${userIdA}`, { userId: userIdA, scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 });
  await put(`/api/health/${userIdB}`, { userId: userIdB, scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 });

  const readA = await get(`/api/health/${userIdA}`);
  const readB = await get(`/api/health/${userIdB}`);
  assert.strictEqual(readA.status, 200);
  assert.strictEqual(readB.status, 200);
  assert.strictEqual(readA.body.snapshot.userId, userIdA);
  assert.strictEqual(readB.body.snapshot.userId, userIdB);
});

test('MSRV-004: 场景选择接口返回服务器场景', async () => {
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const { status, body } = await get(`/api/health/${login.session.userId}/scenario`);
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
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
  });
  const userId = login.session.userId;
  const snapshot = {
    userId,
    scenario: 'NORMAL',
    enabledCardTypes: ['RECOVERY'],
    editableData: null,
    schemaVersion: 7,
  };
  const saved = await put(`/api/sync/health?userId=${userId}`, { snapshots: [snapshot] });
  assert.strictEqual(saved.status, 200);

  const pulled = await get(`/api/sync/health?userId=${userId}`);
  assert.strictEqual(pulled.status, 200);
  const found = pulled.body.snapshots.find((s) => s.userId === userId);
  assert.strictEqual(found.userId, userId);

  const health = await get(`/api/health/${userId}`);
  assert.strictEqual(health.status, 200);
  assert.strictEqual(health.body.snapshot.userId, userId);
});

test('MSRV-008-SYNC: 同步健康快照按 userId 合并，不覆盖其他用户', async () => {
  await post('/api/auth/verify-code', { account: 'merge-a@example.com' });
  const ra = await post('/api/auth/register', {
    account: 'merge-a@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  await post('/api/auth/verify-code', { account: 'merge-b@example.com' });
  const rb = await post('/api/auth/register', {
    account: 'merge-b@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
  });
  const userIdA = ra.body.session.userId;
  const userIdB = rb.body.session.userId;

  const userA = { userId: userIdA, scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 };
  const userB = { userId: userIdB, scenario: 'ABNORMAL', enabledCardTypes: [], schemaVersion: 7 };
  await put(`/api/sync/health?userId=${userIdB}`, { snapshots: [userA, userB] });

  // 鸿蒙仅提交 userB 的新数据，userA 必须保留
  const updatedB = { userId: userIdB, scenario: 'NORMAL', enabledCardTypes: ['RECOVERY'], schemaVersion: 7 };
  const saved = await put(`/api/sync/health?userId=${userIdB}`, { snapshots: [updatedB] });
  assert.strictEqual(saved.status, 200);

  const a = await get(`/api/health/${userIdA}`);
  assert.strictEqual(a.status, 200);
  assert.strictEqual(a.body.snapshot.scenario, 'NORMAL');
  assert.deepStrictEqual(a.body.snapshot.enabledCardTypes, []);

  const b = await get(`/api/health/${userIdB}`);
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

  // 账号会话一并删除：再拉头像应无会话返回 401，且文件已删除
  const after = await fetch(`${base}/api/avatar/${userId}`);
  assert.strictEqual(after.status, 401);
  const afterBody = await after.json();
  assert.strictEqual(afterBody.error.code, 'AUTH_REQUIRED');
  assert.strictEqual(store.loadAvatar(userId), null);
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

test('MSRV-015: 头像 GET 忽略设备匹配，仅要求会话有效', async () => {
  resetStore();
  await post('/api/auth/login', { account: '13107012029', password: '123456', deviceId: 'dev-x' });
  const imageBytes = Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
  await fetch(`${base}/api/avatar/mock-user-default`, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/jpeg', 'X-Device-Id': 'dev-x' },
    body: imageBytes,
  });

  // 携带不匹配的设备头仍可读取（图片加载器场景，仅校验会话有效）
  const downloaded = await fetch(`${base}/api/avatar/mock-user-default`, {
    headers: { 'X-Device-Id': 'dev-other' },
  });
  assert.strictEqual(downloaded.status, 200);
  const bytes = Buffer.from(await downloaded.arrayBuffer());
  assert.deepStrictEqual(bytes, imageBytes);
});

// ---- MSRV-016: 单账号单设备登录（微信模式顶号 + 二次确认） ----

test('MSRV-016: 同 deviceId 重复登录不触发冲突，直接刷新会话', async () => {
  resetStore();
  const first = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-same',
  });
  assert.strictEqual(first.status, 200);

  const second = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-same',
  });
  assert.strictEqual(second.status, 200);
  assert.strictEqual(second.body.session.deviceId, 'dev-same');
});

test('MSRV-016: 非 force 登录遇有效异地会话返回 409 SESSION_ACTIVE_ELSEWHERE 且不顶号', async () => {
  resetStore();
  const first = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-a',
    deviceName: 'Device A',
  });
  assert.strictEqual(first.status, 200);

  const conflict = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-b',
    deviceName: 'Device B',
  });
  assert.strictEqual(conflict.status, 409);
  assert.strictEqual(conflict.body.error.code, 'SESSION_ACTIVE_ELSEWHERE');
  assert.strictEqual(conflict.body.error.activeDevice.deviceId, 'dev-a');
  assert.strictEqual(conflict.body.error.activeDevice.deviceName, 'Device A');

  // 未顶号：旧设备会话仍有效
  const check = await get(`/api/auth/session?userId=${first.body.session.userId}`, devHeaders('dev-a'));
  assert.strictEqual(check.status, 200);
});

test('MSRV-016: force 登录顶号，被顶设备请求返回 SESSION_EXPIRED_ELSEWHERE', async () => {
  resetStore();
  const first = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-a',
  });
  assert.strictEqual(first.status, 200);
  const userId = first.body.session.userId;

  const force = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-b',
    force: true,
  });
  assert.strictEqual(force.status, 200);
  assert.strictEqual(force.body.session.deviceId, 'dev-b');

  // 被顶的旧设备：懒校验返回 401 SESSION_EXPIRED_ELSEWHERE
  const kicked = await get(`/api/auth/session?userId=${userId}`, devHeaders('dev-a'));
  assert.strictEqual(kicked.status, 401);
  assert.strictEqual(kicked.body.error.code, 'SESSION_EXPIRED_ELSEWHERE');

  // 新设备会话正常
  const active = await get(`/api/auth/session?userId=${userId}`, devHeaders('dev-b'));
  assert.strictEqual(active.status, 200);
});

test('MSRV-016: 被顶设备写操作同样被拦截', async () => {
  resetStore();
  const first = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-a',
  });
  const userId = first.body.session.userId;
  await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-b',
    force: true,
  });

  const profile = {
    username: 'Kicked Edit',
    birthDate: '2000-01-01',
    heightCm: 178,
    weightKg: 70,
    measurementSystem: 'METRIC',
    phone: '13107012029',
    countryRegion: 'CN',
    gender: 'MALE',
    email: '',
  };
  const edit = await put('/api/auth/profile', { userId, profile }, devHeaders('dev-a'));
  assert.strictEqual(edit.status, 401);
  assert.strictEqual(edit.body.error.code, 'SESSION_EXPIRED_ELSEWHERE');
});

// ---- MSRV-017: 多账号并存（per-account 会话） ----

test('MSRV-017: 两个账号各自独立登录并存，互不影响', async () => {
  resetStore();
  await post('/api/auth/verify-code', { account: 'multi-a@example.com' });
  const ra = await post('/api/auth/register', {
    account: 'multi-a@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
    deviceId: 'dev-a',
  });
  assert.strictEqual(ra.status, 200);

  await post('/api/auth/verify-code', { account: 'multi-b@example.com' });
  const rb = await post('/api/auth/register', {
    account: 'multi-b@example.com',
    password: 'abcdef',
    verifyCode: '1234',
    region: 'CN',
    deviceId: 'dev-b',
  });
  assert.strictEqual(rb.status, 200);

  const a = await post('/api/auth/login', { account: 'multi-a@example.com', password: 'abcdef', deviceId: 'dev-a' });
  const b = await post('/api/auth/login', { account: 'multi-b@example.com', password: 'abcdef', deviceId: 'dev-b' });
  assert.strictEqual(a.status, 200);
  assert.strictEqual(b.status, 200);

  // A 登出只影响 A，B 仍有效
  const logoutA = await post('/api/auth/logout', { userId: a.body.session.userId }, devHeaders('dev-a'));
  assert.strictEqual(logoutA.status, 200);

  const checkA = await get(`/api/auth/session?userId=${a.body.session.userId}`, devHeaders('dev-a'));
  assert.strictEqual(checkA.status, 401);

  const checkB = await get(`/api/auth/session?userId=${b.body.session.userId}`, devHeaders('dev-b'));
  assert.strictEqual(checkB.status, 200);
  assert.strictEqual(checkB.body.session.userId, b.body.session.userId);
});

test('MSRV-017: sessions 按 userId 隔离为集合', async () => {
  resetStore();
  const loginRes = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-iso',
  });
  assert.strictEqual(loginRes.status, 200);
  const s1 = store.getSession('mock-user-default');
  assert.strictEqual(s1.deviceId, 'dev-iso');
  // 另一个账号无会话
  assert.strictEqual(store.getSession('no-such-user'), null);
});

// ---- MSRV-018: 数据接口会话校验 ----

test('MSRV-018: 无会话访问健康数据返回 AUTH_REQUIRED(401)', async () => {
  resetStore();
  const { status, body } = await get('/api/health/mock-user-default');
  assert.strictEqual(status, 401);
  assert.strictEqual(body.error.code, 'AUTH_REQUIRED');
});

test('MSRV-018: 设备不匹配访问健康数据返回 SESSION_EXPIRED_ELSEWHERE(401)', async () => {
  resetStore();
  await post('/api/auth/login', { account: '13107012029', password: '123456', deviceId: 'dev-x' });
  const { status, body } = await get('/api/health/mock-user-default', devHeaders('dev-y'));
  assert.strictEqual(status, 401);
  assert.strictEqual(body.error.code, 'SESSION_EXPIRED_ELSEWHERE');
});

test('MSRV-018: 本人有效会话可读写健康数据，越权读写被拒', async () => {
  resetStore();
  const { body: login } = await post('/api/auth/login', {
    account: '13107012029',
    password: '123456',
    deviceId: 'dev-x',
  });
  const userId = login.session.userId;

  const saved = await put(`/api/health/${userId}`, {
    userId,
    scenario: 'NORMAL',
    enabledCardTypes: [],
    schemaVersion: 7,
  }, devHeaders('dev-x'));
  assert.strictEqual(saved.status, 200);

  const read = await get(`/api/health/${userId}`, devHeaders('dev-x'));
  assert.strictEqual(read.status, 200);
  assert.strictEqual(read.body.snapshot.userId, userId);

  // 他人设备（无会话/不匹配）无法读该用户健康数据
  const denied = await get(`/api/health/${userId}`, devHeaders('dev-other'));
  assert.strictEqual(denied.status, 401);
  assert.strictEqual(denied.body.error.code, 'SESSION_EXPIRED_ELSEWHERE');
});

test('MSRV-018: sync 接口要求有效会话，无会话返回 401', async () => {
  resetStore();
  const { status, body } = await get('/api/sync/health?userId=mock-user-default');
  assert.strictEqual(status, 401);
  assert.strictEqual(body.error.code, 'AUTH_REQUIRED');
});

test('MSRV-018: 头像上传需有效会话，无会话返回 401', async () => {
  resetStore();
  const uploaded = await fetch(`${base}/api/avatar/mock-user-default`, {
    method: 'PUT',
    headers: { 'Content-Type': 'image/jpeg' },
    body: Buffer.from([0xff, 0xd8, 0xff]),
  });
  assert.strictEqual(uploaded.status, 401);
  const body = await uploaded.json();
  assert.strictEqual(body.error.code, 'AUTH_REQUIRED');
});

test('MSRV-018: sync/auth 不带 userId 返回全部账号（鸿蒙未登录登录发现）', async () => {
  resetStore();
  const { status, body } = await get('/api/sync/auth');
  assert.strictEqual(status, 200);
  assert.ok(Array.isArray(body.store.accounts), '应返回账号列表');
  assert.ok(body.store.accounts.length >= 2, '种子账号应包含');
  const ids = body.store.accounts.map((a) => a.userId);
  assert.ok(ids.includes('mock-user-default'), '默认种子账号应存在');
  assert.strictEqual(body.store.currentSession, null);
});
