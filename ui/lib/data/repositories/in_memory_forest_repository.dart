import 'dart:async';
import '../../domain/models/extended_models.dart';
import '../../domain/repositories/forest_repository.dart';

class InMemoryForestRepository implements ForestRepository {
  // App starts fresh with no fake data
  ForestStats _stats = ForestStats(
    totalFocusMinutes: 0,
    currentStreakDays: 0,
    treesPlanted: 0,
    seeds: 0,
    recentGrowth: [],
  );

  @override
  Future<ForestStats> getStats() async {
    return _stats;
  }

  @override
  Future<void> addFocusSession(int minutes, String type) async {
    // Logic: 
    // 10 minutes = 1 seed.
    // 5 seeds = 1 fully grown tree.
    
    int newlyEarnedSeeds = (minutes / 10).floor();
    int totalSeeds = _stats.seeds + newlyEarnedSeeds;
    
    int newTrees = (totalSeeds / 5).floor();
    int remainingSeeds = totalSeeds % 5;

    // Add to recent growth
    final newTree = TreeGrowth(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plantedDate: DateTime.now(),
      type: newlyEarnedSeeds > 0 ? type : 'dead_shrub',
      focusMinutes: minutes,
    );
    
    // Update streak (simple logic)
    int newStreak = _stats.currentStreakDays;
    if (_stats.recentGrowth.isEmpty) {
      newStreak = 1;
    } else {
      final lastDate = _stats.recentGrowth.first.plantedDate;
      final difference = DateTime.now().difference(lastDate).inDays;
      if (difference == 1) {
        newStreak++;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    _stats = ForestStats(
      totalFocusMinutes: _stats.totalFocusMinutes + minutes,
      currentStreakDays: newStreak, 
      treesPlanted: _stats.treesPlanted + newTrees,
      seeds: remainingSeeds,
      recentGrowth: [newTree, ..._stats.recentGrowth],
    );
  }
}
