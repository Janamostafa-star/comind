import '../models/session_model.dart';

abstract class NoteRepository {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> createNote(NoteModel note);
  Future<void> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
}
