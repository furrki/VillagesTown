import 'package:flutter/material.dart';

enum Resource {
  food('Food', '🌾', Colors.green),
  wood('Wood', '🪵', Colors.brown),
  iron('Iron', '⚔️', Colors.grey),
  gold('Gold', '💰', Colors.amber);

  final String displayName;
  final String emoji;
  final Color color;

  const Resource(this.displayName, this.emoji, this.color);
}
