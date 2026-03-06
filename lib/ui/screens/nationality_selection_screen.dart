import 'package:flutter/material.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/game_modifier.dart';
import '../../data/models/nationality.dart';
import '../../data/models/victory_condition.dart';
import '../../core/constants/layout_constants.dart';
import '../../engines/game_manager.dart';
import 'stats_screen.dart';

class NationalitySelectionScreen extends StatefulWidget {
  final void Function(Nationality) onSelect;
  final bool hasSavedGame;
  final VoidCallback? onContinue;

  const NationalitySelectionScreen({
    super.key,
    required this.onSelect,
    this.hasSavedGame = false,
    this.onContinue,
  });

  @override
  State<NationalitySelectionScreen> createState() => _NationalitySelectionScreenState();
}

class _NationalitySelectionScreenState extends State<NationalitySelectionScreen> {
  Nationality? _selectedNationality;
  VictoryType _selectedVictory = VictoryType.domination;
  Difficulty _selectedDifficulty = Difficulty.normal;
  final Set<GameModifier> _activeModifiers = {};
  bool _showModifiers = false;

  void _selectNationality(Nationality nationality) {
    setState(() => _selectedNationality = nationality);
    LayoutConstants.selectionFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final majorFactions = Nationality.getMajor();
    final minorFactions = Nationality.getMinor();
    final isCompact = LayoutConstants.isPhone(context);

    return Scaffold(
      backgroundColor: const Color(0xFF11141C),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'CHOOSE YOUR EMPIRE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatsScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                              SizedBox(width: 4),
                              Text('STATS', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Major Factions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'MAJOR POWERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.amber.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: majorFactions.map((n) {
                        final isSelected = _selectedNationality == n;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () => _selectNationality(n),
                              child: _buildFactionCard(n, isSelected, isMajor: true),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Minor Factions Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'MINOR POWERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: minorFactions.map((n) {
                        final isSelected = _selectedNationality == n;
                        return SizedBox(
                          width: isCompact ? 80 : 100,
                          child: GestureDetector(
                            onTap: () => _selectNationality(n),
                            child: _buildFactionCard(n, isSelected, isMajor: false),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Victory Type Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'VICTORY CONDITION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: VictoryType.values.map((vt) {
                        final isSelected = _selectedVictory == vt;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedVictory = vt);
                            LayoutConstants.selectionFeedback();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.amber : Colors.white.withOpacity(0.1),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(vt.emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(
                                  vt.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.amber : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _selectedVictory.description,
                        key: ValueKey(_selectedVictory),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Difficulty Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'DIFFICULTY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: Difficulty.values.map((d) {
                        final isSelected = _selectedDifficulty == d;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedDifficulty = d);
                              LayoutConstants.selectionFeedback();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? d.color.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? d.color : Colors.white.withOpacity(0.1),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                d.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? d.color : Colors.white38,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedDifficulty.description,
                      style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.35)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Game Modifiers (collapsible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showModifiers = !_showModifiers),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'GAME MODIFIERS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_activeModifiers.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_activeModifiers.length}',
                                style: const TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            _showModifiers ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                    if (_showModifiers) ...[
                      const SizedBox(height: 10),
                      ...ModifierCategory.values.map((cat) {
                        final mods = GameModifier.values.where((m) => m.category == cat).toList();
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                cat.displayName,
                                style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.3), letterSpacing: 1.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: mods.map((mod) {
                                final isActive = _activeModifiers.contains(mod);
                                final hasConflict = mod.conflicts.any((c) => _activeModifiers.contains(c));
                                return GestureDetector(
                                  onTap: hasConflict && !isActive ? null : () {
                                    setState(() {
                                      if (isActive) {
                                        _activeModifiers.remove(mod);
                                      } else {
                                        _activeModifiers.add(mod);
                                      }
                                    });
                                    LayoutConstants.selectionFeedback();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.purple.withOpacity(0.2)
                                          : hasConflict
                                              ? Colors.white.withOpacity(0.02)
                                              : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isActive ? Colors.purpleAccent : Colors.white.withOpacity(hasConflict ? 0.05 : 0.1),
                                        width: isActive ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(mod.emoji, style: TextStyle(fontSize: 12, color: hasConflict && !isActive ? Colors.white24 : null)),
                                        const SizedBox(width: 4),
                                        Text(
                                          mod.displayName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive ? Colors.purpleAccent : hasConflict ? Colors.white24 : Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue saved game
              if (widget.hasSavedGame && widget.onContinue != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () {
                      LayoutConstants.impactFeedback(style: HapticStyle.medium);
                      widget.onContinue!();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                ),

              // Start Button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedNationality != null
                    ? ElevatedButton(
                        key: ValueKey(_selectedNationality!.id),
                        onPressed: () {
                          LayoutConstants.impactFeedback(style: HapticStyle.heavy);
                          GameManager.shared.selectedVictoryType = _selectedVictory;
                          GameManager.shared.difficulty = _selectedDifficulty;
                          GameManager.shared.activeModifiers = Set.from(_activeModifiers);
                          widget.onSelect(_selectedNationality!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _selectedNationality!.color,
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          elevation: 8,
                          shadowColor: _selectedNationality!.color.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'START CONQUEST',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    : const SizedBox(height: 50),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactionCard(Nationality n, bool isSelected, {required bool isMajor}) {
    final iconSize = isMajor ? 60.0 : 45.0;
    final fontSize = isMajor ? 11.0 : 9.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? n.color.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? n.color : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: n.color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: n.color, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                n.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: n.color,
                  child: Center(
                    child: Text(
                      n.name[0],
                      style: TextStyle(color: Colors.white, fontSize: iconSize * 0.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            n.name.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
