import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Native desktop window chrome.
///
///  The Windows runner keeps its title bar in sync with the in-app
///  light/dark theme through a tiny `noir/window` method channel.
///  On web and on every other platform these calls are no-ops, so
///  the widget tests and the Chrome build keep working unchanged.
/// ─────────────────────────────────────────────────────────────
class WindowChrome {
  WindowChrome._();

  static const MethodChannel _channel = MethodChannel('noir/window');

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Repaints the native title bar for the given brightness.
  ///
  /// Fail-safe by design: a missing runner (tests, embedded use) must
  /// never take the timer down.
  static Future<void> setDark(bool isDark) async {
    if (!_isWindows) return;
    try {
      await _channel.invokeMethod<void>('setBrightness', isDark);
    } on MissingPluginException {
      // Running under `flutter test` or a runner without the channel.
    } catch (e) {
      debugPrint('Window chrome update skipped: $e');
    }
  }
}
