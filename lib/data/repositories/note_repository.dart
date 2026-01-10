import 'package:isar/isar.dart';
import 'package:mindfree/data/models/note.dart';
import 'package:mindfree/data/services/isar_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_repository.g.dart';

class NoteRepository {
  final Isar isar;
  NoteRepository(this.isar);

  Future<List<Note>> getNotesByParent(int parentType, int parentId) async {
    return isar.notes
        .filter()
        .parentTypeEqualTo(parentType)
        .and()
        .parentIdEqualTo(parentId)
        .findAll();
  }

  Stream<List<Note>> watchNotesByParent(int parentType, int parentId) {
    return isar.notes
        .filter()
        .parentTypeEqualTo(parentType)
        .and()
        .parentIdEqualTo(parentId)
        .watch(fireImmediately: true);
  }

  Stream<List<Note>> watchAllNotes() {
    return isar.notes.where().sortByCreatedAtDesc().watch(
      fireImmediately: true,
    );
  }

  Future<Note?> getNoteById(Id id) async {
    return isar.notes.get(id);
  }

  Future<void> saveNote(Note note) async {
    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });
  }

  Future<void> deleteNote(Id id) async {
    await isar.writeTxn(() async {
      await isar.notes.delete(id);
    });
  }

  Future<void> deleteNotesByParent(int parentType, int parentId) async {
    await isar.writeTxn(() async {
      await isar.notes
          .filter()
          .parentTypeEqualTo(parentType)
          .and()
          .parentIdEqualTo(parentId)
          .deleteAll();
    });
  }
}

@riverpod
NoteRepository noteRepository(NoteRepositoryRef ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) throw Exception('Isar not initialized');
  return NoteRepository(isar);
}
