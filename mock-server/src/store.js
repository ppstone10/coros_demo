const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');
const AVATAR_DIR = path.join(DATA_DIR, 'avatars');

// 默认数据文件名；按端口隔离时由 configureDataFile 覆盖，避免多实例互相覆盖。
let dataFileName = 'mock-server-store.json';
let DATA_FILE = path.join(DATA_DIR, dataFileName);

/** 配置数据文件名（不含路径），用于按端口隔离不同实例的持久化。 */
function configureDataFile(name) {
  dataFileName = name;
  DATA_FILE = path.join(DATA_DIR, name);
  return DATA_FILE;
}

function avatarPath(userId) {
  return path.join(AVATAR_DIR, `${userId}.jpg`);
}

function saveAvatar(userId, buffer) {
  try {
    if (!fs.existsSync(AVATAR_DIR)) fs.mkdirSync(AVATAR_DIR, { recursive: true });
    fs.writeFileSync(avatarPath(userId), buffer);
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
    currentSession: null,
    verifyCodes: [],
    defaultAccountsInitialized: true,
    healthSnapshots: {},
  };
}

let store = seedStore();
let persistEnabled = true;

function setPersistEnabled(enabled) {
  persistEnabled = enabled;
}

function resetStore() {
  store = seedStore();
  return store;
}

function loadFromDisk() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const raw = fs.readFileSync(DATA_FILE, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.accounts)) {
        store = { ...seedStore(), ...parsed, healthSnapshots: parsed.healthSnapshots || {} };
        return true;
      }
    }
  } catch (e) {
    // 损坏或缺失时回退种子
  }
  return false;
}

function persist() {
  if (!persistEnabled) return true;
  try {
    if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
    fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2), 'utf8');
    return true;
  } catch (e) {
    return false;
  }
}

function findAccountByAccount(account) {
  const normalized = account.trim();
  return store.accounts.find((a) => a.account.toLowerCase() === normalized.toLowerCase());
}

function findAccountByUserId(userId) {
  return store.accounts.find((a) => a.userId === userId);
}

function addAccount(account) {
  store.accounts.push(account);
  return persist();
}

function updateAccount(userId, patch) {
  const idx = store.accounts.findIndex((a) => a.userId === userId);
  if (idx < 0) return false;
  store.accounts[idx] = { ...store.accounts[idx], ...patch };
  return persist();
}

function deleteAccount(userId) {
  store.accounts = store.accounts.filter((a) => a.userId !== userId);
  if (store.currentSession && store.currentSession.userId === userId) {
    store.currentSession = null;
  }
  store.verifyCodes = store.verifyCodes.filter((c) => c.account !== userId);
  delete store.healthSnapshots[userId];
  deleteAvatar(userId);
  return persist();
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
  return persist();
}

function getSession() {
  const session = store.currentSession;
  if (!session) return null;
  return session;
}

function saveSession(session) {
  store.currentSession = session;
  return persist();
}

function clearSession() {
  store.currentSession = null;
  return persist();
}

function getHealthSnapshot(userId) {
  return store.healthSnapshots[userId] || null;
}

function allHealthSnapshots() {
  return Object.values(store.healthSnapshots);
}

function replaceAllHealthSnapshots(snapshots) {
  store.healthSnapshots = {};
  snapshots.forEach((snapshot) => {
    if (snapshot && snapshot.userId) store.healthSnapshots[snapshot.userId] = snapshot;
  });
  return persist();
}

function saveHealthSnapshot(snapshot) {
  store.healthSnapshots[snapshot.userId] = snapshot;
  return persist();
}

function deleteHealthSnapshot(userId) {
  delete store.healthSnapshots[userId];
  return persist();
}

module.exports = {
  DATA_FILE,
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
  resetStore,
  setPersistEnabled,
  configureDataFile,
  loadFromDisk,
  findAccountByAccount,
  findAccountByUserId,
  addAccount,
  updateAccount,
  deleteAccount,
  findVerifyCode,
  verifyCodesForAccount,
  saveVerifyCode,
  getSession,
  saveSession,
  clearSession,
  getHealthSnapshot,
  allHealthSnapshots,
  replaceAllHealthSnapshots,
  saveHealthSnapshot,
  deleteHealthSnapshot,
  saveAvatar,
  loadAvatar,
  deleteAvatar,
};
