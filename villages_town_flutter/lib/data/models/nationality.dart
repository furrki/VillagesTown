class Nationality {
  final String id;
  final String name;
  final String flag;

  const Nationality({
    required this.id,
    required this.name,
    required this.flag,
  });

  static const turkish = Nationality(id: 'tr', name: 'Turkish', flag: '🇹🇷');
  static const greek = Nationality(id: 'gr', name: 'Greek', flag: '🇬🇷');
  static const bulgarian = Nationality(id: 'bg', name: 'Bulgarian', flag: '🇧🇬');

  static List<Nationality> getAll() => [turkish, greek, bulgarian];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Nationality && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
