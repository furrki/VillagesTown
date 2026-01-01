import 'package:flutter/material.dart';
import '../../data/models/village.dart';
import '../theme/app_theme.dart';
import '../components/owner_flag_view.dart';

class VillageMarker extends StatelessWidget {
  final Village village;
  final bool isSelected;
  final int armyStrength;
  final bool hasThreat;
  final VoidCallback onTap;

  const VillageMarker({
    super.key,
    required this.village,
    required this.isSelected,
    required this.armyStrength,
    required this.hasThreat,
    required this.onTap,
  });

  Color get ownerColor => AppTheme.ownerColor(village.owner);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Selection ring
            if (isSelected)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ownerColor, width: 3),
                ),
              ),
            // Threat pulse
            if (hasThreat)
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
              ),
            // Main circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? ownerColor : Colors.black.withOpacity(0.8),
                border: Border.all(color: ownerColor, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OwnerFlagView(owner: village.owner, size: 28),
                  Text(
                    village.name,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Army badge
            if (armyStrength > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$armyStrength',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
