import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  Odometer-style rolling time, tuned for NOIR CHROME.
///
///  Timing ported from the CSS reference:
///    .dstrip { transition: transform .55s cubic-bezier(.22,1,.36,1) }
///  → 550 ms with Cubic(0.22, 1.0, 0.36, 1.0).
///
///  Only the digit that actually changes rolls; the rest stay still.
/// ─────────────────────────────────────────────────────────────
class RollingTime extends StatefulWidget {
  const RollingTime({
    super.key,
    required this.seconds,
    required this.fontSize,
    required this.color,
    this.showHours = false,
    this.animate = true,
    this.weight = FontWeight.w300,
    this.fontFamily,
    this.metallic = false,
    this.rollDuration = const Duration(milliseconds: 550),
  });

  final int seconds;
  final double fontSize;
  final Color color;
  final bool showHours;
  final bool animate;
  final FontWeight weight;
  final String? fontFamily;

  /// Subtle vertical chrome sheen (light → shadow → light) across digits.
  final bool metallic;
  final Duration rollDuration;

  @override
  State<RollingTime> createState() => _RollingTimeState();
}

class _RollingTimeState extends State<RollingTime> {
  bool _down = true;

  @override
  void didUpdateWidget(covariant RollingTime oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      // countdown → roll down / reset → roll up
      _down = widget.seconds < oldWidget.seconds;
    }
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final int total = widget.seconds < 0 ? 0 : widget.seconds;
    final int hh = widget.showHours ? (total ~/ 3600) % 100 : 0;
    final int mm = widget.showHours ? (total % 3600) ~/ 60 : total ~/ 60;
    final int ss = total % 60;

    final double digitW = widget.fontSize * 0.62;
    final double digitH = widget.fontSize * 1.20;

    final TextStyle style = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: widget.weight,
      fontFamily: widget.fontFamily,
      height: 1.0,
      letterSpacing: -widget.fontSize * 0.02, // matches CSS letter-spacing:-.02em
      color: widget.color,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );

    Widget digit(String id, String char) => ExcludeSemantics(
          child: _DigitRoller(
            key: ValueKey<String>(id),
            char: char,
            width: digitW,
            height: digitH,
            style: style,
            down: _down,
            animate: widget.animate,
            duration: widget.rollDuration,
          ),
        );

    Widget colon() => ExcludeSemantics(
          child: SizedBox(
            width: widget.fontSize * 0.30,
            height: digitH,
            child: Center(
              child: Transform.translate(
                offset: Offset(0, -widget.fontSize * 0.04),
                child: Text(
                  ':',
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    color: widget.color.withAlpha(64),
                  ),
                ),
              ),
            ),
          ),
        );

    final List<Widget> children = <Widget>[];

    if (widget.showHours) {
      final String hStr = _pad(hh);
      children.addAll([
        digit('h0', hStr[0]),
        digit('h1', hStr[1]),
        colon(),
      ]);
    }

    final String mStr = _pad(mm);
    final String sStr = _pad(ss);

    children.addAll([
      digit('m0', mStr[0]),
      digit('m1', mStr[1]),
      colon(),
      digit('s0', sStr[0]),
      digit('s1', sStr[1]),
    ]);

    final String label = widget.showHours
        ? '${_pad(hh)}:${_pad(mm)}:${_pad(ss)}'
        : '${_pad(mm)}:${_pad(ss)}';

    Widget row = Semantics(
      label: 'Time remaining: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );

    if (widget.metallic) {
      // Liquid-chrome sheen: ink at top, deeper tone through the waist,
      // a faint specular band, back to ink at the base.
      final Color deep = Color.lerp(widget.color, Colors.black, 0.35)!;
      final Color spec = Color.lerp(widget.color, Colors.white, 0.25)!;
      row = ShaderMask(
        shaderCallback: (Rect bounds) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.40, 0.58, 0.74, 1.0],
          colors: [
            widget.color,
            deep,
            spec,
            deep,
            widget.color,
          ],
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: row,
      );
    }

    return row;
  }
}

/// Single-digit pulley: two glyphs (new + previous) inside a clipped window.
class _DigitRoller extends StatefulWidget {
  const _DigitRoller({
    super.key,
    required this.char,
    required this.width,
    required this.height,
    required this.style,
    required this.down,
    required this.animate,
    required this.duration,
  });

  final String char;
  final double width;
  final double height;
  final TextStyle style;
  final bool down;
  final bool animate;
  final Duration duration;

  @override
  State<_DigitRoller> createState() => _DigitRollerState();
}

class _DigitRollerState extends State<_DigitRoller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _current;
  late String _previous;

  /// NOIR CHROME roll curve — cubic-bezier(.22, 1, .36, 1).
  static const Curve _rollCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  @override
  void initState() {
    super.initState();
    _current = widget.char;
    _previous = widget.char;
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant _DigitRoller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.char == widget.char) return;

    _previous = _current;
    _current = widget.char;

    if (widget.animate) {
      _controller.forward(from: 0.0);
    } else {
      _controller.value = 1.0;
      _previous = _current;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _tile(String char) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Text(
            char,
            textAlign: TextAlign.center,
            style: widget.style,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(child: Text(_current, style: widget.style)),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double t = _rollCurve.transform(_controller.value);
        final double h = widget.height;

        // Both glyphs travel together, one direction — a real odometer pulley.
        final double currentTop = widget.down ? h * (t - 1) : h * (1 - t);
        final double previousTop = widget.down ? h * t : -h * t;

        return SizedBox(
          width: widget.width,
          height: h,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(left: 0, top: currentTop, child: _tile(_current)),
              Positioned(left: 0, top: previousTop, child: _tile(_previous)),
            ],
          ),
        );
      },
    );
  }
}
