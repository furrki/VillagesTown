import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/player_character.dart';
import '../../data/models/village.dart';
import '../../engines/game_manager.dart';
import '../../providers/game_provider.dart';
import '../map/map_view.dart';
import '../panels/cargo_panel.dart';
import '../panels/travel_panel.dart';
import 'city_screen.dart';
import '../panels/warband_panel.dart';
import '../components/rts_hud.dart';
import '../components/game_over_overlay.dart';
import 'battle/countryball_battle_screen.dart';

class RtsGameView extends StatefulWidget {
  const RtsGameView({super.key});

  @override
  State<RtsGameView> createState() => _RtsGameViewState();
}

class _RtsGameViewState extends State<RtsGameView> {
  String? _toastMessage;
  bool _showWarband = false;
  bool _showCargo = false;
  bool _showCityPanel = true;

  @override
  void initState() {
    super.initState();
  }

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _onVillageTapped(Village village) {
    final game = GameManager.shared;
    final pc = game.playerCharacter;
    if (pc == null) return;

    if (pc.state == PlayerState.atCity && pc.currentCityId != null) {
      if (village.id == pc.currentCityId) {
        // Tapped current city — toggle city panel
        setState(() => _showCityPanel = !_showCityPanel);
      } else if (game.areNeighbors(pc.currentCityId!, village.id)) {
        // Tapped connected city — just go there, Bannerlord style
        game.startTravel(village.id);
        setState(() => _showCityPanel = false);
      } else {
        _showToast('No road to ${game.getVillageDisplayName(village)}');
      }
    }
  }

  void _leaveCity() {
    // Just close city panel so player sees the map and can tap a destination
    setState(() => _showCityPanel = false);
  }

  void _showMenuDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Return to Menu', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                final game = GameManager.shared;
                game.resetGame();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Track previous state to auto-open city panel on arrival
  PlayerState? _prevState;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final game = provider.gameManager;
        final pc = game.playerCharacter;

        if (pc == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Consume pending notifications from game engine
        if (game.pendingNotifications.isNotEmpty) {
          final notifications = List<String>.from(game.pendingNotifications);
          game.pendingNotifications.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final msg in notifications) {
              _showToast(msg);
            }
          });
        }

        // Auto-open city panel when arriving at a city
        if (_prevState == PlayerState.traveling && pc.state == PlayerState.atCity) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showCityPanel = true);
          });
        }
        _prevState = pc.state;

        final isAtCity = pc.state == PlayerState.atCity && game.playerCurrentCity != null;
        final isTraveling = pc.state == PlayerState.traveling;
        final screenHeight = MediaQuery.of(context).size.height;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Map — always full screen
              Positioned.fill(
                child: _buildMap(game, pc),
              ),

              // Bottom panel: city or travel
              if (isAtCity && _showCityPanel)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: screenHeight * 0.55,
                  child: _buildCityBottomPanel(game, pc),
                ),

              if (isTraveling)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: screenHeight * 0.40),
                        child: TravelPanel(
                          player: pc,
                          encounter: game.currentEncounter,
                          onDismissEncounter: () => game.dismissEncounter(),
                          showToast: _showToast,
                        ),
                      ),
                    ],
                  ),
                ),

              // Hint bar when map is visible at city (city panel closed)
              if (isAtCity && !_showCityPanel)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  child: _buildMapHintBar(game),
                ),

              // HUD overlay — always on top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RtsHud(
                  onWarbandTap: () => setState(() { _showWarband = !_showWarband; _showCargo = false; }),
                  onCargoTap: () => setState(() { _showCargo = !_showCargo; _showWarband = false; }),
                  onMenuTap: () => _showMenuDialog(),
                ),
              ),

              // Warband panel overlay
              if (_showWarband)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: WarbandPanel(
                      onClose: () => setState(() => _showWarband = false),
                    ),
                  ),
                ),

              // Cargo panel overlay
              if (_showCargo)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: CargoPanel(
                      player: pc,
                      onClose: () => setState(() => _showCargo = false),
                    ),
                  ),
                ),

              // Toast
              if (_toastMessage != null) _buildToast(),

              // Battle screen overlay
              if (game.pendingBattles.any((b) =>
                  b.attackerOwnerId == 'player' || b.defenderOwnerId == 'player'))
                CountryballBattleScreen(
                  key: ValueKey(game.pendingBattles
                      .firstWhere((b) =>
                          b.attackerOwnerId == 'player' || b.defenderOwnerId == 'player')
                      .id),
                  record: game.pendingBattles.firstWhere((b) =>
                      b.attackerOwnerId == 'player' || b.defenderOwnerId == 'player'),
                  onDismiss: () => setState(() {}),
                ),

              // Game over overlay
              if (game.isGameOver)
                const Positioned.fill(
                  child: GameOverOverlay(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(GameManager game, PlayerCharacter pc) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A1A), Color(0xFF0D1A0D), Color(0xFF152015)],
        ),
      ),
      child: MapView(
        selectedVillage: game.playerCurrentCity,
        onVillageSelected: _onVillageTapped,
        onArmySelected: (_) {},
      ),
    );
  }

  /// Bottom panel for city — pixel art header + tabs
  Widget _buildCityBottomPanel(GameManager game, PlayerCharacter pc) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CityScreen(
                city: game.playerCurrentCity!,
                player: pc,
                onLeave: _leaveCity,
                showToast: _showToast,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hint bar when looking at map from city — tells player to tap a city
  Widget _buildMapHintBar(GameManager game) {
    final cityName = game.getVillageDisplayName(game.playerCurrentCity!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showCityPanel = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  cityName,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_up, color: Colors.white38, size: 18),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Tap a city to travel',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildToast() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _toastMessage != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _toastMessage ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
