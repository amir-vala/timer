import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const TimerApp());
}

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF), 
          brightness: Brightness.dark
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
      ),
      home: const TimerScreen(),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  
  int _totalSeconds = 300;
  int _remainingSeconds = 300;
  bool _isRunning = false;
  
  // تایمر چرخه‌ای ۳ دقیقه‌ای
  final int _cycleTotalSeconds = 180;
  int _cycleRemainingSeconds = 180;
  int _completedCycleCount = 0;

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
        // کاهش ثانیه‌های تایمر اصلی
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }
        
        // کاهش ثانیه‌های تایمر چرخه‌ای (همزمان با تایمر اصلی)
        if (_cycleRemainingSeconds > 0) {
          _cycleRemainingSeconds--;
        }
        
        // اگر تایمر چرخه‌ای به صفر رسید: شمارش + ریست
        if (_cycleRemainingSeconds == 0) {
          _completedCycleCount++;
          _cycleRemainingSeconds = _cycleTotalSeconds;
        }
        
        // اگر تایمر اصلی تمام شد، کل سیستم متوقف شود
        if (_remainingSeconds == 0) {
          _stopTimer();
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
  }

  void _updateDuration(int seconds) {
    if (!_isRunning) {
      setState(() {
        _totalSeconds = seconds;
        _remainingSeconds = seconds;
        _cycleRemainingSeconds = _cycleTotalSeconds;
        _completedCycleCount = 0;
      });
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بخش اصلی (تایمر بزرگ)
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ساعت اصلی بزرگ
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 130,
                          fontWeight: FontWeight.w200,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 50),
                      
                      // تایمر چرخه‌ای
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'CYCLE',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(_cycleRemainingSeconds),
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w300,
                                color: theme.colorScheme.primary,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                      
                      // دکمه‌های کنترل
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildControlButton(
                            onTap: _isRunning ? _stopTimer : _startTimer,
                            icon: _isRunning ? Icons.pause : Icons.play_arrow,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 30),
                          _buildControlButton(
                            onTap: _resetTimer,
                            icon: Icons.restart_alt,
                            color: Colors.redAccent,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // انتخاب مدت زمان
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildTimeChip('1 MIN', 60),
                          _buildTimeChip('5 MIN', 300),
                          _buildTimeChip('10 MIN', 600),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // لیست چرخه‌های تکمیل شده
              Expanded(
                flex: 1,
                child: _buildCyclesList(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCyclesList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 40),
      padding: const EdgeInsets.all(24),
      height: 500,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.loop, color: theme.colorScheme.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Cycles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '$_completedCycleCount',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _completedCycleCount == 0
                ? Center(
                    child: Text(
                      'No cycles yet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _completedCycleCount,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.secondary.withOpacity(0.8),
                                    theme.colorScheme.secondary.withOpacity(0.4),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              '3min',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.secondary.withOpacity(0.6),
                              size: 18,
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

  Widget _buildTimeChip(String label, int seconds) {
    final theme = Theme.of(context);
    bool isSelected = _totalSeconds == seconds;
    return ChoiceChip(
      label: Text(
        label, 
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 1,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
        width: 1.5,
      ),
      onSelected: (selected) {
        if (selected) _updateDuration(seconds);
      },
    );
  }

  Widget _buildControlButton({required VoidCallback onTap, required IconData icon, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 38),
      ),
    );
  }
}
