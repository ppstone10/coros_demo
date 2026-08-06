const express = require('express');
const store = require('./store');

const HTTP_BY_ERROR = {
  AUTH_REQUIRED: 401,
  INVALID_PARAM: 400,
  ACCOUNT_EXISTS: 409,
  ACCOUNT_NOT_FOUND: 404,
  PASSWORD_INCORRECT: 401,
  VERIFY_CODE_INVALID: 400,
  VERIFY_CODE_EXPIRED: 400,
  REGION_REQUIRED: 400,
  NEW_PASSWORD_SAME_AS_OLD: 400,
  EMPTY_DATA: 404,
  CORRUPTED_DATA: 500,
  PERSIST_FAILED: 500,
  // MSRV-016：非 force 登录遇有效异地会话 / 被顶设备请求
  SESSION_ACTIVE_ELSEWHERE: 409,
  SESSION_EXPIRED_ELSEWHERE: 401,
};

const MESSAGES = {
  AUTH_REQUIRED: '请先登录',
  INVALID_PARAM: '参数不合法',
  ACCOUNT_EXISTS: '账号已存在',
  ACCOUNT_NOT_FOUND: '账号不存在',
  PASSWORD_INCORRECT: '密码错误',
  VERIFY_CODE_INVALID: '验证码错误',
  VERIFY_CODE_EXPIRED: '验证码已过期',
  REGION_REQUIRED: '请选择注册区域',
  NEW_PASSWORD_SAME_AS_OLD: '新密码不能与旧密码相同',
  EMPTY_DATA: '暂无数据',
  CORRUPTED_DATA: '数据读取失败',
  PERSIST_FAILED: '保存失败',
  SESSION_ACTIVE_ELSEWHERE: '该账号已在其他设备登录',
  SESSION_EXPIRED_ELSEWHERE: '该账号已在其他设备登录，请重新登录',
};

function error(code) {
  return { error: { code, message: MESSAGES[code] || code } };
}

function jsonError(res, code) {
  return res.status(HTTP_BY_ERROR[code] || 500).json(error(code));
}

/** 设备标识：body → query → header → 默认。未提供时所有客户端共享 device-default（向后兼容）。 */
function deviceIdOf(req) {
  const fromBody = req.body && req.body.deviceId;
  const fromQuery = req.query && req.query.deviceId;
  const fromHeader = req.get('x-device-id');
  return String(fromBody || fromQuery || fromHeader || 'device-default');
}

function deviceNameOf(req) {
  const fromBody = req.body && req.body.deviceName;
  const fromQuery = req.query && req.query.deviceName;
  return String(fromBody || fromQuery || '其他设备');
}

/** 会话校验（MSRV-018）：失败时写错误响应并返回 null。 */
function requireSession(req, res, userId) {
  const status = store.sessionStatus(userId, deviceIdOf(req));
  if (status.error) {
    jsonError(res, status.error);
    return null;
  }
  return status.session;
}

// 构造 AuthSession JSON（与 auth_mock.proto 契约一致，lowerCamelCase；含 deviceId/deviceName）
function sessionJson(account, deviceId, deviceName, issuedAtEpochMs = Date.now()) {
  const profile = account.profile || null;
  return {
    userId: account.userId,
    account: account.account,
    displayName: account.displayName,
    region: account.region,
    isValid: true,
    deviceId,
    deviceName,
    issuedAtEpochMs,
    expireAtEpochMs: 0,
    profile,
  };
}

function createApp() {
  const app = express();
  app.use(express.json({ limit: '2mb' }));
  const avatarRaw = express.raw({ type: ['image/*', 'application/octet-stream'], limit: '5mb' });

  // ---- 认证域 ----

  // 获取注册区域
  app.post('/api/auth/regions', (req, res) => {
    res.json({ regions: store.REGIONS });
  });

  // 发送验证码：服务器生成/存储，固定 1234/4321，TTL 60s
  app.post('/api/auth/verify-code', (req, res) => {
    const account = (req.body && req.body.account || '').trim();
    if (account === '' || !store.isAccountFormatValid(account)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    const now = Date.now();
    const codeState = {
      account,
      code: req.body.code || store.DEFAULT_VERIFY_CODE,
      expireAtEpochMs: now + store.VERIFY_CODE_TTL_MS,
    };
    if (!store.saveVerifyCode(codeState)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ account, expireAtEpochMs: codeState.expireAtEpochMs });
  });

  // 校验验证码（注册前 UX 预检查）
  app.post('/api/auth/verify-code/check', (req, res) => {
    const account = (req.body && req.body.account || '').trim();
    const code = req.body && req.body.code || '';
    if (account === '' || !store.isAccountFormatValid(account)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    const savedCode = store.findVerifyCode(account);
    if (!savedCode) {
      return jsonError(res, 'VERIFY_CODE_INVALID');
    }
    if (savedCode.expireAtEpochMs <= Date.now()) {
      return jsonError(res, 'VERIFY_CODE_EXPIRED');
    }
    if (code !== savedCode.code) {
      return jsonError(res, 'VERIFY_CODE_INVALID');
    }
    res.json({ ok: true });
  });

  // 判断账号是否已存在（注册/找回密码 UX 预检查）
  app.get('/api/auth/account', (req, res) => {
    const account = (req.query.account || '').trim();
    if (account === '' || !store.isAccountFormatValid(account)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    res.json({ exists: store.findAccountByAccount(account) != null });
  });

  // 注册：校验验证码/区域/格式，写入账号库并签发会话（MSRV-016/017）
  app.post('/api/auth/register', (req, res) => {
    const account = (req.body && req.body.account || '').trim();
    const password = req.body && req.body.password || '';
    const verifyCode = req.body && req.body.verifyCode || '';
    const region = req.body && req.body.region || '';
    const displayName = req.body && req.body.displayName || '';

    if (account === '' || !store.isAccountFormatValid(account)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    if (!password || password.length < 6 || password.length > 20) {
      return jsonError(res, 'INVALID_PARAM');
    }
    if (store.findAccountByAccount(account)) {
      return jsonError(res, 'ACCOUNT_EXISTS');
    }
    const savedCode = store.findVerifyCode(account);
    if (!savedCode) {
      return jsonError(res, 'VERIFY_CODE_INVALID');
    }
    if (savedCode.expireAtEpochMs <= Date.now()) {
      return jsonError(res, 'VERIFY_CODE_EXPIRED');
    }
    if (verifyCode !== savedCode.code) {
      return jsonError(res, 'VERIFY_CODE_INVALID');
    }
    if (!region || !store.REGIONS.some((r) => r.region === region)) {
      return jsonError(res, 'REGION_REQUIRED');
    }

    const newAccount = {
      userId: store.buildUserId(account),
      account,
      passwordHash: store.hashMockPassword(password),
      displayName: displayName !== '' ? displayName : account,
      region,
      profile: null,
    };
    if (!store.addAccount(newAccount)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    const session = sessionJson(newAccount, deviceIdOf(req), deviceNameOf(req));
    if (!store.saveSession(session)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ session });
  });

  // 登录：校验账号密码，单设备顶号 + 二次确认（MSRV-016）
  app.post('/api/auth/login', (req, res) => {
    const account = (req.body && req.body.account || '').trim();
    const password = req.body && req.body.password || '';
    if (account === '' || !store.isAccountFormatValid(account)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    const localAccount = store.findAccountByAccount(account);
    if (!localAccount) {
      return jsonError(res, 'ACCOUNT_NOT_FOUND');
    }
    if (localAccount.passwordHash !== store.hashMockPassword(password)) {
      return jsonError(res, 'PASSWORD_INCORRECT');
    }

    const deviceId = deviceIdOf(req);
    const deviceName = deviceNameOf(req);
    const force = !!(req.body && req.body.force);
    const existing = store.getSession(localAccount.userId);

    // 有效异地会话 + 未确认（force）-> 返回 409 冲突，不顶号
    if (existing && existing.isValid && existing.deviceId !== deviceId && !force) {
      return res.status(HTTP_BY_ERROR.SESSION_ACTIVE_ELSEWHERE).json({
        error: {
          code: 'SESSION_ACTIVE_ELSEWHERE',
          message: MESSAGES.SESSION_ACTIVE_ELSEWHERE,
          activeDevice: {
            deviceId: existing.deviceId,
            deviceName: existing.deviceName || '其他设备',
          },
        },
      });
    }

    // 顶号：旧会话来自不同设备
    if (existing && existing.deviceId !== deviceId) {
      store.invalidateSession(localAccount.userId, Date.now());
    }
    const session = sessionJson(localAccount, deviceId, deviceName);
    if (!store.saveSession(session)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ session });
  });

  // 会话懒校验（冷启动/回前台，MSRV-019）
  app.get('/api/auth/session', (req, res) => {
    const userId = (req.query.userId || '').trim();
    const status = store.sessionStatus(userId, deviceIdOf(req));
    if (status.error) {
      return jsonError(res, status.error);
    }
    res.json({ session: status.session });
  });

  // 登出：按 userId 作用域化，只清本账号（MSRV-017）
  app.post('/api/auth/logout', (req, res) => {
    const userId = (req.body && req.body.userId || '').trim();
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    store.clearSession(userId);
    res.json({ ok: true });
  });

  // 更新资料：校验必填字段，更新账号与会话
  app.put('/api/auth/profile', (req, res) => {
    const userId = (req.body && req.body.userId || '').trim();
    const profile = req.body && req.body.profile || null;
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    if (!profile || typeof profile !== 'object') {
      return jsonError(res, 'INVALID_PARAM');
    }
    const clean = {
      avatarUri: profile.avatarUri || null,
      username: (profile.username || '').trim(),
      birthDate: profile.birthDate || '',
      heightCm: profile.heightCm ?? null,
      weightKg: profile.weightKg ?? null,
      measurementSystem: profile.measurementSystem || 'METRIC',
      phone: (profile.phone || '').trim(),
      email: profile.email || '',
      countryRegion: profile.countryRegion || session.region,
      gender: profile.gender || null,
    };
    const isComplete = clean.username !== '' &&
      clean.birthDate !== '' &&
      clean.heightCm !== null &&
      clean.weightKg !== null &&
      clean.gender !== null;
    if (!isComplete) {
      return jsonError(res, 'INVALID_PARAM');
    }
    const account = store.findAccountByUserId(userId);
    if (!account) {
      return jsonError(res, 'ACCOUNT_NOT_FOUND');
    }
    const updatedAccount = { ...account, displayName: clean.username, profile: clean };
    if (!store.updateAccount(userId, updatedAccount)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    const updatedSession = {
      ...session,
      displayName: clean.username,
      profile: clean,
      isValid: true,
      deviceId: session.deviceId,
      deviceName: session.deviceName,
    };
    if (!store.saveSession(updatedSession)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ session: updatedSession });
  });

  // 修改密码
  app.post('/api/auth/password/change', (req, res) => {
    const account = (req.body && req.body.account || '').trim();
    const oldPassword = req.body && req.body.oldPassword || '';
    const newPassword = req.body && req.body.newPassword || '';
    const localAccount = store.findAccountByAccount(account);
    if (!localAccount) {
      return jsonError(res, 'ACCOUNT_NOT_FOUND');
    }
    if (localAccount.passwordHash !== store.hashMockPassword(oldPassword)) {
      return jsonError(res, 'PASSWORD_INCORRECT');
    }
    if (!newPassword || newPassword.length < 6 || newPassword.length > 20) {
      return jsonError(res, 'INVALID_PARAM');
    }
    if (oldPassword === newPassword) {
      return jsonError(res, 'NEW_PASSWORD_SAME_AS_OLD');
    }
    if (!store.updateAccount(localAccount.userId, { passwordHash: store.hashMockPassword(newPassword) })) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  // 重置密码
  app.post('/api/auth/password/reset', (req, res) => {
    const account = (req.body && req.body.account || '').trim();
    const newPassword = req.body && req.body.newPassword || '';
    const localAccount = store.findAccountByAccount(account);
    if (!localAccount) {
      return jsonError(res, 'ACCOUNT_NOT_FOUND');
    }
    if (!newPassword || newPassword.length < 6 || newPassword.length > 20) {
      return jsonError(res, 'INVALID_PARAM');
    }
    if (!store.updateAccount(localAccount.userId, { passwordHash: store.hashMockPassword(newPassword) })) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  // 注销账号：删除账号、会话与健康快照/头像（级联）
  app.delete('/api/auth/account', (req, res) => {
    const userId = (req.body && req.body.userId || '').trim();
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    if (!store.deleteAccount(userId)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  // ---- 健康域（MSRV-018：需本人有效会话）----

  // 拉取健康快照
  app.get('/api/health/:userId', (req, res) => {
    const session = requireSession(req, res, req.params.userId);
    if (!session) {
      return;
    }
    const snapshot = store.getHealthSnapshot(req.params.userId);
    if (!snapshot) {
      return jsonError(res, 'EMPTY_DATA');
    }
    res.json({ snapshot });
  });

  // 提交健康快照
  app.put('/api/health/:userId', (req, res) => {
    const session = requireSession(req, res, req.params.userId);
    if (!session) {
      return;
    }
    const snapshot = req.body;
    if (!snapshot || typeof snapshot !== 'object' || snapshot.userId !== req.params.userId) {
      return jsonError(res, 'INVALID_PARAM');
    }
    if (!store.saveHealthSnapshot(snapshot)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  // 场景选择
  app.get('/api/health/:userId/scenario', (req, res) => {
    const session = requireSession(req, res, req.params.userId);
    if (!session) {
      return;
    }
    const snapshot = store.getHealthSnapshot(req.params.userId);
    res.json({ scenario: (snapshot && snapshot.scenario) || 'NORMAL' });
  });

  // ---- HarmonyOS 快照同步（MSRV-008；MSRV-018 需有效会话）----

  // 拉取权威认证 store 文档
  // - 带 userId + 有效会话：按当前用户作用域拉取（避免覆盖其他用户）；
  // - 不带 userId：返回全部账号（含 mock passwordHash），供鸿蒙"未登录"时的登录发现
  //   （鸿蒙登录是本地校验，需要先在本地 store 具备服务器账号，见 MSRV-018 边界）。
  app.get('/api/sync/auth', (req, res) => {
    const userId = (req.query.userId || '').trim();
    if (!userId) {
      res.json({
        store: {
          accounts: store.allAccounts(),
          currentSession: null,
          verifyCodes: [],
          defaultAccountsInitialized: true,
        },
      });
      return;
    }
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    const userAccount = userId ? store.findAccountByUserId(userId) : null;
    const storeDoc = {
      accounts: userAccount ? [userAccount] : [],
      currentSession: session,
      verifyCodes: userId && userAccount
        ? store.verifyCodesForAccount(userAccount.account)
        : [],
      defaultAccountsInitialized: true,
    };
    res.json({ store: storeDoc });
  });

  // 提交认证 store 文档（仅同步 currentSession 对应账号与会话，不覆盖其他用户）
  app.put('/api/sync/auth', (req, res) => {
    const doc = req.body && req.body.store ? req.body.store : req.body;
    if (!doc || !Array.isArray(doc.accounts)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    const session = doc.currentSession;
    const targetUserId = session && session.userId ? session.userId : null;
    if (!targetUserId) {
      return jsonError(res, 'AUTH_REQUIRED');
    }
    // 校验：目标用户必须存在有效会话且设备匹配
    const status = store.sessionStatus(targetUserId, deviceIdOf(req));
    if (status.error) {
      return jsonError(res, status.error);
    }
    const targetAccount = doc.accounts.find((a) => a && a.userId === targetUserId);
    if (targetAccount && targetAccount.userId) {
      const existing = store.findAccountByUserId(targetAccount.userId);
      if (existing) {
        if (!store.updateAccount(targetAccount.userId, targetAccount)) {
          return jsonError(res, 'PERSIST_FAILED');
        }
      } else if (!store.addAccount(targetAccount)) {
        return jsonError(res, 'PERSIST_FAILED');
      }
    }
    if (session && session.userId) {
      const sessionAccount = store.findAccountByUserId(session.userId);
      if (sessionAccount) {
        if (session.isValid) {
          store.saveSession(session);
        } else {
          store.clearSession(session.userId);
        }
      }
    }
    res.json({ ok: true });
  });

  // 拉取权威健康快照集合
  app.get('/api/sync/health', (req, res) => {
    const userId = (req.query.userId || '').trim();
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    res.json({ snapshots: store.allHealthSnapshots() });
  });

  // 提交健康快照集合（逐条按 userId upsert，保留其他用户快照，不整体替换）
  app.put('/api/sync/health', (req, res) => {
    const userId = String(
      (req.query && req.query.userId) || (req.body && req.body.userId) || ''
    ).trim();
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    const snapshots = req.body && req.body.snapshots;
    if (!Array.isArray(snapshots)) {
      return jsonError(res, 'INVALID_PARAM');
    }
    for (const snapshot of snapshots) {
      if (!snapshot || !snapshot.userId) continue;
      if (!store.saveHealthSnapshot(snapshot)) {
        return jsonError(res, 'PERSIST_FAILED');
      }
    }
    res.json({ ok: true });
  });

  // ---- 头像文件存储（MSRV-015；MSRV-018 写操作需有效会话）----

  // 上传头像：二进制 body 落盘 data/{PORT}/avatars/{userId}.jpg
  app.put('/api/avatar/:userId', avatarRaw, (req, res) => {
    const userId = req.params.userId;
    if (!userId || !store.findAccountByUserId(userId)) {
      return jsonError(res, 'ACCOUNT_NOT_FOUND');
    }
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    const buffer = req.body;
    if (!buffer || !Buffer.isBuffer(buffer) || buffer.length === 0) {
      return jsonError(res, 'INVALID_PARAM');
    }
    if (!store.saveAvatar(userId, buffer)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  // 拉取头像：只要求该用户存在有效会话（图片加载器无法携带设备头，故不做设备匹配）
  app.get('/api/avatar/:userId', (req, res) => {
    const userId = req.params.userId;
    const status = store.sessionStatus(userId, null);
    if (status.error) {
      return jsonError(res, status.error);
    }
    const buffer = store.loadAvatar(userId);
    if (!buffer) {
      return jsonError(res, 'EMPTY_DATA');
    }
    res.set('Content-Type', 'image/jpeg');
    res.send(buffer);
  });

  // 删除头像：注销账号级联调用
  app.delete('/api/avatar/:userId', (req, res) => {
    const userId = req.params.userId;
    const session = requireSession(req, res, userId);
    if (!session) {
      return;
    }
    if (!store.deleteAvatar(userId)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  app.use((req, res) => {
    res.status(404).json(error('ACCOUNT_NOT_FOUND'));
  });

  return app;
}

module.exports = { createApp, resetStore: store.resetStore, setPersistEnabled: store.setPersistEnabled };
