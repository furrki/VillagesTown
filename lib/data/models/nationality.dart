import 'package:flutter/material.dart';

class Nationality {
  final String id;
  final String name;
  final String assetPath;
  final Color color;
  final bool isMajor;
  final double aggression; // 0.0 = passive, 1.0 = very aggressive

  const Nationality({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.color,
    this.isMajor = true,
    this.aggression = 0.7,
  });

  // === MAJOR FACTIONS ===
  static const ottomans = Nationality(
    id: 'ottoman',
    name: 'Ottomans',
    assetPath: 'assets/ottoman.png',
    color: Color(0xFF2E7D32),
    isMajor: true,
    aggression: 0.75,
  );

  static const byzantines = Nationality(
    id: 'byzantine',
    name: 'Byzantines',
    assetPath: 'assets/byzantium.png',
    color: Color(0xFF7B1FA2),
    isMajor: true,
    aggression: 0.6,
  );

  static const crusaders = Nationality(
    id: 'crusader',
    name: 'Crusaders',
    assetPath: 'assets/crusaders.png',
    color: Color(0xFFD32F2F),
    isMajor: true,
    aggression: 0.7,
  );

  // === MINOR FACTIONS ===
  static const bulgaria = Nationality(
    id: 'bulgarian',
    name: 'Bulgaria',
    assetPath: 'assets/bulgar.png',
    color: Color(0xFF4E342E), // Brown
    isMajor: false,
    aggression: 0.4,
  );

  static const serbia = Nationality(
    id: 'serbian',
    name: 'Serbia',
    assetPath: 'assets/srb.png',
    color: Color(0xFFC62828), // Dark red
    isMajor: false,
    aggression: 0.45,
  );

  static const armenia = Nationality(
    id: 'armenian',
    name: 'Armenia',
    assetPath: 'assets/armenia.png',
    color: Color(0xFFFF8F00), // Orange/Apricot
    isMajor: false,
    aggression: 0.35,
  );

  static const mamluks = Nationality(
    id: 'mamluk',
    name: 'Mamluks',
    assetPath: 'assets/mamluk.png',
    color: Color(0xFFFBC02D), // Gold/Yellow
    isMajor: false,
    aggression: 0.5,
  );

  static List<Nationality> getMajor() => [byzantines, ottomans, crusaders];
  static List<Nationality> getMinor() => [bulgaria, serbia, armenia, mamluks];
  static List<Nationality> getAll() => [...getMajor(), ...getMinor()];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nationality && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
