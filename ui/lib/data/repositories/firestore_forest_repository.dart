import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/extended_models.dart';
import '../../domain/repositories/forest_repository.dart';

class FirestoreForestRepository implements ForestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // TODO: Use real userId
  final String _userId = 'current_user_id'; 

  @override
  Future<ForestStats> getStats() async {
    try {
      final doc = await _firestore.collection('forest_stats').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final growthList = (data['recentGrowth'] as List?)?.map((g) {
           return TreeGrowth(
             id: g['id'] ?? '',
             plantedDate: (g['plantedDate'] as Timestamp).toDate(),
             type: g['type'] ?? 'oak',
             focusMinutes: g['focusMinutes'] ?? 0,
           );
        }).toList() ?? [];

        return ForestStats(
          totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
          currentStreakDays: data['currentStreakDays'] ?? 0,
          treesPlanted: data['treesPlanted'] ?? 0,
          seeds: data['seeds'] ?? 0,
          recentGrowth: growthList,
        );
      }
      // If no stats yet, return empty
      return ForestStats(
        totalFocusMinutes: 0,
        currentStreakDays: 0,
        treesPlanted: 0,
        seeds: 0,
        recentGrowth: [],
      );
    } catch (e) {
      return ForestStats(
        totalFocusMinutes: 0,
        currentStreakDays: 0,
        treesPlanted: 0,
        seeds: 0,
        recentGrowth: [],
      );
    }
  }

  @override
  Future<void> addFocusSession(int minutes, String type) async {
    // We replicate the logic from InMemory logic OR we just update the doc.
    // Ideally, we fetch, update, and save. Transactional ideally.
    final ref = _firestore.collection('forest_stats').doc(_userId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      ForestStats currentStats;
      
      if (!snapshot.exists) {
        currentStats = ForestStats(totalFocusMinutes: 0, currentStreakDays: 0, treesPlanted: 0, seeds: 0, recentGrowth: []);
      } else {
        final data = snapshot.data()!;
        final growthList = (data['recentGrowth'] as List?)?.map((g) {
           return TreeGrowth(
             id: g['id'],
             plantedDate: (g['plantedDate'] as Timestamp).toDate(),
             type: g['type'],
             focusMinutes: g['focusMinutes'],
           );
        }).toList() ?? [];
        currentStats = ForestStats(
          totalFocusMinutes: data['totalFocusMinutes'],
          currentStreakDays: data['currentStreakDays'],
          treesPlanted: data['treesPlanted'],
          seeds: data['seeds'] ?? 0,
          recentGrowth: growthList,
        );
      }

      // Logic
      int newTreesForSession = 0;
      if (minutes >= 30) {
        newTreesForSession = (minutes / 30).floor();
      }
      
      final newExampleTree = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'plantedDate': Timestamp.now(),
        'type': minutes >= 30 ? type : 'dead_shrub',
        'focusMinutes': minutes,
      };

      // Streak Logic (simplified)
      int newStreak = currentStats.currentStreakDays;
      if (currentStats.recentGrowth.isEmpty) {
        newStreak = 1;
      } else {
         // simplified verification
         // In real app, check dates. 
         // For now, let's just increment for demo if it's a new session
         newStreak++;
      }

      transaction.set(ref, {
        'totalFocusMinutes': currentStats.totalFocusMinutes + minutes,
        'currentStreakDays': newStreak,
        'treesPlanted': currentStats.treesPlanted + newTreesForSession,
        'recentGrowth': [newExampleTree, ...snapshot.exists ? (snapshot.data()!['recentGrowth'] as List) : []],
      });
    });
  }
}
