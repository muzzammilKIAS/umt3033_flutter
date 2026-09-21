import 'dart:js_interop';
import 'package:web/web.dart' as web;

String? sessionRead(String key) => web.window.sessionStorage.getItem(key);
void sessionWrite(String key, String value) =>
    web.window.sessionStorage.setItem(key, value);
Future<void> projectorFullscreen() async {
  if (web.document.fullscreenElement != null) {
    await web.document.exitFullscreen().toDart;
  } else {
    await web.document.documentElement!.requestFullscreen().toDart;
  }
}

void downloadCsv(String content) {
  final anchor = web.HTMLAnchorElement()
    ..href =
        'data:text/csv;charset=utf-8,${Uri.encodeComponent('\uFEFF$content')}'
    ..download = 'muamalat-class-results.csv';
  anchor.click();
}
