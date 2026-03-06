import 'package:flutter/material.dart';
import '../../data/models/achievement.dart';
import '../../data/models/game_record.dart';
import '../../data/models/nationality.dart';
import '../../engines/progression_engine.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await ProgressionEngine.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11141C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('STATS & ACHIEVEMENTS',
            style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.white70)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverview(),
                  const SizedBox(height: 24),
                  _buildAchievements(),
                  const SizedBox(height: 24),
                  _buildRecentGames(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview() {
    final stats = _stats!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statBox('Games', '${stats['totalGames']}'),
              _statBox('Wins', '${stats['totalWins']}'),
              _statBox('High Score', '${stats['highScore']}'),
              if (stats['fastestWin'] != null)
                _statBox('Fastest', 'T${stats['fastestWin']}'),
            ],
          ),
          const SizedBox(height: 12),
          // Faction wins
          if ((stats['factionWins'] as Map).isNotEmpty) ...[
            const Divider(color: Colors.white12),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (stats['factionWins'] as Map<String, int>)
                  .entries
                  .map((e) {
                final nat = Nationality.getAll().firstWhere(
                    (n) => n.id == e.key,
                    orElse: () => Nationality.byzantines);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: nat.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${nat.name}: ${e.value}W',
                    style: TextStyle(fontSize: 11, color: nat.color),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final unlocked = _stats!['unlocked'] as Set<String>;
    final total = _stats!['totalAchievements'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('ACHIEVEMENTS',
                style: TextStyle(
                    fontSize: 12, letterSpacing: 2, color: Colors.white54, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${unlocked.length}/$total',
                style: const TextStyle(fontSize: 12, color: Colors.amber)),
          ],
        ),
        const SizedBox(height: 12),
        ...Achievement.values.map((a) {
          final isUnlocked = unlocked.contains(a.name);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.amber.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: isUnlocked
                  ? Border.all(color: Colors.amber.withValues(alpha: 0.2))
                  : null,
            ),
            child: Row(
              children: [
                Text(
                  isUnlocked ? a.emoji : '🔒',
                  style: TextStyle(fontSize: 18, color: isUnlocked ? null : Colors.white24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.white : Colors.white30,
                        ),
                      ),
                      Text(
                        a.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isUnlocked ? Colors.white54 : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentGames() {
    final records = (_stats!['records'] as List<GameRecord>).reversed.take(10).toList();
    if (records.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT GAMES',
            style: TextStyle(
                fontSize: 12, letterSpacing: 2, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...records.map((r) {
          final nat = Nationality.getAll().firstWhere(
              (n) => n.id == r.factionId,
              orElse: () => Nationality.byzantines);
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: r.isVictory ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(nat.name,
                    style: TextStyle(fontSize: 12, color: nat.color, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (r.victoryType != null)
                  Text(r.victoryType!,
                      style: const TextStyle(fontSize: 10, color: Colors.white38)),
                const Spacer(),
                Text('${r.score}pts',
                    style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('T${r.turns}',
                    style: const TextStyle(fontSize: 11, color: Colors.white30)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
