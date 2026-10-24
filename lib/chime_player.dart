import 'dart:developer' as developer;

import 'package:audioplayers/audioplayers.dart';

/// ─────────────────────────────────────────────────────────────
///  Completion chimes.
///  • [playCycle]    – soft ding when a 3-minute cycle completes
///  • [playComplete] – warm ascending arpeggio when the session ends
///
///  Uses two dedicated low-latency players that are pre-loaded in
///  advance so the sound fires instantly on the tick. Every call is
///  fail-safe: audio problems must never crash the timer.
/// ─────────────────────────────────────────────────────────────
class ChimePlayer {
  AudioPlayer? _cycle;
  AudioPlayer? _complete;
  bool _ready = false;

  static const String _cycleAsset = 'sounds/cycle_chime.wav';
  static const String _completeAsset = 'sounds/complete_chime.wav';

  Future<void> preload() async {
    try {
      _cycle = AudioPlayer(playerId: 'noir_cycle_chime');
      _complete = AudioPlayer(playerId: 'noir_complete_chime');

      await _cycle!.setPlayerMode(PlayerMode.lowLatency);
      await _complete!.setPlayerMode(PlayerMode.lowLatency);
      await _cycle!.setReleaseMode(ReleaseMode.stop);
      await _complete!.setReleaseMode(ReleaseMode.stop);

      // Pre-decode both sources so the first play is latency-free.
      await _cycle!.setSource(AssetSource(_cycleAsset));
      await _complete!.setSource(AssetSource(_completeAsset));
      await _cycle!.stop();
      await _complete!.stop();

      _ready = true;
    } catch (e) {
      developer.log('Chime preload failed (audio disabled): $e',
          name: 'ChimePlayer');
      _ready = false;
    }
  }

  /// Soft ding — a cycle (180 s) just completed.
  Future<void> playCycle() => _fire(_cycle, _cycleAsset, 0.55);

  /// Bright arpeggio — the whole session just completed.
  Future<void> playComplete() => _fire(_complete, _completeAsset, 0.95);

  Future<void> _fire(AudioPlayer? player, String asset, double volume) async {
    if (!_ready || player == null) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } catch (e) {
      // Web autoplay policies / missing device etc. — stay silent.
      developer.log('Chime playback skipped: $e', name: 'ChimePlayer');
    }
  }

  void dispose() {
    try {
      _cycle?.dispose();
      _complete?.dispose();
    } catch (_) {}
    _cycle = null;
    _complete = null;
    _ready = false;
  }
}
