import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:villages_town/main.dart';
import 'package:villages_town/providers/game_provider.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameProvider(),
        child: const VillagesTownApp(),
      ),
    );

    // Verify the nationality selection screen loads
    expect(find.text('Villages Town'), findsOneWidget);
  });
}
