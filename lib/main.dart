import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'rolling_time.dart';

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

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0D12),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6CFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
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

class _TimerScreenState extends State<TimerScreen> {
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
            HapticFeedback.heavyImpact();
          }
        }

        if (_remainingSeconds == 0) {
          _isRunning = false;
          _sessionComplete = true;
          timer.cancel();
          HapticFeedback.heavyImpact();
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
    HapticFeedback.mediumImpact();
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
    HapticFeedback.lightImpact();
  }

  void _toggleCycle() {
    setState(() {
      _isCycleEnabled = !_isCycleEnabled;
      if (!_isCycleEnabled) {
        _cycleRemainingSeconds = _cycleTotalSeconds;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _toggleFocus() {
    setState(() => _focusMode = !_focusMode);
  }

  String _formatTime(int totalSeconds) {
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _openCustomTimerModal() {
    int customHours = _totalSeconds ~/ 3600;
    int customMinutes = (_totalSeconds % 3600) ~/ 60;
    int customSeconds = _totalSeconds % 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                top: 32,
                left: 32,
                right: 32,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Set Custom Timer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSliderRow(theme, 'Hours', customHours, 'hr', 0, 3, 3,
                      (v) => setModalState(() => customHours = v.toInt())),
                  const SizedBox(height: 20),
                  _buildSliderRow(theme, 'Minutes', customMinutes, 'min', 0,
                      59, 59,
                      (v) => setModalState(() => customMinutes = v.toInt())),
                  const SizedBox(height: 20),
                  _buildSliderRow(theme, 'Seconds', customSeconds, 'sec', 0,
                      59, 59,
                      (v) => setModalState(() => customSeconds = v.toInt())),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer,
                            color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          _formatTime((customHours * 3600) +
                              (customMinutes * 60) +
                              customSeconds),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final total = (customHours * 3600) +
                            (customMinutes * 60) +
                            customSeconds;
                        if (total > 0) {
                          _updateDuration(total);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Apply',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderRow(ThemeData theme, String label, int value,
      String unit, double min, double max, int divisions,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$value $unit',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: theme.colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _hud(Widget child) {
    return AnimatedOpacity(
      opacity: _focusMode ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(ignoring: _focusMode, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool compact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _focusMode ? () => setState(() => _focusMode = false) : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: AmbientBackground(isDark: widget.isDark),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClockArea(theme, compact),
                      const SizedBox(height: 28),
                      _buildHairline(theme),
                      const SizedBox(height: 36),
                      _hud(_buildCycleBox(theme)),
                      if (!_focusMode) const SizedBox(height: 44),
                      _hud(_buildControls(theme)),
                      if (!_focusMode) const SizedBox(height: 36),
                      _hud(_buildChips(theme)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: _hud(
                _MiniButton(
                  onTap: widget.toggleTheme,
                  icon: widget.isDark ? Icons.light_mode : Icons.dark_mode,
                  color: theme.colorScheme.onSurface,
                  size: 48,
                ),
              ),
            ),
            Positioned(
              left: 24,
              bottom: 24,
              child: _hud(
                _FloatingCyclesMenu(
                  completedCycles: _completedCycleCount,
                  cycleTotalSeconds: _cycleTotalSeconds,
                ),
              ),
            ),
            if (_focusMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(
                  child: Text(
                    'tap anywhere to exit focus',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClockArea(ThemeData theme, bool compact) {
    String status;
    Color statusColor;
    if (_sessionComplete) {
      status = 'Session complete';
      statusColor = theme.colorScheme.secondary;
    } else if (_isRunning) {
      status = 'RUNNING';
      statusColor = theme.colorScheme.primary;
    } else {
      status = 'READY';
      statusColor = theme.colorScheme.onSurface.withOpacity(0.5);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _CompletionRipple(
          trigger: _sessionComplete,
          color: theme.colorScheme.secondary,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RollingTime(
              seconds: _remainingSeconds,
              fontSize: compact ? 64 : 112,
              color: _sessionComplete
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface,
              showHours: _totalSeconds >= 3600,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                status,
                key: ValueKey<String>(status),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHairline(ThemeData theme) {
    final double progress = _totalSeconds == 0
        ? 0
        : (1 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = math.min(constraints.maxWidth, 420);
        return SizedBox(
          width: width,
          height: 6,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.linear,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (value > 0.001)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCycleBox(ThemeData theme) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isCycleEnabled ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.15),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: _isCycleEnabled
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              'CYCLE',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            RollingTime(
              seconds: _cycleRemainingSeconds,
              fontSize: 36,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MiniButton(
          onTap: _isRunning ? _stopTimer : _startTimer,
          icon: _isRunning ? Icons.pause : Icons.play_arrow,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 14),
        _MiniButton(
          onTap: _resetTimer,
          icon: Icons.restart_alt,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 14),
        _MiniButton(
          onTap: _toggleCycle,
          icon: Icons.loop,
          color: theme.colorScheme.secondary,
          active: _isCycleEnabled,
          indicator: true,
          indicatorOn: _isCycleEnabled,
        ),
        const SizedBox(width: 14),
        _MiniButton(
          onTap: _openCustomTimerModal,
          icon: Icons.tune,
          color: Colors.amber,
        ),
        const SizedBox(width: 14),
        _MiniButton(
          onTap: _toggleFocus,
          icon: Icons.center_focus_strong,
          color: theme.colorScheme.onSurface,
        ),
      ],
    );
  }

  Widget _buildChips(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildTimeChip(theme, '45 MIN', 2700),
        _buildTimeChip(theme, '1 HOUR', 3600),
        _buildTimeChip(theme, '60 MIN', 3600),
        _buildTimeChip(theme, '90 MIN', 5400),
      ],
    );
  }

  Widget _buildTimeChip(ThemeData theme, String label, int seconds) {
    final bool isSelected = _totalSeconds == seconds;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(isSelected ? 0.3 : 0.1),
            theme.colorScheme.secondary.withOpacity(isSelected ? 0.2 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _updateDuration(seconds),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AmbientBackground extends StatefulWidget {
  final bool isDark;
  const AmbientBackground({super.key, required this.isDark});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

// ============================================================
//  Ambient Background — نسخهٔ بازنویسی‌شده
//  - بدون پرش: از repeat(reverse:true) استفاده می‌کند (پینگ‌پونگ)
//  - بدون بندینگ: گرادیانت ۶ استاپه + تغییر رنگ بین استاپ‌ها
//  - عملکرد بالا: CustomPainter به‌جای ویجت‌های سنگین
// ============================================================

class AmbientBackground extends StatefulWidget {
  final bool isDark;
  const AmbientBackground({super.key, required this.isDark});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  // سه کنترلر مستقل با دوره‌های اول‌نسبت‌به‌هم برای حرکت ارگانیک
  // چون همه reverse:true دارند، هیچ‌وقت پرش نمی‌کنند
  late final AnimationController _driftA;
  late final AnimationController _driftB;
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _driftA = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    )..repeat(reverse: true);

    _driftB = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 27),
    )..repeat(reverse: true);

    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 13),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftA.dispose();
    _driftB.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_driftA, _driftB, _breathe]),
        builder: (context, _) {
          return CustomPaint(
            painter: _AmbientPainter(
              driftA: _driftA.value,
              driftB: _driftB.value,
              breathe: _breathe.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final double driftA;
  final double driftB;
  final double breathe;
  final bool isDark;

  _AmbientPainter({
    required this.driftA,
    required this.driftB,
    required this.breathe,
    required this.isDark,
  });

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    // ── پس‌زمینهٔ پایه ──
    final Color base =
        isDark ? const Color(0xFF0B0D12) : const Color(0xFFF6F7FB);
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    // ── موقعیت حباب A ──
    // منحنی‌های متفاوت برای x و y → مسیر منحنی به‌جای خط مستقیم
    final double ax = _lerp(
        0.10, 0.32, Curves.easeInOutSine.transform(driftA)) * size.width;
    final double ay = _lerp(
        0.12, 0.38, Curves.easeInOutCubic.transform(driftA)) * size.height;

    // ── موقعیت حباب B ──
    final double bx = _lerp(
        0.68, 0.90, Curves.easeInOutCubic.transform(driftB)) * size.width;
    final double by = _lerp(
        0.58, 0.84, Curves.easeInOutSine.transform(driftB)) * size.height;

    // ── تنفس: تغییر مقیاس بسیار ملایم ──
    final double breathT = Curves.easeInOutSine.transform(breathe);
    final double scaleA = 0.92 + 0.08 * breathT;
    final double scaleB = 1.04 - 0.08 * breathT;

    // ── رنگ‌ها ──
    final Color colorA =
        isDark ? const Color(0xFF7C6CFF) : const Color(0xFF8B7CFF);
    final Color colorB =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFFF2B84B);
    final double opA = isDark ? 0.32 : 0.22;
    final double opB = isDark ? 0.25 : 0.20;

    // ── رسم حباب‌ها ──
    _drawBlob(canvas, Offset(ax, ay), size.width * 0.52 * scaleA,
        colorA, base, opA);
    _drawBlob(canvas, Offset(bx, by), size.width * 0.48 * scaleB,
        colorB, base, opB);

    // ── گرین: شکنندگی بندینگ رنگی ──
    _drawGrain(canvas, size);
  }

  /// گرادیانت شعاعی ۶ استاپه با تغییر رنگ بین استاپ‌ها
  /// برای جلوگیری از بندینگ روی مانیتورهای ۸ بیتی
  void _drawBlob(Canvas canvas, Offset center, double radius,
      Color color, Color base, double maxOpacity) {
    // به‌جای تغییر صرف آلفا، رنگ را هم کمی به سمت رنگ پایه شیفت می‌دهیم
    // این کار «پله‌های» گرادیانت را می‌شکند و بندینگ را نامرئی می‌کند
    final gradient = RadialGradient(
      colors: [
        Color.lerp(color, Colors.white, 0.06)!.withOpacity(maxOpacity),
        color.withOpacity(maxOpacity * 0.72),
        Color.lerp(color, base, 0.25)!.withOpacity(maxOpacity * 0.45),
        Color.lerp(color, base, 0.50)!.withOpacity(maxOpacity * 0.22),
        Color.lerp(color, base, 0.75)!.withOpacity(maxOpacity * 0.08),
        base.withOpacity(0.0),
      ],
      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius, paint);
  }

  /// نویز بسیار ریز برای شکستن حلقه‌های بندینگ
  /// تعداد نقاط بیشتر از قبل + توزیع یکنواخت‌تر
  void _drawGrain(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final Color grainColor = isDark ? Colors.white : Colors.black;
    final double grainOpacity = isDark ? 0.028 : 0.022;
    final paint = Paint()..color = grainColor.withOpacity(grainOpacity);

    // ۱۴۰۰ نقطه برای پوشش بهتر بدون افت عملکرد محسوس
    for (int i = 0; i < 1400; i++) {
      final double x = rand.nextDouble() * size.width;
      final double y = rand.nextDouble() * size.height;
      final double r = rand.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.driftA != driftA ||
      oldDelegate.driftB != driftB ||
      oldDelegate.breathe != breathe ||
      oldDelegate.isDark != isDark;
}

class _CompletionRipple extends StatefulWidget {
  final bool trigger;
  final Color color;
  const _CompletionRipple({required this.trigger, required this.color});

  @override
  State<_CompletionRipple> createState() => _CompletionRippleState();
}

class _CompletionRippleState extends State<_CompletionRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

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
          final double scale = 1 + _controller.value * 2.4;
          final double opacity = ((1 - _controller.value) * 0.35).clamp(0, 1);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(opacity),
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  final bool active;
  final bool indicator;
  final bool indicatorOn;

  const _MiniButton({
    required this.onTap,
    required this.icon,
    required this.color,
    this.size = 52,
    this.active = true,
    this.indicator = false,
    this.indicatorOn = false,
  });

  @override
  State<_MiniButton> createState() => _MiniButtonState();
}

class _MiniButtonState extends State<_MiniButton> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : (_hover ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(_hover ? 0.18 : 0.10),
                    border: Border.all(
                      color: widget.color
                          .withOpacity(_hover ? 0.75 : 0.4),
                      width: _hover ? 1.8 : 1.4,
                    ),
                    boxShadow: (_hover && widget.active)
                        ? [
                            BoxShadow(
                              color: widget.color.withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: -4,
                            ),
                          ]
                        : null,
                  ),
                ),
                Icon(
                  widget.icon,
                  color: widget.active
                      ? widget.color
                      : widget.color.withOpacity(0.45),
                  size: widget.size * 0.5,
                ),
                if (widget.indicator)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: AnimatedScale(
                      scale: widget.indicatorOn ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.8),
                              blurRadius: 6,
                            ),
                          ],
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
  }
}

class _FloatingCyclesMenu extends StatefulWidget {
  final int completedCycles;
  final int cycleTotalSeconds;

  const _FloatingCyclesMenu({
    required this.completedCycles,
    required this.cycleTotalSeconds,
  });

  @override
  State<_FloatingCyclesMenu> createState() => _FloatingCyclesMenuState();
}

class _FloatingCyclesMenuState extends State<_FloatingCyclesMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _numberBubble(ThemeData theme) {
    final bool has = widget.completedCycles > 0;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: has
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.secondary,
                  theme.colorScheme.secondary.withOpacity(0.7),
                ],
              )
            : null,
        color: has ? null : theme.colorScheme.surfaceVariant,
        shape: BoxShape.circle,
        boxShadow: has
            ? [
                BoxShadow(
                  color: theme.colorScheme.secondary.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '${widget.completedCycles}',
          style: TextStyle(
            color: has
                ? Colors.white
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _expanded(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.3),
                    theme.colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.loop,
                  color: theme.colorScheme.secondary, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Cycles',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${widget.completedCycles}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.completedCycles == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.3),
                          size: 32),
                      const SizedBox(height: 12),
                      Text('No cycles yet',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                              fontStyle: FontStyle.italic,
                              fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.completedCycles,
                  itemBuilder: (context, index) {
                    final bool isNewest =
                        index == widget.completedCycles - 1;
                    final Widget row = Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withOpacity(0.15),
                            theme.colorScheme.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.secondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.secondary,
                                  theme.colorScheme.secondary
                                      .withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                              '${widget.cycleTotalSeconds ~/ 60}min',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const Spacer(),
                          Icon(Icons.check_circle,
                              color: Colors.green.withOpacity(0.7),
                              size: 16),
                        ],
                      ),
                    );

                    if (!isNewest) {
                      return row;
                    }
                    return TweenAnimationBuilder<double>(
                      key: ValueKey<int>(index),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: row,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) {
        if (!_open) {
          _open = true;
          _controller.forward();
        }
      },
      onExit: (_) {
        if (_open) {
          _open = false;
          _controller.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final Curve curve =
              _open ? Curves.easeOutBack : Curves.easeOutCubic;
          final double t = curve.transform(_controller.value);
          final double width = 60 + (280 - 60) * t;
          final double height = 60 + (400 - 60) * t;
          final double contentT = ((t - 0.35) / 0.65).clamp(0.0, 1.0);

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Opacity(
                    opacity: (1 - contentT).clamp(0.0, 1.0),
                    child: Center(child: _numberBubble(theme)),
                  ),
                  Opacity(
                    opacity: contentT,
                    child: IgnorePointer(
                      ignoring: contentT < 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _expanded(theme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
