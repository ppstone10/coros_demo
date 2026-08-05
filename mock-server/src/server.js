const { createApp, resetStore } = require('./app');
const store = require('./store');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// 按端口隔离数据文件：每个端口实例读写各自的持久化文件，避免多实例互相覆盖。
const dataFileName = process.env.DATA_FILE || `mock-server-store-${PORT}.json`;
store.configureDataFile(dataFileName);

store.loadFromDisk();

const app = createApp();
app.listen(PORT, HOST, () => {
  console.log(`[mock-server] listening on http://${HOST}:${PORT}`);
  console.log(`[mock-server] data file: ${dataFileName}`);
  console.log(`[mock-server] seed accounts: ${store.DEFAULT_ACCOUNT} / ${store.DEFAULT_PASSWORD}`);
});
