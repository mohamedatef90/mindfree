import 'package:isar/isar.dart';
import 'package:mindfree/data/models/note.dart';
import 'package:mindfree/data/repositories/note_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_controller.g.dart';

@riverpod
class NotesController extends _$NotesController {
  @override
  FutureOr<void> build() async {}

  Future<void> saveNote({
    int? id,
    required int parentId,
    required int parentType,
    required String content,
    List<String>? attachmentPaths,
    String? extractedText,
  }) async {
    final note = Note()
      ..id = id ?? Isar.autoIncrement
      ..parentId = parentId
      ..parentType = parentType
      ..content = content
      ..attachmentPaths = attachmentPaths
      ..extractedText = extractedText
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await ref.read(noteRepositoryProvider).saveNote(note);
  }

  Future<void> deleteNote(Id id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
  }
}

@riverpod
Stream<List<Note>> allNotes(AllNotesRef ref) {
  return ref.watch(noteRepositoryProvider).watchAllNotes();
}

@riverpod
Stream<List<Note>> notesByParent(
  NotesByParentRef ref,
  int parentType,
  int parentId,
) {
  return ref
      .watch(noteRepositoryProvider)
      .watchNotesByParent(parentType, parentId);
}
