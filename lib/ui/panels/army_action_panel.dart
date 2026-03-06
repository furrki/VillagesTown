import 'package:flutter/material.dart';
import '../../data/models/army.dart';

class ArmyActionPanel extends StatelessWidget {
  final Army army;
  final VoidCallback onEndTurn;
  final VoidCallback? onCancel;
  final bool isProcessingTurn;

  const ArmyActionPanel({
    super.key,
    required this.army,
    required this.onEndTurn,
    this.onCancel,
    required this.isProcessingTurn,
  });

  @override
  Widget build(BuildContext context) {
    final isStationedAndReady = !army.isMarching && army.stationedAt != null;

    return Column(
      children: [
        // March instruction banner
        if (isStationedAndReady)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade800, Colors.amber.shade900],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tap a neighboring village to march',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (onCancel != null)
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withValues(alpha: 0.05),
          child: Column(
            children: [
              Row(
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
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  _buildEndTurnButton(),
                ],
              ),
              if (army.isMarching && army.turnsUntilArrival > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade800, Colors.blue.shade900],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${army.turnsUntilArrival} turn${army.turnsUntilArrival > 1 ? "s" : ""} to arrive',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              if (army.totalMarchTurns > 1) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Long march • ${((1.0 - army.marchFatigueModifier) * 100).toStringAsFixed(0)}% fatigue penalty',
                        style: const TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _statItem(Icons.people, '${army.unitCount}', 'Units')),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.1)),
              Expanded(child: _statItem(Icons.flash_on, '${army.strength}', 'Strength')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
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
