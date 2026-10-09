import 'package:flutter_test/flutter_test.dart';
import 'package:octava/widgets/musician_card.dart';

/// Drags the top card off to the right (Jam), like a person would.
Future<void> swipeJam(WidgetTester tester) => _swipe(tester, 400);

/// Drags the top card off to the left (Pass).
Future<void> swipePass(WidgetTester tester) => _swipe(tester, -400);

Future<void> _swipe(WidgetTester tester, double dx) async {
  // The top card is drawn last.
  await tester.drag(find.byType(MusicianCard).last, Offset(dx, 0));
  await tester.pumpAndSettle();
}
