import 'package:flutter/material.dart';

class Nationality {
  final String id;
  final String name;
  final String assetPath;
  final Color color;
  final bool isRectangular;

  const Nationality({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.color,
    this.isRectangular = false,
  });

  static const ottomans = Nationality(
    id: 'ottoman',
    name: 'Ottomans',
    assetPath: 'assets/ottoman.png',
    color: Color(0xFF2E7D32),
    isRectangular: true,
  );

  static const byzantines = Nationality(
    id: 'byzantine',
    name: 'Byzantines',
    assetPath: 'assets/byzantium.png',
    color: Color(0xFF7B1FA2),
    isRectangular: false,
  );

  static const crusaders = Nationality(
    id: 'crusader',
    name: 'Crusaders',
    assetPath: 'assets/crusaders.png',
    color: Color(0xFFD32F2F),
    isRectangular: true,
  );

  static List<Nationality> getAll() => [ottomans, byzantines, crusaders];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nationality && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
