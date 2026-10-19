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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF), brightness: Brightness.dark),
        useMaterial3: true,
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

class _TimerScreenState extends State<TimerScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animationController;
  
  int _totalSeconds = 300; // پیش‌فرض ۵ دقیقه
  int _remainingSeconds = 300;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds == 0) return;
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _animationController.value = 1 - (_remainingSeconds / _totalSeconds);
        });
      } else {
        _stopTimer();
      }
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
      _animationController.reset();
    });
  }

  void _updateDuration(int seconds) {
    if (!_isRunning) {
      setState(() {
        _totalSeconds = seconds;
        _remainingSeconds = seconds;
        _animationController.duration = Duration(seconds: seconds);
        _animationController.reset();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beautiful Timer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: _animationController.value),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 18,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.grey.shade800,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRunning ? "در حال اجرا..." : (_remainingSeconds == _totalSeconds ? "آماده" : "متوقف شده"),
                          style: TextStyle(color: Colors.grey.shade400),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildTimeChip('۱ دقیقه', 60),
                  _buildTimeChip('۵ دقیقه', 300),
                  _buildTimeChip('۱۰ دقیقه', 600),
                ],
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    onTap: _isRunning ? _stopTimer : _startTimer,
                    icon: _isRunning ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 30),
                  _buildControlButton(
                    onTap: _resetTimer,
                    icon: Icons.restart_alt,
                    color: Colors.redAccent,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, int seconds) {
    bool isSelected = _totalSeconds == seconds;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      selected: isSelected,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
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
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }
}