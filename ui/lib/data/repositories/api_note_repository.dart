import '../../domain/repositories/note_repository.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/extended_models.dart';
import '../../core/api_service.dart';

class ApiNoteRepository implements NoteRepository {
  final ApiService _api;

  ApiService get api => _api;
  
  ApiNoteRepository(this._api);

  @override
  Future<List<NoteModel>> getNotes() async {
    final response = await _api.get('/student/notes');
    if (response['success'] == true) {
      final List<dynamic> data = response['notes'];
      return data.map((json) => NoteModel.fromJson(json)).toList(); // Reusing fromJson
    }
    return [];
  }

  @override
  Future<NoteModel> createNote(NoteModel note) async {
    final response = await _api.post('/student/notes', {
      'title': note.title,
      'content': note.content,
      'slideNumber': note.slideNumber,
      'color': note.color,
    });
    return NoteModel.fromJson(response['note']);
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await _api.put('/student/notes/${note.id}', {
      'title': note.title,
      'content': note.content,
      'slideNumber': note.slideNumber,
      'color': note.color,
    });
  }

  @override
  Future<void> deleteNote(String id) async {
    await _api.delete('/student/notes/$id');
  }
}
