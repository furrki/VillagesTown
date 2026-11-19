import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/ui/screens/battle/battle_painter.dart';

void main() {
  testWidgets('the flag shadow is built once per radius', (tester) async {
    final first = BattlePainter.shadowSprite(12);
    expect(identical(first, BattlePainter.shadowSprite(12)), isTrue);
    expect(first.width, 96);
  });
}
