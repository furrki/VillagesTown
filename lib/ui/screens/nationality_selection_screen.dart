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
    final nationalities = Nationality.getAll();
    final isCompact = LayoutConstants.isPhone(context);

    return Scaffold(
      backgroundColor: const Color(0xFF11141C), // Deep dark background
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            
            // 1. Header
            Text(
              'CHOOSE YOUR EMPIRE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: Colors.white.withOpacity(0.9),
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
            ),
            
            const Spacer(),

            // 2. Compact Selection Pod (Centered)
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? 340 : 800,
                  maxHeight: isCompact ? 450 : 400,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Flex(
                      direction: isCompact ? Axis.vertical : Axis.horizontal,
                      children: nationalities.map((n) {
                        final isSelected = _selectedNationality == n;
                        final flex = isSelected ? 4 : 3;

                        return Expanded(
                          flex: flex,
                          child: GestureDetector(
                            onTap: () => _selectNationality(n),
                            child: _buildNationPanel(n, isSelected),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 3. Start Button
            SizedBox(
              height: 80, // Fixed height area for button to avoid layout shifts
              child: Center(
                child: AnimatedSwitcher(
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
                          child: Text(
                            'START CONQUEST',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ),
            
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildNationPanel(Nationality n, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: n.color,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [
                  n.color.withOpacity(0.9),
                  n.color.withOpacity(0.7),
                ]
              : [
                  n.color.withOpacity(0.2), // Much darker/dimmer when inactive
                  Colors.black.withOpacity(0.7),
                ],
        ),
        border: isSelected
            ? Border(
                top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                // Handle side borders based on flex direction context if rigorous
              ) 
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Texture (Background Image)
          Positioned(
            right: -30,
            bottom: -30,
            child: Transform.rotate(
              angle: -0.2,
              child: Opacity(
                opacity: 0.2, 
                child: Image.asset(n.assetPath, width: 250, height: 250),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: n.isRectangular 
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: const Offset(0,4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            n.assetPath,
                            width: 140, 
                            height: 90, // Rectangular aspect
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : ClipOval(
                        child: Image.asset(
                          n.assetPath,
                          width: 100, 
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    n.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Flash effect
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
