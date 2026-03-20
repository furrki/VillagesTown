import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
      final File image = File('screenshots/$screenshotName.png');
      await image.parent.create(recursive: true);
      await image.writeAsBytes(screenshotBytes);
      return true;
    },
  );
}
