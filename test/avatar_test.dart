import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:octava/data/avatar_repository.dart';
import 'package:octava/data/repositories.dart';
import 'package:octava/main.dart';
import 'package:octava/models/musician.dart';
import 'package:octava/widgets/avatar_section.dart';

class FakeAvatarRepository implements AvatarRepository {
  FakeAvatarRepository({this.current, this.error});

  String? current;
  final String? error;
  int generated = 0;

  @override
  Future<String?> myAvatarPath() async => current;

  @override
  Future<({String path, int remaining})> generate() async {
    if (error != null) throw UserFacingException(error!);
    generated++;
    current = 'me/$generated.jpg';
    return (path: current!, remaining: 5 - generated);
  }

  // An empty link draws nothing, so tests don't touch the network.
  @override
  Future<String> imageUrl(String path) async => '';
}

void main() {
  Future<void> pump(WidgetTester tester, AvatarRepository avatars) async {
    await tester.pumpWidget(
      OctavaApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AvatarSection(avatars: avatars),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first avatar, then a new one, counting what is left', (
    tester,
  ) async {
    final avatars = FakeAvatarRepository();
    await pump(tester, avatars);

    await tester.tap(find.text('Generate my avatar'));
    await tester.pumpAndSettle();
    expect(avatars.generated, 1);
    expect(find.text('4 more today'), findsOneWidget);

    await tester.tap(find.text('Make a new one'));
    await tester.pumpAndSettle();
    expect(avatars.current, 'me/2.jpg');
    expect(find.text('3 more today'), findsOneWidget);
  });

  testWidgets('someone with an avatar is offered a new one', (tester) async {
    await pump(tester, FakeAvatarRepository(current: 'me/old.jpg'));
    expect(find.text('Make a new one'), findsOneWidget);
  });

  testWidgets('explains the daily limit', (tester) async {
    await pump(
      tester,
      FakeAvatarRepository(
        error: "You've made 5 avatars today. Try again tomorrow.",
      ),
    );

    await tester.tap(find.text('Generate my avatar'));
    await tester.pumpAndSettle();
    expect(
      find.text("You've made 5 avatars today. Try again tomorrow."),
      findsOneWidget,
    );
  });

  test('get_deck rows carry the avatar', () {
    final m = Musician.fromDeckRow({
      'id': 'x',
      'display_name': 'Ana',
      'age': 25,
      'avatar_path': 'x/1.jpg',
      'instruments': [],
    });
    expect(m.avatarPath, 'x/1.jpg');
  });
}
