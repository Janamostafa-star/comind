import '../models/extended_models.dart';

abstract class ForestRepository {
  Future<ForestStats> getStats();
  Future<void> addFocusSession(int minutes, String type);
}
