// Start must not replace the only save unasked. Board Appgea/ops#30.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/data/models/nationality.dart';
import 'package:villages_town/ui/screens/nationality_selection_screen.dart';

void main() {
  Future<List<Nationality>> start(WidgetTester tester, {required bool hasSave, String? answer}) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final picked = <Nationality>[];
    await tester.pumpWidget(MaterialApp(
      home: NationalitySelectionScreen(hasSavedGame: hasSave, onContinue: () {}, onSelect: picked.add),
    ));
    await tester.tap(find.text(Nationality.ottomans.name.toUpperCase()).first, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('START CONQUEST'));
    await tester.pumpAndSettle();
    if (answer != null) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }
    return picked;
  }

  testWidgets('a save asks first, and Keep Save keeps it', (tester) async {
    expect(await start(tester, hasSave: true, answer: 'Keep Save'), isEmpty);
  });

  testWidgets('Start New goes on', (tester) async {
    expect(await start(tester, hasSave: true, answer: 'Start New'), [Nationality.ottomans]);
  });

  testWidgets('no save, no question', (tester) async {
    expect(await start(tester, hasSave: false), [Nationality.ottomans]);
  });
}
