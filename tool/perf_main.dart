// [PERF-PROBE] Instrumented entrypoint: same app + a metrics probe.
// Build with:  flutter build windows --release -t tool/perf_main.dart
//
// Set NOIR_AUTOSTART=1 to have the harness tap the play key for you, so a
// measurement run never needs the window to be focused (or even visible).
import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_timer/main.dart';
import 'package:my_timer/perf_probe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PerfProbe.install();
  runApp(const TimerApp());
  if (Platform.environment['NOIR_AUTOSTART'] == '1') {
    Timer(const Duration(seconds: 2), _tapPlay);
  }
}

/// Synthesises a tap on the play key through the gesture pipeline.
void _tapPlay() {
  final Element? icon = _findIcon(
    WidgetsBinding.instance.rootElement,
    Icons.play_arrow,
  );
  final RenderBox? box = icon?.renderObject as RenderBox?;
  if (box == null || !box.hasSize) return;
  final Offset center = box.localToGlobal(box.size.center(Offset.zero));
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(pointer: 1, position: center),
  );
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(pointer: 1, position: center),
  );
}

Element? _findIcon(Element? node, IconData icon) {
  if (node == null) return null;
  if (node.widget is Icon && (node.widget as Icon).icon == icon) return node;
  Element? found;
  node.visitChildren((Element child) {
    found ??= _findIcon(child, icon);
  });
  return found;
}
