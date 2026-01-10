import 'package:isar/isar.dart';
import 'package:mindfree/data/models/note.dart';
import 'package:mindfree/data/models/project.dart';
import 'package:mindfree/data/models/task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'isar_service.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isar(IsarRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open([
    ProjectSchema,
    TaskSchema,
    NoteSchema,
  ], directory: dir.path);
}

class IsarService {
  final Isar isar;
  IsarService(this.isar);

  // Helper methods for generic CRUD can be added here if needed
}
