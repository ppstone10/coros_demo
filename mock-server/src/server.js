const { createApp } = require('./app');
const store = require('./store');

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// 数据根目录可覆盖（默认 mock-server/data/）；按端口目录隔离（MSRV-020）。
if (process.env.DATA_DIR) {
  store.setDataRoot(process.env.DATA_DIR);
}
store.configureDataDir(PORT);

store.loadFromDisk();

const app = createApp();
app.listen(PORT, HOST, () => {
  console.log(`[mock-server] listening on http://${HOST}:${PORT}`);
  console.log(`[mock-server] data dir: ${store.DATA_DIR}`);
  console.log(`[mock-server] seed accounts: ${store.DEFAULT_ACCOUNT} / ${store.DEFAULT_PASSWORD}`);
});
