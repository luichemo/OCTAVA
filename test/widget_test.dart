import 'package:flutter_test/flutter_test.dart';

import 'package:octava/main.dart';

void main() {
  testWidgets('home shows the wordmark and the band lineup', (tester) async {
    await tester.pumpWidget(const OctavaApp());

    expect(find.text('OCTAVA'), findsOneWidget);
    expect(find.text('Your band'), findsOneWidget);
    expect(find.text('Drums'), findsOneWidget);
    expect(find.text('Open'), findsNWidgets(4));
  });
}
