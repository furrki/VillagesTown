import 'package:flutter/foundation.dart';
import '../engines/game_manager.dart';

class GameProvider extends ChangeNotifier {
  final GameManager _gameManager = GameManager.shared;

  GameManager get gameManager => _gameManager;

  GameProvider() {
    _gameManager.addListener(_onGameManagerChange);
  }

  void _onGameManagerChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _gameManager.removeListener(_onGameManagerChange);
    super.dispose();
  }
}
