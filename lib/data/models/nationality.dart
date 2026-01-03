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

  static const turkish = Nationality(
    id: 'tr',
    name: 'Turkish',
    flag: '🇹🇷',
    color: Color(0xFFE30A17),
  );

  static const greek = Nationality(
    id: 'gr',
    name: 'Greek',
    flag: '🇬🇷',
    color: Color(0xFF0D5EAF),
  );

  static const bulgarian = Nationality(
    id: 'bg',
    name: 'Bulgarian',
    flag: '🇧🇬',
    color: Color(0xFF00966E),
  );

  static List<Nationality> getAll() => [turkish, greek, bulgarian];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nationality && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
