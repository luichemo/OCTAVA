import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/models/profile_draft.dart';
import 'package:octava/screens/edit_profile_screen.dart';
import 'package:octava/theme.dart';
import 'package:octava/widgets/musician_card.dart';

import 'profile_helpers.dart';
import 'signup_flow_test.dart' show FakeProfileRepository;

void main() {
  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(OctavaApp(home: home));
    await tester.pumpAndSettle();
  }

  test('other instruments come from get_deck, best first', () {
    final m = Musician.fromDeckRow({
      'id': '6f1c0d1e-0000-4000-8000-000000000001',
      'display_name': 'Ana',
      'age': 25,
      'instruments': [
        {'instrument': 'bass', 'skill': 'pro', 'is_primary': true},
        {'instrument': 'drums', 'skill': 'beginner', 'is_primary': false},
        {'instrument': 'guitar', 'skill': 'pro', 'is_primary': false},
        {'instrument': 'keys', 'skill': 'advanced', 'is_primary': false},
      ],
    });
    expect(m.instrumentId, 'bass');
    expect(
      [for (final i in m.otherInstruments) i.id],
      ['guitar', 'keys', 'drums'],
    );
  });

  testWidgets('the card lists the other instruments under the name', (
    tester,
  ) async {
    await pump(
      tester,
      Scaffold(
        body: SizedBox(
          height: 640,
          child: MusicianCard(
            musician: Musician(
              name: 'Ana',
              age: 25,
              instrumentId: 'bass',
              otherInstruments: [
                (id: 'guitar', skill: 'pro'),
                (id: 'keys', skill: 'advanced'),
              ],
            ),
            tone: OctavaColors.aqua,
            fitsOpenSlot: false,
          ),
        ),
      ),
    );
    // Pills with skill dots; screen readers hear the whole line.
    expect(find.text('Guitar'), findsOneWidget);
    expect(find.text('Keys'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Also: Guitar · Pro, Keys · Advanced'),
      findsOneWidget,
    );
  });

  testWidgets('the star makes an instrument the main one', (tester) async {
    final repo = FakeProfileRepository(hasBirthDate: true, hasProfile: true)
      ..saved = const ProfileDraft(
        displayName: 'Luka',
        instruments: {'bass': 'pro', 'guitar': 'pro'},
      );
    await pump(tester, EditProfileScreen(repository: repo));
    await openSection(tester, 'What you play');
    final scroll = find.byType(Scrollable).first;

    final makeMain = find.byTooltip('Make this your main instrument');
    await tester.scrollUntilVisible(makeMain, 200, scrollable: scroll);
    await tester.ensureVisible(makeMain);
    await tester.pumpAndSettle();
    expect(find.text('Bass (main)'), findsOneWidget);
    await tester.tap(makeMain);
    await tester.pumpAndSettle();
    expect(find.text('Guitar (main)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Save changes'),
      200,
      scrollable: scroll,
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repo.saved?.instruments.keys.toList(), ['guitar', 'bass']);
  });
}
