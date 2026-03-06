import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/layout_constants.dart';
import '../../data/models/army.dart';
import '../../data/models/building.dart';
import '../../data/models/combat_log.dart';
import '../../data/models/unit_type.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../engines/building_construction_engine.dart';
import '../../engines/recruitment_engine.dart';
import '../../providers/game_provider.dart';
import '../map/map_view.dart';
import '../panels/side_info_panel.dart';
import 'victory_screen.dart';
import 'battle/countryball_battle_screen.dart';
import 'battle/battle_test_screen.dart';

class DesktopGameView extends StatefulWidget {
  const DesktopGameView({super.key});

  @override
  State<DesktopGameView> createState() => _DesktopGameViewState();
}

class _DesktopGameViewState extends State<DesktopGameView> {
  Village? _selectedVillage;
  Army? _selectedArmy;
  bool _isProcessingTurn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = GameManager.shared;
      if (!game.gameStarted) {
        game.initializeGame();
      }
      final playerVillages = game.getPlayerVillages('player');
      if (playerVillages.isNotEmpty) {
        setState(() => _selectedVillage = playerVillages.first);
      }
    });
  }

  Village? get _currentVillage {
    if (_selectedVillage == null) return null;
    return GameManager.shared.getVillageById(_selectedVillage!.id);
  }

  void _processTurn() {
    setState(() => _isProcessingTurn = true);
    LayoutConstants.impactFeedback(style: HapticStyle.medium);

    Future.delayed(const Duration(milliseconds: 100), () {
      GameManager.shared.turnEngine.doTurn();
      if (mounted) {
        setState(() {
          _isProcessingTurn = false;
          if (_selectedVillage != null) {
            _selectedVillage = _currentVillage;
          }
        });
      }
    });
  }

  void _selectVillage(Village village) {
    final game = GameManager.shared;

    // If army is selected and tapped village is a valid march target, send the army
    if (_selectedArmy != null && _selectedArmy!.stationedAt != null) {
      final armyOrigin = _selectedArmy!.stationedAt!;
      if (armyOrigin != village.id && game.areNeighbors(armyOrigin, village.id)) {
        game.sendArmy(_selectedArmy!.id, village.id);
        setState(() {
          _selectedArmy = null;
          _selectedVillage = game.map.villages.firstWhere((v) => v.id == armyOrigin);
        });
        return;
      }
    }

    setState(() {
      _selectedVillage = village;
      _selectedArmy = null;
    });
  }

  void _selectArmy(Army army) {
    setState(() {
      _selectedArmy = army;
      _selectedVillage = null;
    });
  }

  void _quickBuild(Building building, Village village) {
    final game = GameManager.shared;
    if (BuildingConstructionEngine().buildBuilding(building, village)) {
      setState(() => _selectedVillage = game.map.villages.firstWhere((v) => v.id == village.id));
    }
  }

  void _quickUpgrade(Building building, Village village) {
    final game = GameManager.shared;
    if (BuildingConstructionEngine().upgradeBuilding(building.id, village)) {
      setState(() => _selectedVillage = game.map.villages.firstWhere((v) => v.id == village.id));
    }
  }

  void _quickRecruit(UnitType type, Village village) {
    final game = GameManager.shared;
    final units = RecruitmentEngine().recruitUnits(type, 1, village, village.coordinates);
    if (units.isNotEmpty) {
      setState(() => _selectedVillage = game.map.villages.firstWhere((v) => v.id == village.id));
    }
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
      _processTurn();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _selectedVillage = null;
        _selectedArmy = null;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.digit1) {
      _selectPlayerVillage(0);
    } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
      _selectPlayerVillage(1);
    } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
      _selectPlayerVillage(2);
    } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
      _selectPlayerVillage(3);
    } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BattleTestScreen()),
      );
    }
  }

  void _selectPlayerVillage(int index) {
    final playerVillages = GameManager.shared.getPlayerVillages('player');
    if (index < playerVillages.length) {
      _selectVillage(playerVillages[index]);
    }
  }

  BattleRecord? _getPlayerBattle(GameManager game) {
    for (final battle in game.pendingBattles) {
      if (battle.attackerOwnerId == 'player' || battle.defenderOwnerId == 'player') {
        return battle;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;

        // Check for victory
        final winner = game.getWinner();
        if (winner != null) {
          return VictoryScreen(winner: winner);
        }

        return KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: _handleKeyPress,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Row(
                  children: [
                    // Map Section
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A2A1A), Color(0xFF0D1A0D), Color(0xFF152015)],
                          ),
                        ),
                        child: MapView(
                          selectedVillage: _selectedVillage,
                          selectedArmy: _selectedArmy,
                          onVillageSelected: _selectVillage,
                          onArmySelected: _selectArmy,
                          onArmySent: (army, destination) {
                            game.sendArmy(army.id, destination.id);
                          },
                        ),
                      ),
                    ),
                    // Side Panel
                    SizedBox(
                      width: 320,
                      child: SideInfoPanel(
                        selectedVillage: _currentVillage,
                        selectedArmy: _selectedArmy,
                        onEndTurn: _processTurn,
                        isProcessingTurn: _isProcessingTurn,
                        onBuild: _currentVillage != null ? (b) => _quickBuild(b, _currentVillage!) : null,
                        onUpgrade: _currentVillage != null ? (b) => _quickUpgrade(b, _currentVillage!) : null,
                        onRecruit: _currentVillage != null ? (t) => _quickRecruit(t, _currentVillage!) : null,
                        onSelectArmy: _selectArmy,
                      ),
                    ),
                  ],
                ),
                // Battle Screen Overlay
                if (_getPlayerBattle(game) != null)
                  CountryballBattleScreen(
                    key: ValueKey(_getPlayerBattle(game)!.id),
                    record: _getPlayerBattle(game)!,
                    onDismiss: () => setState(() {}),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
