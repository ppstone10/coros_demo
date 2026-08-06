const { test, after } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const store = require('../src/store');

// 独立的临时数据根，绝不触碰运行时 data/ 目录
const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'mock-server-store-test-'));
after(() => {
  fs.rmSync(tmpRoot, { recursive: true, force: true });
});

function withTmpDir(dirName) {
  store.setDataRoot(tmpRoot);
  store.configureDataDir(dirName);
  store.resetStore();
  store.setPersistEnabled(true);
}

test('MSRV-020: 健康快照按 userId 独立文件落盘，账号库为单文件', () => {
  withTmpDir('layout-test');

  store.saveHealthSnapshot({ userId: 'u-1', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 });
  store.saveHealthSnapshot({ userId: 'u-2', scenario: 'ABNORMAL', enabledCardTypes: [], schemaVersion: 7 });
  store.saveSession({ userId: 'u-1', account: 'a@example.com', isValid: true, deviceId: 'dev-1' });

  const accountsPath = path.join(tmpRoot, 'layout-test', 'accounts.json');
  const health1 = path.join(tmpRoot, 'layout-test', 'health', 'u-1.json');
  const health2 = path.join(tmpRoot, 'layout-test', 'health', 'u-2.json');

  assert.ok(fs.existsSync(accountsPath), 'accounts.json 应落盘');
  assert.ok(fs.existsSync(health1), 'u-1 健康文件应落盘');
  assert.ok(fs.existsSync(health2), 'u-2 健康文件应落盘');

  const accounts = JSON.parse(fs.readFileSync(accountsPath, 'utf8'));
  assert.ok(Array.isArray(accounts.accounts));
  assert.strictEqual(accounts.sessions['u-1'].deviceId, 'dev-1');
});

test('MSRV-020: 健康文件缺失视为空快照，且可重新加载', () => {
  withTmpDir('layout-reload');

  store.saveHealthSnapshot({ userId: 'u-9', scenario: 'NORMAL', enabledCardTypes: ['RECOVERY'], schemaVersion: 7 });
  store.saveSession({ userId: 'u-9', account: 'u9@example.com', isValid: true, deviceId: 'dev-9' });

  // 模拟重启：重新加载
  store.loadFromDisk();
  const loaded = store.getHealthSnapshot('u-9');
  assert.ok(loaded, '重启后应从文件恢复健康快照');
  assert.deepStrictEqual(loaded.enabledCardTypes, ['RECOVERY']);
  assert.strictEqual(store.getHealthSnapshot('no-such-user'), null);
});

test('MSRV-020: 旧单文件启动时一次性迁移为新布局', () => {
  withTmpDir('migrate-test');

  // 构造旧版单文件 data/mock-server-store-migrate-test.json
  const legacyPath = path.join(tmpRoot, 'mock-server-store-migrate-test.json');
  const legacy = {
    accounts: [
      { userId: 'mock-user-default', account: '13107012029', passwordHash: 'mock:...:6', displayName: 'COROS User', region: 'CN', profile: null },
    ],
    currentSession: { userId: 'mock-user-default', account: '13107012029', displayName: 'COROS User', region: 'CN', isValid: true },
    verifyCodes: [{ account: '13107012029', code: '1234', expireAtEpochMs: Date.now() + 60000 }],
    defaultAccountsInitialized: true,
    healthSnapshots: {
      'mock-user-default': { userId: 'mock-user-default', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 },
    },
  };
  fs.writeFileSync(legacyPath, JSON.stringify(legacy), 'utf8');

  store.loadFromDisk();

  assert.strictEqual(fs.existsSync(legacyPath), false, '迁移后旧文件应删除');
  const accountsPath = path.join(tmpRoot, 'migrate-test', 'accounts.json');
  assert.ok(fs.existsSync(accountsPath), '迁移后应生成 accounts.json');
  const accounts = JSON.parse(fs.readFileSync(accountsPath, 'utf8'));
  assert.strictEqual(accounts.accounts.length, 1);
  assert.strictEqual(accounts.sessions['mock-user-default'].isValid, true);

  const healthPath = path.join(tmpRoot, 'migrate-test', 'health', 'mock-user-default.json');
  assert.ok(fs.existsSync(healthPath), '迁移后应生成健康文件');
  const migrated = store.getHealthSnapshot('mock-user-default');
  assert.strictEqual(migrated.scenario, 'NORMAL');
});

test('MSRV-021: 写操作走临时文件 + rename 原子替换，不留 .tmp 残留', () => {
  withTmpDir('atomic-test');

  store.saveHealthSnapshot({ userId: 'u-atomic', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 });
  store.saveHealthSnapshot({ userId: 'u-atomic', scenario: 'ABNORMAL', enabledCardTypes: ['RECOVERY'], schemaVersion: 7 });
  store.saveSession({ userId: 'u-atomic', account: 'u@example.com', isValid: true, deviceId: 'dev' });

  const healthPath = path.join(tmpRoot, 'atomic-test', 'health', 'u-atomic.json');
  const accountsPath = path.join(tmpRoot, 'atomic-test', 'accounts.json');

  // 覆盖写之后目标文件是完整 JSON，且目录下无 .tmp 残留
  const health = JSON.parse(fs.readFileSync(healthPath, 'utf8'));
  assert.strictEqual(health.scenario, 'ABNORMAL');
  assert.deepStrictEqual(health.enabledCardTypes, ['RECOVERY']);

  const accounts = JSON.parse(fs.readFileSync(accountsPath, 'utf8'));
  assert.strictEqual(accounts.sessions['u-atomic'].isValid, true);

  const leftover = fs.readdirSync(path.dirname(healthPath)).filter((f) => f.endsWith('.tmp'));
  assert.deepStrictEqual(leftover, []);
  const leftoverAccounts = fs.readdirSync(path.dirname(accountsPath)).filter((f) => f.endsWith('.tmp'));
  assert.deepStrictEqual(leftoverAccounts, []);
});

test('MSRV-021: 注销账号级联删除健康文件与会话', () => {
  withTmpDir('cascade-test');

  store.saveHealthSnapshot({ userId: 'u-del', scenario: 'NORMAL', enabledCardTypes: [], schemaVersion: 7 });
  store.saveSession({ userId: 'u-del', account: 'del@example.com', isValid: true, deviceId: 'dev' });
  assert.ok(store.deleteAccount('u-del'));

  const healthPath = path.join(tmpRoot, 'cascade-test', 'health', 'u-del.json');
  assert.strictEqual(fs.existsSync(healthPath), false, '注销后健康文件应删除');
  assert.strictEqual(store.getSession('u-del'), null);
});
