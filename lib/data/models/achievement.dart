enum Achievement {
  // Combat
  firstBlood(
    'First Blood',
    'Win your first battle',
    '🩸',
  ),
  undefeated(
    'Undefeated',
    'Win a game without losing a single battle',
    '🛡️',
  ),
  blitzkrieg(
    'Blitzkrieg',
    'Conquer 3 villages in 5 turns',
    '⚡',
  ),
  cavalryMaster(
    'Cavalry Master',
    'Win a battle using only cavalry units',
    '🐴',
  ),

  // Economic
  merchantPrince(
    'Merchant Prince',
    'Accumulate 5,000 gold in a single game',
    '💰',
  ),

  // Strategic
  empireBuilder(
    'Empire Builder',
    'Control 10 or more villages at once',
    '🏛️',
  ),
  speedRun(
    'Speed Run',
    'Win a game in under 25 turns',
    '⏱️',
  ),
  marathon(
    'Marathon',
    'Win a game lasting 60+ turns',
    '🏃',
  ),
  underdog(
    'Underdog',
    'Win as a minor faction',
    '🐺',
  ),
  worldConqueror(
    'World Conqueror',
    'Win with every faction at least once',
    '🌍',
  ),
  survivor(
    'Survivor',
    'Win after losing your capital city',
    '🔥',
  ),

  // Victory type
  economicVictor(
    'Trade Empire',
    'Win by Economic victory',
    '💎',
  ),
  militaryVictor(
    'Warlord',
    'Win by Military victory',
    '⚔️',
  ),
  imperialVictor(
    'Civilization Builder',
    'Win by Imperial victory',
    '👑',
  ),

  // Event-related
  winterWarrior(
    'Winter Warrior',
    'Conquer a village during Harsh Winter',
    '❄️',
  ),
  earthquakeSurvivor(
    'Earthquake Survivor',
    'Win after an earthquake hit your village',
    '🌍',
  );

  final String displayName;
  final String description;
  final String emoji;
  const Achievement(this.displayName, this.description, this.emoji);
}
