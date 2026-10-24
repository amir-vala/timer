import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────
///  Haptics that degrade gracefully.
///
///  `HapticFeedback` only has a platform implementation on Android
///  and iOS. The Windows (and Linux/macOS) embedders do not handle
///  `HapticFeedback.vibrate`, so calling it there raises an
///  unhandled MissingPluginException in the console on every tap.
///  Everything goes through this guard instead.
/// ─────────────────────────────────────────────────────────────
class Haptics {
  Haptics._();

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static void light() {
    if (_supported) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_supported) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_supported) HapticFeedback.heavyImpact();
  }
}
