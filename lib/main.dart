import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chime_player.dart';
import 'haptics.dart';
import 'noir_palette.dart';
import 'rolling_time.dart';
import 'window_chrome.dart';

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, curly_braces_in_flow_control_structures, library_private_types_in_public_api, use_super_parameters

void main() {
  runApp(const TimerApp());
}

class TimerApp extends StatefulWidget {
  const TimerApp({super.key});

  @override
  State<TimerApp> createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    // Match the Windows title bar to the starting (dark) theme.
    WindowChrome.setDark(true);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    WindowChrome.setDark(_themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NoirPalette.dark.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8E6FF),
          brightness: Brightness.dark,
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: NoirPalette.light.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3D6E99),
          brightness: Brightness.light,
        ),
      ),
      home: TimerScreen(
        toggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class TimerScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  const TimerScreen({
    super.key,
    required this.toggleTheme,
    required this.isDark,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin {
  Timer? _timer;

  int _totalSeconds = 300;
  int _remainingSeconds = 300;
  bool _isRunning = false;

  final int _cycleTotalSeconds = 180;
  int _cycleRemainingSeconds = 180;
  int _completedCycleCount = 0;
  bool _isCycleEnabled = true;

  bool _focusMode = false;
  bool _sessionComplete = false;

  // NOIR CHROME additions ──────────────────────────────────────
  late final ChimePlayer _chimes = ChimePlayer();

  /// Fires every time a 3-minute cycle completes → card pulse.
  late final AnimationController _cyclePulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _chimes.preload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cyclePulse.dispose();
    _chimes.dispose();
    super.dispose();
  }

  // ── engine ──────────────────────────────────────────────────

  void _startTimer() {
    if (_remainingSeconds == 0) return;
    setState(() {
      _isRunning = true;
      _sessionComplete = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }

        if (_isCycleEnabled) {
          if (_cycleRemainingSeconds > 0) {
            _cycleRemainingSeconds--;
          }
          if (_cycleRemainingSeconds == 0) {
            _completedCycleCount++;
            _cycleRemainingSeconds = _cycleTotalSeconds;
            Haptics.heavy();
            _cyclePulse.forward(from: 0);
            _chimes.playCycle(); // ← cycle chime
          }
        }

        if (_remainingSeconds == 0) {
          _isRunning = false;
          _sessionComplete = true;
          timer.cancel();
          Haptics.heavy();
          _chimes.playComplete(); // ← completion chime
        }
      });
    });
  }

  void _stopTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _cycleRemainingSeconds = _cycleTotalSeconds;
      _completedCycleCount = 0;
      _sessionComplete = false;
    });
    Haptics.medium();
  }

  void _updateDuration(int seconds) {
    if (_isRunning) return;
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _cycleRemainingSeconds = _cycleTotalSeconds;
      _completedCycleCount = 0;
      _sessionComplete = false;
    });
    Haptics.light();
  }

  void _toggleCycle() {
    setState(() {
      _isCycleEnabled = !_isCycleEnabled;
      if (!_isCycleEnabled) {
        _cycleRemainingSeconds = _cycleTotalSeconds;
      }
    });
    Haptics.light();
  }

  void _toggleFocus() {
    setState(() => _focusMode = !_focusMode);
    Haptics.light();
  }

  void _toggleRun() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  // ── helpers ─────────────────────────────────────────────────

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _hud(Widget child) {
    return AnimatedOpacity(
      opacity: _focusMode ? 0 : 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(ignoring: _focusMode, child: child),
    );
  }

  // ── build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = widget.isDark ? NoirPalette.dark : NoirPalette.light;
    final bool compact = MediaQuery.of(context).size.width < 680;

    return Scaffold(
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.space,
              includeRepeats: false): _toggleRun,
          const SingleActivator(LogicalKeyboardKey.keyR): _resetTimer,
          const SingleActivator(LogicalKeyboardKey.keyC): _toggleCycle,
          const SingleActivator(LogicalKeyboardKey.keyF): _toggleFocus,
          const SingleActivator(LogicalKeyboardKey.keyT): _openCustomTimerModal,
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_focusMode) _toggleFocus();
          },
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focusMode ? () => setState(() => _focusMode = false) : null,
            child: Stack(
              children: [
                // liquid-chrome stage
                Positioned.fill(
                  child: _ChromeStage(palette: p, running: _isRunning),
                ),

                // top bar — logo / status / theme
                Positioned(
                  top: 18,
                  left: 24,
                  right: 24,
                  child: _hud(
                    Row(
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'NOIR',
                            style: _capStyle(p, 12, p.ink),
                            children: [
                              TextSpan(
                                text: '/CHROME',
                                style: _capStyle(p, 12, p.inkDim),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        RepaintBoundary(
                          child: _StatusBadge(
                            running: _isRunning,
                            done: _sessionComplete,
                            palette: p,
                          ),
                        ),
                        const SizedBox(width: 12),
                        RepaintBoundary(
                          child: _MiniGlassButton(
                            onTap: widget.toggleTheme,
                            icon: widget.isDark
                                ? Icons.light_mode
                                : Icons.dark_mode,
                            palette: p,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // center column — no scrolling: the HUD is scaled down just
                // enough that every element stays on screen at any window size
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: compact ? 360 : 520,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildClockArea(p),
                              const SizedBox(height: 40),
                              _hud(
                                _MercuryTimeline(
                                  progress: _totalSeconds == 0
                                      ? 0
                                      : (1 - _remainingSeconds / _totalSeconds)
                                          .clamp(0.0, 1.0),
                                  elapsedLabel: _formatTime(math.max(
                                      0, _totalSeconds - _remainingSeconds)),
                                  totalLabel: _formatTime(_totalSeconds),
                                  running: _isRunning,
                                  compact: compact,
                                  palette: p,
                                ),
                              ),
                              const SizedBox(height: 26),
                              _hud(
                                _buildMidRow(p, compact),
                              ),
                              const SizedBox(height: 30),
                              _hud(
                                _DockTray(
                                  running: _isRunning,
                                  cycleOn: _isCycleEnabled,
                                  compact: compact,
                                  palette: p,
                                  onPlay: _toggleRun,
                                  onReset: _resetTimer,
                                  onCycle: _toggleCycle,
                                  onTune: _openCustomTimerModal,
                                  onFocus: _toggleFocus,
                                ),
                              ),
                              const SizedBox(height: 30),
                              _hud(_buildChips(p, compact)),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // focus-mode hint
                if (_focusMode)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 24,
                    child: Center(
                      child: Text(
                        'TAP ANYWHERE TO EXIT FOCUS',
                        style: _capStyle(p, 10, p.inkFaint),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Small uppercase caption style used across the UI.
  TextStyle _capStyle(NoirPalette p, double size, Color color,
      {double spacing = 4}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w700,
      fontFamily: NoirPalette.font,
      letterSpacing: spacing,
      color: color,
    );
  }

  // ── clock ───────────────────────────────────────────────────

  Widget _buildClockArea(NoirPalette p) {
    final Size screen = MediaQuery.of(context).size;
    final bool compact = screen.width < 680;
    final double vmin = math.min(screen.width, screen.height) / 100;
    // prototype: clamp(84px, 18.5vmin, 220px)
    final double clockSize = compact ? 64 : (vmin * 18.5).clamp(88.0, 220.0);
    // The clock repaints while digits roll; keep that inside its own layer so
    // the glass panels behind it are not re-rasterised every frame.
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _CompletionRipple(trigger: _sessionComplete, color: p.accent),
          RollingTime(
            seconds: _remainingSeconds,
            fontSize: clockSize,
            color: p.ink,
            showHours: _totalSeconds >= 3600,
            rollDuration: const Duration(milliseconds: 180),
            weight: FontWeight.w300,
            fontFamily: NoirPalette.font,
            metallic: true,
          ),
        ],
      ),
    );
  }

  // ── cycle card + log rail ───────────────────────────────────

  Widget _buildMidRow(NoirPalette p, bool compact) {
    final List<Widget> items = [
      // Each slab keeps its blurred shadow in its own layer, so a ticking
      // counter never drags the rest of the screen into the raster pass.
      RepaintBoundary(
        child: _CycleCard(
          cycleRemaining: _cycleRemainingSeconds,
          completed: _completedCycleCount,
          enabled: _isCycleEnabled,
          pulse: _cyclePulse.view,
          compact: compact,
          palette: p,
        ),
      ),
      RepaintBoundary(
        child: _CycleRail(
          completed: _completedCycleCount,
          compact: compact,
          palette: p,
        ),
      ),
    ];

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          items[0],
          const SizedBox(height: 12),
          items[1],
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        items[0],
        const SizedBox(width: 14),
        items[1],
      ],
    );
  }

  // ── preset chips ────────────────────────────────────────────

  Widget _buildChips(NoirPalette p, bool compact) {
    const List<MapEntry<String, int>> presets = [
      MapEntry('25 MIN', 1500),
      MapEntry('45 MIN', 2700),
      MapEntry('60 MIN', 3600),
      MapEntry('90 MIN', 5400),
    ];
    // One layer for the whole row: this machine composites every layer on
    // every frame, so fewer, larger layers are cheaper than many small ones.
    return RepaintBoundary(
      child: Wrap(
        spacing: compact ? 18 : 34,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: [
          for (final MapEntry<String, int> e in presets)
            _PresetChip(
              label: e.key,
              seconds: e.value,
              selected: _totalSeconds == e.value,
              onTap: () => _updateDuration(e.value),
              palette: p,
            ),
        ],
      ),
    );
  }

  // ── custom duration sheet ───────────────────────────────────

  void _openCustomTimerModal() {
    int customHours = _totalSeconds ~/ 3600;
    int customMinutes = (_totalSeconds % 3600) ~/ 60;
    int customSeconds = _totalSeconds % 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: widget.isDark
          ? Colors.black.withAlpha(153)
          : Colors.black.withAlpha(77),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final NoirPalette p =
                widget.isDark ? NoirPalette.dark : NoirPalette.light;
            final int previewTotal =
                customHours * 3600 + customMinutes * 60 + customSeconds;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.isDark
                          ? const Color(0xF2101013)
                          : const Color(0xF5F3F4F7),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                      border: Border(
                        top: BorderSide(color: p.glassBorder, width: 1),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: 26,
                      left: 34,
                      right: 34,
                      bottom: 30 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 22),
                          decoration: BoxDecoration(
                            color: p.ink.soft(0.18),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'SET CUSTOM TIMER',
                          style: _capStyle(p, 15, p.ink, spacing: 2),
                        ),
                        const SizedBox(height: 26),
                        _buildSheetSlider(p, 'HOURS', customHours, 'hr', 0, 3,
                            (v) => setModalState(() => customHours = v)),
                        _buildSheetSlider(p, 'MINUTES', customMinutes, 'min', 0,
                            59, (v) => setModalState(() => customMinutes = v)),
                        _buildSheetSlider(p, 'SECONDS', customSeconds, 'sec', 0,
                            59, (v) => setModalState(() => customSeconds = v)),
                        const SizedBox(height: 20),
                        // preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: p.ink.soft(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: p.glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: RollingTime(
                            seconds: previewTotal,
                            fontSize: 32,
                            color: p.ink,
                            showHours: previewTotal >= 3600,
                            weight: FontWeight.w300,
                            fontFamily: NoirPalette.font,
                            metallic: true,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _PressScale(
                          onTap: () {
                            if (_isRunning) return; // original guard
                            if (previewTotal > 0) {
                              _updateDuration(previewTotal);
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: p.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'APPLY',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: NoirPalette.font,
                                letterSpacing: 2.4,
                                color: p.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetSlider(NoirPalette p, String label, int value, String unit,
      int min, int max, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: _capStyle(p, 11, p.inkDim, spacing: 3)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.ink.soft(0.30))),
              ),
              child: Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: NoirPalette.font,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            activeTrackColor: p.ink,
            inactiveTrackColor: p.ink.soft(0.12),
            thumbColor: p.ink,
            overlayColor: p.ink.soft(0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  MERCURY TIMELINE — glass track, light-metal fill, shimmer.
//  Port of the prototype's .line / .mercury / .fill recipe.
// ============================================================

class _MercuryTimeline extends StatelessWidget {
  final double progress; // 0..1 elapsed
  final String elapsedLabel;
  final String totalLabel;
  final bool running;
  final bool compact;
  final NoirPalette palette;

  const _MercuryTimeline({
    required this.progress,
    required this.elapsedLabel,
    required this.totalLabel,
    required this.running,
    required this.compact,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = math.min(constraints.maxWidth, 460);
        return SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    Text(elapsedLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: NoirPalette.font,
                          letterSpacing: 3,
                          color: p.inkFaint,
                        )),
                    Expanded(
                      child: Text(
                        'ELAPSED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: NoirPalette.font,
                          letterSpacing: 3.5,
                          color: p.inkFaint,
                        ),
                      ),
                    ),
                    Text(totalLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: NoirPalette.font,
                          letterSpacing: 3,
                          color: p.inkFaint,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // The fill advances 1–2 px per second, so a 60 fps width tween
              // bought no visible smoothness — it just kept the raster thread
              // busy for the whole session. Draw the value directly.
              _MercuryTrack(
                fill: progress,
                running: running,
                compact: compact,
                palette: p,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MercuryTrack extends StatefulWidget {
  final double fill;
  final bool running;
  final bool compact;
  final NoirPalette palette;

  const _MercuryTrack({
    required this.fill,
    required this.running,
    required this.compact,
    required this.palette,
  });

  @override
  State<_MercuryTrack> createState() => _MercuryTrackState();
}

class _MercuryTrackState extends State<_MercuryTrack> {
  /// The bar is the only thing that animates for a whole session, and on this
  /// hardware a frame costs ~10 ms of raster no matter how little moved — so
  /// the cadence *is* the budget knob. 30 fps reads as smooth for a diffuse
  /// highlight band while costing half of what vsync would.
  static const int _frameMs = 83;
  static const Duration _frameInterval = Duration(milliseconds: _frameMs);
  static const double _shimmerPeriodMs = 12000;

  /// Position of the highlight band, 0 → 1.
  final _TrackGlow _glow = _TrackGlow();
  final _TrackPaints _paints = _TrackPaints();

  /// Repaint driver: bumping this repaints the bar without rebuilding widgets.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _glow.fill = widget.fill;
    _sync();
  }

  @override
  void didUpdateWidget(covariant _MercuryTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  bool get _settled => (widget.fill - _glow.fill).abs() <= 0.0004;

  void _sync() {
    if (widget.running || !_settled) {
      _timer ??= Timer.periodic(_frameInterval, (_) => _tick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _tick() {
    if (!mounted) return;
    _glow.phase = (_glow.phase + _frameMs / _shimmerPeriodMs) % 1.0;
    final double delta = widget.fill - _glow.fill;
    _glow.fill =
        delta.abs() <= 0.0004 ? widget.fill : _glow.fill + delta * 0.16;
    _frame.value++;
    if (!widget.running && _settled) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = widget.palette;

    return RepaintBoundary(
      child: Container(
        height: widget.compact ? 46 : 64,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          gradient: p.glassGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.soft(p.isDark ? 0.45 : 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
              spreadRadius: -12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          // Only the liquid itself animates, and it lives in its own layer so
          // neither the glass nor its shadow is re-rasterised while it moves.
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _MercuryPainter(
                glow: _glow,
                paints: _paints,
                running: widget.running,
                palette: p,
                repaint: _frame,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mutable animation state of the mercury bar.
///
/// It lives outside the widget tree so a 30 Hz tick repaints the bar without
/// rebuilding widgets: [ChangeNotifier] drives the painter directly.
class _TrackGlow {
  /// Highlight band position, 0 → 1.
  double phase = 0;

  /// Smoothed copy of the target fill. The target only moves once a second —
  /// often by a single pixel — so gliding to it turns a visible step into
  /// continuous motion for free.
  double fill = 0;
}

/// Paints and shaders for the bar, rebuilt only when its size or palette
/// changes. Recreating these every frame made Skia build a new gradient
/// shader per frame, which dominated the cost of the whole bar.
class _TrackPaints {
  Size size = Size.zero;
  NoirPalette? palette;

  double bodyWidth = -1;

  final Paint bed = Paint();
  final Paint body = Paint();
  final Paint hairline = Paint();
  final Paint band = Paint();
  final Paint meniscusSoft = Paint();
  final Paint meniscusMid = Paint();
  final Paint meniscusCore = Paint();

  void ensure(Size size, NoirPalette p) {
    if (size == this.size && p == palette) return;
    this.size = size;
    palette = p;
    bodyWidth = -1;

    bed.color = p.isDark ? Colors.white.soft(0.04) : Colors.black.soft(0.06);

    hairline.color =
        p.isDark ? Colors.white.soft(0.50) : Colors.white.soft(0.85);

    band.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 0.5, 1.0],
      colors: [
        Colors.white.soft(0.0),
        Colors.white.soft(0.28),
        Colors.white.soft(0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width * 0.45, size.height));

    meniscusSoft.color = Colors.white.soft(0.08);
    meniscusMid.color = Colors.white.soft(0.22);
    meniscusCore.color = Colors.white.soft(0.95);
  }

  /// The fill grows by ~1 px a second, so its gradient only needs rebuilding
  /// when the width actually moves — not on every frame.
  void ensureBody(double width, Size size, NoirPalette p) {
    if ((width - bodyWidth).abs() < 0.75 && p == palette) return;
    bodyWidth = width;
    body.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        p.isDark ? Colors.white.soft(0.16) : Colors.black.soft(0.10),
        p.accent.soft(p.isDark ? 0.42 : 0.34),
      ],
    ).createShader(Rect.fromLTWH(0, 0, width, size.height));
  }
}

class _MercuryPainter extends CustomPainter {
  _MercuryPainter({
    required this.glow,
    required this.paints,
    required this.running,
    required this.palette,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final _TrackGlow glow;
  final _TrackPaints paints;
  final bool running;
  final NoirPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    paints.ensure(size, palette);
    final RRect track =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14));

    // dark bed behind the liquid
    canvas.drawRRect(track, paints.bed);

    final double w = size.width * glow.fill.clamp(0.0, 1.0);
    if (w <= 0.5) return;

    canvas.save();

    // liquid body — white → ice, like the prototype .fill
    paints.ensureBody(w, size, palette);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, size.height), paints.body);

    // specular hairline along the top of the liquid
    canvas.drawRect(Rect.fromLTWH(0, 1, w, 1), paints.hairline);

    // travelling shimmer band (screen-lit highlight)
    final double band = size.width * 0.45;
    final double x = -band + (size.width + 2 * band) * glow.phase;
    canvas.save();
    canvas.translate(x, 0);
    canvas.drawRect(Rect.fromLTWH(0, 0, band, size.height), paints.band);
    canvas.restore();

    canvas.restore();

    // meniscus — glowing leading edge while running
    if (running) {
      final Offset m = Offset(w, size.height / 2);
      canvas.drawCircle(m, 11, paints.meniscusSoft);
      canvas.drawCircle(m, 6.5, paints.meniscusMid);
      canvas.drawCircle(m, 2.6, paints.meniscusCore);
    }
  }

  @override
  bool shouldRepaint(covariant _MercuryPainter oldDelegate) =>
      oldDelegate.running != running || oldDelegate.palette != palette;
}

// ============================================================
//  CYCLE CARD — glass slab with label, rolling time and count.
//  Pulses (scale + glow) each time a cycle completes.
// ============================================================

class _CycleCard extends StatelessWidget {
  final int cycleRemaining;
  final int completed;
  final bool enabled;
  final Animation<double> pulse;
  final bool compact;
  final NoirPalette palette;

  const _CycleCard({
    required this.cycleRemaining,
    required this.completed,
    required this.enabled,
    required this.pulse,
    required this.compact,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = palette;

    Widget card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 24 : 28,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: p.glassGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.soft(p.isDark ? 0.35 : 0.08),
            blurRadius: 34,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CYCLE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: NoirPalette.font,
                  letterSpacing: 4.2,
                  color: p.inkDim,
                ),
              ),
              const SizedBox(height: 8),
              RollingTime(
                seconds: cycleRemaining,
                fontSize: compact ? 20 : 24,
                color: enabled ? p.ink : p.inkFaint,
                weight: FontWeight.w500,
                fontFamily: NoirPalette.font,
                rollDuration: const Duration(milliseconds: 180),
              ),
            ],
          ),
          const SizedBox(width: 22),
          Container(width: 1, height: 36, color: p.glassBorder),
          const SizedBox(width: 22),
          Text(
            '$completed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: NoirPalette.font,
              color: p.ink,
            ),
          ),
        ],
      ),
    );

    card = AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: enabled ? 1.0 : 0.35,
      child: card,
    );

    // completion pulse: quick pop that settles with a springy curve
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final double v = Curves.easeOutBack.transform(pulse.value);
        final double scale = 1 + 0.05 * (1 - v);
        return Transform.scale(scale: scale, child: child);
      },
      child: card,
    );
  }
}

// ============================================================
//  LOG RAIL — vertical strip of dots, one per completed cycle.
//  Newest dot sits at the bottom and pops when lit.
// ============================================================

class _CycleRail extends StatelessWidget {
  final int completed;
  final bool compact;
  final NoirPalette palette;

  const _CycleRail({
    required this.completed,
    required this.compact,
    required this.palette,
  });

  static const int _maxDots = 6;

  Widget _dot(int litCount, int index, NoirPalette p) {
    final bool lit = index < math.min(litCount, _maxDots);
    final Color dotBase = p.isDark ? Colors.white : p.ink;
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('dot-$index-$lit'),
      tween: Tween<double>(begin: lit ? 0.3 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: lit ? dotBase : dotBase.soft(0.14),
          boxShadow: lit
              ? [
                  BoxShadow(
                    color: dotBase.soft(p.isDark ? 0.65 : 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  Widget _label(NoirPalette p) => Text(
        'LOG',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: NoirPalette.font,
          letterSpacing: 4.2,
          color: p.inkDim,
        ),
      );

  Widget _count(NoirPalette p, {double size = 14}) => Text(
        '$completed/∞',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          fontFamily: NoirPalette.font,
          fontFamilyFallback: const ['Roboto'],
          color: p.inkDim,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = palette;

    final List<Widget> dots = <Widget>[];
    for (int i = _maxDots - 1; i >= 0; i--) {
      dots.add(_dot(completed, i, p));
      if (i != 0) dots.add(const SizedBox(height: 8));
    }
    final Widget dotsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots,
    );

    final List<Widget> dotsRow = <Widget>[];
    for (int i = _maxDots - 1; i >= 0; i--) {
      dotsRow.add(_dot(completed, i, p));
      if (i != 0) dotsRow.add(const SizedBox(width: 8));
    }

    final Widget box = Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: p.glassGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.soft(p.isDark ? 0.35 : 0.08),
            blurRadius: 34,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
      ),
      child: compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _label(p),
                const SizedBox(width: 16),
                Row(mainAxisSize: MainAxisSize.min, children: dotsRow),
                const SizedBox(width: 16),
                _count(p),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotatedBox(quarterTurns: -1, child: _label(p)),
                const SizedBox(width: 16),
                dotsColumn,
                const SizedBox(width: 16),
                _count(p, size: 20),
              ],
            ),
    );

    return box;
  }
}

// ============================================================
//  DOCK TRAY — frosted tray with five chrome keys.
//  Hover: lift + brighten. Press: settle. Primary: white chrome.
// ============================================================

class _DockTray extends StatelessWidget {
  final bool running;
  final bool cycleOn;
  final bool compact;
  final NoirPalette palette;
  final VoidCallback onPlay;
  final VoidCallback onReset;
  final VoidCallback onCycle;
  final VoidCallback onTune;
  final VoidCallback onFocus;

  const _DockTray({
    required this.running,
    required this.cycleOn,
    required this.compact,
    required this.palette,
    required this.onPlay,
    required this.onReset,
    required this.onCycle,
    required this.onTune,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        gradient: p.glassGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.soft(p.isDark ? 0.50 : 0.10),
            blurRadius: 46,
            offset: const Offset(0, 22),
            spreadRadius: -12,
          ),
        ],
      ),
      child: RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DockButton(
              onTap: onPlay,
              palette: p,
              primary: true,
              size: compact ? 56 : 64,
              icon: running ? Icons.pause : Icons.play_arrow,
            ),
            const SizedBox(width: 12),
            _DockButton(
              onTap: onReset,
              palette: p,
              size: compact ? 46 : 54,
              icon: Icons.restart_alt,
            ),
            const SizedBox(width: 12),
            _DockButton(
              onTap: onCycle,
              palette: p,
              size: compact ? 46 : 54,
              icon: Icons.loop,
              indicatorOn: cycleOn,
            ),
            const SizedBox(width: 12),
            _DockButton(
              onTap: onTune,
              palette: p,
              size: compact ? 46 : 54,
              icon: Icons.tune,
            ),
            const SizedBox(width: 12),
            _DockButton(
              onTap: onFocus,
              palette: p,
              size: compact ? 46 : 54,
              icon: Icons.center_focus_strong,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single dock key with the macOS-style lift interaction.
class _DockButton extends StatefulWidget {
  final VoidCallback onTap;
  final NoirPalette palette;
  final IconData icon;
  final bool primary;
  final bool indicatorOn;
  final double size;

  const _DockButton({
    required this.onTap,
    required this.palette,
    required this.icon,
    this.primary = false,
    this.indicatorOn = false,
    required this.size,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = widget.palette;
    final bool primary = widget.primary;

    final Color iconColor = primary ? p.onPrimary : (_hover ? p.ink : p.inkDim);

    final Offset lift = _pressed
        ? const Offset(0, -2)
        : (_hover ? const Offset(0, -6) : Offset.zero);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset.zero, end: lift),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) =>
              Transform.translate(offset: offset, child: child),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : (_hover ? 1.06 : 1.0),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: primary
                    ? p.primaryGradient
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.soft(_hover ? 0.12 : 0.07),
                          Colors.white.soft(_hover ? 0.05 : 0.015),
                        ],
                      ),
                border: primary
                    ? Border.all(color: Colors.white.soft(0.0), width: 1)
                    : Border.all(
                        color: Colors.white.soft(_hover ? 0.22 : 0.10),
                        width: 1,
                      ),
                boxShadow: [
                  if (_hover && !primary)
                    BoxShadow(
                      color: Colors.black.soft(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                      spreadRadius: -6,
                    ),
                  if (primary)
                    BoxShadow(
                      color: Colors.white.soft(_hover ? 0.30 : 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: -4,
                    ),
                  if (widget.indicatorOn && !primary)
                    BoxShadow(
                      color: Colors.white.soft(0.14),
                      blurRadius: 22,
                      spreadRadius: -6,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // inner top sheen (emulates inset highlight)
                  if (!primary)
                    Positioned(
                      top: 1,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 1,
                        color: Colors.white.soft(_hover ? 0.32 : 0.20),
                      ),
                    ),
                  // toggle indicator dot (cycle on/off)
                  if (!primary)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: AnimatedScale(
                        scale: widget.indicatorOn ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.soft(0.8),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(begin: iconColor, end: iconColor),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      builder: (context, color, _) => Icon(
                        widget.icon,
                        size: widget.size * (primary ? 0.42 : 0.40),
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  PRESET CHIP — text-only with a gradient underline when selected.
// ============================================================

class _PresetChip extends StatefulWidget {
  final String label;
  final int seconds;
  final bool selected;
  final VoidCallback onTap;
  final NoirPalette palette;

  const _PresetChip({
    required this.label,
    required this.seconds,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = widget.palette;
    final bool sel = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: NoirPalette.font,
                    letterSpacing: 3.4,
                    color:
                        sel ? p.ink : (_hover ? p.ink.soft(0.85) : p.inkFaint),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: sel
                        ? LinearGradient(
                            colors: [
                              Colors.white.soft(0.0),
                              Colors.white.soft(0.9),
                              Colors.white.soft(0.0),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.white.soft(0.0),
                              Colors.white.soft(0.0),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny press-feedback wrapper (scale 0.98) shared by tappable slabs.
class _PressScale extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _PressScale({required this.onTap, required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ============================================================
//  STATUS BADGE — blinking dot + label in the top bar.
// ============================================================

class _StatusBadge extends StatelessWidget {
  final bool running;
  final bool done;
  final NoirPalette palette;

  const _StatusBadge({
    required this.running,
    required this.done,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = palette;

    final String label = done ? 'COMPLETE' : (running ? 'RUNNING' : 'READY');
    final Color color = done ? p.done : (running ? p.accent : p.inkFaint);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey<String>(label),
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: color, blink: running && !done),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: NoirPalette.font,
              letterSpacing: 4.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool blink;

  const _PulsingDot({required this.color, required this.blink});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> {
  /// A 6 px dot breathing at vsync forced a full-window repaint every frame.
  /// ~8 updates a second is plenty for a dim glow, and the dot now lives in
  /// its own layer.
  static const Duration _interval = Duration(milliseconds: 300);
  static const double _periodMs = 1400;

  double _phase = 0.75;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.blink) {
      _timer ??= Timer.periodic(_interval, (_) {
        if (!mounted) return;
        setState(() {
          _phase = (_phase + _interval.inMilliseconds / _periodMs) % 1.0;
        });
      });
    } else {
      _timer?.cancel();
      _timer = null;
      _phase = 0.75;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double breath = widget.blink
        ? Curves.easeInOut.transform(0.5 - 0.5 * math.cos(_phase * 2 * math.pi))
        : 1.0;
    return RepaintBoundary(
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.soft(0.35 + 0.65 * breath),
          boxShadow: [
            BoxShadow(
              color: widget.color.soft(0.55 * breath),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  MINI GLASS BUTTON — theme toggle in the top bar.
// ============================================================

class _MiniGlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final NoirPalette palette;

  const _MiniGlassButton({
    required this.onTap,
    required this.icon,
    required this.palette,
  });

  @override
  State<_MiniGlassButton> createState() => _MiniGlassButtonState();
}

class _MiniGlassButtonState extends State<_MiniGlassButton> {
  static const double _size = 36;
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final NoirPalette p = widget.palette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : (_hover ? 1.08 : 1.0),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: p.glassGradient,
              border: Border.all(color: p.glassBorder, width: 1),
            ),
            child: Icon(
              widget.icon,
              size: _size * 0.44,
              color: _hover ? p.ink : p.inkDim,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  COMPLETION RIPPLE — one expanding chrome ring on completion.
// ============================================================

class _CompletionRipple extends StatefulWidget {
  final bool trigger;
  final Color color;

  const _CompletionRipple({required this.trigger, required this.color});

  @override
  State<_CompletionRipple> createState() => _CompletionRippleState();
}

class _CompletionRippleState extends State<_CompletionRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(covariant _CompletionRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
    if (!widget.trigger && oldWidget.trigger) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (!widget.trigger || _controller.value == 0) {
            return const SizedBox.shrink();
          }
          final double t = Curves.easeOutCubic.transform(_controller.value);
          final double scale = 1 + t * 3.2;
          final double opacity = (1 - t) * 0.40;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacitySafe(opacity),
                  width: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// extension alias so ripple code stays self-explanatory
extension _RippleColorX on Color {
  Color withOpacitySafe(double a) =>
      withAlpha((a.clamp(0.0, 1.0) * 255).round());
}

// ============================================================
//  CHROME STAGE — ambient background:
//  slow liquid-chrome light streaks + vignette + fine grain.
//  Streak softness is baked into layered gradients (no runtime
//  blur filters) so it stays cheap on every device.
// ============================================================

class _ChromeStage extends StatefulWidget {
  final NoirPalette palette;

  /// While a session runs the stage drifts slowly; otherwise it is a still
  /// image and costs nothing at all.
  final bool running;

  const _ChromeStage({required this.palette, required this.running});

  @override
  State<_ChromeStage> createState() => _ChromeStageState();
}

class _ChromeStageState extends State<_ChromeStage>
    with WidgetsBindingObserver {
  /// The three streaks sweep over 21–33 s. Re-rasterising that much gradient
  /// on every vsync measured ~100 ms per frame (7 fps) on integrated
  /// graphics, so the whole stage is baked into a texture and then only
  /// translated — a few pixels a second, at ~6 Hz.
  static const Duration _driftInterval = Duration(milliseconds: 400);

  /// Delay before re-baking while the window is being resized.
  static const Duration _bakeDelay = Duration(milliseconds: 140);

  /// The stage is baked slightly larger than the viewport so it can be drawn
  /// 1:1 (a plain blit) while the drift moves it.
  static const double _overscan = 20;

  ui.Image? _texture;
  Size _textureSize = Size.zero;
  NoirPalette? _texturePalette;
  bool _baking = false;
  Timer? _bakeTimer;

  /// Seconds of drift; only advances while the timer runs.
  double _clock = 0;
  Timer? _driftTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.running) _startDrift();
  }

  @override
  void didUpdateWidget(covariant _ChromeStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.running != widget.running) {
      if (widget.running) {
        _startDrift();
      } else {
        _stopDrift();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // save battery/GPU when the app is not visible
    if (state == AppLifecycleState.resumed) {
      if (widget.running) _startDrift();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _stopDrift();
    }
  }

  void _startDrift() {
    _driftTimer?.cancel();
    _driftTimer = Timer.periodic(_driftInterval, (_) {
      if (!mounted) return;
      setState(() {
        _clock += _driftInterval.inMilliseconds / 1000.0;
      });
    });
  }

  void _stopDrift() {
    _driftTimer?.cancel();
    _driftTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _driftTimer?.cancel();
    _bakeTimer?.cancel();
    _texture?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final NoirPalette p = widget.palette;
        final Size size = constraints.biggest;
        final double dpr = math.min(
          MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0,
          2.0,
        );
        _ensureTexture(size, p, dpr);
        final ui.Image? texture = _texture;
        if (texture == null) {
          // Before the texture exists, paint the cheap half of the stage
          // directly so the first frames are not a flat colour.
          return RepaintBoundary(
            child: CustomPaint(painter: _StaticStagePainter(palette: p)),
          );
        }

        // Barely-there drift with two periods so the motion never visibly
        // loops. Off entirely when the timer is idle.
        final double dx = math.sin(_clock * 2 * math.pi / 150) * 9;
        final double dy = math.cos(_clock * 2 * math.pi / 197) * 6;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _StageTexturePainter(image: texture),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  void _ensureTexture(Size size, NoirPalette p, double dpr) {
    if (size.isEmpty) return;
    if (size == _textureSize && p == _texturePalette) return;
    // Claim the request right away so the next build does not queue another.
    _textureSize = size;
    _texturePalette = p;
    _bakeTimer?.cancel();
    // First paint bakes right away; later ones wait for the window to settle.
    final Duration delay = _texture == null ? Duration.zero : _bakeDelay;
    _bakeTimer = Timer(delay, () {
      if (mounted) _startBake(dpr);
    });
  }

  void _startBake(double dpr) {
    if (_baking) return;
    final Size size = _textureSize;
    final NoirPalette? palette = _texturePalette;
    if (size.isEmpty || palette == null) return;
    _baking = true;
    _bake(size, palette, dpr).then((ui.Image image) {
      _baking = false;
      if (!mounted) {
        image.dispose();
        return;
      }
      final ui.Image? previous = _texture;
      setState(() => _texture = image);
      previous?.dispose();
      // A resize during the bake: schedule one more.
      if (_textureSize != size) {
        _bakeTimer?.cancel();
        _bakeTimer = Timer(_bakeDelay, () {
          if (mounted) _startBake(dpr);
        });
      }
    }, onError: (Object error, StackTrace stack) {
      _baking = false;
    });
  }

  Future<ui.Image> _bake(Size size, NoirPalette p, double dpr) async {
    final Size baked = Size(
      size.width + _overscan * 2,
      size.height + _overscan * 2,
    );
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(dpr);
    _StaticStagePainter(palette: p).paint(canvas, baked);
    _StreakPainter(
      sweepA: 0.28,
      sweepB: 0.62,
      driftC: 0.45,
      palette: p,
    ).paint(canvas, baked);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      (baked.width * dpr).ceil(),
      (baked.height * dpr).ceil(),
    );
    picture.dispose();
    return image;
  }
}

/// Draws the pre-rasterised ambient stage — one unfiltered textured quad.
class _StageTexturePainter extends CustomPainter {
  final ui.Image image;

  _StageTexturePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    // Stretched to the current viewport, which is a 1:1 blit whenever the
    // texture was baked for this size.
    final Rect dst = Rect.fromLTWH(
      -_ChromeStageState._overscan,
      -_ChromeStageState._overscan,
      size.width + _ChromeStageState._overscan * 2,
      size.height + _ChromeStageState._overscan * 2,
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _StageTexturePainter oldDelegate) =>
      oldDelegate.image != image;
}

/// Base colour, vignette and film grain — completely static.
class _StaticStagePainter extends CustomPainter {
  final NoirPalette palette;
  _StaticStagePainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final NoirPalette p = palette;

    // base
    canvas.drawRect(Offset.zero & size, Paint()..color = p.bg);

    // vignette
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.1),
          radius: 1.25,
          stops: const [0.0, 0.55, 1.0],
          colors: [
            p.vignette.soft(0.0),
            p.vignette.soft(0.0),
            p.vignette.soft(0.85),
          ],
        ).createShader(rect),
    );

    // film grain (seeded → identical every paint, so it can stay static)
    final math.Random rand = math.Random(7);
    final Paint grainPaint = Paint()
      ..color = p.grain.soft(p.isDark ? 0.030 : 0.024);
    final int count = p.isDark ? 1200 : 900;
    for (int i = 0; i < count; i++) {
      final double x = rand.nextDouble() * size.width;
      final double y = rand.nextDouble() * size.height;
      final double r = rand.nextDouble() * 1.1 + 0.3;
      canvas.drawCircle(Offset(x, y), r, grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticStagePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// The three sweeping liquid-chrome streaks.
class _StreakPainter extends CustomPainter {
  final double sweepA;
  final double sweepB;
  final double driftC;
  final NoirPalette palette;

  _StreakPainter({
    required this.sweepA,
    required this.sweepB,
    required this.driftC,
    required this.palette,
  });

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    final NoirPalette p = palette;
    final double vmax = math.max(size.width, size.height);

    // s1 — long diagonal streak, upper third, sweeping right
    _drawStreak(
      canvas,
      size,
      center: Offset(
        _lerp(0.12, 0.66, Curves.easeInOutSine.transform(sweepA)) * size.width,
        0.26 * size.height,
      ),
      angle: -14 * math.pi / 180,
      length: vmax * 1.35,
      thickness: (vmax * 0.16).clamp(90.0, 240.0),
      palette: p,
      intensity: 1.0,
    );

    // s2 — lower streak, sweeping the other way
    _drawStreak(
      canvas,
      size,
      center: Offset(
        _lerp(0.88, 0.34, Curves.easeInOutCubic.transform(sweepB)) * size.width,
        0.76 * size.height,
      ),
      angle: 9 * math.pi / 180,
      length: vmax * 1.25,
      thickness: (vmax * 0.11).clamp(60.0, 160.0),
      palette: p,
      intensity: 0.85,
    );

    // s3 — soft radial glow drifting down from the top
    final double gt = Curves.easeInOutSine.transform(driftC);
    final Offset c3 = Offset(
      0.5 * size.width,
      _lerp(-0.10, 0.10, gt) * size.height,
    );
    final double r3 = vmax * _lerp(0.30, 0.36, gt);
    canvas.drawCircle(
      c3,
      r3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.soft(p.isDark ? 0.050 : 0.09),
            Colors.white.soft(p.isDark ? 0.028 : 0.05),
            Colors.white.soft(0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: c3, radius: r3)),
    );
  }

  /// One streak = three nested rounded rects; the layering fakes the
  /// gaussian blur of the CSS `filter: blur(70px)` at zero runtime cost.
  void _drawStreak(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double angle,
    required double length,
    required double thickness,
    required NoirPalette palette,
    required double intensity,
  }) {
    final NoirPalette p = palette;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    const List<double> layers = [1.00, 0.84, 0.62, 0.40, 0.20];
    const List<double> alphas = [0.016, 0.026, 0.040, 0.058, 0.085];

    for (int i = 0; i < layers.length; i++) {
      final double h = thickness * layers[i];
      final double a = alphas[i] * intensity * (p.isDark ? 1.0 : 1.6);
      final Rect rect = Rect.fromCenter(
        center: Offset.zero,
        width: length,
        height: h,
      );
      final Paint paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.30, 0.50, 0.70, 1.0],
          colors: [
            Colors.white.soft(0.0),
            p.streak.soft(a * 0.55),
            p.streakHot.soft(a * 1.5),
            p.streak.soft(a * 0.55),
            Colors.white.soft(0.0),
          ],
        ).createShader(rect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(h / 2)),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StreakPainter oldDelegate) =>
      oldDelegate.sweepA != sweepA ||
      oldDelegate.sweepB != sweepB ||
      oldDelegate.driftC != driftC ||
      oldDelegate.palette != palette;
}
