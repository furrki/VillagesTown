import 'dart:async';

import '../data/models/encounter.dart';

enum GameSpeed { paused, normal, fast, fastest }

class GameLoop {
  Timer? _timer;
  GameSpeed speed = GameSpeed.paused;
  int _tickCount = 0;

  void Function()? onTick;
  void Function(Encounter)? onEncounter;
  void Function(String)? onArrival;
  void Function()? onWorldEvent;

  int get tickCount => _tickCount;
  set tickCount(int v) { _tickCount = v; }

  Duration get _tickDuration => switch (speed) {
    GameSpeed.paused => Duration.zero,
    GameSpeed.normal => const Duration(milliseconds: 1000),
    GameSpeed.fast => const Duration(milliseconds: 500),
    GameSpeed.fastest => const Duration(milliseconds: 250),
  };

  void start() {
    speed = GameSpeed.normal;
    _restartTimer();
  }

  void pause() {
    speed = GameSpeed.paused;
    _timer?.cancel();
  }

  void setSpeed(GameSpeed newSpeed) {
    speed = newSpeed;
    _restartTimer();
  }

  void dispose() {
    _timer?.cancel();
  }

  void _onTimerTick() {
    if (speed == GameSpeed.paused) return;
    _tickCount++;
    onTick?.call();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (speed == GameSpeed.paused) return;
    _timer = Timer.periodic(_tickDuration, (_) => _onTimerTick());
  }
}
