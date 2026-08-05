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
};

function error(code) {
  return { error: { code, message: MESSAGES[code] || code } };
}

function jsonError(res, code) {
  return res.status(HTTP_BY_ERROR[code] || 500).json(error(code));
}

function createApp() {
  const app = express();
  app.use(express.json({ limit: '2mb' }));
  const avatarRaw = express.raw({ type: ['image/*', 'application/octet-stream'], limit: '5mb' });

  // 会话有效性：当前登录用户与会话存在
  function activeSession(userId) {
    const session = store.getSession();
    if (!session || session.userId !== userId || !session.isValid) return null;
    return session;
  }

  // 构造 AuthSession JSON（与 auth_mock.proto 契约一致，lowerCamelCase）
  function sessionJson(account, issuedAtEpochMs = Date.now()) {
    const profile = account.profile || null;
    return {
      userId: account.userId,
      account: account.account,
      displayName: account.displayName,
      region: account.region,
      isValid: true,
      issuedAtEpochMs,
      expireAtEpochMs: 0,
      profile,
    };
  }

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

  // 注册：校验验证码/区域/格式，写入账号库并签发会话
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
    const session = sessionJson(newAccount);
    if (!store.saveSession(session)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ session });
  });

  // 登录：校验账号密码，签发会话
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
    const session = sessionJson(localAccount);
    if (!store.saveSession(session)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ session });
  });

  // 会话懒校验（冷启动）
  app.get('/api/auth/session', (req, res) => {
    const userId = req.query.userId || '';
    const session = activeSession(userId);
    if (!session) {
      return jsonError(res, 'AUTH_REQUIRED');
    }
    res.json({ session });
  });

  // 登出：清除会话
  app.post('/api/auth/logout', (req, res) => {
    const userId = req.body && req.body.userId || '';
    const session = activeSession(userId);
    if (!session) {
      return jsonError(res, 'AUTH_REQUIRED');
    }
    store.clearSession();
    res.json({ ok: true });
  });

  // 更新资料：校验必填字段，更新账号与会话
  app.put('/api/auth/profile', (req, res) => {
    const userId = req.body && req.body.userId || '';
    const profile = req.body && req.body.profile || null;
    const session = activeSession(userId);
    if (!session) {
      return jsonError(res, 'AUTH_REQUIRED');
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
    const updatedSession = { ...session, displayName: clean.username, profile: clean, isValid: true };
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

  // 注销账号：删除账号、会话与健康快照（级联）
  app.delete('/api/auth/account', (req, res) => {
    const userId = req.body && req.body.userId || '';
    const session = activeSession(userId);
    if (!session) {
      return jsonError(res, 'AUTH_REQUIRED');
    }
    if (!store.deleteAccount(userId)) {
      return jsonError(res, 'PERSIST_FAILED');
    }
    res.json({ ok: true });
  });

  // ---- 健康域 ----

  // 拉取健康快照
  app.get('/api/health/:userId', (req, res) => {
    const snapshot = store.getHealthSnapshot(req.params.userId);
    if (!snapshot) {
      return jsonError(res, 'EMPTY_DATA');
    }
    res.json({ snapshot });
  });

  // 提交健康快照
  app.put('/api/health/:userId', (req, res) => {
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
    const snapshot = store.getHealthSnapshot(req.params.userId);
    res.json({ scenario: (snapshot && snapshot.scenario) || 'NORMAL' });
  });

  // ---- HarmonyOS 快照同步（MSRV-008：ArkTS 经 ohos.net.http 读写整份文档）----

  // 拉取权威认证 store 文档（按当前用户作用域，避免覆盖其他用户）
  app.get('/api/sync/auth', (req, res) => {
    const userId = (req.query.userId || '').trim();
    const session = store.getSession();
    const userSession = session && session.userId === userId ? session : null;
    const userAccount = userId ? store.findAccountByUserId(userId) : null;
    const storeDoc = {
      accounts: userAccount ? [userAccount] : [],
      currentSession: userSession,
      verifyCodes: userId
        ? store.findVerifyCode(userAccount ? userAccount.account : '')
          ? store.verifyCodesForAccount(userAccount.account)
          : []
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
    // 若带有效会话，则只 upsert 该会话对应用户；否则按传入 accounts 首个合法账号
    const targetAccount = targetUserId
      ? doc.accounts.find((a) => a && a.userId === targetUserId)
      : doc.accounts[0];
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
          store.clearSession();
        }
      }
    }
    res.json({ ok: true });
  });

  // 拉取权威健康快照集合
  app.get('/api/sync/health', (req, res) => {
    res.json({ snapshots: store.allHealthSnapshots() });
  });

  // 提交健康快照集合（逐条按 userId upsert，保留其他用户快照，不整体替换）
  app.put('/api/sync/health', (req, res) => {
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

  // ---- 头像文件存储（MSRV-015：真实图片文件 + URL 展示）----

  // 上传头像：二进制 body 落盘 data/avatars/{userId}.jpg
  app.put('/api/avatar/:userId', avatarRaw, (req, res) => {
    const userId = req.params.userId;
    if (!userId || !store.findAccountByUserId(userId)) {
      return jsonError(res, 'ACCOUNT_NOT_FOUND');
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

  // 拉取头像：返回图片二进制
  app.get('/api/avatar/:userId', (req, res) => {
    const buffer = store.loadAvatar(req.params.userId);
    if (!buffer) {
      return jsonError(res, 'EMPTY_DATA');
    }
    res.set('Content-Type', 'image/jpeg');
    res.send(buffer);
  });

  // 删除头像：注销账号级联调用
  app.delete('/api/avatar/:userId', (req, res) => {
    if (!store.deleteAvatar(req.params.userId)) {
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
