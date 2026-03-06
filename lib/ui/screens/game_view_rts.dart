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
  bool _showTravelPicker = false;
  bool _showWarband = false;
  bool _showCargo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = GameManager.shared;
      if (!game.gameStarted) {
        game.initializeGame();
      }
    });
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

    // If at a city and tapped a connected city, start travel
    if (pc.state == PlayerState.atCity && pc.currentCityId != null) {
      if (game.areNeighbors(pc.currentCityId!, village.id)) {
        game.startTravel(village.id);
        setState(() => _showTravelPicker = false);
      } else {
        _showToast('Not connected to ${game.getVillageDisplayName(village)}');
      }
    }
  }

  void _openTravelPicker() {
    setState(() => _showTravelPicker = !_showTravelPicker);
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

        // If at city, show full city screen
        if (pc.state == PlayerState.atCity && game.playerCurrentCity != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                CityScreen(
                  city: game.playerCurrentCity!,
                  player: pc,
                  onLeave: _openTravelPicker,
                  showToast: _showToast,
                ),
                // Travel picker overlay (centered on screen)
                if (_showTravelPicker)
                  _buildCityTravelPicker(game),
                // Toast
                if (_toastMessage != null) _buildToast(),
                // Game over overlay
                if (game.isGameOver)
                  const Positioned.fill(
                    child: GameOverOverlay(),
                  ),
              ],
            ),
          );
        }

        // Traveling view: map + travel panel
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Map (full screen) + bottom travel panel
              Column(
                children: [
                  Expanded(child: _buildMap(game, pc)),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: TravelPanel(
                      player: pc,
                      encounter: game.currentEncounter,
                      onDismissEncounter: () => game.dismissEncounter(),
                      showToast: _showToast,
                    ),
                  ),
                ],
              ),
              // HUD overlay
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

  Widget _buildCityTravelPicker(GameManager game) {
    final destinations = game.travelDestinations;
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.2,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.blue, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Travel to...',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showTravelPicker = false),
                      child: const Icon(Icons.close, color: Colors.white38, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF333333)),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final dest = destinations[index];
                    final name = game.getVillageDisplayName(dest);
                    final owner = dest.owner == 'neutral'
                        ? 'Neutral'
                        : game.getNationality(dest.owner)?.name ?? dest.owner;
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('$owner | ${dest.trait.name}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                      onTap: () {
                        game.startTravel(dest.id);
                        setState(() => _showTravelPicker = false);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
