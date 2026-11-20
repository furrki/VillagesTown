import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:villages_town/ui/screens/battle/battlefield_painter.dart';

Future<Uint8List> render(BattlefieldPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(Offset.zero & size);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = picture.toImageSync(size.width.toInt(), size.height.toInt());
  try {
    return (await image.toByteData())!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fixed scenery is reused until size or terrain changes', () async {
    final cache = BattlefieldSceneryCache();
    addTearDown(cache.dispose);

    ui.Picture paint(Size size, TerrainType terrain, double time) {
      final recorder = ui.PictureRecorder();
      BattlefieldPainter(
        terrain: terrain,
        isSiege: false,
        time: time,
        particles: [],
        sceneryCache: cache,
      ).paint(Canvas(recorder), size);
      recorder.endRecording().dispose();
      return cache.backgroundPicture!;
    }

    const size = Size(240, 400);
    final forest = paint(size, TerrainType.forest, 0);
    expect(paint(size, TerrainType.forest, 1), same(forest));
    const larger = Size(280, 400);
    final resized = paint(larger, TerrainType.forest, 1);
    expect(resized, isNot(same(forest)));
    final coastal = paint(larger, TerrainType.coastal, 1);
    expect(coastal, isNot(same(resized)));
    cache.dispose();
    expect(cache.backgroundPicture, isNull);
  });

  test('cached forest, coast and siege match direct rendering', () async {
    const size = Size(240, 400);
    final cache = BattlefieldSceneryCache();
    addTearDown(cache.dispose);

    Future<Uint8List> frame(
      TerrainType terrain, {
      double time = 0,
      double city = 0,
      double flag = 0,
      double particleX = 40,
    }) async {
      BattlefieldPainter painter({BattlefieldSceneryCache? cache}) =>
          BattlefieldPainter(
            terrain: terrain,
            isSiege: terrain == TerrainType.city,
            time: time,
            cityProgress: city,
            flagRaiseProgress: flag,
            particles: [
              AtmosphericParticle(
                position: Offset(particleX, 100),
                velocity: Offset.zero,
                size: 12,
                opacity: 0.7,
                color: Colors.orange,
              ),
            ],
            sceneryCache: cache,
          );
      final cached = await render(painter(cache: cache), size);
      final direct = await render(painter(), size);
      expect(
        cached,
        orderedEquals(direct),
        reason: '$terrain at $time/$city/$flag',
      );
      return cached;
    }

    final forest = await frame(TerrainType.forest);
    final movingParticle = await frame(TerrainType.forest, particleX: 80);
    expect(movingParticle, isNot(orderedEquals(forest)));
    final coast = await frame(TerrainType.coastal);
    final waves = await frame(TerrainType.coastal, time: 0.3);
    expect(waves, isNot(orderedEquals(coast)));
    final walls = await frame(TerrainType.city);
    final interior = await frame(TerrainType.city, city: 0.8);
    expect(interior, isNot(orderedEquals(walls)));
    final raisedFlag = await frame(TerrainType.city, city: 0.8, flag: 0.9);
    expect(raisedFlag, isNot(orderedEquals(interior)));
  });
}
