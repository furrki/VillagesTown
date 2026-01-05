import 'package:flutter/material.dart';
import '../../data/models/nationality.dart';
import '../../core/constants/layout_constants.dart';

class NationalitySelectionScreen extends StatefulWidget {
  final void Function(Nationality) onSelect;

  const NationalitySelectionScreen({super.key, required this.onSelect});

  @override
  State<NationalitySelectionScreen> createState() => _NationalitySelectionScreenState();
}

class _NationalitySelectionScreenState extends State<NationalitySelectionScreen> {
  Nationality? _selectedNationality;

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
              Text(
                'CHOOSE YOUR EMPIRE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                  color: Colors.white.withOpacity(0.9),
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

              const SizedBox(height: 32),

              // Start Button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedNationality != null
                    ? ElevatedButton(
                        key: ValueKey(_selectedNationality!.id),
                        onPressed: () {
                          LayoutConstants.impactFeedback(style: HapticStyle.heavy);
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
    final size = isMajor ? 100.0 : 70.0;
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
