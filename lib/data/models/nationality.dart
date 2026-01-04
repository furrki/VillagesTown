import 'package:flutter/material.dart';

class Nationality {
  final String id;
  final String name;
  final String flag;
  final Color color;

  const Nationality({
    required this.id,
    required this.name,
    required this.flag,
    required this.color,
  });

  static const ottomans = Nationality(
    id: 'ottoman',
    name: 'Ottomans',
    flag: '☪️',
    color: Color(0xFF2E7D32),
  );

  static const byzantines = Nationality(
    id: 'byzantine',
    name: 'Byzantines',
    flag: '🦅',
    color: Color(0xFF7B1FA2),
  );

  static const crusaders = Nationality(
    id: 'crusader',
    name: 'Crusaders',
    flag: '✝️',
    color: Color(0xFFD32F2F),
  );

  static List<Nationality> getAll() => [ottomans, byzantines, crusaders];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nationality && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
