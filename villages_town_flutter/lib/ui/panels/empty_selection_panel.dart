import 'package:flutter/material.dart';

class EmptySelectionPanel extends StatelessWidget {
  final VoidCallback onEndTurn;
  final bool isProcessingTurn;

  const EmptySelectionPanel({
    super.key,
    required this.onEndTurn,
    required this.isProcessingTurn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Icon(Icons.touch_app, size: 40, color: Colors.white.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(
          'Select a village on the map',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.5)),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: isProcessingTurn ? null : onEndTurn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isProcessingTurn)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else
                    const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  const Text('End Turn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
