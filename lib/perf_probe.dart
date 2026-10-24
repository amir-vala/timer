// [PERF-PROBE] Temporary instrumentation for measuring UI cost.
// Not part of the shipped app. Delete together with tool/perf_main.dart,
// lib/perf_flags.dart and tool/perf/ once the optimisation work is done.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

class PerfProbe {
  static late final IOSink _out;
  static final List<int> _buildUs = <int>[];
  static final List<int> _rasterUs = <int>[];
  static int _frames = 0;
  static int _timingFrames = 0;
  static int _jankFrames = 0;
  static int _windowStartFrames = 0;

  static void install() {
    final String path = Platform.environment['PERF_OUT'] ?? 'perf_probe.jsonl';
    final File f = File(path);
    f.parent.createSync(recursive: true);
    _out = f.openWrite(mode: FileMode.append);

    final ui.FlutterView view = ui.PlatformDispatcher.instance.views.first;
    _emit(<String, Object?>{
      't': 'start',
      'pid': pid,
      'variant': Platform.environment['NOIR_PERF'] ?? 'baseline',
      'physical': <double>[view.physicalSize.width, view.physicalSize.height],
      'dpr': view.devicePixelRatio,
    });

    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      _frames++;
    });

    SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final FrameTiming t in timings) {
        _timingFrames++;
        _buildUs.add(t.buildDuration.inMicroseconds);
        _rasterUs.add(t.rasterDuration.inMicroseconds);
        if (t.totalSpan.inMicroseconds > 16667) _jankFrames++;
      }
    });

    Timer.periodic(const Duration(seconds: 1), (_) => _report());
  }

  static void _report() {
    final int frames = _frames - _windowStartFrames;
    _windowStartFrames = _frames;
    _emit(<String, Object?>{
      't': 'sec',
      'fps': frames,
      'build_avg_ms': _avgMs(_buildUs),
      'build_p95_ms': _p95Ms(_buildUs),
      'raster_avg_ms': _avgMs(_rasterUs),
      'raster_p95_ms': _p95Ms(_rasterUs),
      'timed': _timingFrames,
      'jank': _jankFrames,
      'rss_mb': (ProcessInfo.currentRss / (1024 * 1024)).round(),
    });
    _buildUs.clear();
    _rasterUs.clear();
    _timingFrames = 0;
    _jankFrames = 0;
  }

  static double _avgMs(List<int> us) {
    if (us.isEmpty) return 0;
    int sum = 0;
    for (final int v in us) {
      sum += v;
    }
    return sum / us.length / 1000.0;
  }

  static double _p95Ms(List<int> us) {
    if (us.isEmpty) return 0;
    final List<int> sorted = List<int>.of(us)..sort();
    final int idx = (sorted.length * 0.95).floor().clamp(0, sorted.length - 1);
    return sorted[idx] / 1000.0;
  }

  static void _emit(Map<String, Object?> json) {
    _out.writeln(jsonEncode(json));
  }
}
