const fs = require('fs');
const path = require('path');

// 数据根目录（可被 setDataRoot 覆盖，测试用临时目录）
let dataRoot = path.join(__dirname, '..', 'data');
// 端口/实例目录名：data/{dirName}/accounts.json、data/{dirName}/health/、data/{dirName}/avatars/
let dirName = '3000';
let DATA_DIR = path.join(dataRoot, dirName);

function recomputeDir() {
  DATA_DIR = path.join(dataRoot, dirName);
}

/** 覆盖数据根目录（测试隔离用）。 */
function setDataRoot(root) {
  dataRoot = root;
  recomputeDir();
  return DATA_DIR;
}

/** 配置数据目录名（按端口隔离，MSRV-020）。 */
function configureDataDir(name) {
  dirName = String(name);
  recomputeDir();
  return DATA_DIR;
}

function accountsFile() {
  return path.join(DATA_DIR, 'accounts.json');
}

function healthDir() {
  return path.join(DATA_DIR, 'health');
}

function healthFile(userId) {
  return path.join(healthDir(), `${userId}.json`);
}

function avatarDir() {
  return path.join(DATA_DIR, 'avatars');
}

function avatarPath(userId) {
  return path.join(avatarDir(), `${userId}.jpg`);
}

/** 旧版单文件位置：data/mock-server-store-{PORT}.json（迁移用）。 */
function legacyFile() {
  return path.join(dataRoot, `mock-server-store-${dirName}.json`);
}

function saveAvatar(userId, buffer) {
  try {
    atomicWriteBuffer(avatarPath(userId), buffer);
    return true;
  } catch (e) {
    return false;
  }
}

function loadAvatar(userId) {
  try {
    const file = avatarPath(userId);
    if (!fs.existsSync(file)) return null;
    return fs.readFileSync(file);
  } catch (e) {
    return null;
  }
}

function deleteAvatar(userId) {
  try {
    const file = avatarPath(userId);
    if (fs.existsSync(file)) fs.unlinkSync(file);
    return true;
  } catch (e) {
    return false;
  }
}

const DEFAULT_ACCOUNT = '13107012029';
const DEFAULT_EMAIL_ACCOUNT = '2232591785@qq.com';
const DEFAULT_PASSWORD = '123456';
const DEFAULT_VERIFY_CODE = '1234';
const RESENT_VERIFY_CODE = '4321';
const VERIFY_CODE_TTL_MS = 60 * 1000;

const REGIONS = [
  { region: 'CN', displayName: 'China', isDefault: true },
  { region: 'US', displayName: 'United States', isDefault: false },
];

function hashMockPassword(password) {
  return `mock:${password.split('').reverse().join('')}:${password.length}`;
}

function buildUserId(account) {
  // 与 common 端 LocalMockAuthRepository.buildUserId 完全一致：
  // account.fold(17) { acc, char -> acc * 31 + char.code } 的 Int32 环绕语义。
  let hash = 17;
  for (const ch of account) {
    hash = Math.imul(hash, 31) + ch.codePointAt(0);
    hash |= 0; // Int32 环绕
  }
  if (hash < 0) hash = -hash;
  return `mock-user-${hash}`;
}

function isAccountFormatValid(account) {
  const isEmailLike = account.includes('@') && account.split('@')[1].includes('.');
  const isPhoneLike = account.length >= 5 && account.length <= 20 &&
    account.split('').every((c) => c >= '0' && c <= '9' || c === '+' || c === '-');
  return isEmailLike || isPhoneLike;
}

function seedAccounts() {
  return [
    {
      userId: 'mock-user-default',
      account: DEFAULT_ACCOUNT,
      passwordHash: hashMockPassword(DEFAULT_PASSWORD),
      displayName: 'COROS User',
      region: 'CN',
      profile: null,
    },
    {
      userId: 'mock-user-default-email',
      account: DEFAULT_EMAIL_ACCOUNT,
      passwordHash: hashMockPassword(DEFAULT_PASSWORD),
      displayName: 'COROS Email User',
      region: 'CN',
      profile: null,
    },
  ];
}

function seedStore() {
  return {
    accounts: seedAccounts(),
    sessions: {}, // per-account 会话集合（MSRV-017）
    verifyCodes: [],
    defaultAccountsInitialized: true,
  };
}

let store = seedStore();
let healthCache = {}; // 健康快照内存权威（MSRV-020）
let persistEnabled = true;

function setPersistEnabled(enabled) {
  persistEnabled = enabled;
}

function resetStore() {
  store = seedStore();
  healthCache = {};
  return store;
}

/** 原子落盘：先写临时文件再 rename（MSRV-021）。 */
function atomicWrite(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tmp = `${filePath}.tmp`;
  fs.writeFileSync(tmp, data, 'utf8');
  fs.renameSync(tmp, filePath);
}

function atomicWriteBuffer(filePath, buffer) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tmp = `${filePath}.tmp`;
  fs.writeFileSync(tmp, buffer);
  fs.renameSync(tmp, filePath);
}

function persistAccounts() {
  if (!persistEnabled) return true;
  try {
    atomicWrite(accountsFile(), JSON.stringify(store, null, 2));
    return true;
  } catch (e) {
    return false;
  }
}

function loadHealthFromDisk() {
  healthCache = {};
  const dir = healthDir();
  if (!fs.existsSync(dir)) return;
  for (const file of fs.readdirSync(dir)) {
    if (!file.endsWith('.json')) continue;
    const userId = file.slice(0, -'.json'.length);
    try {
      const parsed = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
      if (parsed && parsed.userId === userId) healthCache[userId] = parsed;
    } catch (e) {
      // 损坏的单用户文件跳过，不阻塞启动
    }
  }
}

/** 旧单文件一次性迁移到新布局（MSRV-020）。 */
function migrateFromLegacy() {
  try {
    const legacy = legacyFile();
    const parsed = JSON.parse(fs.readFileSync(legacy, 'utf8'));
    if (!parsed || !Array.isArray(parsed.accounts)) return false;
    const sessions = {};
    const oldSession = parsed.currentSession;
    if (oldSession && oldSession.userId) {
      sessions[oldSession.userId] = {
        ...oldSession,
        deviceId: oldSession.deviceId || 'device-default',
        deviceName: oldSession.deviceName || '其他设备',
      };
    }
    store = {
      accounts: parsed.accounts || [],
      sessions,
      verifyCodes: parsed.verifyCodes || [],
      defaultAccountsInitialized: true,
    };
    healthCache = {};
    const oldSnapshots = parsed.healthSnapshots || {};
    for (const [userId, snapshot] of Object.entries(oldSnapshots)) {
      if (!snapshot || !userId) continue;
      healthCache[userId] = snapshot;
      atomicWrite(healthFile(userId), JSON.stringify(snapshot));
    }
    persistAccounts();
    fs.unlinkSync(legacy);
    return true;
  } catch (e) {
    return false;
  }
}

function loadFromDisk() {
  try {
    if (fs.existsSync(accountsFile())) {
      const raw = fs.readFileSync(accountsFile(), 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.accounts)) {
        store = { ...seedStore(), ...parsed };
        store.sessions = parsed.sessions || {};
        loadHealthFromDisk();
        return true;
      }
    }
    if (fs.existsSync(legacyFile())) {
      if (migrateFromLegacy()) return true;
    }
  } catch (e) {
    // 损坏或缺失时回退种子
  }
  store = seedStore();
  loadHealthFromDisk();
  return false;
}

function findAccountByAccount(account) {
  const normalized = account.trim();
  return store.accounts.find((a) => a.account.toLowerCase() === normalized.toLowerCase());
}

function findAccountByUserId(userId) {
  return store.accounts.find((a) => a.userId === userId);
}

/** 全部账号（鸿蒙未登录时的登录发现用）。 */
function allAccounts() {
  return store.accounts;
}

function addAccount(account) {
  store.accounts.push(account);
  return persistAccounts();
}

function updateAccount(userId, patch) {
  const idx = store.accounts.findIndex((a) => a.userId === userId);
  if (idx < 0) return false;
  store.accounts[idx] = { ...store.accounts[idx], ...patch };
  return persistAccounts();
}

function deleteAccount(userId) {
  store.accounts = store.accounts.filter((a) => a.userId !== userId);
  delete store.sessions[userId];
  store.verifyCodes = store.verifyCodes.filter((c) => c.account !== userId);
  deleteHealthSnapshot(userId);
  deleteAvatar(userId);
  return persistAccounts();
}

function findVerifyCode(account) {
  const normalized = account.trim();
  return store.verifyCodes
    .filter((c) => c.account.toLowerCase() === normalized.toLowerCase())
    .sort((a, b) => b.expireAtEpochMs - a.expireAtEpochMs)[0] || null;
}

function verifyCodesForAccount(account) {
  const normalized = account.trim();
  return store.verifyCodes.filter(
    (c) => c.account.toLowerCase() === normalized.toLowerCase()
  );
}

function saveVerifyCode(codeState) {
  store.verifyCodes = store.verifyCodes.filter(
    (c) => c.account.toLowerCase() !== codeState.account.toLowerCase()
  );
  store.verifyCodes.push(codeState);
  return persistAccounts();
}

// ---- 会话（per-account 集合，MSRV-016/017）----

function getSession(userId) {
  return store.sessions[userId] || null;
}

function saveSession(session) {
  store.sessions[session.userId] = session;
  return persistAccounts();
}

/** 使某账号会话失效（被顶号），保留记录供审计。 */
function invalidateSession(userId, nowEpochMs) {
  const current = store.sessions[userId];
  if (!current) return true;
  store.sessions[userId] = { ...current, isValid: false, invalidatedAtEpochMs: nowEpochMs };
  return persistAccounts();
}

function clearSession(userId) {
  delete store.sessions[userId];
  return persistAccounts();
}

/**
 * 会话状态判定：返回 { session } 或 { error }。
 * - 无会话 -> AUTH_REQUIRED
 * - 会话已失效 -> SESSION_EXPIRED_ELSEWHERE
 * - 提供 deviceId 且不匹配 -> SESSION_EXPIRED_ELSEWHERE（活跃设备在别处）
 */
function sessionStatus(userId, deviceId) {
  const session = store.sessions[userId];
  if (!session) return { error: 'AUTH_REQUIRED' };
  if (session.isValid !== true) return { error: 'SESSION_EXPIRED_ELSEWHERE' };
  if (deviceId && session.deviceId !== deviceId) return { error: 'SESSION_EXPIRED_ELSEWHERE' };
  return { session };
}

// ---- 健康快照（每账号一文件，MSRV-020）----

function getHealthSnapshot(userId) {
  return healthCache[userId] || null;
}

function saveHealthSnapshot(snapshot) {
  healthCache[snapshot.userId] = snapshot;
  if (!persistEnabled) return true;
  try {
    atomicWrite(healthFile(snapshot.userId), JSON.stringify(snapshot));
    return true;
  } catch (e) {
    return false;
  }
}

function allHealthSnapshots() {
  return Object.values(healthCache);
}

function deleteHealthSnapshot(userId) {
  delete healthCache[userId];
  if (!persistEnabled) return true;
  try {
    const file = healthFile(userId);
    if (fs.existsSync(file)) fs.unlinkSync(file);
    return true;
  } catch (e) {
    return false;
  }
}

module.exports = {
  DATA_DIR,
  DEFAULT_ACCOUNT,
  DEFAULT_EMAIL_ACCOUNT,
  DEFAULT_PASSWORD,
  DEFAULT_VERIFY_CODE,
  RESENT_VERIFY_CODE,
  VERIFY_CODE_TTL_MS,
  REGIONS,
  hashMockPassword,
  buildUserId,
  isAccountFormatValid,
  setDataRoot,
  configureDataDir,
  resetStore,
  setPersistEnabled,
  loadFromDisk,
  findAccountByAccount,
  findAccountByUserId,
  allAccounts,
  addAccount,
  updateAccount,
  deleteAccount,
  findVerifyCode,
  verifyCodesForAccount,
  saveVerifyCode,
  getSession,
  saveSession,
  invalidateSession,
  clearSession,
  sessionStatus,
  getHealthSnapshot,
  allHealthSnapshots,
  saveHealthSnapshot,
  deleteHealthSnapshot,
  saveAvatar,
  loadAvatar,
  deleteAvatar,
};
