import 'package:flutter/material.dart';
import '../../data/models/army.dart';

class ArmyActionPanel extends StatelessWidget {
  final Army army;
  final VoidCallback onEndTurn;
  final bool isProcessingTurn;

  const ArmyActionPanel({
    super.key,
    required this.army,
    required this.onEndTurn,
    required this.isProcessingTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.05),
          child: Row(
            children: [
              Text(army.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      army.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      army.isMarching ? 'Marching • ${army.turnsUntilArrival} turns' : '${army.unitCount} units',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              _buildEndTurnButton(),
            ],
          ),
        ),
        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _statItem(Icons.people, '${army.unitCount}', 'Units')),
              Container(width: 1, height: 50, color: Colors.white.withOpacity(0.1)),
              Expanded(child: _statItem(Icons.flash_on, '${army.strength}', 'Strength')),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4))),
      ],
    );
  }

  Widget _buildEndTurnButton() {
    return GestureDetector(
      onTap: isProcessingTurn ? null : onEndTurn,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isProcessingTurn)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            const Text('End Turn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
