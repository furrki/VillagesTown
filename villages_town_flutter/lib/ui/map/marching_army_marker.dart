import 'package:flutter/material.dart';
import '../../data/models/army.dart';

class MarchingArmyMarker extends StatelessWidget {
  final Army army;
  final bool isSelected;

  const MarchingArmyMarker({
    super.key,
    required this.army,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: army.owner == 'player' ? Colors.blue.withOpacity(0.9) : Colors.red.withOpacity(0.9),
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            army.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            '${army.turnsUntilArrival}t',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
