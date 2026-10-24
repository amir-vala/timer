import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_timer/main.dart';

void main() {
  testWidgets('NOIR CHROME app boots into idle state', (tester) async {
    await tester.pumpWidget(const TimerApp());
    await tester.pump(const Duration(seconds: 1));

    // top bar brand + status
    expect(find.textContaining('NOIR'), findsWidgets);
    expect(find.text('READY'), findsOneWidget);

    // cycle card + rail + dock + chips present
    expect(find.text('CYCLE'), findsOneWidget);
    expect(find.text('LOG'), findsOneWidget);
    expect(find.text('25 MIN'), findsOneWidget);
    expect(find.text('90 MIN'), findsOneWidget);

    // default duration is 05:00 → digits 0,5,0,0 rendered
    expect(find.text('0'), findsWidgets);
    expect(find.text('5'), findsWidgets);
  });

  testWidgets('start tick rolls the clock and flips status', (tester) async {
    await tester.pumpWidget(const TimerApp());
    await tester.pump();

    // tap the primary (play) dock button
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('RUNNING'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('idle screen runs no vsync animation and repaints nothing',
      (tester) async {
    await tester.pumpWidget(const TimerApp());
    await tester.pump(const Duration(seconds: 1));

    // Regression guard: the ambient stage used to drive three repeating
    // AnimationControllers, so an idle window re-rasterised a full-screen
    // gradient at vsync (measured: ~55% of a core, 7 fps, 1.9 GB RSS on
    // integrated graphics). At rest the tree must hold no tickers at all.
    expect(tester.binding.transientCallbackCount, 0);
  });
}
