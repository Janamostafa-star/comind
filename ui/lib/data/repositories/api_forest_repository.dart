import 'package:flutter/foundation.dart';
import '../../domain/repositories/forest_repository.dart';
import '../../domain/models/extended_models.dart';
import '../../core/api_service.dart';

class ApiForestRepository implements ForestRepository {
  final ApiService _api;
  
  // Cache to behave like in-memory for immediate UI updates, but syncs with backend
  ForestStats? _cachedStats;

  ApiForestRepository(this._api);

  @override
  Future<ForestStats> getStats() async {
    try {
      final response = await _api.get('/student/forest');
      
      if (response['success'] == true && response['forest'] != null) {
        final data = response['forest'];
        final List<dynamic> growthList = data['recentGrowth'] ?? [];
        
        _cachedStats = ForestStats(
          totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
          currentStreakDays: 0, // Backend doesn't fully track streak logic yet in 'forest' object. 
          // Ideally backend calculates this. For now default 0.
          
          treesPlanted: data['treesPlanted'] ?? 0,
          seeds: data['seeds'] ?? 0,
          recentGrowth: growthList.map((g) => TreeGrowth(
            id: g['id'],
            plantedDate: DateTime.parse(g['plantedDate']),
            type: g['type'],
            focusMinutes: g['focusMinutes'],
          )).toList(),
        );
        
        // Improve: Fetch total minutes from /student/stats if possible, but let's stick to forest data first.
        return _cachedStats!;
      }
    } catch (e) {
      print('Error fetching forest stats: $e');
      if (_cachedStats != null) return _cachedStats!;
    }

    // Fallback if failed or empty
    return ForestStats(
      totalFocusMinutes: 0,
      currentStreakDays: 0,
      treesPlanted: 0,
      seeds: 0,
      recentGrowth: [],
    );
  }

  @override
  Future<void> addFocusSession(int minutes, String type) async {
    try {
      final response = await _api.post('/student/forest/grow', {
        'minutes': minutes,
        'type': type,
      });

      if (response['success'] == true) {
        // Backend returns updated forest
        final data = response['forest'];
        final List<dynamic> growthList = data['recentGrowth'] ?? [];

        _cachedStats = ForestStats(
          totalFocusMinutes: (_cachedStats?.totalFocusMinutes ?? 0) + minutes, // Optimistic update for minutes
          currentStreakDays: _cachedStats?.currentStreakDays ?? 0, 
          treesPlanted: data['treesPlanted'] ?? 0,
          seeds: data['seeds'] ?? 0,
          recentGrowth: growthList.map((g) => TreeGrowth(
            id: g['id'],
            plantedDate: DateTime.parse(g['plantedDate']),
            type: g['type'],
            focusMinutes: g['focusMinutes'],
          )).toList(),
        );
      }
    } catch (e) {
      print('Error adding focus session: $e');
      // In a real app, queue this for retry
    }
  }
}
