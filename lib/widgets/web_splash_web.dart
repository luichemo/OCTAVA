import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Fades out and removes `#splash` in web/index.html.
void removeWebSplash() {
  final splash = web.document.getElementById('splash');
  if (splash == null) return;
  splash.classList.add('gone');
  web.window.setTimeout((() => splash.remove()).toJS, 400.toJS);
}
