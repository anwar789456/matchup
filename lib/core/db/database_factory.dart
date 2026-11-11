// The sqflite factory for the platform: the plugin on Android/iOS, SQLite compiled to
// WebAssembly (web/sqlite3.wasm + web/sqflite_sw.js, stored in IndexedDB) in the browser.
export 'database_factory_native.dart' if (dart.library.js_interop) 'database_factory_web.dart';
