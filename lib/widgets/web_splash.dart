// Removing the web page's own splash (web/index.html) once the app is ready.
// Only the browser has one; elsewhere this does nothing.
export 'web_splash_stub.dart'
    if (dart.library.js_interop) 'web_splash_web.dart';
