import 'package:flutter/material.dart';
import '../../data/models/character_origin.dart';
import '../../data/models/nationality.dart';
import '../components/countryball_avatar.dart';

class OriginSelectionScreen extends StatefulWidget {
  final Nationality nationality;
  final String characterName;
  final void Function(CharacterOrigin origin) onSelect;

  const OriginSelectionScreen({
    super.key,
    required this.nationality,
    required this.characterName,
    required this.onSelect,
  });

  @override
  State<OriginSelectionScreen> createState() => _OriginSelectionScreenState();
}

class _OriginSelectionScreenState extends State<OriginSelectionScreen> {
  CharacterOriginType? _selectedType;

  static const _bgColor = Color(0xFF11141C);
  static const _cardColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final origins = CharacterOrigin.all();

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    // Header
                    Text(
                      'YOUR STORY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Character identity row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CountryballAvatar(
                          size: 40,
                          nationality: widget.nationality,
                          borderColor: widget.nationality.color,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.characterName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Origin cards
                    ...origins.map((origin) {
                      final isSelected = _selectedType == origin.type;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = isSelected ? null : origin.type;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber.withValues(alpha: 0.08)
                                  : _cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.amber
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + icon row
                                Row(
                                  children: [
                                    Icon(
                                      _iconForOrigin(origin.type),
                                      size: 18,
                                      color: isSelected
                                          ? Colors.amber
                                          : Colors.white.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        origin.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.amber.withValues(alpha: 0.8),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Short description (always visible)
                                Text(
                                  origin.shortDescription,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.45),
                                    height: 1.3,
                                  ),
                                ),

                                // Expanded content
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: _buildExpandedContent(origin),
                                  crossFadeState: isSelected
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 250),
                                  sizeCurve: Curves.easeOut,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedType != null
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: ValueKey(_selectedType),
                          onPressed: () {
                            final origin = origins.firstWhere(
                              (o) => o.type == _selectedType,
                            );
                            widget.onSelect(origin);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: _bgColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 8,
                            shadowColor: Colors.amber.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'BEGIN JOURNEY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 50,
                        child: Center(
                          child: Text(
                            'Choose your origin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.25),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(CharacterOrigin origin) {
    final bonuses = _collectBonuses(origin);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              origin.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stat bonus pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: bonuses.map((b) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: b.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: b.color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(b.icon, size: 13, color: b.color),
                    const SizedBox(width: 5),
                    Text(
                      b.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: b.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<_BonusInfo> _collectBonuses(CharacterOrigin origin) {
    final list = <_BonusInfo>[];

    if (origin.bonusCombat > 0) {
      list.add(_BonusInfo(
        icon: Icons.sports_martial_arts,
        label: '+${origin.bonusCombat} Combat',
        color: const Color(0xFFEF5350),
      ));
    }
    if (origin.bonusLeadership > 0) {
      list.add(_BonusInfo(
        icon: Icons.groups,
        label: '+${origin.bonusLeadership} Leadership',
        color: const Color(0xFF42A5F5),
      ));
    }
    if (origin.bonusTactics > 0) {
      list.add(_BonusInfo(
        icon: Icons.shield,
        label: '+${origin.bonusTactics} Tactics',
        color: const Color(0xFF66BB6A),
      ));
    }
    if (origin.bonusTrade > 0) {
      list.add(_BonusInfo(
        icon: Icons.monetization_on,
        label: '+${origin.bonusTrade} Trade',
        color: const Color(0xFFFFCA28),
      ));
    }
    if (origin.bonusScouting > 0) {
      list.add(_BonusInfo(
        icon: Icons.visibility,
        label: '+${origin.bonusScouting} Scouting',
        color: const Color(0xFF26C6DA),
      ));
    }
    if (origin.bonusGold > 0) {
      list.add(_BonusInfo(
        icon: Icons.paid,
        label: '+${origin.bonusGold} Gold',
        color: const Color(0xFFFFB74D),
      ));
    }
    if (origin.bonusMilitia > 0) {
      list.add(_BonusInfo(
        icon: Icons.people,
        label: '+${origin.bonusMilitia} Militia',
        color: const Color(0xFF8D6E63),
      ));
    }
    if (origin.bonusSwordsmen > 0) {
      list.add(_BonusInfo(
        icon: Icons.sports_martial_arts,
        label: '+${origin.bonusSwordsmen} Swordsmen',
        color: const Color(0xFFE57373),
      ));
    }
    if (origin.startsWithPackMule) {
      list.add(_BonusInfo(
        icon: Icons.inventory_2,
        label: '+1 Pack Mule',
        color: const Color(0xFFA1887F),
      ));
    }

    return list;
  }

  IconData _iconForOrigin(CharacterOriginType type) {
    switch (type) {
      case CharacterOriginType.exiledNoble:
        return Icons.castle;
      case CharacterOriginType.merchantSon:
        return Icons.storefront;
      case CharacterOriginType.deserter:
        return Icons.directions_run;
      case CharacterOriginType.pilgrim:
        return Icons.explore;
    }
  }
}

class _BonusInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _BonusInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}
