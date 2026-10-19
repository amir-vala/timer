import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF050508),
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: TimerScreen(toggleTheme: _toggleTheme, isDark: _themeMode == ThemeMode.dark),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 🎬 DIGIT ROLLER - اعداد اسکرول شونده
// ═══════════════════════════════════════════════════════
class DigitRoller extends StatelessWidget {
  final String char;
  final int index;
  final TextStyle? style;

  const DigitRoller({
    super.key,
    required this.char,
    required this.index,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.9),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      child: Text(
        char,
        key: ValueKey('$index-$char'),
        style: style,
      ),
    );
  }
}

Widget buildRollingTime(String time, TextStyle style) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(time.length, (index) {
      final char = time[index];
      if (char == ':') {
        return Text(':', style: style);
      }
      return DigitRoller(char: char, index: index, style: style);
    }),
  );
}

// ═══════════════════════════════════════════════════════
// 🌌 AURORA BACKGROUND - پس‌زمینه متحرک
// ═══════════════════════════════════════════════════════
class AuroraBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const AuroraBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        
        return Stack(
          children: [
            // Base gradient
            Container(
              decoration: BoxDecoration(
                gradient: widget.isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF050508), Color(0xFF0A0A12)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF8F9FA), Color(0xFFE8EAF0)],
                      ),
              ),
            ),
            // Floating orbs
            Positioned(
              left: MediaQuery.of(context).size.width * 0.1 + math.sin(t) * 50,
              top: MediaQuery.of(context).size.height * 0.2 + math.cos(t) * 30,
              child: _buildOrb(
                color: const Color(0xFF6C63FF).withOpacity(widget.isDark ? 0.15 : 0.1),
                size: 300,
              ),
            ),
            Positioned(
              right: MediaQuery.of(context).size.width * 0.1 + math.cos(t * 0.7) * 40,
              bottom: MediaQuery.of(context).size.height * 0.3 + math.sin(t * 0.7) * 40,
              child: _buildOrb(
                color: const Color(0xFFA855F7).withOpacity(widget.isDark ? 0.12 : 0.08),
                size: 250,
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.4 + math.sin(t * 1.3) * 60,
              bottom: MediaQuery.of(context).size.height * 0.1 + math.cos(t * 1.3) * 35,
              child: _buildOrb(
                color: const Color(0xFF38BDF8).withOpacity(widget.isDark ? 0.1 : 0.07),
                size: 200,
              ),
            ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _buildOrb({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 🪟 GLASS CONTAINER - افکت شیشه‌ای
// ═══════════════════════════════════════════════════════
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Color? borderColor;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.borderColor,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ColorFilter.mode(
          theme.colorScheme.surface.withOpacity(0.1),
          BlendMode.srcOver,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.05),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? theme.colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: blur,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ⏱️ TIMER SCREEN
// ═══════════════════════════════════════════════════════
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds == 0) return;
    setState(() => _isRunning = true);
    
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
          _stopTimer();
          HapticFeedback.selectionClick();
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
    });
    HapticFeedback.mediumImpact();
  }

  void _updateDuration(int seconds) {
    if (!_isRunning) {
      setState(() {
        _totalSeconds = seconds;
        _remainingSeconds = seconds;
        _cycleRemainingSeconds = _cycleTotalSeconds;
        _completedCycleCount = 0;
      });
      HapticFeedback.lightImpact();
    }
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
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                  top: 32,
                  left: 32,
                  right: 32,
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
                    
                    _buildSliderRow(
                      theme,
                      'Hours',
                      customHours,
                      'hr',
                      0,
                      3,
                      3,
                      (value) => setModalState(() => customHours = value.toInt()),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildSliderRow(
                      theme,
                      'Minutes',
                      customMinutes,
                      'min',
                      0,
                      59,
                      59,
                      (value) => setModalState(() => customMinutes = value.toInt()),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildSliderRow(
                      theme,
                      'Seconds',
                      customSeconds,
                      'sec',
                      0,
                      59,
                      59,
                      (value) => setModalState(() => customSeconds = value.toInt()),
                    ),
                    const SizedBox(height: 32),
                    
                    GlassContainer(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: theme.colorScheme.primary, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              _formatTime((customHours * 3600) + (customMinutes * 60) + customSeconds),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: theme.colorScheme.primary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final totalSeconds = (customHours * 3600) + (customMinutes * 60) + customSeconds;
                          if (totalSeconds > 0) {
                            _updateDuration(totalSeconds);
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
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderRow(
    ThemeData theme,
    String label,
    int value,
    String unit,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value $unit',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
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

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AuroraBackground(
        isDark: widget.isDark,
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme Toggle Button
                      Align(
                        alignment: Alignment.topRight,
                        child: GlassContainer(
                          borderRadius: BorderRadius.circular(16),
                          child: IconButton(
                            onPressed: widget.toggleTheme,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                widget.isDark ? Icons.light_mode : Icons.dark_mode,
                                key: ValueKey(widget.isDark),
                                color: theme.colorScheme.onSurface,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Main Timer with Digit Rollers
                      GlassContainer(
                        borderRadius: BorderRadius.circular(40),
                        borderColor: _isRunning 
                            ? theme.colorScheme.primary.withOpacity(0.5) 
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildRollingTime(
                                _formatTime(_remainingSeconds),
                                TextStyle(
                                  fontSize: 120,
                                  fontWeight: FontWeight.w200,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -5,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: _isRunning ? 1.0 : 0.6,
                                child: Text(
                                  _isRunning ? 'RUNNING' : 'READY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _isRunning 
                                        ? theme.colorScheme.primary 
                                        : theme.colorScheme.onSurface.withOpacity(0.5),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      
                      // Cycle Timer with Digit Rollers
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _isCycleEnabled ? 1.0 : 0.4,
                        child: GlassContainer(
                          borderRadius: BorderRadius.circular(24),
                          borderColor: theme.colorScheme.primary.withOpacity(0.4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
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
                                buildRollingTime(
                                  _formatTime(_cycleRemainingSeconds),
                                  TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w300,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 70),
                      
                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGlassButton(
                            onTap: _isRunning ? _stopTimer : _startTimer,
                            icon: _isRunning ? Icons.pause : Icons.play_arrow,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          _buildGlassButton(
                            onTap: _resetTimer,
                            icon: Icons.restart_alt,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 16),
                          _buildGlassButton(
                            onTap: _toggleCycle,
                            icon: Icons.loop,
                            color: _isCycleEnabled ? theme.colorScheme.secondary : Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          _buildGlassButton(
                            onTap: _openCustomTimerModal,
                            icon: Icons.tune,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Preset Chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTimeChip('45 MIN', 2700),
                          _buildTimeChip('1 HOUR', 3600),
                          _buildTimeChip('60 MIN', 3600),
                          _buildTimeChip('90 MIN', 5400),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Floating Cycles Menu
            Positioned(
              left: 24,
              bottom: 24,
              child: _FloatingCyclesMenu(
                completedCycles: _completedCycleCount,
                cycleTotalSeconds: _cycleTotalSeconds,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton({required VoidCallback onTap, required IconData icon, required Color color}) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(28),
      borderColor: color.withOpacity(0.3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, int seconds) {
    final theme = Theme.of(context);
    bool isSelected = _totalSeconds == seconds;
    
    return GlassContainer(
      borderRadius: BorderRadius.circular(16),
      borderColor: isSelected 
          ? theme.colorScheme.primary 
          : theme.colorScheme.outline.withOpacity(0.2),
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

// ═══════════════════════════════════════════════════════
// 🎯 FLOATING CYCLES MENU
// ═══════════════════════════════════════════════════════
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

class _FloatingCyclesMenuState extends State<_FloatingCyclesMenu> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isExpanded = true),
      onExit: (_) => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        width: _isExpanded ? 280 : 60,
        height: _isExpanded ? 400 : 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _isExpanded ? _buildExpandedView(theme) : _buildCollapsedView(theme),
        ),
      ),
    );
  }

  Widget _buildCollapsedView(ThemeData theme) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: widget.completedCycles > 0 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withOpacity(0.7),
                  ],
                )
              : null,
          color: widget.completedCycles > 0 ? null : theme.colorScheme.surfaceVariant,
          shape: BoxShape.circle,
          boxShadow: widget.completedCycles > 0 ? [
            BoxShadow(
              color: theme.colorScheme.secondary.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            '${widget.completedCycles}',
            style: TextStyle(
              color: widget.completedCycles > 0 
                  ? Colors.white 
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
                child: Icon(Icons.loop, color: theme.colorScheme.secondary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Cycles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.completedCycles}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
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
                        Icon(
                          Icons.hourglass_empty,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No cycles yet',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.completedCycles,
                    itemBuilder: (context, index) {
                      return Container(
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
                            color: theme.colorScheme.secondary.withOpacity(0.3),
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
                                    theme.colorScheme.secondary.withOpacity(0.6),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.cycleTotalSeconds ~/ 60}min',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.withOpacity(0.7),
                              size: 16,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
