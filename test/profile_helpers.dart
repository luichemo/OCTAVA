import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unfolds a section of the edit-profile form by tapping its heading.
/// (Sections start folded when editing.)
Future<void> openSection(WidgetTester tester, String title) async {
  final heading = find.text(title);
  await tester.scrollUntilVisible(
    heading,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(heading);
  await tester.pumpAndSettle();
  await tester.tap(heading);
  await tester.pumpAndSettle();
}
