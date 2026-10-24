import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
///  NOIR CHROME — monochrome liquid-metal design tokens.
///  Ported from prototype-2 / main-ui-noir-chrome.html
/// ─────────────────────────────────────────────────────────────
class NoirPalette {
  final bool isDark;

  // stage
  final Color bg;
  final Color ink;
  final Color inkDim;
  final Color inkFaint;
  final Color accent; // ice-blue flash, used sparingly
  final Color done; // mint for completion

  // smoked-chrome glass recipe
  final Color glassTop;
  final Color glassMid;
  final Color glassBottom;
  final Color glassBorder;
  final Color glassHighlight; // inner top edge sheen

  // primary (chrome) button
  final Color primaryTop;
  final Color primaryBottom;
  final Color onPrimary;

  // ambient streaks
  final Color streak;
  final Color streakHot;
  final Color vignette;
  final Color grain;
  final BlendMode streakBlend;

  const NoirPalette({
    required this.isDark,
    required this.bg,
    required this.ink,
    required this.inkDim,
    required this.inkFaint,
    required this.accent,
    required this.done,
    required this.glassTop,
    required this.glassMid,
    required this.glassBottom,
    required this.glassBorder,
    required this.glassHighlight,
    required this.primaryTop,
    required this.primaryBottom,
    required this.onPrimary,
    required this.streak,
    required this.streakHot,
    required this.vignette,
    required this.grain,
    required this.streakBlend,
  });

  static const String font = 'SpaceGrotesk';

  static const NoirPalette dark = NoirPalette(
    isDark: true,
    bg: Color(0xFF0A0A0B),
    ink: Color(0xFFECECEE),
    inkDim: Color(0x80ECECEE),
    inkFaint: Color(0x38ECECEE),
    accent: Color(0xFFC8E6FF),
    done: Color(0xFFB9F5D0),
    glassTop: Color(0x13FFFFFF), // rgba(255,255,255,.075)
    glassMid: Color(0x05FFFFFF), // rgba(255,255,255,.02)
    glassBottom: Color(0x0DFFFFFF), // rgba(255,255,255,.05)
    glassBorder: Color(0x1FFFFFFF), // rgba(255,255,255,.12)
    glassHighlight: Color(0x38FFFFFF), // inset 0 1px 0 rgba(255,255,255,.22)
    primaryTop: Color(0xFFFFFFFF),
    primaryBottom: Color(0xFFB9C6D4),
    onPrimary: Color(0xFF0A0A0B),
    streak: Color(0xFFFFFFFF),
    streakHot: Color(0xFFC8E6FF),
    vignette: Color(0x8C000000),
    grain: Color(0xFFFFFFFF),
    streakBlend: BlendMode.screen,
  );

  static const NoirPalette light = NoirPalette(
    isDark: false,
    bg: Color(0xFFE9EBEF),
    ink: Color(0xFF17181B),
    inkDim: Color(0x8C17181B),
    inkFaint: Color(0x3817181B),
    accent: Color(0xFF3D6E99),
    done: Color(0xFF2F8A5B),
    glassTop: Color(0x8CFFFFFF),
    glassMid: Color(0x40FFFFFF),
    glassBottom: Color(0x73FFFFFF),
    glassBorder: Color(0x14101418),
    glassHighlight: Color(0xB3FFFFFF),
    primaryTop: Color(0xFF23262C),
    primaryBottom: Color(0xFF0E1013),
    onPrimary: Color(0xFFECECEE),
    streak: Color(0xFF5A6E88),
    streakHot: Color(0xFF8FA8C4),
    vignette: Color(0x1A000000),
    grain: Color(0xFF101318),
    streakBlend: BlendMode.multiply,
  );

  /// 160° smoked-chrome glass gradient (the .glass recipe).
  LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.55, 1.0],
        colors: [glassTop, glassMid, glassBottom],
      );

  /// Filled chrome gradient for the primary button / apply button.
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryTop, primaryBottom],
      );
}

/// Opacity helper that works on every Flutter version
/// (avoids the deprecated `withOpacity` on newer SDKs).
extension NoirColorExt on Color {
  Color soft(double alpha) => withAlpha((alpha.clamp(0.0, 1.0) * 255).round());
}
