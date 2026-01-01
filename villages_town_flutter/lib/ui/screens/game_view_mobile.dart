import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/layout_constants.dart';
import '../../data/models/army.dart';
import '../../data/models/building.dart';
import '../../data/models/unit_type.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../engines/building_construction_engine.dart';
import '../../engines/recruitment_engine.dart';
import '../../providers/game_provider.dart';
import '../map/map_view.dart';
import '../panels/inline_village_panel.dart';
import '../panels/army_action_panel.dart';
import '../panels/empty_selection_panel.dart';
import '../components/floating_hud.dart';
import 'victory_screen.dart';

class MobileGameLayout extends StatefulWidget {
  const MobileGameLayout({super.key});

  @override
  State<MobileGameLayout> createState() => _MobileGameLayoutState();
}

class _MobileGameLayoutState extends State<MobileGameLayout> {
  Village? _selectedVillage;
  Army? _selectedArmy;
  bool _isProcessingTurn = false;
  String? _toastMessage;

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
    return GameManager.shared.map.villages.cast<Village?>().firstWhere(
          (v) => v!.id == _selectedVillage!.id,
          orElse: () => null,
        );
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _processTurn() {
    setState(() => _isProcessingTurn = true);
    LayoutConstants.impactFeedback(style: HapticStyle.medium);

    Future.delayed(const Duration(milliseconds: 100), () {
      GameManager.shared.turnEngine.doTurn();
      if (mounted) {
        setState(() {
          _isProcessingTurn = false;
          // Refresh selection
          if (_selectedVillage != null) {
            _selectedVillage = _currentVillage;
          }
        });
      }
    });
  }

  void _selectVillage(Village village) {
    LayoutConstants.selectionFeedback();
    setState(() {
      _selectedVillage = village;
      _selectedArmy = null;
    });
  }

  void _selectArmy(Army army) {
    LayoutConstants.selectionFeedback();
    setState(() {
      _selectedArmy = army;
      _selectedVillage = null;
    });
  }

  void _quickBuild(Building building, Village village) {
    final game = GameManager.shared;
    if (BuildingConstructionEngine().buildBuilding(building, village)) {
      setState(() => _selectedVillage = game.map.villages.firstWhere((v) => v.id == village.id));
      _showToast('Built ${building.name}');
    } else {
      _showToast("Can't build - check resources");
    }
  }

  void _quickUpgrade(Building building, Village village) {
    final game = GameManager.shared;
    if (BuildingConstructionEngine().upgradeBuilding(building.id, village)) {
      setState(() => _selectedVillage = game.map.villages.firstWhere((v) => v.id == village.id));
      _showToast('${building.name} upgraded');
    } else {
      _showToast("Can't upgrade - check resources");
    }
  }

  void _quickRecruit(UnitType type, Village village) {
    final game = GameManager.shared;
    final units = RecruitmentEngine().recruitUnits(type, 1, village, village.coordinates);
    if (units.isNotEmpty) {
      setState(() => _selectedVillage = game.map.villages.firstWhere((v) => v.id == village.id));
      _showToast('Recruited ${type.displayName}');
    } else {
      _showToast("Can't recruit - check requirements");
    }
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

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Column(
                children: [
                  // Map Section (50%)
                  Expanded(
                    child: _buildMapSection(game),
                  ),
                  // Divider
                  Container(height: 1, color: Colors.white.withOpacity(0.15)),
                  // Action Panel (50%)
                  Expanded(
                    child: _buildActionPanel(game),
                  ),
                ],
              ),
              // Toast overlay
              if (_toastMessage != null) _buildToast(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapSection(GameManager game) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF1A2A1A),
          child: MapView(
            selectedVillage: _selectedVillage,
            selectedArmy: _selectedArmy,
            onVillageSelected: _selectVillage,
            onArmySelected: _selectArmy,
            onArmySent: (army, destination) {
              game.sendArmy(army.id, destination.id);
              _showToast('Army marching to ${destination.name}');
            },
          ),
        ),
        // Floating HUD
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 10,
          right: 10,
          child: const FloatingHUD(),
        ),
      ],
    );
  }

  Widget _buildActionPanel(GameManager game) {
    return Container(
      color: const Color(0xFF141414),
      child: _currentVillage != null
          ? InlineVillagePanel(
              village: _currentVillage!,
              onBuild: (b) => _quickBuild(b, _currentVillage!),
              onUpgrade: (b) => _quickUpgrade(b, _currentVillage!),
              onRecruit: (t) => _quickRecruit(t, _currentVillage!),
              onSendArmy: () {
                // TODO: Show send army sheet
              },
              onEndTurn: _processTurn,
              isProcessingTurn: _isProcessingTurn,
              showToast: _showToast,
            )
          : _selectedArmy != null
              ? ArmyActionPanel(
                  army: _selectedArmy!,
                  onEndTurn: _processTurn,
                  isProcessingTurn: _isProcessingTurn,
                )
              : EmptySelectionPanel(
                  onEndTurn: _processTurn,
                  isProcessingTurn: _isProcessingTurn,
                ),
    );
  }

  Widget _buildToast() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.46,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _toastMessage != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _toastMessage ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
